Shader "Image Effects/Rotoscope" 
{
	Properties 
	{
		_MainTex ("ScreenTexture", 2D) = "white" {}
		_LineTint("Line tint", Color) = (1,1,1,1)
		_Strength("Strength", Range(0,1)) = 0
		_UVModifierX("UV Modifier X", int) = 2
		_UVModifierY("UV Modifier Y", int) = 2
	}

	SubShader 
	{
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			fixed4 _LineTint;
			float _Strength;
			int _UVModifierX;
			int _UVModifierY;

			v2f_img vert(appdata_img v) 
			{
				v2f_img o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.texcoord);
				return o;
			}

			fixed4 frag (v2f_img i) : COLOR 
			{
				fixed4 scrTex = tex2D(_MainTex, i.uv);

				half xTexel = _MainTex_TexelSize.x * _UVModifierX;
				half yTexel = _MainTex_TexelSize.y * _UVModifierY;
				
				fixed3 texX = tex2D(_MainTex, i.uv + float2(xTexel, 0)).xyz;
				fixed3 texY = tex2D(_MainTex, i.uv + float2(0, yTexel)).xyz;

				half f = 0;

				f += abs(scrTex.x - texX.x);
				f += abs(scrTex.y - texX.y);
				f += abs(scrTex.z - texX.z);
				
				f += abs(scrTex.x - texY.x);
				f += abs(scrTex.y - texY.y);
				f += abs(scrTex.z - texY.z);

				f /= _Strength;

				// Clamp b/w 0,1
				f = saturate(f);


				scrTex.xyz = ((1 - f) + (_LineTint) * f);

				return scrTex;
			}
			ENDCG
		}
	}

	Fallback off
}