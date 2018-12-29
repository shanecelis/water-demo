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

#ifndef HELPER_FUNCTIONS
#define HELPER_FUNCTIONS

static const float IOR_AIR = 1.0;
static const float IOR_WATER = 1.333;
static const float3 abovewaterColor = float3(0.25, 1.0, 1.25);
static const float3 underwaterColor = float3(0.4, 0.9, 1.0);
float poolHeight;
float3 light;
float3 sphereCenter;
float sphereRadius;
sampler2D tiles;
sampler2D causticTex;
sampler2D water;

float2 intersectCube(float3 origin, float3 ray, float3 cubeMin, float3 cubeMax) {
  float3 tMin = (cubeMin - origin) / ray;
  float3 tMax = (cubeMax - origin) / ray;
  float3 t1 = min(tMin, tMax);
  float3 t2 = max(tMin, tMax);
  float tNear = max(max(t1.x, t1.y), t1.z);
  float tFar = min(min(t2.x, t2.y), t2.z);
  return float2(tNear, tFar);
}

float intersectSphere(float3 origin, float3 ray, float3 sphereCenter, float sphereRadius) {
  float3 toSphere = origin - sphereCenter;
  float a = dot(ray, ray);
  float b = 2.0 * dot(toSphere, ray);
  float c = dot(toSphere, toSphere) - sphereRadius * sphereRadius;
  float discriminant = b*b - 4.0*a*c;
  if (discriminant > 0.0) {
    float t = (-b - sqrt(discriminant)) / (2.0 * a);
    if (t > 0.0) return t;
  }
  return 1.0e6;
}

float3 getSphereColor(float3 _point) {
  float3 color = float3(0.5, 0.5, 0.5);

  /* ambient occlusion with walls */
  color *= 1.0 - 0.9 / pow((1.0 + sphereRadius - abs(_point.x)) / sphereRadius, 3.0);
  color *= 1.0 - 0.9 / pow((1.0 + sphereRadius - abs(_point.z)) / sphereRadius, 3.0);
  color *= 1.0 - 0.9 / pow((_point.y + 1.0 + sphereRadius) / sphereRadius, 3.0);

  /* caustics */
  float3 sphereNormal = (_point - sphereCenter) / sphereRadius;
  float3 refractedLight = refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
  float diffuse = max(0.0, dot(-refractedLight, sphereNormal)) * 0.5;
  float4 info = tex2D(water, _point.xz * 0.5 + 0.5);
  if (_point.y < info.r) {
    float4 caustic = tex2D(causticTex, 0.75 * (_point.xz - _point.y * refractedLight.xz / refractedLight.y) * 0.5 + 0.5);
    diffuse *= caustic.r * 4.0;
  }
  color += diffuse;

  return color;
}

float3 getWallColor(float3 _point) {
  float scale = 0.5;

  float3 wallColor;
  float3 normal;
  if (abs(_point.x) > 0.999) {
    wallColor = tex2D(tiles, _point.yz * 0.5 + float2(1.0, 0.5)).rgb;
    normal = float3(-_point.x, 0.0, 0.0);
  } else if (abs(_point.z) > 0.999) {
    wallColor = tex2D(tiles, _point.yx * 0.5 + float2(1.0, 0.5)).rgb;
    normal = float3(0.0, 0.0, -_point.z);
  } else {
    wallColor = tex2D(tiles, _point.xz * 0.5 + 0.5).rgb;
    normal = float3(0.0, 1.0, 0.0);
  }

  scale /= length(_point); /* pool ambient occlusion */
  scale *= 1.0 - 0.9 / pow(length(_point - sphereCenter) / sphereRadius, 4.0); /* sphere ambient occlusion */

  /* caustics */
  float3 refractedLight = -refract(-light, float3(0.0, 1.0, 0.0), IOR_AIR / IOR_WATER);
  float diffuse = max(0.0, dot(refractedLight, normal));
  float4 info = tex2D(water, _point.xz * 0.5 + 0.5);
  if (_point.y < info.r) {
    float4 caustic = tex2D(causticTex, 0.75 * (_point.xz - _point.y * refractedLight.xz / refractedLight.y) * 0.5 + 0.5);
    scale += diffuse * caustic.r * 2.0 * caustic.g;
  } else {
    /* shadow for the rim of the pool */
    float2 t = intersectCube(_point, refractedLight, float3(-1.0, -poolHeight, -1.0), float3(1.0, 2.0, 1.0));
    diffuse *= 1.0 / (1.0 + exp(-200.0 / (1.0 + 10.0 * (t.y - t.x)) * (_point.y + refractedLight.y * t.y - 2.0 / 12.0)));

    scale += diffuse * 0.5;
  }

  return wallColor * scale;
}

#endif
