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

public class CameraOrbit : MonoBehaviour {
  public float rotationRate = 100f;

  // Use this for initialization
  void Start () {
  }

  // Update is called once per frame
  void Update () {
    if (Input.GetMouseButton(0)) {
      transform.Rotate(-Input.GetAxis("Mouse Y") * rotationRate * Time.deltaTime, 0f, 0f, Space.Self);
      transform.Rotate(0f, Input.GetAxis("Mouse X") * rotationRate * Time.deltaTime, 0f, Space.World);
    }
  }
}
