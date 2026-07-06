using UnityEngine;

namespace BeadWorks.Workshop
{
    /// <summary>
    /// Orthographic camera pan and zoom for mobile workshop editing.
    /// </summary>
    [RequireComponent(typeof(Camera))]
    public class CameraController : MonoBehaviour
    {
        [SerializeField] private Transform _pegboardTarget;
        [SerializeField] private float _minOrthographicSize = 3f;
        [SerializeField] private float _maxOrthographicSize = 12f;
        [SerializeField] private float _zoomSpeed = 0.01f;
        [SerializeField] private float _defaultOrthographicSize = 6f;

        private Camera _camera;
        private Vector3 _dragOriginWorld;
        private bool _isPanning;
        private Input.InputController _inputController;
        private WorkshopController _workshopController;
        private Vector2 _lastPinchMidpoint;
        private bool _hasPinchMidpoint;

        public Transform PegboardTarget
        {
            get => _pegboardTarget;
            set
            {
                _pegboardTarget = value;
                FocusOnPegboard();
            }
        }

        private void Awake()
        {
            _camera = GetComponent<Camera>();
            _camera.orthographic = true;
            _camera.orthographicSize = _defaultOrthographicSize;
        }

        public void Bind(Input.InputController inputController, WorkshopController workshopController)
        {
            if (_inputController != null)
            {
                _inputController.PointerDown -= OnPointerDown;
                _inputController.PointerUp -= OnPointerUp;
                _inputController.PointerMove -= OnPointerMove;
                _inputController.PinchDelta -= OnPinchDelta;
            }

            _inputController = inputController;
            _workshopController = workshopController;
            if (_inputController == null)
            {
                return;
            }

            _inputController.PointerDown += OnPointerDown;
            _inputController.PointerUp += OnPointerUp;
            _inputController.PointerMove += OnPointerMove;
            _inputController.PinchDelta += OnPinchDelta;
        }

        private void LateUpdate()
        {
            if (_pegboardTarget == null)
            {
                return;
            }

            HandleTwoFingerPan();

            var targetPosition = _pegboardTarget.position;
            transform.position = new Vector3(transform.position.x, transform.position.y, targetPosition.z - 10f);
            transform.rotation = Quaternion.LookRotation(Vector3.forward, Vector3.up);
        }

        private void HandleTwoFingerPan()
        {
            if (UnityEngine.Input.touchCount < 2)
            {
                _hasPinchMidpoint = false;
                return;
            }

            var touch0 = UnityEngine.Input.GetTouch(0);
            var touch1 = UnityEngine.Input.GetTouch(1);
            var midpoint = (touch0.position + touch1.position) * 0.5f;

            if (_hasPinchMidpoint)
            {
                var previousWorld = ScreenToWorld(_lastPinchMidpoint);
                var currentWorld = ScreenToWorld(midpoint);
                var delta = previousWorld - currentWorld;
                transform.position += new Vector3(delta.x, delta.y, 0f);
            }

            _lastPinchMidpoint = midpoint;
            _hasPinchMidpoint = true;
        }

        public void FocusOnPegboard()
        {
            if (_pegboardTarget == null)
            {
                return;
            }

            var target = _pegboardTarget.position;
            transform.position = new Vector3(target.x, target.y, target.z - 10f);
            _camera.orthographicSize = _defaultOrthographicSize;
        }

        private void OnPointerDown(Vector2 screenPosition)
        {
            if (ShouldBlockPan())
            {
                return;
            }

            _isPanning = true;
            _dragOriginWorld = ScreenToWorld(screenPosition);
        }

        private void OnPointerMove(Vector2 screenPosition)
        {
            if (!_isPanning || ShouldBlockPan())
            {
                return;
            }

            if (UnityEngine.Input.touchCount == 1 && ShouldUseSingleFingerPan())
            {
                return;
            }

            if (UnityEngine.Input.touchCount >= 2)
            {
                return;
            }

            var currentWorld = ScreenToWorld(screenPosition);
            var delta = _dragOriginWorld - currentWorld;
            transform.position += new Vector3(delta.x, delta.y, 0f);
        }

        private bool ShouldBlockPan()
        {
            if (_workshopController == null)
            {
                return false;
            }

            return _workshopController.IsHoldingBead || _workshopController.IsDraggingIron;
        }

        private static bool ShouldUseSingleFingerPan()
        {
            return Application.isMobilePlatform;
        }

        private void OnPointerUp(Vector2 screenPosition)
        {
            _isPanning = false;
        }

        private void OnPinchDelta(float delta)
        {
            var nextSize = _camera.orthographicSize - delta * _zoomSpeed;
            _camera.orthographicSize = Mathf.Clamp(nextSize, _minOrthographicSize, _maxOrthographicSize);
        }

        private void OnDestroy()
        {
            Bind(null, null);
        }

        private Vector3 ScreenToWorld(Vector2 screenPosition)
        {
            var depth = Mathf.Abs(transform.position.z - (_pegboardTarget != null ? _pegboardTarget.position.z : 0f));
            var world = _camera.ScreenToWorldPoint(new Vector3(screenPosition.x, screenPosition.y, depth));
            return world;
        }
    }
}
