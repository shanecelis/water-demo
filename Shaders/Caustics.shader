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
Shader "Unlit/Caustics"
{
  Properties
  {
    // _MainTex ("Texture", 2D) = "white" {}
    tiles ("Tile Texture", 2D) = "white" {}
    poolHeight ("Pool Height", Float) = 1
    sphereCenter ("Sphere Center", Vector) = (0, 0, 0, 0)
    sphereRadius ("Sphere Radius", Float) = 0.25
    light ("Light", Vector) = (0, -1, 0, 0)
    water ("Water", 2D) = "black" {}
  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
    LOD 100
    Cull Off

    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      // make fog work
      // #pragma multi_compile_fog
      #define HAS_DERIVATIVES

      #include "UnityCG.cginc"
      #include "HelperFunctions.cginc"

      struct appdata
      {
        float4 vertex : POSITION;
        // float2 uv : TEXCOORD0;
      };

      struct v2f
      {
        // float2 uv : TEXCOORD0;
        // UNITY_FOG_COORDS(1)
        float4 vertex : SV_POSITION;
        float3 oldPos : TEXCOORD1;
        float3 newPos : TEXCOORD2;
        // float3 ray : TEXCOORD3;
        // float3 worldPos : TEXCOORD1;
      };

      // sampler2D _MainTex;
      // float4 _MainTex_ST;

      /* project the ray onto the plane */
      float3 project(float3 origin, float3 ray, float3 refractedLight) {
        float2 tcube = intersectCube(origin, ray, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
        origin += ray * tcube.y;
        float tplane = (-origin.y - 1.0) / refractedLight.y;
        return origin + refractedLight * tplane;
      }

      v2f vert (appdata v)
      {
        v2f o;
        float4 info = tex2Dlod(water, float4(v.vertex.xy * 0.5 + 0.5, 0, 0));
        info.ba *= 0.5;
        float3 normal = float3(info.b, sqrt(1.0 - dot(info.ba, info.ba)), info.a);

        /* project the vertices along the refracted vertex ray */
        float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
        float3 ray = refract(-light, normal, IOR_AIR / IOR_WATER);
        o.oldPos = project(v.vertex.xzy, refractedLight, refractedLight);
        o.newPos = project(v.vertex.xzy + float3(0.0, info.r, 0.0), ray, refractedLight);
        o.vertex = float4(0.75 * (o.newPos.xz + refractedLight.xz / refractedLight.y), 0.0, 1.0);
        /* This fixes the texture being Y-inverted, but it changes the triangle
           face, so the Cull was changed from Cull Back to Cull Off. */
        o.vertex.y *= -1;

        // o.vertex = UnityObjectToClipPos(o.position);
        // o.vertex = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1));
        // o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        // UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }

      fixed4 frag (v2f i) : SV_Target
      {
        #if defined(HAS_DERIVATIVES)
        /* if the triangle gets smaller, it gets brighter, and vice versa */
        float oldArea = length(ddx(i.oldPos)) * length(ddy(i.oldPos));
        float newArea = length(ddx(i.newPos)) * length(ddy(i.newPos));
        fixed4 col = float4(oldArea / newArea * 0.2, 1.0, 0.0, 0.0);
        #else
        fixed4 col = float4(0.2, 0.2, 0.0, 0.0);
        #endif

        float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);

        /* compute a blob shadow and make sure we only draw a shadow if the player is blocking the light */
        float3 dir = (sphereCenter - i.oldPos) / sphereRadius;
        float3 area = cross(dir, refractedLight);
        float shadow = dot(area, area);
        float dist = dot(dir, -refractedLight);
        shadow = 1.0 + (shadow - 1.0) / (0.05 + dist * 0.025);
        shadow = clamp(1.0 / (1.0 + exp(-shadow)), 0.0, 1.0);
        shadow = lerp(1.0, shadow, clamp(dist * 2.0, 0.0, 1.0));
        col.g = shadow;

        /* shadow for the rim of the pool */
        float2 t = intersectCube(i.newPos, -refractedLight, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
        col.r *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (i.newPos.y - refractedLight.y * t.y - 2.0 / 12.0)));

        // apply fog
        // UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }
      ENDCG
    }
  }
}
