//$ cite -u https://github.com/evanw/webgl-water -U https://github.com/shanecelis/water-demo -mC -l mit
/* Original code[1] Copyright (c) 2015 Evan Wallace[2]
   Modified code[3] Copyright (c) 2018 Shane Celis[4]
   Licensed under the MIT License[5]

   [1]: https://github.com/evanw/webgl-water
   [2]: https://github.com/evanw
   [3]: https://github.com/shanecelis/water-demo
   [4]: http://twitter.com/shanecelis
   [5]: https://opensource.org/licenses/MIT
*/
Shader "CustomRenderTexture/WaterIntegrate"
{
  Properties
  {
    // _waveSpeed("Wave Speed", Float) = 1
    // _gridSpacing("Grid Spacing", Float) = 1
    // _dampingConstant("Damping Constant", Float) = 0.1
    _Tex("InputTex", 2D) = "white" {}
    radius("Drop Radius", Float) = 0.03
    strength("Drop Strength", Float) = 0.01
    center("Drop Center", Vector) = (0, 0, 0, 0)
  }

  CGINCLUDE
  #include "UnityCustomRenderTexture.cginc"
  #pragma target 3.0
  static const float PI = 3.14159265f;

  // float4      _Color;
  sampler2D   _Tex;
  // float _waveSpeed;
  // float _gridSpacing;
  // float _dampingConstant;
  float radius;
  float strength;
  float2 center;

  fixed4 frag_integrate(v2f_customrendertexture IN) : COLOR
  {
    float2 delta = float2(1 / _CustomRenderTextureWidth, 1 / _CustomRenderTextureHeight);
    float2 coord = IN.globalTexcoord.xy;

    /* get vertex info */
    float4 info = tex2D(_SelfTexture2D, coord);

    /* calculate average neighbor height */
    // float2 dx = float2(delta.x, 0.0);
    // float2 dy = float2(0.0, delta.y);
    float2 dx = ddx(coord);
    float2 dy = ddy(coord);
    float average = (
      tex2D(_SelfTexture2D, coord - dx).r +
      tex2D(_SelfTexture2D, coord - dy).r +
      tex2D(_SelfTexture2D, coord + dx).r +
      tex2D(_SelfTexture2D, coord + dy).r
    ) * 0.25;

    /* change the velocity to move toward the average */
    info.g += (average - info.r) * 2.0;

    /* attenuate the velocity a little so waves do not last forever */
    info.g *= 0.995;

    /* move the vertex along the velocity */
    info.r += info.g;

    // /* Let's just update the normal while we're at it. */
    // /* update the normal */
    // float3 dx2 = float3(delta.x, tex2D(_SelfTexture2D, float2(coord.x + delta.x, coord.y)).r - info.r, 0.0);
    // float3 dy2 = float3(0.0, tex2D(_SelfTexture2D, float2(coord.x, coord.y + delta.y)).r - info.r, delta.y);
    // info.ba = normalize(cross(dy2, dx2)).xz;
    fixed4 col = info;
    // col.a = 1;
    return col;
  }

  float4 frag_normal(v2f_customrendertexture IN) : COLOR
  {
    float4 coord = float4(IN.localTexcoord.xy, 0, 0);
    /* get vertex info */
    float4 info = tex2D(_SelfTexture2D, coord);
    float2 delta = float2(1 / _CustomRenderTextureWidth, 1 / _CustomRenderTextureHeight);

    /* update the normal */
    float3 dx = float3(delta.x, tex2D(_SelfTexture2D, float2(coord.x + delta.x, coord.y)).r - info.r, 0.0);
    float3 dy = float3(0.0, tex2D(_SelfTexture2D, float2(coord.x, coord.y + delta.y)).r - info.r, delta.y);
    info.ba = normalize(cross(dy, dx)).xz;

    return info;
  }

  float4 frag_drop(v2f_customrendertexture IN) : COLOR
  {
    float2 coord = IN.localTexcoord.xy;
    // float2 coord = float2(IN.globalTexcoord.xy);
    /* get vertex info */
    // float4 info = tex2D(_SelfTexture2D, coord);
    float4 info = tex2D(_SelfTexture2D, IN.globalTexcoord.xy);

    /* add the drop to the height */
    // float drop = max(0.0, 1.0 - length(center * 0.5 + 0.5 - coord) / radius);
    float drop = max(0, 1.0 - length(float2(0.5, 0.5) - coord) / 0.5);
    drop = 0.5 - cos(drop * PI) * 0.5;
    info.r += drop * strength;

    return info;
  }


  // float4 frag_copy(v2f_init_customrendertexture IN) : COLOR
  // {
  //   return tex2D(_Tex, IN.texcoord.xy);
  // }

  float4 frag_raise(v2f_customrendertexture i) : COLOR
  {
    return float4(1, 0, 0, 0);
  }

  float4 frag_lower(v2f_customrendertexture i) : COLOR
  {
    return float4(0, 0, 0, 0);
  }

  ENDCG

  SubShader
  {
    Lighting Off
    Blend One Zero

    Pass
    {
      Name "Integrate"
      CGPROGRAM
      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag_integrate
      ENDCG
    }

    Pass
    {
      Name "Drop"
      CGPROGRAM
      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag_drop
      ENDCG
    }

    Pass
    {
      Name "Normal"
      CGPROGRAM
      #pragma vertex CustomRenderTextureVertexShader
      #pragma fragment frag_normal
      ENDCG
    }

    // Pass
    // {
    //   Name "Lower"
    //   CGPROGRAM
    //   #pragma vertex CustomRenderTextureVertexShader
    //   #pragma fragment frag_lower
    //   ENDCG
    // }

  }

}
