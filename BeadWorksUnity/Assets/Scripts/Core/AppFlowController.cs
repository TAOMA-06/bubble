using System;
using System.Collections.Generic;
using BeadWorks.Data;
using BeadWorks.Presentation;
using BeadWorks.Services;
using BeadWorks.UI;
using BeadWorks.Workshop;
using UnityEngine;

namespace BeadWorks.Core
{
    /// <summary>
    /// Orchestrates the vertical-slice screen flow within a single scene.
    /// </summary>
    public class AppFlowController : MonoBehaviour
    {
        [SerializeField] private Transform _workshopRoot;
        [SerializeField] private Transform _pegboardRoot;

        private WorkshopController _workshop;
        private WorkshopUIController _workshopUi;
        private IroningUIController _ironingUi;
        private MainMenuUIController _mainMenu;
        private PatternSelectUIController _patternSelect;
        private ImageImportUIController _imageImportUi;
        private PatternGuideUIController _patternGuideUi;
        private GalleryUIController _galleryUi;
        private FinishedWorkViewerUIController _finishedViewerUi;
        private DebugOverlayController _debugOverlay;
        private PatternGuidePresenter _patternGuide;
        private FinishedWorkPresenter _finishedPresenter;
        private CameraController _cameraController;
        private WorkbenchBackground _workbenchBackground;
        private PegboardPresenter _pegboardPresenter;
        private BeadPaletteRepository _palette;
        private PatternRepository _patternRepository;
        private GalleryRepository _galleryRepository;
        private ShareCaptureService _shareCapture;

        private AppScreen _currentScreen = AppScreen.MainMenu;
        private WorkshopSession _session;
        private FinishedProductType _productType = FinishedProductType.FridgeMagnet;
        private DateTime _completedAt;
        private readonly List<Vector2Int> _wrongCells = new();
        private readonly List<Vector2Int> _missingCells = new();
        private FinishedWorkRecord _viewingRecord;

        public AppScreen CurrentScreen => _currentScreen;
        public GalleryRepository Gallery => _galleryRepository;

        public void Initialize(
            WorkshopController workshop,
            WorkshopUIController workshopUi,
            IroningUIController ironingUi,
            CameraController cameraController,
            WorkbenchBackground workbenchBackground,
            PegboardPresenter pegboardPresenter,
            BeadPaletteRepository palette,
            Transform workshopRoot,
            Transform pegboardRoot,
            Camera mainCamera)
        {
            _workshop = workshop;
            _workshopUi = workshopUi;
            _ironingUi = ironingUi;
            _cameraController = cameraController;
            _workbenchBackground = workbenchBackground;
            _pegboardPresenter = pegboardPresenter;
            _palette = palette;
            _workshopRoot = workshopRoot;
            _pegboardRoot = pegboardRoot;

            SetWorkshopVisible(false);

            _patternRepository = new PatternRepository();
            _patternRepository.LoadBuiltins();
            _galleryRepository = new GalleryRepository();
            _shareCapture = new ShareCaptureService();

            EnsureUiComponents(workshopUi);
            EnsurePresenters(pegboardRoot, mainCamera);

            WireEvents();
            NavigateTo(AppScreen.MainMenu);
        }

        private void EnsureUiComponents(WorkshopUIController workshopUi)
        {
            var canvas = workshopUi != null ? workshopUi.gameObject : gameObject;
            if (canvas.GetComponent<RectTransform>() == null)
            {
                throw new InvalidOperationException(
                    $"Cannot initialize BeadWorks UI: '{canvas.name}' has no RectTransform.");
            }

            _mainMenu = EnsureUiComponent<MainMenuUIController>(canvas);
            _patternSelect = EnsureUiComponent<PatternSelectUIController>(canvas);
            _imageImportUi = EnsureUiComponent<ImageImportUIController>(canvas);
            _patternGuideUi = EnsureUiComponent<PatternGuideUIController>(canvas);
            _galleryUi = EnsureUiComponent<GalleryUIController>(canvas);

            _galleryUi.Bind(_galleryRepository);

            _finishedViewerUi = EnsureUiComponent<FinishedWorkViewerUIController>(canvas);

            if (DebugOverlayController.IsAvailable)
            {
                _debugOverlay = EnsureUiComponent<DebugOverlayController>(canvas);
                _debugOverlay.Bind(_workshop);
            }
        }

