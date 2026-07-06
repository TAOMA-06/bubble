using BeadWorks.Data;
using BeadWorks.Feedback;
using BeadWorks.Presentation;
using BeadWorks.UI;
using BeadWorks.Workshop;
using UnityEngine;

namespace BeadWorks.Core
{
    /// <summary>
    /// Entry point that wires workshop systems and app flow together.
    /// </summary>
    public class GameBootstrap : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private WorkshopController _workshopController;
        [SerializeField] private Input.InputController _inputController;
        [SerializeField] private CameraController _cameraController;
        [SerializeField] private PegboardPresenter _pegboardPresenter;
        [SerializeField] private WorkbenchBackground _workbenchBackground;
        [SerializeField] private WorkshopUIController _uiController;
        [SerializeField] private IroningUIController _ironingUIController;
        [SerializeField] private BeadFactory _beadFactory;
        [SerializeField] private WorkshopFeedback _workshopFeedback;
        [SerializeField] private TextAsset _paletteJson;

        [Header("Scene Targets")]
        [SerializeField] private Transform _workshopRoot;
        [SerializeField] private Transform _pegboardRoot;

        private BeadPaletteRepository _paletteRepository;
        private AppFlowController _appFlow;

        private void Awake()
        {
            Application.targetFrameRate = 60;

            _paletteRepository = new BeadPaletteRepository();
            _paletteRepository.Load(_paletteJson);

            EnsureFeedbackComponent();
            EnsureBeadFactory();
            EnsureIroningUi();
            EnsureAppFlow();

            if (_workbenchBackground != null && _pegboardRoot != null)
            {
                _workbenchBackground.BuildAround(_pegboardRoot, WorkshopController.DefaultGridSize);
            }

            var camera = Camera.main;
            _workshopController.Initialize(
                _paletteRepository,
                _pegboardPresenter,
                _uiController,
                _ironingUIController,
                _beadFactory,
                _workshopFeedback,
                _pegboardRoot,
                camera);

            _cameraController.Bind(_inputController, _workshopController);
            _cameraController.PegboardTarget = _pegboardRoot;

            _inputController.PointerDown += OnPointerDown;
            _inputController.PointerUp += OnPointerUp;
            _inputController.PointerMove += OnPointerMove;
            _inputController.PinchDelta += OnPinchDelta;
            _workshopController.StatusChanged += OnStatusChanged;

            _appFlow.Initialize(
                _workshopController,
                _uiController,
                _ironingUIController,
                _cameraController,
                _workbenchBackground,
                _pegboardPresenter,
                _paletteRepository,
                _workshopRoot != null ? _workshopRoot : _pegboardRoot.parent,
                _pegboardRoot,
                camera);
        }

        private void OnDestroy()
        {
            if (_inputController != null)
            {
                _inputController.PointerDown -= OnPointerDown;
                _inputController.PointerUp -= OnPointerUp;
                _inputController.PointerMove -= OnPointerMove;
                _inputController.PinchDelta -= OnPinchDelta;
            }

            if (_workshopController != null)
            {
                _workshopController.StatusChanged -= OnStatusChanged;
            }
        }

        private void OnPointerDown(Vector2 screenPosition)
        {
            if (_appFlow != null && _appFlow.CurrentScreen == AppScreen.FinishedViewer)
            {
                var presenterHost = _workshopRoot != null ? _workshopRoot : _pegboardRoot;
                var presenter = presenterHost != null
                    ? presenterHost.GetComponent<FinishedWorkPresenter>()
                    : null;
                presenter?.BeginDrag(screenPosition);
                return;
            }

            _workshopController.HandlePointerDown(screenPosition);
        }

        private void OnPointerMove(Vector2 screenPosition)
        {
            if (_appFlow != null && _appFlow.CurrentScreen == AppScreen.FinishedViewer)
            {
                var presenterHost = _workshopRoot != null ? _workshopRoot : _pegboardRoot;
                var presenter = presenterHost != null
                    ? presenterHost.GetComponent<FinishedWorkPresenter>()
                    : null;
                presenter?.UpdateDrag(screenPosition);
                return;
            }

            _workshopController.HandlePointerMove(screenPosition);
        }

        private void OnPointerUp(Vector2 screenPosition)
        {
            if (_appFlow != null && _appFlow.CurrentScreen == AppScreen.FinishedViewer)
            {
                var presenterHost = _workshopRoot != null ? _workshopRoot : _pegboardRoot;
                var presenter = presenterHost != null
                    ? presenterHost.GetComponent<FinishedWorkPresenter>()
                    : null;
                presenter?.EndDrag();
                return;
            }

            _workshopController.HandlePointerUp(screenPosition);
        }

        private void OnPinchDelta(float delta)
        {
            if (_appFlow != null && _appFlow.CurrentScreen == AppScreen.FinishedViewer)
            {
                var presenterHost = _workshopRoot != null ? _workshopRoot : _pegboardRoot;
                var presenter = presenterHost != null
                    ? presenterHost.GetComponent<FinishedWorkPresenter>()
                    : null;
                presenter?.HandleZoom(delta);
            }
        }

        private void OnStatusChanged(string message)
        {
            _uiController?.SetStatus(message);
        }

        private void EnsureAppFlow()
        {
            _appFlow = GetComponent<AppFlowController>();
            if (_appFlow == null)
            {
                _appFlow = gameObject.AddComponent<AppFlowController>();
            }
        }

        private void EnsureFeedbackComponent()
        {
            if (_workshopFeedback != null)
            {
                return;
            }

            _workshopFeedback = gameObject.GetComponent<WorkshopFeedback>();
            if (_workshopFeedback == null)
            {
                _workshopFeedback = gameObject.AddComponent<WorkshopFeedback>();
            }
        }

        private void EnsureBeadFactory()
        {
            if (_beadFactory != null)
            {
                return;
            }

            _beadFactory = gameObject.GetComponent<BeadFactory>();
            if (_beadFactory == null)
            {
                _beadFactory = gameObject.AddComponent<BeadFactory>();
            }
        }

        private void EnsureIroningUi()
        {
            if (_ironingUIController != null)
            {
                return;
            }

            var canvas = _uiController != null ? _uiController.GetComponent<RectTransform>() : null;
            if (canvas == null)
            {
                return;
            }

            _ironingUIController = canvas.gameObject.GetComponent<IroningUIController>();
            if (_ironingUIController == null)
            {
                _ironingUIController = canvas.gameObject.AddComponent<IroningUIController>();
            }
        }
    }
}
