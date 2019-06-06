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
Shader "Unlit/Water"
{
  Properties
  {
    _MainTex ("Texture", 2D) = "white" {}
    tiles ("Tile Texture", 2D) = "white" {}
    poolHeight ("Pool Height", Float) = 1
    sphereCenter ("Sphere Center", Vector) = (0, 0, 0, 0)
    sphereRadius ("Sphere Radius", Float) = 0.25
    light ("Light", Vector) = (0, -1, 0, 0)
    water ("Water", 2D) = "black" {}
    eye ("Eye", Vector) = (0, -1, 0, 0)
    sky ("Sky Cubemap", Cube) = "white" {}
    causticTex ("Caustics", 2D) = "white" {}
    [Toggle(UNDER_WATER)]
    _UnderWater ("Under Water?", Float) = 0
    // [Enum(Off,0,Front,1,Back,2)] _MyCullVariable ("Cull", Int) = 2
    // https://gist.github.com/smkplus/2a5899bf415e2b6bf6a59726bb1ae2ec
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull", Float) = 2 //"Back"

  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Cull [_Cull]
    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      // make fog work
      #pragma multi_compile_fog
      #pragma target 3.0
      #pragma shader_feature UNDER_WATER

      #include "UnityCG.cginc"
      #include "HelperFunctions.cginc"

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
        float3 position : TEXCOORD1;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;

      float3 eye;
      samplerCUBE sky;

      float3 getSurfaceRayColor(float3 origin, float3 ray, float3 waterColor) {
        float3 color;
        float q = intersectSphere(origin, ray, sphereCenter, sphereRadius);
        if (q < 1.0e6) {
          color = getSphereColor(origin + ray * q);
        } else if (ray.y < 0.0) {
          float2 t = intersectCube(origin, ray, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
          color = getWallColor(origin + ray * t.y);
        } else {
          float2 t = intersectCube(origin, ray, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
          float3 hit = origin + ray * t.y;
          if (hit.y < 2.0 / 12.0) {
            color = getWallColor(hit);
          } else {
            color = texCUBE(sky, ray).rgb;
            color += pow(max(0.0, dot(light, ray)), 5000.0) * float3(10.0, 8.0, 6.0);
          }
        }
        if (ray.y < 0.0) color *= waterColor;
        return color;
      }


      v2f vert (appdata v)
      {
        v2f o;
        float4 info = tex2Dlod(water, float4(v.vertex.xy * 0.5 + 0.5, 0, 0));
        o.position = v.vertex.xzy;
        o.position.y += info.r;
        // o.vertex = UnityObjectToClipPos(v.vertex);
        o.vertex = UnityObjectToClipPos(o.position);
        // o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        // UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }


      fixed4 frag (v2f i) : SV_Target
      {
        // sample the texture
        // fixed4 col = tex2D(_MainTex, i.uv);

        float2 coord = i.position.xz * 0.5 + 0.5;
        float4 info = tex2D(water, coord);

        /* make water look more "peaked" */
        for (int j = 0; j < 5; j++) {
          coord += info.ba * 0.005;
          info = tex2D(water, coord);
        }

        float3 normal = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);
        float3 incomingRay = normalize(i.position - eye.xyz);
#if UNDER_WATER
        /* underwater */
        normal = -normal;
        float3 reflectedRay = reflect(incomingRay, normal);
        float3 refractedRay = refract(incomingRay, normal, IOR_WATER / IOR_AIR);
        float fresnel = lerp(0.5, 1.0, pow(1.0 - dot(normal, -incomingRay), 3.0));

        float3 reflectedColor = getSurfaceRayColor(i.position, reflectedRay, underwaterColor);
        float3 refractedColor = getSurfaceRayColor(i.position, refractedRay, float3(1, 1, 1)) * float3(0.8, 1.0, 1.1);

        // XXX This lerp is not working. If you provide 0 as its last argument or multiply by 0, it
        // shows the reflectedColor.  If however, you multiply its last argument by 0.00000001, you
        // get a black surface.
        // fixed4 col = float4(lerp(reflectedColor, saturate(refractedColor), (1.0 - fresnel) * length(refractedRay)), 1.0);
        fixed4 col = float4(lerp(reflectedColor, saturate(refractedColor), (1.0 - fresnel) * length(refractedRay)), 1.0);
        // fixed4 col = float4(reflectedColor, 1);
        // fixed4 col = float4(refractedColor, 1);
#else
        /* above water */
        float3 reflectedRay = reflect(incomingRay, normal);
        float3 refractedRay = refract(incomingRay, normal, IOR_AIR / IOR_WATER);
        float fresnel = lerp(0.25, 1.0, pow(1.0 - dot(normal, -incomingRay), 3.0));

        float3 reflectedColor = getSurfaceRayColor(i.position, reflectedRay, abovewaterColor);
        float3 refractedColor = getSurfaceRayColor(i.position, refractedRay, abovewaterColor);

        fixed4 col = float4(lerp(refractedColor, reflectedColor, fresnel), 1.0);
#endif
        return col;
      }
      ENDCG
    }
  }
}
