Shader "Unlit/NahidaFace"
{
    Properties {
    _AmbientColor ("Ambient Color", Color) = (0.667, 0.667, 0.667, 1)
    _DiffuseColor ("Diffuse Color", Color) = (0.906, 0.906, 0.906, 1)
    _ShadowColor ("Shadow Color", Color) = (0.737, 0.737, 0.737, 1)
        
    _BaseTexFac ("Base Tex Fac", Range(0,1)) = 1
    _BaseTex ("Base Tex", 2D) = "white" {}
    _ToonTexFac ("Toon Tex Fac", Range(0,1)) = 1
    _ToonTex ("Toon Tex", 2D) = "white" {}
    _SphereTexFac ("Sphere Tex", Range(0,1)) = 0
    _SphereTex ("Sphere Tex", 2D) = "white" {}
    _SphereMulAdd ("Sphere Mul/Add", Range(0,1)) = 0
    
    _DoubleSided ("Double sided", Range(0,1)) = 0
    _Alpha ("Alpha", Range(0,1)) = 1
    
    _ShadowTex ("Shadow Tex",2D) = "black"{}
        
    _SDF ("SDF",2D) = "black"{}
        
    _ForwardVector("Forward Vector",Vector) = (0,0,1,0)
    _RightVector("Right Vector",Vector) = (1,0,0,0)
        
    _RampTex ("Ramp Tex", 2D) = "white" {}
    _RampMapRow4 ("Ramp Map Row 4", Range(1,5)) = 5
        
    _OutlineColor ("Outline Color", Color) = (0,0,0,0)
    _OutlineOffset ("Outline Offset", Float) = 0.000015 

    
    
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
            
            float4 _AmbientColor;
            float4 _DiffuseColor;
            float4 _ShadowColor;

            float4 _ForwardVector;
            float4 _RightVector;

            half _BaseTexFac;
            sampler2D _BaseTex;
            sampler2D _SkinTex;

            float4 _BaseTex_ST;

            half _ToonTexFac;
            
            sampler2D _ToonTex;                // 卡通风格主纹理
            sampler2D _MetalTex;               // 金属度贴图
            sampler2D _NormalMap;             // 法线贴图
            sampler2D _ILM;                    // ILM贴图（可能用于光照模型控制）
            sampler2D _RampTex;               // 渐变纹理（用于卡通着色过渡）
            sampler2D _SphereTex;
            sampler2D _SDF;
            sampler2D _ShadowTex;

            // 浮点/半精度参数
            half _SphereTexFac;               // 球面纹理混合系数
            half _SphereMulAdd;             // 球面纹理的乘加参数（可能用于UV变换）
            half _DoubleSided;                // 双面渲染开关（0或1）
            half _Alpha;                       // 透明度控制

                      // 金属材质的高光强度

            // 渐变纹理参数（修正拼写错误）
          
            float _RampMapRow4;

           

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

            
            float4 frag(v2f i,bool IsFacing : SV_IsfrontFace) : SV_Target
            {
                Light light = GetMainLight(i.shadowCoord);
                
                float3 N = normalize(i.normalWS);
                float3 V = normalize(mul((float3x3)UNITY_MATRIX_I_V,i.positionVS * (-1)));
                float3 L = normalize(light.direction);
                float3 normalVS = normalize(mul((float3x3)UNITY_MATRIX_V,N));
                float2 matcapUV = normalVS.xy * 0.5 + 0.5;

                float4 baseTex = tex2D(_BaseTex,i.uv);
                float4 toonTex = tex2D(_ToonTex,matcapUV);
                float4 sphereTex = tex2D(_BaseTex,matcapUV);

                float NoV = dot(N,V);
                float NoL = dot(N,L);
               
                
                // BaseColor
                float3 baseColor = _AmbientColor.rgb;
                baseColor = saturate(lerp(baseColor,baseColor+_DiffuseColor.rgb,0.6));
                baseColor = lerp(baseColor,baseColor * baseTex.rgb,_BaseTexFac);
                baseColor= lerp(baseColor,baseColor * toonTex.rgb,_ToonTexFac);
                baseColor = lerp(lerp(baseColor,baseColor * sphereTex.rgb,_BaseTexFac) ,lerp(baseColor,baseColor + sphereTex.rgb,_SphereTexFac),_SphereMulAdd);

                
                float rampDayV = _RampMapRow4/10 -0.05;
                float rampNightV = rampDayV + 0.5;
                float clampMin = 0.003;
                float2 rampDayUV = float2(clampMin,1-rampDayV);
                float2 rampNightUV = float2(clampMin,1-rampNightV);
                float isDay = L.y * 0.5 + 0.5;
                float3 rampColor = lerp(tex2D(_RampTex,rampNightUV).rgb,tex2D(_RampTex,rampDayV).rgb,isDay);
                rampColor = rampColor * baseColor * _ShadowColor.rgb;
                

                float3 forwardVec = _ForwardVector;
                float3 rightVec = _RightVector;
                float3 upVector = cross(forwardVec,rightVec);
                float3 LpU = dot(L,upVector)/pow(length(upVector),2) * upVector;
                float3 LpHeadHorizon = L - LpU;

                float pi = 3.14159;
                float value = acos(dot(normalize(rightVec),normalize(LpHeadHorizon)))/pi;
                float exposeRight = step(value,0.5);

                // right : 1~0  把value从0~0.5~1  映射成1~0~1
                // left: 0~1

                float valueR = pow(1 - (value * 2),3);
                float valueL = pow(value * 2 - 1,3);
                float mixValue = lerp(valueL, valueR, exposeRight);
                
                float sdfRembrandtRight = tex2D(_SDF,i.uv).r;
                float sdfRembrandtLeft = tex2D(_SDF,float2(1-i.uv.x,i.uv.y)).r; //只需把右脸的u坐标反向就能得到左脸的SDF纹理
                float mixSdf = lerp(sdfRembrandtRight,sdfRembrandtLeft,exposeRight);
                float sdf = step(mixValue,mixSdf);
                sdf = lerp(0,sdf,step(0,dot(normalize(forwardVec),normalize(LpHeadHorizon))));
                sdf *= tex2D(_ShadowTex,i.uv).r;
                sdf = lerp(sdf,0.997,tex2D(_ShadowTex,i.uv).a);
                float3 diffuse = lerp(rampColor,baseColor,sdf);

                float4 col;
                col = float4(diffuse,1);
                col.rgb = MixFog(col.rgb, i.fogCoord);
                return col;
            }
            
            
            ENDHLSL
        }
    }

}
