using UnityEngine;

namespace BeadWorks.Tools
{
    /// <summary>
    /// Drag the iron across the pegboard; exposes world position and heat zone for IroningSystem.
    /// </summary>
    public class IroningTool
    {
        public const float DefaultHeatRadius = 1.35f;
        public const float DefaultIronPower = 1.15f;

        private readonly Camera _camera;
        private readonly Transform _pegboardRoot;
        private readonly Transform _toolsRoot;

        private GameObject _ironRoot;
        private GameObject _heatZoneVisual;
        private Vector3 _worldPosition;
        private Vector3 _lastWorldPosition;
        private bool _isDragging;
        private float _cellSize = 0.5f;

        public bool IsDraggingIron => _isDragging;
        public Vector3 WorldPosition => _worldPosition;
        public float HeatRadius { get; set; } = DefaultHeatRadius;
        public float IronPower { get; set; } = DefaultIronPower;
        public float MoveSpeed { get; private set; }

        public IroningTool(Camera camera, Transform pegboardRoot, Transform toolsRoot)
        {
            _camera = camera;
            _pegboardRoot = pegboardRoot;
            _toolsRoot = toolsRoot;
            BuildVisuals();
            SetVisible(false);
        }

        public void SetCellSize(float cellSize)
        {
            _cellSize = cellSize;
        }

        public void BeginDrag(Vector2 screenPosition)
        {
            _isDragging = true;
            _worldPosition = ScreenToWorld(screenPosition);
            _lastWorldPosition = _worldPosition;
            SetVisible(true);
            UpdateVisuals();
        }

        public void UpdateDrag(Vector2 screenPosition)
        {
            if (!_isDragging)
            {
                return;
            }

            _lastWorldPosition = _worldPosition;
            _worldPosition = ScreenToWorld(screenPosition);
            MoveSpeed = Vector3.Distance(_worldPosition, _lastWorldPosition) / Mathf.Max(Time.deltaTime, 0.0001f);
            UpdateVisuals();
        }

        public void EndDrag(Vector2 screenPosition)
        {
            _isDragging = false;
            _worldPosition = ScreenToWorld(screenPosition);
            MoveSpeed = 0f;
            SetVisible(false);
        }

        public void CancelDrag()
        {
            _isDragging = false;
            MoveSpeed = 0f;
            SetVisible(false);
        }

        private void BuildVisuals()
        {
            _ironRoot = new GameObject("Iron");
            _ironRoot.transform.SetParent(_toolsRoot, false);

            var body = GameObject.CreatePrimitive(PrimitiveType.Quad);
            body.name = "IronBody";
            body.transform.SetParent(_ironRoot.transform, false);
            body.transform.localScale = new Vector3(0.85f, 0.55f, 1f);
            body.transform.localPosition = new Vector3(0f, 0f, -0.12f);

            var bodyRenderer = body.GetComponent<MeshRenderer>();
            var bodyMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            bodyMaterial.color = new Color(0.55f, 0.57f, 0.62f);
            bodyMaterial.SetFloat("_Smoothness", 0.72f);
            bodyRenderer.sharedMaterial = bodyMaterial;
            Object.Destroy(body.GetComponent<Collider>());

            var tip = GameObject.CreatePrimitive(PrimitiveType.Quad);
            tip.name = "IronTip";
            tip.transform.SetParent(_ironRoot.transform, false);
            tip.transform.localScale = new Vector3(0.55f, 0.55f, 1f);
            tip.transform.localPosition = new Vector3(0.42f, 0f, -0.11f);

            var tipRenderer = tip.GetComponent<MeshRenderer>();
            var tipMaterial = new Material(bodyMaterial);
            tipMaterial.color = new Color(0.72f, 0.74f, 0.78f);
            tipRenderer.sharedMaterial = tipMaterial;
            Object.Destroy(tip.GetComponent<Collider>());

            _heatZoneVisual = GameObject.CreatePrimitive(PrimitiveType.Quad);
            _heatZoneVisual.name = "HeatZone";
            _heatZoneVisual.transform.SetParent(_ironRoot.transform, false);
            _heatZoneVisual.transform.localPosition = new Vector3(0f, 0f, -0.005f);
            _heatZoneVisual.transform.localScale = Vector3.one;

            var heatRenderer = _heatZoneVisual.GetComponent<MeshRenderer>();
            var heatMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            heatMaterial.color = new Color(1f, 0.45f, 0.12f, 0.22f);
            heatMaterial.SetFloat("_Smoothness", 0.2f);
            heatRenderer.sharedMaterial = heatMaterial;
            Object.Destroy(_heatZoneVisual.GetComponent<Collider>());
        }

        private void UpdateVisuals()
        {
            if (_ironRoot == null)
            {
                return;
            }

            _ironRoot.transform.position = _worldPosition + new Vector3(0f, 0f, -0.1f);

            var heatDiameter = HeatRadius * _cellSize * 2f;
            _heatZoneVisual.transform.localScale = new Vector3(heatDiameter, heatDiameter, 1f);

            var pulse = 0.18f + (Mathf.Sin(Time.time * 8f) * 0.04f);
            var heatRenderer = _heatZoneVisual.GetComponent<MeshRenderer>();
            if (heatRenderer != null)
            {
                heatRenderer.sharedMaterial.color = new Color(1f, 0.45f, 0.12f, pulse);
            }
        }

        private void SetVisible(bool visible)
        {
            if (_ironRoot != null)
            {
                _ironRoot.SetActive(visible);
            }
        }

        private Vector3 ScreenToWorld(Vector2 screenPosition)
        {
            var depth = Mathf.Abs(_camera.transform.position.z - _pegboardRoot.position.z);
            return _camera.ScreenToWorldPoint(new Vector3(screenPosition.x, screenPosition.y, depth));
        }
    }
}
