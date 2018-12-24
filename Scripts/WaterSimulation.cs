using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

// http://tips.hecomi.com/entry/2017/05/17/020037
public class WaterSimulation : MonoBehaviour, IPointerClickHandler, IDragHandler {
  public CustomRenderTexture texture;
  private CustomRenderTextureUpdateZone[] zones = null;

  private Collider collider;
  void Start() {
    texture.Initialize();
    collider = GetComponent<Collider>();
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

    Debug.Log("We got a click " + localCursor + " uv " + uv);
    AddWave(uv, leftClick ? 2 : 3); // 1 または -1 にバッファを塗るパス);
  }

  void AddWave(Vector2 uv, int passIndex) {

    var defaultZone = new CustomRenderTextureUpdateZone();
    defaultZone.needSwap = true;
    defaultZone.passIndex = 0; // 波動方程式のシミュレーションのパス
    defaultZone.rotation = 0f;
    defaultZone.updateZoneCenter = new Vector2(0.5f, 0.5f);
    defaultZone.updateZoneSize = new Vector2(1f, 1f);

    var clickZone = new CustomRenderTextureUpdateZone();
    clickZone.needSwap = true;
    clickZone.passIndex = 1;
    clickZone.rotation = 0f;
    // clickZone.updateZoneCenter = uv;
    clickZone.updateZoneCenter = new Vector2(uv.x, 1 - uv.y);
    clickZone.updateZoneSize = new Vector2(0.1f, 0.1f);
    // clickZone.updateZoneCenter = new Vector2(0.5f, 0.5f);
    // clickZone.updateZoneSize = new Vector2(1f, 1f);

    zones = new CustomRenderTextureUpdateZone[] { defaultZone, clickZone };

    // texture.Update(1);
  }

  void Update() {
    // UpdateZones();
    if (zones != null) {
      texture.SetUpdateZones(zones);
      zones = null;
    } else {
      texture.ClearUpdateZones();
    }
    texture.Update(1);
  }

  // void UpdateZones() {
  //   if (collider == null) return;
  //   bool leftClick = Input.GetMouseButton(0);
  //   bool rightClick = Input.GetMouseButton(1);
  //   if (!leftClick && !rightClick) return;

  //   RaycastHit hit;
  //   var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
  //   // if (Physics.Raycast(ray, out hit)
  //   //     && hit.transform == transform) {

  //   if (collider.Raycast(ray, out hit, 100f)) {
  //     Debug.Log("Clicked uv " + hit.textureCoord2);
  //     AddWave(hit.textureCoord2, leftClick ? 2 : 3);
  //   }
  // }
}
