//$ cite -u https://github.com/shanecelis/water-demo -C -l mit
/* Original code[1] Copyright (c) 2018 Shane Celis[2]
   Licensed under the MIT License[3]

   [1]: https://github.com/shanecelis/water-demo
   [2]: https://github.com/shanecelis
   [3]: https://opensource.org/licenses/MIT
*/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MaterialUpdater : MonoBehaviour {

  public Material[] materials;
  public Transform sphere;
  public Transform light;

  // Use this for initialization
  void Start () {

  }

  void OnEnable() {
    Camera.onPreRender += UpdateMaterials;
  }

  void OnDisable() {
    Camera.onPreRender -= UpdateMaterials;
  }

  void UpdateMaterials(Camera camera) {
    for (int i = 0; i < materials.Length; i++) {
      materials[i].SetVector("sphereCenter", sphere.position);
      materials[i].SetVector("light", -light.forward);
      // materials[i].SetVector("light", light.position);
      materials[i].SetVector("eye", camera.transform.position);
    }
  }
}
