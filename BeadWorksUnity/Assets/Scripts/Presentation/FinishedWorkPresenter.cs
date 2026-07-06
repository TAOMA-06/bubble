using System;
using System.Collections.Generic;
using BeadWorks.Data;
using BeadWorks.Workshop;
using UnityEngine;

namespace BeadWorks.Presentation
{
    /// <summary>
    /// Displays a finished work on a clean background with rotation, zoom, and product attachments.
    /// </summary>
    public class FinishedWorkPresenter : MonoBehaviour
    {
        [SerializeField] private Color _backgroundColor = new(0.95f, 0.94f, 0.92f);
        [SerializeField] private float _defaultScale = 1f;

        private Transform _viewerRoot;
        private Transform _workRoot;
        private Transform _attachmentRoot;
        private GameObject _background;
        private Camera _viewerCamera;
        private readonly List<GameObject> _clonedBeads = new();
        private float _rotationY;
        private float _zoom = 1f;
        private bool _isActive;
        private Vector2 _lastDrag;
        private bool _isDragging;

        public bool IsActive => _isActive;
        public event Action<FinishedProductType> ProductTypeChanged;

        public void Show(
            PegboardGrid grid,
            BeadPaletteRepository palette,
            FinishedProductType productType,
            Transform sceneRoot,
            Camera mainCamera)
        {
            Hide();
            _isActive = true;
            _rotationY = 0f;
            _zoom = 1f;

            _viewerRoot = new GameObject("FinishedWorkViewer").transform;
            _viewerRoot.SetParent(sceneRoot, false);

            _background = GameObject.CreatePrimitive(PrimitiveType.Quad);
            _background.name = "ViewerBackground";
            _background.transform.SetParent(_viewerRoot, false);
            _background.transform.localScale = new Vector3(20f, 20f, 1f);
            _background.transform.localPosition = new Vector3(0f, 0f, 0.1f);
            var bgRenderer = _background.GetComponent<MeshRenderer>();
            var bgMat = new Material(Shader.Find("Universal Render Pipeline/Unlit") ?? Shader.Find("Sprites/Default"));
            bgMat.color = _backgroundColor;
            bgRenderer.sharedMaterial = bgMat;
            Destroy(_background.GetComponent<Collider>());

            _workRoot = new GameObject("WorkPivot").transform;
            _workRoot.SetParent(_viewerRoot, false);

            _attachmentRoot = new GameObject("Attachment").transform;
            _attachmentRoot.SetParent(_workRoot, false);

            CloneBeadsFromGrid(grid, palette);
            SetProductType(productType);

            if (mainCamera != null)
            {
                _viewerCamera = mainCamera;
            }
        }

        public void Hide()
        {
            _isActive = false;
            _clonedBeads.Clear();

            if (_viewerRoot != null)
            {
                Destroy(_viewerRoot.gameObject);
                _viewerRoot = null;
            }
        }

        public void SetProductType(FinishedProductType type)
        {
            if (_attachmentRoot == null)
            {
                return;
            }

            for (var i = _attachmentRoot.childCount - 1; i >= 0; i--)
            {
                Destroy(_attachmentRoot.GetChild(i).gameObject);
            }

            switch (type)
            {
                case FinishedProductType.FridgeMagnet:
                    CreateMagnetBacking();
                    break;
                case FinishedProductType.Keychain:
                    CreateKeychainRing();
                    break;
                case FinishedProductType.Pendant:
                    CreatePendantString();
                    break;
            }

            ProductTypeChanged?.Invoke(type);
        }

        public void HandleDrag(Vector2 screenDelta)
        {
            if (!_isActive || _workRoot == null)
            {
                return;
            }

            _rotationY -= screenDelta.x * 0.4f;
            _workRoot.localRotation = Quaternion.Euler(8f, _rotationY, 0f);
        }

