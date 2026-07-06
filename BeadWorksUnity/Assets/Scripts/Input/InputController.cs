using System;
using UnityEngine;

namespace BeadWorks.Input
{
    /// <summary>
    /// Unified mouse and touch input for workshop tools.
    /// </summary>
    public class InputController : MonoBehaviour
    {
        public event Action<Vector2> PointerDown;
        public event Action<Vector2> PointerUp;
        public event Action<Vector2> PointerMove;
        public event Action<float> PinchDelta;

        [SerializeField] private bool _blockUiHits = true;

        private int _activeFingerId = -1;
        private bool _isPointerDown;
        private float _lastPinchDistance = -1f;

        public bool IsPointerDown => _isPointerDown;
        public Vector2 LastPointerPosition { get; private set; }

        private void Update()
        {
            if (UnityEngine.Input.touchCount > 0)
            {
                HandleTouchInput();
                return;
            }

            HandleMouseInput();
        }

        private void HandleMouseInput()
        {
            var position = (Vector2)UnityEngine.Input.mousePosition;

            if (UnityEngine.Input.GetMouseButtonDown(0))
            {
                if (_blockUiHits && IsOverUi(position))
                {
                    return;
                }

                _isPointerDown = true;
                LastPointerPosition = position;
                PointerDown?.Invoke(position);
            }
            else if (UnityEngine.Input.GetMouseButton(0) && _isPointerDown)
            {
                LastPointerPosition = position;
                PointerMove?.Invoke(position);
            }
            else if (UnityEngine.Input.GetMouseButtonUp(0) && _isPointerDown)
            {
                _isPointerDown = false;
                LastPointerPosition = position;
                PointerUp?.Invoke(position);
            }
        }

        private void HandleTouchInput()
        {
            if (UnityEngine.Input.touchCount >= 2)
            {
                HandlePinch();
                return;
            }

            _lastPinchDistance = -1f;

            var touch = UnityEngine.Input.GetTouch(0);
            var position = touch.position;

            switch (touch.phase)
            {
                case TouchPhase.Began:
                    if (_blockUiHits && IsOverUi(position, touch.fingerId))
                    {
                        return;
                    }

                    _activeFingerId = touch.fingerId;
                    _isPointerDown = true;
                    LastPointerPosition = position;
                    PointerDown?.Invoke(position);
                    break;

                case TouchPhase.Moved:
                case TouchPhase.Stationary:
                    if (!_isPointerDown || touch.fingerId != _activeFingerId)
                    {
                        return;
                    }

                    LastPointerPosition = position;
                    PointerMove?.Invoke(position);
                    break;

                case TouchPhase.Ended:
                case TouchPhase.Canceled:
                    if (!_isPointerDown || touch.fingerId != _activeFingerId)
                    {
                        return;
                    }

                    _isPointerDown = false;
                    _activeFingerId = -1;
                    LastPointerPosition = position;
                    PointerUp?.Invoke(position);
                    break;
            }
        }

        private void HandlePinch()
        {
            var touch0 = UnityEngine.Input.GetTouch(0);
            var touch1 = UnityEngine.Input.GetTouch(1);
            var distance = Vector2.Distance(touch0.position, touch1.position);

            if (_lastPinchDistance > 0f)
            {
                var delta = distance - _lastPinchDistance;
                PinchDelta?.Invoke(delta);
            }

            _lastPinchDistance = distance;
        }

        private static bool IsOverUi(Vector2 screenPosition, int pointerId = -1)
        {
            if (UnityEngine.EventSystems.EventSystem.current == null)
            {
                return false;
            }

            return pointerId >= 0
                ? UnityEngine.EventSystems.EventSystem.current.IsPointerOverGameObject(pointerId)
                : UnityEngine.EventSystems.EventSystem.current.IsPointerOverGameObject();
        }
    }
}
