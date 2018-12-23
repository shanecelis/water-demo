using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UpdateMaterials : MonoBehaviour {

  public Material[] materials;
  public Transform sphere;
  public Transform light;

	// Use this for initialization
	void Start () {
	}

	// Update is called once per frame
	void Update () {
    for (int i = 0; i < materials.Length; i++) {
      materials[i].SetVector("sphereCenter", sphere.position);
      materials[i].SetVector("light", light.forward);
    }
	}
}
