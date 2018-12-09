Shader "Other/Rotoscope" 
{
	Properties 
	{
		_LineTint("Line tint", Color) = (1,1,1,1)
		_Strength("Strength", Range(0,1)) = 0
		_UVModifierX("UV Modifier X", int) = 2
		_UVModifierY("UV Modifier Y", int) = 2
	}

	SubShader 
	{
		Pass 
		{
			Tags { "LightMode" = "Always" "Queue" = "Transparent"}
			//ZTest Always 
			Cull Off 
			ZTest Less
			ZWrite Off 
			//Blend SrcAlpha OneMinusSrcAlpha
			//Blend One OneMinusSrcAlpha
			//Blend One One // Additive
			//Blend OneMinusDstColor One // Soft Additive
			//Blend DstColor Zero // Multiplicative
			//Blend DstColor SrcColor // 2x Multiplicative

			Fog { Mode off }

			LOD 100

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"

			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform float4 _CameraDepthTexture_TexelSize;
			float4 _Size;
			fixed4 _LineTint;
			float _Strength;
			int _UVModifierX;
			int _UVModifierY;


			struct vertData
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float2 scrPos : TEXCOORD1;
			};



			struct v2f 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 scrPos : TEXCOORD1;
			};

			//Vertex Shader
			v2f vert(vertData v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeScreenPos(o.pos);
				o.scrPos.y = o.scrPos.y;
				//o.uv = TRANSFORM_TEX(v.texcoord, _CameraDepthTexture);
				o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.texcoord);
				return o;
			}

			//Fragment Shader
			fixed4 frag(v2f i) : COLOR
			{
				float2 screenUV = i.scrPos.xy / i.scrPos.w;

				fixed4 main = tex2D(_CameraDepthTexture, screenUV);
				//fixed4 main = tex2Dproj(_MainTex, i.scrPos);
				//fixed4 main = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.scrPos)));
				//fixed4 main = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.pos));
				
				float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).x);
				//float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).y);
				//float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).z);
				
				half xTexel = _CameraDepthTexture_TexelSize.x * _UVModifierX;
				half yTexel = _CameraDepthTexture_TexelSize.y * _UVModifierY;
															  
				//fixed3 texX = tex2D(_CameraDepthTexture, i.uv).xyz;
				//fixed3 texY = tex2D(_CameraDepthTexture, i.uv).xyz;
				fixed3 texX = tex2D(_CameraDepthTexture, screenUV + float2(xTexel,0)).xyz;
				fixed3 texY = tex2D(_CameraDepthTexture, screenUV + float2(0, yTexel)).xyz;

				half f = 0;

				f += abs(main.x - texX.x);
				f += abs(main.y - texX.y);
				f += abs(main.z - texX.z);						 
				f += abs(main.x - texY.x);
				f += abs(main.y - texY.y);
				f += abs(main.z - texY.z);

				f /= (depthValue * _Strength);
				//f /= _Strength;

				// Clamp b/w 0,1
				f = saturate(f);


				main.xyz = ((1 - f) + (_LineTint)* f);
				// If you want inverse effect
				//main.xyz = 1 - ((1 - f) + (_LineTint)* f);


				return main;
				
			}


			ENDCG
		}
	}

	Fallback off
}



// Things kinda break but look kinda cool
/*
			sampler2D _CameraDepthTexture;
			//Vertex Shader
			v2f vert(appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.scrPos = ComputeScreenPos(o.vertex);
				//for some reason, the y position of the depth texture comes out inverted
				o.scrPos.y = 1 - o.scrPos.y;
				return o;
			}

			//Fragment Shader
			half4 frag(v2f i) : COLOR
			{
			   float depthValue = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.scrPos)));
			   half4 depth;

			   depth.x = depthValue;
			   depth.y = depthValue;
			   depth.z = depthValue;

			   depth.a = 1;
			   return depth;
			}


*/