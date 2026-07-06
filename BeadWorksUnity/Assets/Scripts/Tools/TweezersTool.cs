using BeadWorks.Data;
using BeadWorks.Feedback;
using BeadWorks.Presentation;
using BeadWorks.Workshop;
using UnityEngine;

namespace BeadWorks.Tools
{
    /// <summary>
    /// Pick beads from the palette, drag with tweezers, snap to pegboard cells.
    /// </summary>
    public class TweezersTool
    {
        private PegboardGrid _grid;
        private readonly BeadFactory _beadFactory;
        private readonly WorkshopFeedback _feedback;
        private readonly Transform _beadsRoot;
        private readonly Camera _camera;
        private readonly Transform _pegboardRoot;

        private BeadView _heldBead;
        private BeadView _previewBead;
        private BeadColorData _heldColor;
        private BeadSizeType _beadSize;
        private Vector3 _rejectOrigin;
        private bool _isRejecting;

        public System.Action OnBeadPlaced;

        public bool IsHoldingBead => _heldBead != null;

        public void SetGrid(PegboardGrid grid)
        {
            _grid = grid;
        }

        public TweezersTool(
            PegboardGrid grid,
            BeadFactory beadFactory,
            WorkshopFeedback feedback,
            Transform beadsRoot,
            Camera camera,
            Transform pegboardRoot)
        {
            _grid = grid;
            _beadFactory = beadFactory;
            _feedback = feedback;
            _beadsRoot = beadsRoot;
            _camera = camera;
            _pegboardRoot = pegboardRoot;
        }

        public void SetBeadSize(BeadSizeType beadSize)
        {
            _beadSize = beadSize;
        }

        public void BeginPick(BeadColorData color, Vector2 screenPosition)
        {
            if (color == null || _heldBead != null)
            {
                return;
            }

            _heldColor = color;
            _rejectOrigin = ScreenToWorld(screenPosition);
            _isRejecting = false;

            _heldBead = _beadFactory.CreateHeldBead(color, _beadSize, _rejectOrigin, _beadsRoot);
            _feedback.PlayPickUp();
            _feedback.LightHaptic();
        }

        public void UpdateDrag(Vector2 screenPosition)
        {
            if (_heldBead == null)
            {
                return;
            }

            if (_isRejecting)
            {
                return;
            }

            var world = ScreenToWorld(screenPosition);
            _heldBead.transform.position = world + new Vector3(0f, 0f, -0.08f);
            UpdatePreview(world);
        }

        public void EndDrag(Vector2 screenPosition)
        {
            if (_heldBead == null)
            {
                ClearPreview();
                return;
            }

            if (_isRejecting)
            {
                return;
            }

            var world = ScreenToWorld(screenPosition);
            var cell = _grid.FindNearestCell(world);

            if (_grid.IsInside(cell) && !_grid.IsOccupied(cell))
            {
                PlaceAt(cell);
                return;
            }

            RejectPlacement();
        }

        public void CancelPick()
        {
            ClearPreview();
            DestroyHeldBead();
        }

        private void PlaceAt(Vector2Int cell)
        {
            var bead = BeadInstance.CreateHeld(_heldColor, _beadSize);
            if (!_grid.TryPlaceBead(cell, bead, out var placedView))
            {
                RejectPlacement();
                return;
            }

            DestroyHeldBead();
            ClearPreview();

            placedView.PlayPlaceBounce();
            _feedback.PlayPlace();
            _feedback.LightHaptic();
            OnBeadPlaced?.Invoke();
        }

        private void RejectPlacement()
        {
            if (_heldBead == null)
            {
                return;
            }

            _isRejecting = true;
            ClearPreview();
            _feedback.PlayReject();
            _feedback.LightHaptic();

            var start = _heldBead.transform.position;
            var end = _rejectOrigin + new Vector3(0f, 0f, -0.08f);
            var view = _heldBead;
            _heldBead = null;

            LeanReject(view, start, end);
        }

        private void LeanReject(BeadView view, Vector3 start, Vector3 end)
        {
            if (view == null)
            {
                return;
            }

            var runner = view.gameObject.AddComponent<RejectMotion>();
            runner.Run(start, end, 0.18f, () =>
            {
                if (view != null)
                {
                    Object.Destroy(view.gameObject);
                }
            });
        }

        private void UpdatePreview(Vector3 world)
        {
            var cell = _grid.FindNearestCell(world);

            if (!_grid.IsInside(cell) || _grid.IsOccupied(cell))
            {
                ClearPreview();
                return;
            }

            var snapWorld = _grid.CellToWorld(cell);

            if (_previewBead == null)
            {
                var previewInstance = BeadInstance.CreateHeld(_heldColor, _beadSize);
                _previewBead = _beadFactory.CreateBead(previewInstance, snapWorld, _beadsRoot, isPreview: true);
            }
            else
            {
                _previewBead.transform.position = snapWorld;
            }
        }

        private void ClearPreview()
        {
            if (_previewBead != null)
            {
                Object.Destroy(_previewBead.gameObject);
                _previewBead = null;
            }
        }

        private void DestroyHeldBead()
        {
            if (_heldBead != null)
            {
                Object.Destroy(_heldBead.gameObject);
                _heldBead = null;
            }

            _isRejecting = false;
        }

        private Vector3 ScreenToWorld(Vector2 screenPosition)
        {
            var depth = Mathf.Abs(_camera.transform.position.z - _pegboardRoot.position.z);
            return _camera.ScreenToWorldPoint(new Vector3(screenPosition.x, screenPosition.y, depth));
        }

        private sealed class RejectMotion : MonoBehaviour
        {
            private Vector3 _start;
            private Vector3 _end;
            private float _duration;
            private System.Action _onComplete;
            private float _elapsed;

            public void Run(Vector3 start, Vector3 end, float duration, System.Action onComplete)
            {
                _start = start;
                _end = end;
                _duration = duration;
                _onComplete = onComplete;
            }

            private void Update()
            {
                _elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(_elapsed / _duration);
                var eased = 1f - Mathf.Pow(1f - t, 3f);
                transform.position = Vector3.Lerp(_start, _end, eased);

                if (t >= 1f)
                {
                    _onComplete?.Invoke();
                    Destroy(this);
                }
            }
        }
    }
}
