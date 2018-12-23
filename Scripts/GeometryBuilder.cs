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
    // var cube = MeshDraft.Cube(2f, true);
    var cube = CubeOpenTop(Vector3.right * 2f, Vector3.forward * 2f, Vector3.up * 2f, true);
    // var vs = cube.vertices;
    // cube.vertices = vs.Take(2).Concat(vs.Skip(4)).ToList();
    cube.FlipFaces();
    cubeMeshFilter.mesh = cube.ToMesh();

    var water = MeshDraft.Plane(2f, 2f, 200, 200, true);
    water.vertices = water.vertices.Select(v => v - new Vector3(1f, 0, 1f)).ToList();
    waterMeshFilter.mesh = water.ToMesh();

    // var sphere = MeshDraft.Sphere(0.25f, 10, 10, true);
    var sphere = MeshDraft.Sphere(1f, 10, 10, true);
    sphereMeshFilter.mesh = sphere.ToMesh();
  }

  /// <summary>
  /// Constructs a hexahedron draft
  /// </summary>
  public static MeshDraft CubeOpenTop(Vector3 width, Vector3 length, Vector3 height, bool generateUV = true)
  {
    Vector3 v000 = -width/2 - length/2 - height/2;
    Vector3 v001 = v000 + height;
    Vector3 v010 = v000 + width;
    Vector3 v011 = v000 + width + height;
    Vector3 v100 = v000 + length;
    Vector3 v101 = v000 + length + height;
    Vector3 v110 = v000 + width + length;
    Vector3 v111 = v000 + width + length + height;

    var draft = new MeshDraft {name = "Hexahedron"};
    if (generateUV)
    {
      Vector2 uv0 = new Vector2(0, 0);
      Vector2 uv1 = new Vector2(0, 1);
      Vector2 uv2 = new Vector2(1, 1);
      Vector2 uv3 = new Vector2(1, 0);
      draft.AddQuad(v100, v101, v001, v000, Vector3.left, uv0, uv1, uv2, uv3)
        .AddQuad(v010, v011, v111, v110, Vector3.right, uv0, uv1, uv2, uv3)
        // .AddQuad(v010, v110, v100, v000, Vector3.down, uv0, uv1, uv2, uv3)
        .AddQuad(v111, v011, v001, v101, Vector3.up, uv0, uv1, uv2, uv3)
        .AddQuad(v000, v001, v011, v010, Vector3.back, uv0, uv1, uv2, uv3)
        .AddQuad(v110, v111, v101, v100, Vector3.forward, uv0, uv1, uv2, uv3);
    }
    else
    {
      draft.AddQuad(v100, v101, v001, v000, Vector3.left)
        .AddQuad(v010, v011, v111, v110, Vector3.right)
        // .AddQuad(v010, v110, v100, v000, Vector3.down)
        .AddQuad(v111, v011, v001, v101, Vector3.up)
        .AddQuad(v000, v001, v011, v010, Vector3.back)
        .AddQuad(v110, v111, v101, v100, Vector3.forward);
    }
    return draft;
  }



}
