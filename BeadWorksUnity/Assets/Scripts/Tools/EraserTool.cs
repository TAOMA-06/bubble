using BeadWorks.Feedback;
using BeadWorks.Workshop;
using UnityEngine;

namespace BeadWorks.Tools
{
    /// <summary>
    /// Removes placed beads when tapping occupied pegboard cells.
    /// </summary>
    public class EraserTool
    {
        private PegboardGrid _grid;
        private readonly WorkshopFeedback _feedback;
        private readonly Camera _camera;
        private readonly Transform _pegboardRoot;

        public System.Action OnBeadRemoved;

        public EraserTool(
            PegboardGrid grid,
            WorkshopFeedback feedback,
            Camera camera,
            Transform pegboardRoot)
        {
            _grid = grid;
            _feedback = feedback;
            _camera = camera;
            _pegboardRoot = pegboardRoot;
        }

        public void SetGrid(PegboardGrid grid)
        {
            _grid = grid;
        }

        public bool TryEraseAtScreen(Vector2 screenPosition)
        {
            var world = ScreenToWorld(screenPosition);
            var cell = _grid.FindNearestCell(world);

            if (!_grid.IsInside(cell) || !_grid.IsOccupied(cell))
            {
                return false;
            }

            _grid.RemoveBead(cell);
            _feedback.PlayErase();
            _feedback.LightHaptic();
            OnBeadRemoved?.Invoke();
            return true;
        }

        private Vector3 ScreenToWorld(Vector2 screenPosition)
        {
            var depth = Mathf.Abs(_camera.transform.position.z - _pegboardRoot.position.z);
            return _camera.ScreenToWorldPoint(new Vector3(screenPosition.x, screenPosition.y, depth));
        }
    }
}