        private static T EnsureUiComponent<T>(GameObject canvas) where T : Component
        {
            var component = canvas.GetComponent<T>();
            if (component == null)
            {
                component = canvas.AddComponent<T>();
            }

            if (component == null)
            {
                throw new InvalidOperationException(
                    $"Cannot initialize BeadWorks UI: failed to create {typeof(T).Name} on '{canvas.name}'.");
            }

            return component;
        }

        private void EnsurePresenters(Transform pegboardRoot, Camera mainCamera)
        {
            var presenterHost = _workshopRoot != null ? _workshopRoot : pegboardRoot;

            _patternGuide = pegboardRoot.GetComponent<PatternGuidePresenter>();
            if (_patternGuide == null)
            {
                _patternGuide = pegboardRoot.gameObject.AddComponent<PatternGuidePresenter>();
            }

            _finishedPresenter = presenterHost.GetComponent<FinishedWorkPresenter>();
            if (_finishedPresenter == null)
            {
                _finishedPresenter = presenterHost.gameObject.AddComponent<FinishedWorkPresenter>();
            }
        }

        private void WireEvents()
        {
            _mainMenu.FreeCreateRequested += OnFreeCreate;
            _mainMenu.PatternReplicateRequested += OnPatternReplicate;
            _mainMenu.ImageImportRequested += () => NavigateTo(AppScreen.ImageImport);
            _mainMenu.GalleryRequested += () => NavigateTo(AppScreen.Gallery);

            _patternSelect.BackRequested += () => NavigateTo(AppScreen.MainMenu);
            _patternSelect.PatternSelected += OnPatternChosen;

            _imageImportUi.BackRequested += () => NavigateTo(AppScreen.MainMenu);
            _imageImportUi.PatternConfirmed += OnImportedPatternConfirmed;

            _patternGuideUi.GuideVisibilityChanged += v => _patternGuide?.SetGuideVisible(v);
            _patternGuideUi.ErrorHintsChanged += OnErrorHintsChanged;
            _patternGuideUi.MenuRequested += () => NavigateTo(AppScreen.MainMenu);

            _galleryUi.BackRequested += () => NavigateTo(AppScreen.MainMenu);
            _galleryUi.WorkSelected += OnGalleryWorkSelected;

            _finishedViewerUi.ProductTypeSelected += OnProductTypeSelected;
            _finishedViewerUi.ShareRequested += OnShareRequested;
            _finishedViewerUi.SaveRequested += OnSaveRequested;
            _finishedViewerUi.MenuRequested += () => NavigateTo(AppScreen.MainMenu);

            _ironingUi.ShowcaseRequested += OnShowcaseRequested;

            _workshop.BeadPlaced += OnBeadPlaced;
            _workshop.BeadRemoved += OnBeadPlaced;
            _workshopUi.MenuRequested += () => NavigateTo(AppScreen.MainMenu);
        }

        private void OnDestroy()
        {
            if (_mainMenu != null)
            {
                _mainMenu.FreeCreateRequested -= OnFreeCreate;
                _mainMenu.PatternReplicateRequested -= OnPatternReplicate;
            }

            if (_patternSelect != null)
            {
                _patternSelect.BackRequested -= () => NavigateTo(AppScreen.MainMenu);
                _patternSelect.PatternSelected -= OnPatternChosen;
            }

            if (_imageImportUi != null)
            {
                _imageImportUi.PatternConfirmed -= OnImportedPatternConfirmed;
            }

            if (_workshop != null)
            {
                _workshop.BeadPlaced -= OnBeadPlaced;
                _workshop.BeadRemoved -= OnBeadPlaced;
            }

            if (_ironingUi != null)
            {
                _ironingUi.ShowcaseRequested -= OnShowcaseRequested;
            }
        }

