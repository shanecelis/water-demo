using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProceduralToolkit;
using System.Linq;

public class GeometryBuilder : MonoBehaviour {

  public MeshFilter cubeMeshFilter;
  public MeshFilter waterMeshFilter;
  public MeshFilter sphereMeshFilter;

  void Start () {
    GenerateMeshes();
  }

  [ContextMenu("Generate Meshes")]
  void GenerateMeshes() {
    var cube = MeshDraft.Cube(2f, true);
    cube.FlipFaces();
    cubeMeshFilter.mesh = cube.ToMesh();

    var water = MeshDraft.Plane(2f, 2f, 200, 200, true);
    water.vertices = water.vertices.Select(v => v - new Vector3(1f, 0, 1f)).ToList();
    waterMeshFilter.mesh = water.ToMesh();

    var sphere = MeshDraft.Sphere(0.25f, 10, 10, true);
    sphereMeshFilter.mesh = sphere.ToMesh();
  }

}
