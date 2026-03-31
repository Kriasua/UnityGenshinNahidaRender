Shader "Unlit/PBRStudy"
{
   Properties {
    
        _Roughness("Roughness", Range(0,1)) = 0
       _Metallic("Metallic", Range(0,1)) =0
       _BaseTex("BaseTex",2D ) = "white"{}
       _LightColor("LightColor",color) = (1,1,1,1)
    
    
    }
    SubShader
    {
        
        LOD 100
        /*定义一个渲染通道（Pass），专门用于阴影投射。
        Name "ShadowCaster"：命名该Pass为"ShadowCaster"，便于调试。
        Tags { "LightMode" = "ShadowCaster" }：标记该Pass为阴影投射阶段，
        Unity会在此Pass中渲染物体的阴影信息到阴影贴图（Shadow Map）。*/
        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            /*作用：配置深度和剔除等渲染状态。
            ​**ZWrite On**：启用深度写入，将像素深度值写入深度缓冲区（关键，阴影需要精确深度）。
            ​**ZTest LEqual**：深度测试模式为“小于等于当前深度值”时通过（默认，保留最靠近相机的物体）。
            ​**ColorMask 0**：关闭颜色输出（阴影不需要颜色，只关心深度）。
            ​**Cull Off**：禁用背面剔除，渲染双面阴影（避免物体内部因剔除导致阴影缺失）。*/
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off
            
            /*作用：定义HLSL代码块的开始。
            ​**#pragma exclude_renderers gles gles3 glcore**：排除对GLES（移动端）平台的支持，仅保留PC/主机端（可能因使用了高级特性）。
            ​**#pragma target 4.5**：指定Shader Model 4.5，使用更高精度和功能。*/
            
            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            /*作用：启用材质特性开关。
            ​**_ALPHATEST_ON**：支持Alpha Test（透明裁剪），用于丢弃低于阈值的像素（如树叶、栅栏）。
            ​**_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A**：光滑度（Smoothness）数据存储在Albedo纹理的Alpha通道。*/

            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            /*支持GPU实例化（批量渲染相同物体）。
            ​**multi_compile_instancing**：启用实例化渲染。
            ​**_DOTS_INSTANCING_ON**：支持Unity DOTS（Data-Oriented Technology Stack）的实例化。*/
            
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _DOTS_INSTANCING_ON


            /*作用：根据光源类型编译不同代码。
            ​**1_CASTING_PUNCTUAL_LIGHT_SHADOW**：处理点光源（Point Light）或聚光灯（Spotlight）的阴影投射逻辑（与平行光区分）。*/

            // Universal Pipeline keywords
            #pragma multi_compile_vertex _ 1_CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags {"Lightmode" = "DepthNormals"}
            
            ZWrite On
            Cull Off
            
            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SOMMTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "DrawObject"
            Tags
            {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType"="Opaque"
                "LightMode"="UniversalForward"
            }
            Cull Off
            
            HLSLPROGRAM
            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _SHADOWS_SOFT
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            // 引用Unity URP核心库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
                half4 color : COLOR0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 positionVS : TEXCOORD2;
                float4 positionCS : SV_POSITION;
                float4 positionNDC : TEXCOORD3;
                float3 normalWS : TEXCOORD4;
                float3 tangentWS : TEXCOORD5;
                float3 bitangentWS : TEXCOORD6;
                float fogCoord : TEXCOORD7;
                float4 shadowCoord : TEXCOORD8;
            };

            CBUFFER_START(UnityPerMaterial)
            
            sampler2D _BaseTex;
            float4 _BaseTex_ST;
            float _Roughness;
            float _Metallic;
            float4 _LightColor;
            
            
            CBUFFER_END

            v2f vert(appdata v)
            {
                v2f o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);  // UV变换
                o.positionWS = vertexInput.positionWS;  // 世界空间位置
                o.positionVS = vertexInput.positionVS;  // 视图空间位置
                o.positionCS = vertexInput.positionCS;  // 裁剪空间位置
                o.positionNDC = vertexInput.positionNDC;// 标准化设备坐标

                // 获取法线/切线数据
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(v.normal, v.tangent);
                o.tangentWS = vertexNormalInput.tangentWS;    // 世界空间切线
                o.bitangentWS = vertexNormalInput.bitangentWS;// 世界空间副切线
                o.normalWS = vertexNormalInput.normalWS;      // 世界空间法线

                // 计算雾效和阴影
                o.fogCoord = ComputeFogFactor(vertexInput.positionCS.z); // 基于深度的雾效
                o.shadowCoord = TransformWorldToShadowCoord(vertexInput.positionWS); // 阴影坐标
                
                return o;
            }


            float GeometrySchlickGGX(float fl, float k)
            {
                return (fl)/max((fl * (1.0f-k) + k),0.001);
            }

            float GeometrySmith(float NoV, float NoL, float k)
            {
                float ggx1 = GeometrySchlickGGX(NoV,k);
                float ggx2 = GeometrySchlickGGX(NoL,k);
                return ggx1 * ggx2;
            }

            float NormalDistribution(float alpha, float pi, float NoH)
            {
                return (alpha*alpha)/max((pi*pow((NoH * NoH *(alpha*alpha-1)+1),2)),0.001);
            }

            float3 Fresnel(float3 BaseColor, float Metallic,float HoV)
            {
                float3 F0 = float3(0.04,0.04,0.04);
                F0 = lerp(F0,BaseColor,Metallic);
                return F0 + ((1-F0)*pow(1-(HoV),5));
            }
            
            float4 frag(v2f i,bool IsFacing : SV_IsfrontFace) : SV_Target
            {
                Light light = GetMainLight(i.shadowCoord);
                float3 BaseColor = tex2D(_BaseTex,i.uv);
                
                float3 N = i.normalWS;
                float3 L = normalize(light.direction);
                float3 V = normalize(mul((float3x3)UNITY_MATRIX_I_V,i.positionVS * (-1)));
                float3 H = normalize(L+V);
                float NoH = dot(N,H);
                float NoV = dot(N,V);
                float NoL = max(0,dot(N,L));
                float HoV = dot(H,V);
                
                float alpha = _Roughness * _Roughness;
                float pi = 3.14159;
                float3 F0 = float3(0.04,0.04,0.04);
                F0 = lerp(F0,BaseColor,_Metallic);
                float D = NormalDistribution(alpha,pi,NoH);
                float3 F = F0 + ((1-F0)*pow(1-(HoV),5));
                float kdirect = pow((alpha+1),2) / 8;
                float G = GeometrySmith(NoV,NoL,kdirect);
                
                //float3 Ks = F;
                //float3 Kd = (1-Ks)*(1-_Metallic);
                

                float3 BRDF = (F * D * G)/max(0.001,(4*NoV*NoL));

                //float3 Diffuse = Kd * BaseColor / pi;

                float3 DirectLight = BRDF * NoL * _LightColor.rgb;
                return float4(D,D,D,1);
                
            }
            
            
            ENDHLSL
        }
    }
}
