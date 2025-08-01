//-------------------------------------------------------------------------------------
// Defines
//-------------------------------------------------------------------------------------

// Use surface gradient normal mapping as it handle correctly triplanar normal mapping and multiple UVSet
#define SURFACE_GRADIENT

//-------------------------------------------------------------------------------------
// Fill SurfaceData/Builtin data function
//-------------------------------------------------------------------------------------

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Sampling/SampleUVMapping.hlsl"
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialUtilities.hlsl"

#ifndef UNITY_TERRAIN_CB_VARS
    #define UNITY_TERRAIN_CB_VARS
#endif

#ifndef UNITY_TERRAIN_CB_DEBUG_VARS
    #define UNITY_TERRAIN_CB_DEBUG_VARS
#endif

CBUFFER_START(UnityTerrain)
    UNITY_TERRAIN_CB_VARS
#ifdef UNITY_INSTANCING_ENABLED
    float4 _TerrainHeightmapRecipSize;  // float4(1.0f/width, 1.0f/height, 1.0f/(width-1), 1.0f/(height-1))
    float4 _TerrainHeightmapScale;      // float4(hmScale.x, hmScale.y / (float)(kMaxHeight), hmScale.z, 0.0f)
#endif
#ifdef DEBUG_DISPLAY
    UNITY_TERRAIN_CB_DEBUG_VARS
#endif
CBUFFER_END

#ifdef UNITY_INSTANCING_ENABLED
    TEXTURE2D(_TerrainHeightmapTexture);
    TEXTURE2D(_TerrainNormalmapTexture);
    #ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
        SAMPLER(sampler_TerrainNormalmapTexture);
    #endif
#endif

// Declare distortion variables just to make the code compile with the Debug Menu.
// See LitBuiltinData.hlsl:73.
TEXTURE2D(_DistortionVectorMap);
SAMPLER(sampler_DistortionVectorMap);

float _DistortionScale;
float _DistortionVectorScale;
float _DistortionVectorBias;
float _DistortionBlurScale;
float _DistortionBlurRemapMin;
float _DistortionBlurRemapMax;

// Vertex height displacement
#ifdef HAVE_MESH_MODIFICATION

UNITY_INSTANCING_BUFFER_START(Terrain)
UNITY_DEFINE_INSTANCED_PROP(float4, _TerrainPatchInstanceData)  // float4(xBase, yBase, skipScale, ~)
UNITY_INSTANCING_BUFFER_END(Terrain)

// Visualization
//Heatmap
TEXTURE2D(_HeatmapGradient);            SAMPLER(sampler_HeatmapGradient);
TEXTURE2D(_HeatHeightmap);              SAMPLER(sampler_HeatHeightmap);
CBUFFER_START(Heatmap)
half4 _HeatmapData;
CBUFFER_END

//Splatmap
TEXTURE2D(_SplatmapTex);                SAMPLER(sampler_SplatmapTex);

float4 ConstructTerrainTangent(float3 normal, float3 positiveZ)
{
    // Consider a flat terrain. It should have tangent be (1, 0, 0) and bitangent be (0, 0, 1) as the UV of the terrain grid mesh is a scale of the world XZ position.
    // In CreateWorldToTangent function (in SpaceTransform.hlsl), it is cross(normal, tangent) * sgn for the bitangent vector.
    // It is not true in a left-handed coordinate system for the terrain bitangent, if we provide 1 as the tangent.w. It would produce (0, 0, -1) instead of (0, 0, 1).
    // Also terrain's tangent calculation was wrong in a left handed system because cross((0,0,1), terrainNormalOS) points to the wrong direction as negative X.
    // Therefore all the 4 xyzw components of the tangent needs to be flipped to correct the tangent frame.
    // (See TerrainLitData.hlsl - GetSurfaceAndBuiltinData)
    float3 tangent = cross(normal, positiveZ);
    return float4(tangent, -1);
}

AttributesMesh ApplyMeshModification(AttributesMesh input, float3 timeParameters)
{
#ifdef UNITY_INSTANCING_ENABLED
    float2 patchVertex = input.positionOS.xy;
    float4 instanceData = UNITY_ACCESS_INSTANCED_PROP(Terrain, _TerrainPatchInstanceData);

    float2 sampleCoords = (patchVertex.xy + instanceData.xy) * instanceData.z; // (xy + float2(xBase,yBase)) * skipScale
    float height = UnpackHeightmap(_TerrainHeightmapTexture.Load(int3(sampleCoords, 0)));

    input.positionOS.xz = sampleCoords * _TerrainHeightmapScale.xz;
    input.positionOS.y = height * _TerrainHeightmapScale.y;

#ifdef ATTRIBUTES_NEED_NORMAL
    input.normalOS = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb * 2 - 1;
#endif

#if defined(VARYINGS_NEED_TEXCOORD0) || defined(VARYINGS_DS_NEED_TEXCOORD0)
#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
    input.uv0 = sampleCoords;
#else
    input.uv0 = sampleCoords * _TerrainHeightmapRecipSize.zw;
#endif
#endif
#endif

#ifdef ATTRIBUTES_NEED_TANGENT
    input.tangentOS = ConstructTerrainTangent(input.normalOS, float3(0, 0, 1));
#endif
    return input;
}

#endif // HAVE_MESH_MODIFICATION

// We don't use emission for terrain
#define _EmissiveColor float3(0,0,0)
#define _AlbedoAffectEmissive 0
#define _EmissiveExposureWeight 0
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitBuiltinData.hlsl"
#undef _EmissiveColor
#undef _AlbedoAffectEmissive
#undef _EmissiveExposureWeight

