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
using UnityEngine.EventSystems;

// http://tips.hecomi.com/entry/2017/05/17/020037
public class WaterSimulation : MonoBehaviour, IPointerClickHandler, IDragHandler {
  public CustomRenderTexture texture;
  public float dropRadius = 1f; // uv units [0, 1]
  public bool pause = false;
  public int initialDropCount = 20;

  private CustomRenderTextureUpdateZone[] zones = null;
  private Collider collider;
  private CustomRenderTextureUpdateZone defaultZone, normalZone, waveZone;

  void Start() {
    texture.Initialize();
    collider = GetComponent<Collider>();

    defaultZone = new CustomRenderTextureUpdateZone();
    defaultZone.needSwap = true;
    defaultZone.passIndex = 0; // integrate
    defaultZone.rotation = 0f;
    defaultZone.updateZoneCenter = new Vector2(0.5f, 0.5f);
    defaultZone.updateZoneSize = new Vector2(1f, 1f);

    normalZone = new CustomRenderTextureUpdateZone();
    normalZone.needSwap = true;
    normalZone.passIndex = 2; // update normals
    normalZone.rotation = 0f;
    normalZone.updateZoneCenter = new Vector2(0.5f, 0.5f);
    normalZone.updateZoneSize = new Vector2(1f, 1f);

    waveZone = new CustomRenderTextureUpdateZone();
    waveZone.needSwap = true;
    waveZone.passIndex = 1; // drop
    waveZone.rotation = 0f;
    // waveZone.updateZoneCenter = uv;
    waveZone.updateZoneSize = new Vector2(dropRadius, dropRadius);

    var waves = new List<CustomRenderTextureUpdateZone>();
    for (int i = 0; i < initialDropCount; i++) {
      waveZone.updateZoneCenter = new Vector2(Random.Range(0f, 1f),
                                              Random.Range(0f, 1f));
      // CustomRenderTextureUpdateZone is a struct so this is a copy operation.
      waves.Add(waveZone);
    }
    zones = waves.ToArray();
  }

  public void OnDrag(PointerEventData ped) {
    AddWave(ped);
  }

  public void OnPointerClick(PointerEventData ped) {
    AddWave(ped);
  }

  void AddWave(PointerEventData ped) {
    // https://answers.unity.com/questions/892333/find-xy-cordinates-of-click-on-uiimage-new-gui-sys.html
    Vector2 localCursor;
    var rt = GetComponent<RectTransform>();
    if (rt == null || !RectTransformUtility.ScreenPointToLocalPointInRectangle(rt, ped.position, ped.pressEventCamera, out localCursor))
      return;

    // Vector2 uv = Rect.NormalizedToPoint(rt.rect, localCursor);
    Vector2 uv = Rect.PointToNormalized(rt.rect, localCursor);

    var leftClick = ped.button == PointerEventData.InputButton.Left;

    // Debug.Log("We got a click " + localCursor + " uv " + uv);
    // AddWave(uv, leftClick ? 2 : 3); // 1 または -1 にバッファを塗るパス);
    AddWave(uv);
  }

  void AddWave(Vector2 uv) {
    waveZone.updateZoneCenter = new Vector2(uv.x, 1f - uv.y);

    if (pause) {
      zones = new CustomRenderTextureUpdateZone[] { waveZone, normalZone };
    } else {
      zones = new CustomRenderTextureUpdateZone[] { defaultZone, defaultZone, waveZone, normalZone };
    }
    // texture.Update(1);
  }

  void Update() {
    if (Input.GetKeyDown(KeyCode.Space))
      pause = !pause;
    UpdateZones();
    if (zones != null) {
      texture.SetUpdateZones(zones);
      zones = null;
      if (pause)
        texture.Update(1);
    } else {
      texture.SetUpdateZones(new CustomRenderTextureUpdateZone[] { defaultZone, defaultZone, normalZone });
    }
    if (! pause
        || Input.GetKeyDown(KeyCode.N))
      texture.Update(1);
  }

  void UpdateZones() {
    if (collider == null) return;
    bool leftClick = Input.GetMouseButtonDown(0);
    bool rightClick = Input.GetMouseButtonDown(1);
    // bool leftClick = Input.GetMouseButton(0);
    // bool rightClick = Input.GetMouseButton(1);
    if (!leftClick && !rightClick) return;

    RaycastHit hit;
    var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
    // if (Physics.Raycast(ray, out hit)
    //     && hit.transform == transform) {

    if (collider.Raycast(ray, out hit, 100f)) {
      // Debug.Log("Clicked uv " + hit.textureCoord2);
      // AddWave(hit.textureCoord2, leftClick ? 2 : 3);
      AddWave(hit.textureCoord2);
    }
  }
}