        public void NavigateTo(AppScreen screen)
        {
            _currentScreen = screen;
            HideAllScreens();

            switch (screen)
            {
                case AppScreen.MainMenu:
                    _mainMenu.Show();
                    SetWorkshopVisible(false);
                    _finishedPresenter?.Hide();
                    break;

                case AppScreen.PatternSelect:
                    _patternSelect.Show(_patternRepository.Patterns, _palette);
                    SetWorkshopVisible(false);
                    break;

                case AppScreen.ImageImport:
                    _imageImportUi.Show(_palette);
                    SetWorkshopVisible(false);
                    break;

                case AppScreen.Workshop:
                    SetWorkshopVisible(true);
                    if (_workbenchBackground != null)
                    {
                        _workbenchBackground.gameObject.SetActive(true);
                    }

                    if (_pegboardRoot != null)
                    {
                        _pegboardRoot.gameObject.SetActive(true);
                    }

                    _finishedPresenter?.Hide();
                    _workshopUi?.SetEditingPanelsVisible(true);
                    _patternGuideUi.Hide();
                    if (_session != null && !_session.IsFreeMode && _session.Pattern != null)
                    {
                        _patternGuideUi.Show();
                        RefreshPatternProgress();
                    }
                    break;

                case AppScreen.Gallery:
                    _galleryUi.Show();
                    SetWorkshopVisible(false);
                    break;

                case AppScreen.FinishedViewer:
                    SetWorkshopVisible(true);
                    _workshopUi?.SetEditingPanelsVisible(false);
                    _ironingUi?.HideAll();
                    _patternGuideUi.Hide();
                    ShowFinishedViewer();
                    break;
            }
        }

        private void HideAllScreens()
        {
            _mainMenu?.Hide();
            _patternSelect?.Hide();
            _imageImportUi?.Hide();
            _patternGuideUi?.Hide();
            _galleryUi?.Hide();
            _finishedViewerUi?.Hide();
            _finishedPresenter?.Hide();
        }

        private void SetWorkshopVisible(bool visible)
        {
            if (_workshopRoot != null)
            {
                _workshopRoot.gameObject.SetActive(visible);
            }

            if (_pegboardRoot != null)
            {
                _pegboardRoot.gameObject.SetActive(visible);
            }

            if (_workbenchBackground != null)
            {
                _workbenchBackground.gameObject.SetActive(visible);
            }
        }

        private void OnFreeCreate(int gridSize)
        {
            _session = WorkshopSession.FreeCreate(gridSize);
            StartWorkshop();
        }

        private void OnPatternReplicate()
        {
            NavigateTo(AppScreen.PatternSelect);
        }

        private void OnPatternChosen(BeadPatternData pattern)
        {
            _session = WorkshopSession.FromPattern(pattern);
            StartWorkshop();
        }

        private void OnImportedPatternConfirmed(BeadPatternData pattern, string sourceLabel)
        {
            _session = WorkshopSession.FromImportedPattern(pattern, sourceLabel);
            StartWorkshop();
        }

        private void StartWorkshop()
        {
            _workshop.ConfigureSession(_session, _palette, _pegboardPresenter, _workbenchBackground, _patternGuide);
            if (_workshop.Grid != null)
            {
                _cameraController?.FocusOnPegboard(_workshop.GridSize, _workshop.Grid.CellSize);
            }
            else
            {
                _cameraController?.FocusOnPegboard();
            }

            NavigateTo(AppScreen.Workshop);
        }