#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/TerrainLit/TerrainLitSurfaceData.hlsl"

void TerrainLitShade(float2 uv, inout TerrainLitSurfaceData surfaceData);
void TerrainLitDebug(float2 uv, inout float3 baseColor);

float3 ConvertToNormalTS(float3 normalData, float3 tangentWS, float3 bitangentWS)
{
#ifdef _NORMALMAP
    #ifdef SURFACE_GRADIENT
        return SurfaceGradientFromTBN(normalData.xy, tangentWS, bitangentWS);
    #else
        return normalData;
    #endif
#else
    #ifdef SURFACE_GRADIENT
        return float3(0.0, 0.0, 0.0); // No gradient
    #else
        return float3(0.0, 0.0, 1.0);
    #endif
#endif
}

void GetSurfaceAndBuiltinData(inout FragInputs input, float3 V, inout PositionInputs posInput, out SurfaceData surfaceData, out BuiltinData builtinData)
{
#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
    float2 terrainNormalMapUV = (input.texCoord0.xy + 0.5f) * _TerrainHeightmapRecipSize.xy;
    input.texCoord0.xy *= _TerrainHeightmapRecipSize.zw;
#endif

    // terrain lightmap uvs are always taken from uv0
    input.texCoord1 = input.texCoord2 = input.texCoord0;

    TerrainLitSurfaceData terrainLitSurfaceData;
    InitializeTerrainLitSurfaceData(terrainLitSurfaceData);
    TerrainLitShade(input.texCoord0.xy, terrainLitSurfaceData);

    ZERO_INITIALIZE(SurfaceData, surfaceData);

#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
    #ifdef TERRAIN_PERPIXEL_NORMAL_OVERRIDE
        float3 normalWS = terrainLitSurfaceData.normalData.xyz; // normalData directly contains normal in world space.
        surfaceData.normalWS = normalWS;
    #else
        float3 normalOS = SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, terrainNormalMapUV).rgb * 2 - 1;
        float3 normalWS = mul((float3x3)GetObjectToWorldMatrix(), normalOS);
    #endif
    float4 tangentWS = ConstructTerrainTangent(normalWS, GetObjectToWorldMatrix()._13_23_33);
    input.tangentToWorld = BuildWorldToTangent(tangentWS, normalWS);
#endif
    surfaceData.tangentWS = normalize(input.tangentToWorld[0].xyz); // The tangent is not normalize in tangentToWorld for mikkt. Tag: SURFACE_GRADIENT

#if !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL) || !defined(TERRAIN_PERPIXEL_NORMAL_OVERRIDE)
    float3 normalTS = ConvertToNormalTS(terrainLitSurfaceData.normalData, input.tangentToWorld[0], input.tangentToWorld[1]);
    GetNormalWS(input, normalTS, surfaceData.normalWS, float3(1.0, 1.0, 1.0));
#endif
    surfaceData.geomNormalWS = input.tangentToWorld[2];

//Visualization
#ifdef _HEATMAP
#ifdef LOCAL_SPACE
    half height = UnpackHeightmap(SAMPLE_TEXTURE2D(_HeatHeightmap, sampler_HeatHeightmap, input.texCoord0.xy)) * 2;
#else
    half height = ((GetAbsolutePositionWS(posInput.positionWS).y - _HeatmapData.z) - _HeatmapData.x) / (_HeatmapData.y - _HeatmapData.x);
#endif
    surfaceData.baseColor = SAMPLE_TEXTURE2D(_HeatmapGradient, sampler_HeatmapGradient, height.xx).rgb;
#elif _SPLATMAP_PREVIEW
    surfaceData.baseColor = SAMPLE_TEXTURE2D(_SplatmapTex, sampler_SplatmapTex, input.texCoord0.xy).rgb;
#else
    surfaceData.baseColor = terrainLitSurfaceData.albedo;
#endif

    // Init non-zero surface parameters
    surfaceData.perceptualSmoothness = terrainLitSurfaceData.smoothness;
    surfaceData.metallic = terrainLitSurfaceData.metallic;
    surfaceData.ambientOcclusion = terrainLitSurfaceData.ao;
    surfaceData.thickness = 1;
    surfaceData.materialFeatures = MATERIALFEATUREFLAGS_LIT_STANDARD;
    surfaceData.ior = 1.0;
    surfaceData.transmittanceColor = float3(1.0, 1.0, 1.0);
    surfaceData.atDistance = 1000000.0;

    float3 bentNormalWS = surfaceData.normalWS;

    // By default we use the ambient occlusion with Tri-ace trick (apply outside) for specular occlusion.
#ifdef _MASKMAP
    surfaceData.specularOcclusion = GetSpecularOcclusionFromAmbientOcclusion(ClampNdotV(dot(surfaceData.normalWS, V)), surfaceData.ambientOcclusion, PerceptualSmoothnessToRoughness(surfaceData.perceptualSmoothness));
#else
    surfaceData.specularOcclusion = 1.0;
#endif

#ifdef DEBUG_DISPLAY
    if (_DebugMipMapMode != DEBUGMIPMAPMODE_NONE)
    {
        TerrainLitDebug(input.texCoord0.xy, surfaceData.baseColor);
        surfaceData.metallic = 0;
    }
    // We need to call ApplyDebugToSurfaceData after filling the surfarcedata and before filling builtinData
    // as it can modify attribute use for static lighting
    ApplyDebugToSurfaceData(input.tangentToWorld, surfaceData);
#endif

    GetBuiltinData(input, V, posInput, surfaceData, 1, bentNormalWS, 0, builtinData);
}
