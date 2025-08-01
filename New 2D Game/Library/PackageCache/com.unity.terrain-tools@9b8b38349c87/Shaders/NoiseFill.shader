    Shader "Hidden/TerrainTools/NoiseFill"
    {

        Properties
        {
            _MainTex ("Texture", any) = "" {}
        }

        SubShader
        {

            ZTest Always Cull Off ZWrite Off

            HLSLINCLUDE

            #include "UnityCG.cginc"
            #include "Packages/com.unity.terrain-tools/Shaders/TerrainTools.hlsl"

            #define kMaxHeight          (32766.0f/65535.0f)
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;      // 1/width, 1/height, width, height

            sampler2D _BrushTex;

            float4 _BrushParams;
            #define BRUSH_STRENGTH      (_BrushParams[0])
            #define BRUSH_TARGETHEIGHT  (_BrushParams[1])
            #define BRUSH_PINCHAMOUNT   (_BrushParams[2])
            #define BRUSH_ROTATION      (_BrushParams[3])

            struct appdata_t {
                float4 vertex : POSITION;
                float2 pcUV : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 pcUV : TEXCOORD0;
            };

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pcUV = v.pcUV;
                return o;
            }

            ENDHLSL


            Pass
            {
                Name "Noise Fill"

                HLSLPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.terrain-tools/Shaders/NoiseLib/Fbm/Perlin.hlsl"

                float4 _TerrainXform;
                float4 _TerrainScale;

                float2 TransformPosition( float2 brushUV )
                {
                    return _TerrainXform.xz + brushUV * _TerrainScale.xz;
                }

                float4 frag(v2f i) : SV_Target
                {
                    float h = UnpackHeightmap( tex2D( _MainTex, i.pcUV ) );
                    float2 pos = TransformPosition( i.pcUV );
                    float n = noise_FbmPerlin( pos, GetDefaultFbmFractalInput() );

                    return PackHeightmap( clamp(n, 0, kMaxHeight) );
                }

                ENDHLSL
            }
        }

    Fallback Off
}
