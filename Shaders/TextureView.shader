//$ cite -u https://github.com/shanecelis/water-demo -C -l mit
/* Original code[1] Copyright (c) 2018 Shane Celis[2]
   Licensed under the MIT License[3]

   [1]: https://github.com/shanecelis/water-demo
   [2]: https://github.com/shanecelis
   [3]: https://opensource.org/licenses/MIT
*/
/**
 Shader to view the render textures like water and caustics.
*/
Shader "Unlit/TextureView"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" {}
    _ColorMul ("Color Multiplier", Vector) = (1, 1, 1, 1)
  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      // make fog work
      #pragma multi_compile_fog

      #include "UnityCG.cginc"

      struct appdata
      {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        float2 uv : TEXCOORD0;
        UNITY_FOG_COORDS(1)
        float4 vertex : SV_POSITION;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;
      float4 _ColorMul;

      v2f vert (appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }

      fixed4 frag (v2f i) : SV_Target
      {
        // sample the texture
        fixed4 col = tex2D(_MainTex, i.uv);
        // apply fog
        UNITY_APPLY_FOG(i.fogCoord, col);
        // col.r *= 100;
        // col.gb = 0;
        col.a = 1;
        // col.b = 1;
        return col * _ColorMul;
      }
      ENDCG
    }
  }
}
