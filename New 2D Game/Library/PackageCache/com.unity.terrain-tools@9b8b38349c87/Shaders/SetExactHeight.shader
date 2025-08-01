    Shader "Hidden/TerrainTools/SetExactHeight" {

    Properties { _MainTex ("Texture", any) = "" {} }

    SubShader {

        ZTest Always Cull Off ZWrite Off

        CGINCLUDE

            #include "UnityCG.cginc"
            #include "Packages/com.unity.terrain-tools/Shaders/TerrainTools.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;      // 1/width, 1/height, width, height

            sampler2D _BrushTex;
            sampler2D _FilterTex;

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
        ENDCG


        Pass
        {
            Name "Set Exact Height"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment SetExactHeight

            float4 SetExactHeight(v2f i) : SV_Target
            {
                float2 brushUV = PaintContextUVToBrushUV(i.pcUV);
                float2 heightmapUV = i.pcUV;

                // out of bounds multiplier
                float oob = all(saturate(brushUV) == brushUV) ? 1.0f : 0.0f;

                float height = UnpackHeightmap(tex2D(_MainTex, heightmapUV));
                //float brushStrength = saturate(BRUSH_STRENGTH * oob * UnpackHeightmap(tex2D(_BrushTex, brushUV)));
                float brushStrength = BRUSH_STRENGTH * oob * UnpackHeightmap(tex2D(_BrushTex, brushUV)) * UnpackHeightmap(tex2D(_FilterTex, i.pcUV));

                float targetHeight = BRUSH_TARGETHEIGHT;

                // have to do this check to ensure strength 0 == no change (code below makes a super tiny change even with strength 0)
                if (brushStrength > 0.0f)
                {
                    float deltaHeight = height - targetHeight;

                    // see https://www.desmos.com/calculator/880ka3lfkl
                    float p = saturate(brushStrength);
                    float w = (1.0f - p) / (p + 0.000001f);
//                  float w = (1.0f - p*p) / (p + 0.000001f);       // alternative TODO test and compare
                    float fx = clamp(w * deltaHeight, -1.0f, 1.0f);
                    float g = fx * (0.5f * fx * sign(fx) - 1.0f);

                    deltaHeight = deltaHeight + g / w;

                    height = targetHeight + deltaHeight;
                }


                //return PackHeightmap(saturate(brushStrength) * targetHeight);
                return PackHeightmap(lerp(height, targetHeight, brushStrength));
            }
            ENDCG
        }

        Pass
        {
            Name "Fill Height"

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment FillHeight

            float4 FillHeight( v2f i ) : SV_Target
            {
                float oldHeight = UnpackHeightmap(tex2D(_MainTex, i.pcUV));
                return PackHeightmap(lerp(oldHeight, BRUSH_TARGETHEIGHT,  UnpackHeightmap(tex2D(_FilterTex, i.pcUV))));
            }

            ENDCG
        }
    }
    Fallback Off
}