        public void HandleZoom(float delta)
        {
            if (!_isActive || _workRoot == null)
            {
                return;
            }

            _zoom = Mathf.Clamp(_zoom - delta * 0.002f, 0.5f, 2.5f);
            _workRoot.localScale = Vector3.one * (_defaultScale * _zoom);
        }

        public void BeginDrag(Vector2 screenPosition)
        {
            _isDragging = true;
            _lastDrag = screenPosition;
        }

        public void UpdateDrag(Vector2 screenPosition)
        {
            if (!_isDragging)
            {
                return;
            }

            var delta = screenPosition - _lastDrag;
            _lastDrag = screenPosition;
            HandleDrag(delta);
        }

        public void EndDrag()
        {
            _isDragging = false;
        }

        private void CloneBeadsFromGrid(PegboardGrid grid, BeadPaletteRepository palette)
        {
            if (grid == null)
            {
                return;
            }

            var beadsContainer = new GameObject("ClonedBeads").transform;
            beadsContainer.SetParent(_workRoot, false);

            grid.ForEachBead((cell, bead) =>
            {
                var local = grid.CellToWorld(cell) - grid.CellToWorld(Vector2Int.zero);
                var beadGo = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                beadGo.name = $"FinishedBead_{cell.x}_{cell.y}";
                beadGo.transform.SetParent(beadsContainer, false);
                beadGo.transform.localPosition = new Vector3(local.x, local.y, -0.03f);
                beadGo.transform.localScale = new Vector3(grid.CellSize * 0.9f, 0.06f, grid.CellSize * 0.9f);

                var renderer = beadGo.GetComponent<MeshRenderer>();
                var mat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
                mat.color = bead.color?.Color ?? Color.magenta;
                mat.SetFloat("_Smoothness", bead.color?.Smoothness ?? 0.5f);
                renderer.sharedMaterial = mat;

                Destroy(beadGo.GetComponent<Collider>());
                _clonedBeads.Add(beadGo);

                if (bead.meltAmount > 0.1f)
                {
                    beadGo.transform.localScale = new Vector3(
                        grid.CellSize * 0.95f,
                        0.04f + bead.flattenAmount * 0.04f,
                        grid.CellSize * 0.95f);
                }
            });
        }

        private void CreateMagnetBacking()
        {
            var backing = GameObject.CreatePrimitive(PrimitiveType.Cube);
            backing.name = "MagnetBacking";
            backing.transform.SetParent(_attachmentRoot, false);
            backing.transform.localPosition = new Vector3(0f, 0f, 0.08f);
            backing.transform.localScale = new Vector3(2.5f, 2.5f, 0.08f);
            var renderer = backing.GetComponent<MeshRenderer>();
            var mat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            mat.color = new Color(0.75f, 0.12f, 0.12f);
            renderer.sharedMaterial = mat;
            Destroy(backing.GetComponent<Collider>());
        }

        private void CreateKeychainRing()
        {
            var ring = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            ring.name = "KeychainRing";
            ring.transform.SetParent(_attachmentRoot, false);
            ring.transform.localPosition = new Vector3(0f, 1.6f, -0.1f);
            ring.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            ring.transform.localScale = new Vector3(0.5f, 0.04f, 0.5f);
            var renderer = ring.GetComponent<MeshRenderer>();
            var mat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            mat.color = new Color(0.82f, 0.82f, 0.85f);
            renderer.sharedMaterial = mat;
            Destroy(ring.GetComponent<Collider>());
        }

        private void CreatePendantString()
        {
            var knot = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            knot.name = "PendantKnot";
            knot.transform.SetParent(_attachmentRoot, false);
            knot.transform.localPosition = new Vector3(0f, 1.8f, -0.05f);
            knot.transform.localScale = Vector3.one * 0.2f;
            var renderer = knot.GetComponent<MeshRenderer>();
            var mat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            mat.color = new Color(0.9f, 0.75f, 0.3f);
            renderer.sharedMaterial = mat;
            Destroy(knot.GetComponent<Collider>());
        }
    }
}
