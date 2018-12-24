Shader "CustomRenderTexture/ComputeNormal"
{
  Properties
  {
    _Tex("InputTex", 2D) = "white" {}
    [Toggle(PACK_NORMAL)]
    _Refract ("Pack normal?", Float) = 0
  }

  SubShader
  {
    Lighting Off
    Blend One Zero

    Pass
    {
      CGPROGRAM
      #include "UnityCustomRenderTexture.cginc"
      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag
      #pragma target 3.0
      #pragma shader_feature PACK_NORMAL

      float4      _Color;
      sampler2D   _Tex;

      fixed4 frag(v2f_customrendertexture IN) : COLOR
      {
        fixed4 col;
        float2 uv = IN.localTexcoord.xy;
        fixed4 water = tex2D(_Tex, uv);
        // Assumption: uv is aligned with screenspace.
        // fixed2 delta_uv = fixed2(ddx(uv.x), ddy(uv.y));
        // fixed3 dx = fixed3(delta_uv.x, delta_h.x, 0);
        // fixed3 dy = fixed3(0, delta_h.y, delta_uv.y);

        // Changed: uv does not need to be aligned with screen space.
        fixed2 duv_dx = ddx(uv);
        fixed2 duv_dy = ddy(uv);
        fixed2 delta_h = fixed2(ddx(water.r), ddy(water.r));
        fixed3 dx = fixed3(duv_dx.x, delta_h.x, duv_dx.y);
        fixed3 dy = fixed3(duv_dy.x, delta_h.y, duv_dy.y);
        fixed3 normal = normalize(cross(dy, dx));

#if PACK_NORMAL
        col.ba = (normal.xz + 1) / 2;
#else
        col.rgb = normal;
#endif
        // col.g = 0;
        // col.rgb = 0.5 * normal + 0.5;
        // This isn't how normal maps are usually stored.
        // You can't see the negatives, but with this you can.
        // col.rgb = abs(normalize(cross(dy, dx)));
        // We can zero out the green to see it better.
        // col.rgb *= 10;
        // col.rg = delta_h;
        col.a = 1;

        return col;
      }
      ENDCG
    }
  }
}
