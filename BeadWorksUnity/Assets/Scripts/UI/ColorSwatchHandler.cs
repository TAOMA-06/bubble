using System;
using BeadWorks.Data;
using BeadWorks.Tools;
using UnityEngine;
using UnityEngine.EventSystems;

namespace BeadWorks.UI
{
    /// <summary>
    /// Handles press-and-drag from a palette swatch to pick up a bead with tweezers.
    /// </summary>
    public class ColorSwatchHandler : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
    {
        private BeadColorData _color;
        private Func<ToolMode> _toolProvider;
        private Action<BeadColorData, Vector2> _onPickBegin;
        private Action<Vector2> _onPickMove;
        private Action<Vector2> _onPickEnd;
        private bool _isDragging;

        public void Configure(
            BeadColorData color,
            Func<ToolMode> toolProvider,
            Action<BeadColorData, Vector2> onPickBegin,
            Action<Vector2> onPickMove,
            Action<Vector2> onPickEnd)
        {
            _color = color;
            _toolProvider = toolProvider;
            _onPickBegin = onPickBegin;
            _onPickMove = onPickMove;
            _onPickEnd = onPickEnd;
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            if (_toolProvider?.Invoke() != ToolMode.Tweezers || _color == null)
            {
                return;
            }

            _isDragging = true;
            _onPickBegin?.Invoke(_color, eventData.position);
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            FinishDrag(eventData.position);
        }

        private void Update()
        {
            if (!_isDragging)
            {
                return;
            }

            if (!IsPointerHeld())
            {
                FinishDrag(GetPointerPosition());
                return;
            }

            _onPickMove?.Invoke(GetPointerPosition());
        }

        private void FinishDrag(Vector2 position)
        {
            if (!_isDragging)
            {
                return;
            }

            _isDragging = false;
            _onPickEnd?.Invoke(position);
        }

        private static bool IsPointerHeld()
        {
            if (UnityEngine.Input.touchCount > 0)
            {
                return true;
            }

            return UnityEngine.Input.GetMouseButton(0);
        }

        private static Vector2 GetPointerPosition()
        {
            if (UnityEngine.Input.touchCount > 0)
            {
                return UnityEngine.Input.GetTouch(0).position;
            }

            return UnityEngine.Input.mousePosition;
        }
    }
}