        private void OnBeadPlaced()
        {
            if (_currentScreen != AppScreen.Workshop || _session?.IsFreeMode != false)
            {
                return;
            }

            RefreshPatternProgress();
        }

        private void RefreshPatternProgress()
        {
            if (_session?.Pattern == null)
            {
                return;
            }

            var stats = PatternMatcher.Evaluate(_workshop.Grid, _session.Pattern);
            _patternGuideUi.SetProgress(stats.Summary);

            if (_patternGuide != null && _patternGuide.ErrorsVisible)
            {
                PatternMatcher.CollectErrorCells(_workshop.Grid, _session.Pattern, _wrongCells, _missingCells);
                _patternGuide.UpdateErrorMarkers(_wrongCells, _missingCells);
            }
        }

        private void OnErrorHintsChanged(bool visible)
        {
            _patternGuide?.SetErrorsVisible(visible);
            if (visible)
            {
                RefreshPatternProgress();
            }
            else
            {
                _patternGuide?.UpdateErrorMarkers(null, null);
            }
        }

        private void OnShowcaseRequested()
        {
            _completedAt = DateTime.UtcNow;
            NavigateTo(AppScreen.FinishedViewer);
        }

        private void ShowFinishedViewer()
        {
            if (_pegboardRoot != null)
            {
                _pegboardRoot.gameObject.SetActive(false);
            }

            if (_workbenchBackground != null)
            {
                _workbenchBackground.gameObject.SetActive(false);
            }

            _finishedPresenter.Show(
                _workshop.Grid,
                _palette,
                _productType,
                _workshopRoot,
                Camera.main);

            var title = _session?.Title ?? "拼豆作品";
            var beadCount = _workshop.Grid.PlacedBeadCount;
            _finishedViewerUi.Show(title, beadCount, _workshop.LastIroningResult, _completedAt);
        }

        private void OnProductTypeSelected(FinishedProductType type)
        {
            _productType = type;
            _finishedPresenter?.SetProductType(type);
        }

        private void OnShareRequested()
        {
            var png = _shareCapture.CaptureShareImage(
                Camera.main,
                _finishedPresenter != null ? _finishedPresenter.transform : _pegboardRoot,
                _session?.Title ?? "拼豆作品",
                _workshop.Grid.PlacedBeadCount,
                _completedAt,
                _productType);

            _finishedViewerUi.SetShareStatus("正在保存到相册…");
            _shareCapture.ShareNative(this, png, _session?.Title, (success, error) =>
            {
                _finishedViewerUi.SetShareStatus(success
                    ? $"已保存: {_shareCapture.LastSavedPath}"
                    : $"保存到相册失败：{error}（已保留在应用内 {_shareCapture.LastSavedPath}）");
            });
        }

        private void OnSaveRequested()
        {
            var record = _workshop.ExportWorkRecord(_session, _productType, _completedAt);
            var thumbPng = _shareCapture.CaptureShareImage(
                Camera.main,
                _finishedPresenter != null ? _finishedPresenter.transform : _pegboardRoot,
                record.title,
                record.beadCount,
                _completedAt,
                _productType);

            _galleryRepository.SaveWork(record, thumbPng);
            _finishedViewerUi.SetShareStatus("已保存到作品库");
        }

        private void OnGalleryWorkSelected(FinishedWorkRecord record)
        {
            _viewingRecord = record;
            _session = new WorkshopSession
            {
                IsFreeMode = string.IsNullOrEmpty(record.patternId),
                Title = record.title,
                Pattern = string.IsNullOrEmpty(record.patternId)
                    ? null
                    : _patternRepository.GetById(record.patternId)
            };

            _workshop.LoadFromRecord(record, _palette, _pegboardPresenter, _workbenchBackground);
            _completedAt = DateTime.TryParse(record.completedAtUtc, out var dt) ? dt : DateTime.UtcNow;
            _productType = (FinishedProductType)record.productType;
            NavigateTo(AppScreen.FinishedViewer);
        }
    }
}
