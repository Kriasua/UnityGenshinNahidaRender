Shader "Unlit/NahidaBase"
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
    _Roughness("Roughness",Range(0,1))=0
    
    _DoubleSided ("Double sided", Range(0,1)) = 0
    _Alpha ("Alpha", Range(0,1)) = 1
        
    _MetalTex ("Metal Tex", 2D) = "black" {}
        
    _SpecExpon ("Spec Exponent", Range(1, 128)) = 50
    _KsNonMetallic ("Ks Non-Metallic", Range(0,3)) = 1
    _KsMetallic ("Ks Metallic", Range(0,3)) = 1
    _Metallic ("Metallic",Range(0,1)) = 0
        
    _NormalMap ("Normal Map", 2D) = "bump" {}
    _ILM("ILM",2D) = "black" {}
        
    _RampTex ("Ramp Tex", 2D) = "white" {}
        
    _RampMapRow0 ("Ramp Map Row 0", Range(1,5)) = 1
    _RampMapRow1 ("Ramp Map Row 1", Range(1,5)) = 4
    _RampMapRow2 ("Ramp Map Row 2", Range(1,5)) = 3
    _RampMapRow3 ("Ramp Map Row 3", Range(1,5)) = 5
    _RampMapRow4 ("Ramp Map Row 4", Range(1,5)) = 2
        
    _OutlineOffset ("Outline Offset", Float) = 0.0015
        
    _OutlineMapColor0 ("Outline Map Color 0", Color) = (0,0,0,0)
    _OutlineMapColor1 ("Outline Map Color 1", Color) = (0,0,0,0)
    _OutlineMapColor2 ("Outline Map Color 2", Color) = (0,0,0,0)
    _OutlineMapColor3 ("Outline Map Color 3", Color) = (0,0,0,0)
    _OutlineMapColor4 ("Outline Map Color 4", Color) = (0,0,0,0)
    
    
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

            // 浮点/半精度参数
            half _SphereTexFac;               // 球面纹理混合系数
            half _SphereMulAdd;             // 球面纹理的乘加参数（可能用于UV变换）
            half _DoubleSided;                // 双面渲染开关（0或1）
            half _Alpha;                       // 透明度控制
            float _Roughness;

            float _SpecExpon;                 // 高光指数（控制高光锐度）
            float _KsNonMetallic;            // 非金属材质的高光强度
            float _KsMetallic;               // 金属材质的高光强度

            // 渐变纹理参数（修正拼写错误）
            float _RampMapRow0;              // 渐变纹理第0行参数
            float _RampMapRow1;              // 渐变纹理第1行参数
            float _RampMapRow2;              // 渐变纹理第2行参数
            float _RampMapRow3; 
            float _RampMapRow4;

            float _Left;
            float _Right;
            float _Metallic;

            CBUFFER_END

            float GeometrySchlickGGX(float fl, float k)
            {
                return (fl)/max((fl * (1.0f-k) + k),0.001);
            }

            float GeometrySmith(float NoV, float NoL, float k)
            {
                float ggx1 = GeometrySchlickGGX(NoV,k);
                float ggx2 = GeometrySchlickGGX(max(0,NoL),k);
                return ggx1 * ggx2;
            }

            float3 Fresnel(float3 BaseColor, float Metallic,float HoV)
            {
                float3 F0 = float3(0.04,0.04,0.04);
                F0 = lerp(F0,BaseColor,Metallic);
                return F0 + ((1-F0)*pow(1-(HoV),5));
            }

            float NormalDistribution(float alpha, float pi, float NoH)
            {
                return (alpha*alpha)/max((pi*pow((NoH * NoH *(alpha*alpha-1)+1),2)),0.001);
            }

            float3 Fresnel(float3 BaseColor, float Metallic,float HoV,float alpha)
            {
                float3 F0 = float3(0.04,0.04,0.04);
                F0 = lerp(F0,BaseColor,Metallic);
                return F0 + ((max(float3(1.0 - alpha,1.0 - alpha,1.0 - alpha), F0) - F0)*pow(1-(HoV),5));
            }

            float3 ACESToneMapping(float3 color)
            {
                float a =2.51f;
                float b =0.03f;
                float c =2.43f;
                float d =0.59f;
                float e =0.14f;
                return saturate((color * (a*color+b))/(color*(c*color+d)+e));
            }
            

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
                
                float4 normalMap = tex2D(_NormalMap,i.uv);
                
                float3 normalTS;
                normalTS.xy = normalMap.ag * 2 - 1;
                normalTS.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy))));
                //float3 normalTS = UnpackNormal(tex2D(_NormalMap,i.uv));

                
                float3 N = normalize(mul(normalTS,float3x3(i.tangentWS,i.bitangentWS,i.normalWS)));
                float3 V = normalize(mul((float3x3)UNITY_MATRIX_I_V,i.positionVS * (-1)));
                float3 L = normalize(light.direction);
                float3 H = normalize(L+V);

                float NoL = saturate(dot(N,L));
                float NoH = saturate(dot(N,H));
                float NoV = saturate(dot(N,V));
                float HoV = saturate(dot(H,V));

                

                
                float3 normalVS = normalize(mul((float3x3)UNITY_MATRIX_V,N));
                float2 matcapUV = normalVS.xy * 0.5 + 0.5;

                

                float4 baseTex = tex2D(_BaseTex,i.uv);
                float4 toonTex = tex2D(_ToonTex,matcapUV);
                float4 sphereTex = tex2D(_BaseTex,matcapUV);

                // BaseColor
                float3 baseColor = _AmbientColor.rgb;
                baseColor = saturate(lerp(baseColor,baseColor+_DiffuseColor.rgb,0.6));
                baseColor = lerp(baseColor,baseColor * baseTex.rgb,_BaseTexFac);
                baseColor= lerp(baseColor,baseColor * toonTex.rgb,_ToonTexFac);
                baseColor = lerp(lerp(baseColor,baseColor * sphereTex.rgb,_BaseTexFac) ,lerp(baseColor,baseColor + sphereTex.rgb,_SphereTexFac),_SphereMulAdd);

                float4 ilm = tex2D(_ILM,i.uv);
                
                // DiffuseShadow
                //若左上角为UV原点
                float ramp0 = _RampMapRow0/10.0 -0.05;
                float ramp1 = _RampMapRow1/10.0 -0.05;
                float ramp2 = _RampMapRow2/10.0 -0.05;
                float ramp3 = _RampMapRow3/10.0 -0.05;
                float ramp4 = _RampMapRow4/10.0 -0.05;

                float matEnum0 = 0.0;
                float matEnum1 = 0.3;
                float matEnum2 = 0.5;
                float matEnum3 = 0.7;
                float matEnum4 = 1.0;
                
                float dayRampV = lerp(ramp4,ramp3,step(ilm.a,(matEnum3+matEnum4)/2));
                dayRampV = lerp(dayRampV,ramp2,step(ilm.a,(matEnum2+matEnum3)/2));
                dayRampV = lerp(dayRampV,ramp1,step(ilm.a,(matEnum1+matEnum2)/2));
                dayRampV = lerp(dayRampV,ramp0,step(ilm.a,(matEnum0+matEnum1)/2));
                float nightRampV = dayRampV +0.5;

                float lambert = max(0,NoL) ;
                float halfLambert = pow(lambert *0.5 + 0.5,2);
                
                //分成全黑和全白和，中间有些许柔和过度
                float lamberStep = smoothstep(0.423,0.450,halfLambert);

                float rampClampMin = 0.003;
                float rampClampMax = 0.997;
                
                //灰色阴影使用halfLambert区分亮面和暗面，灰色阴影受光照影响
                //float rampGrayU = clamp(halfLambert,rampClampMin,rampClampMax);
                float rampGrayU = clamp(smoothstep(0.2,0.4,halfLambert),rampClampMin,rampClampMax);
                float2 dayGrayRampUV = float2(rampGrayU,1-dayRampV);
                float2 nightGrayRampUV = float2(rampGrayU,1-nightRampV);

                float rampDarkU =rampClampMin;
                float2 dayDarkRampUV = float2(rampDarkU,1-dayRampV);
                float2 nightDarkRampUV = float2(rampDarkU,1-nightRampV);

                float isDay = (L.y+1)/2;
                float3 rampGrayColor = lerp(tex2D(_RampTex,nightGrayRampUV).rgb,tex2D(_RampTex,dayGrayRampUV).rgb,isDay);
                float3 rampDarkColor = lerp(tex2D(_RampTex,nightDarkRampUV).rgb,tex2D(_RampTex,dayDarkRampUV).rgb,isDay);

                
                float3 grayShadowColor = baseColor * rampGrayColor * _ShadowColor.rgb;
                float3 darkShadowColor = baseColor * rampDarkColor * _ShadowColor.rgb;

                
                float3 diffuse = 0;
                //lamberStep的全白部分只用baseColor,全黑部分只用grayShadowColor
                diffuse = lerp(grayShadowColor, baseColor, lamberStep);
                diffuse = lerp(darkShadowColor, diffuse, saturate(ilm.g * 2));
                diffuse = lerp(diffuse,baseColor,saturate(ilm.g - 0.5) *2);

                 /////////////////////////////////////////////////////////////
                /////以下为PBR Specular
                float a2 = _Roughness*_Roughness;
                float kdirect = pow((_Roughness+1),2) / 8;
                float3 F = Fresnel(baseColor,_Metallic,HoV);
                float D = NormalDistribution(_Roughness,3.1415926,NoH);
                float G = GeometrySmith(NoV,NoL,kdirect);
                float3 BRDFSpecularDirect = (F * D * G)/max(0.001,(4*NoV*NoL));

                float3 lightRadiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
                float3 PBRDirect = BRDFSpecularDirect * lightRadiance * NoL * ilm.b;
                //float3 PBRDirect = BRDFSpecularDirect * _AmbientColor * NoL*ilm.b;





                
                /////////////////////////////////////////////////////////////
                
                //Specular
                float blinnPhong = pow(max(0,NoH),_SpecExpon) * step(0,NoL);
                
                float3 nonMetallicSpec = step(1.04-blinnPhong,ilm.b) * ilm.r * _KsNonMetallic;
                float3 metallicSpec = blinnPhong * ilm.b * (lamberStep*0.8+0.2) * baseColor * _KsMetallic;
                float isMetal = step(0.84,ilm.r);
                float3 Spec = lerp(nonMetallicSpec,PBRDirect,isMetal);

               

                //Metallic
                float3 metallic = lerp(0,tex2D(_MetalTex,matcapUV).r * baseColor,isMetal);


                //float3 albedo = diffuse + PBRDirect + Spec;
                float3 albedo = diffuse + Spec;
                float alpha = _Alpha * baseTex.a + toonTex.a * sphereTex.a;
                
                alpha = saturate(min(max(IsFacing,_DoubleSided),alpha));

                float4 col = float4(albedo,alpha);

                //clip(col.a - 0.5);
                float3 yanse = ACESToneMapping(PBRDirect);
                halfLambert = smoothstep(0.2,0.4,halfLambert);
                col.rgb = MixFog(col.rgb, i.fogCoord);
                //return float4(albedo,1);
                
                return col;
            }
            
            
            ENDHLSL
        }

    
    Pass
    {
        Name "DrawOutline"
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
        }
        Cull Front
        
        HLSLPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_fog

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
            float4 positionCS : SV_POSITION;
            float fogCoord : TEXCOORD1;
        };

        CBUFFER_START(UnityPerMaterial)
        sampler2D _BaseTex;
        float4 _BaseTex_ST;

        sampler2D _ILM;

        float4 _OutlineMapColor0;
        float4 _OutlineMapColor1;
        float4 _OutlineMapColor2;
        float4 _OutlineMapColor3;
        float4 _OutlineMapColor4;

        float _OutlineOffset;
        
        
        CBUFFER_END

        v2f vert(appdata v)
        {
            v2f o;
            VertexPositionInputs vertexInputs = GetVertexPositionInputs(v.vertex.xyz + v.normal * _OutlineOffset);
            o.uv = TRANSFORM_TEX(v.uv,_BaseTex);
            o.positionCS = vertexInputs.positionCS;
            o.fogCoord = ComputeFogFactor(vertexInputs.positionCS.z);

            return o;
        }

        float4 frag(v2f i, bool IsFacing : SV_IsFrontFace) : SV_Target
        {
            float4 ilm = tex2D(_ILM,i.uv);
             

            float matEnum0 = 0.0f;
            float matEnum1 = 0.3f;
            float matEnum2 = 0.5f;
            float matEnum3 = 0.7f;
            float matEnum4 = 1.0f;


            float4 color = lerp(_OutlineMapColor3,_OutlineMapColor4,step((matEnum4 + matEnum3)/2 ,ilm.a));
            color = lerp(_OutlineMapColor2,color,step((matEnum3 + matEnum2)/2 ,ilm.a));
            color = lerp(_OutlineMapColor1,color,step((matEnum2 + matEnum1)/2 ,ilm.a));
            color = lerp(_OutlineMapColor0,color,step((matEnum1 + matEnum0)/2 ,ilm.a));

            float3 albedo = color.rgb;

            float4 col = float4(albedo,1);

            col.rgb = MixFog(col.rgb,i.fogCoord);

            return col;
        }



        
        ENDHLSL
    }
    
    }

}
