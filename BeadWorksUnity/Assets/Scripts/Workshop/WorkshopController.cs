using System;
using BeadWorks.Core;
using BeadWorks.Data;
using BeadWorks.Feedback;
using BeadWorks.Ironing;
using BeadWorks.Presentation;
using BeadWorks.Tools;
using BeadWorks.UI;
using UnityEngine;

namespace BeadWorks.Workshop
{
    public enum WorkshopPhase
    {
        Placing,
        Ironing,
        Result,
        Showcase
    }

    /// <summary>
    /// Central state for the workshop vertical slice.
    /// </summary>
    public class WorkshopController : MonoBehaviour
    {
        public const int DefaultGridSize = 16;

        [SerializeField] private BeadSizeType _beadSize = BeadSizeType.Standard5mm;
        [SerializeField] private ToolMode _currentTool = ToolMode.Tweezers;
        [SerializeField] private int _selectedColorId = 2;
        [SerializeField] private int _gridSize = DefaultGridSize;

        private BeadPaletteRepository _paletteRepository;
        private PegboardPresenter _pegboardPresenter;
        private WorkshopUIController _uiController;
        private IroningUIController _ironingUIController;
        private PegboardGrid _grid;
        private TweezersTool _tweezersTool;
        private EraserTool _eraserTool;
        private IroningTool _ironingTool;
        private IroningSystem _ironingSystem;
        private BeadFactory _beadFactory;
        private WorkshopFeedback _feedback;
        private Transform _beadsRoot;
        private Transform _toolsRoot;
        private Transform _gridOrigin;
        private WorkshopPhase _phase = WorkshopPhase.Placing;
        private IroningResult _lastIroningResult = IroningResult.UnderIroned;
        private WorkshopSession _session;
        private PatternGuidePresenter _patternGuide;
        private BeadFactory _boundBeadFactory;
        private WorkshopFeedback _boundFeedback;
        private Transform _boundPegboardRoot;
        private Camera _boundCamera;

        public IroningResult LastIroningResult => _lastIroningResult;
        public WorkshopSession Session => _session;

        public event Action BeadPlaced;
        public event Action BeadRemoved;

        public BeadSizeType BeadSize
        {
            get => _beadSize;
            set
            {
                if (_beadSize == value)
                {
                    return;
                }

                _beadSize = value;
                BuildGrid(_beadFactory);
                RefreshPresentation();
                _tweezersTool?.SetBeadSize(value);
                StatusChanged?.Invoke(BuildStatusMessage());
            }
        }

        public ToolMode CurrentTool
        {
            get => _currentTool;
            set
            {
                if (_currentTool == value)
                {
                    return;
                }

                _tweezersTool?.CancelPick();
                _ironingTool?.CancelDrag();
                _currentTool = value;
                EnterPhaseForTool(value);
                StatusChanged?.Invoke(BuildStatusMessage());
            }
        }

        public int SelectedColorId
        {
            get => _selectedColorId;
            set
            {
                if (_selectedColorId == value)
                {
                    return;
                }

                _selectedColorId = value;
                _uiController?.HighlightColor(value);
                StatusChanged?.Invoke(BuildStatusMessage());
            }
        }

        public int GridSize => _gridSize;
        public BeadPaletteRepository Palette => _paletteRepository;
        public PegboardGrid Grid => _grid;
        public WorkshopPhase Phase => _phase;
        public bool IsHoldingBead => _tweezersTool != null && _tweezersTool.IsHoldingBead;
        public bool IsDraggingIron => _ironingTool != null && _ironingTool.IsDraggingIron;

        public event Action<string> StatusChanged;

        public void Initialize(
            BeadPaletteRepository paletteRepository,
            PegboardPresenter pegboardPresenter,
            WorkshopUIController uiController,
            IroningUIController ironingUIController,
            BeadFactory beadFactory,
            WorkshopFeedback feedback,
            Transform pegboardRoot,
            Camera camera)
        {
            _paletteRepository = paletteRepository;
            _pegboardPresenter = pegboardPresenter;
            _uiController = uiController;
            _ironingUIController = ironingUIController;
            _beadFactory = beadFactory;
            _feedback = feedback;
            _boundBeadFactory = beadFactory;
            _boundFeedback = feedback;
            _boundPegboardRoot = pegboardRoot;
            _boundCamera = camera;

            EnsureSceneRoots(pegboardRoot);
            BuildGrid(beadFactory);
            BuildTools(beadFactory, feedback, pegboardRoot, camera);

            _uiController?.Bind(this);
            _uiController?.ConfigureTweezers(
                () => _currentTool,
                OnPickBegin,
                OnPickMove,
                OnPickEnd);

            BindIroningUi();
            RefreshPresentation();
            EnterPhaseForTool(_currentTool);
            StatusChanged?.Invoke(BuildStatusMessage());
        }

        public void ConfigureSession(
            WorkshopSession session,
            BeadPaletteRepository palette,
            PegboardPresenter pegboardPresenter,
            WorkbenchBackground workbenchBackground,
            PatternGuidePresenter patternGuide)
        {
            _session = session;
            _patternGuide = patternGuide;
            _pegboardPresenter = pegboardPresenter;
            _paletteRepository = palette;

            _grid?.ClearAll();
            _patternGuide?.Clear();

            if (session != null && !session.IsFreeMode && session.Pattern != null)
            {
                _gridSize = Mathf.Max(session.Pattern.width, session.Pattern.height);
                _beadSize = session.Pattern.beadSize;
            }
            else
            {
                _gridSize = session?.RequestedGridSize ?? DefaultGridSize;
            }

            workbenchBackground?.BuildAround(_boundPegboardRoot, _gridSize);
            BuildGrid(_beadFactory);
            RefreshPresentation();

            if (session != null && !session.IsFreeMode && session.Pattern != null && _patternGuide != null)
            {
                _patternGuide.Build(
                    session.Pattern,
                    palette,
                    _boundPegboardRoot,
                    _grid.CellSize,
                    _gridSize);
            }

            _phase = WorkshopPhase.Placing;
            _currentTool = ToolMode.Tweezers;
            _ironingUIController?.HideAll();
            _uiController?.SetEditingPanelsVisible(true);
            _uiController?.RefreshToolbar(_currentTool);
            StatusChanged?.Invoke(BuildStatusMessage());
        }

        public FinishedWorkRecord ExportWorkRecord(
            WorkshopSession session,
            FinishedProductType productType,
            DateTime completedAt)
        {
            return new FinishedWorkRecord
            {
                title = session?.Title ?? "拼豆作品",
                patternId = session?.Pattern?.id ?? string.Empty,
                width = _grid.Width,
                height = _grid.Height,
                beadCount = _grid.PlacedBeadCount,
                ironingResult = (int)_lastIroningResult,
                productType = (int)productType,
                completedAtUtc = completedAt.ToString("o"),
                cells = _grid.ExportCellColors()
            };
        }

        public void LoadFromRecord(
            FinishedWorkRecord record,
            BeadPaletteRepository palette,
            PegboardPresenter pegboardPresenter,
            WorkbenchBackground workbenchBackground)
        {
            _session = new WorkshopSession
            {
                Title = record.title,
                IsFreeMode = string.IsNullOrEmpty(record.patternId)
            };

            _gridSize = Mathf.Max(record.width, DefaultGridSize);
            workbenchBackground?.BuildAround(_boundPegboardRoot, _gridSize);
            BuildGrid(_beadFactory);
            RefreshPresentation();
            _grid.LoadFromCellColors(record.cells, record.width, record.height, palette);
            _lastIroningResult = (IroningResult)record.ironingResult;
            _phase = WorkshopPhase.Showcase;
        }

        public void DebugFillCell(int x, int y, int colorId)
        {
            var color = _paletteRepository?.GetById(colorId);
            if (color == null)
            {
                return;
            }

            var cell = new Vector2Int(x, y);
            _grid.TryPlaceBead(cell, BeadInstance.CreatePlaced(cell, color, _beadSize), out _);
        }

        public bool DebugTryPlaceDuplicate(int x, int y, int colorId)
        {
            var color = _paletteRepository?.GetById(colorId);
            if (color == null)
            {
                return false;
            }

            var cell = new Vector2Int(x, y);
            return _grid.TryPlaceBead(cell, BeadInstance.CreatePlaced(cell, color, _beadSize), out _);
        }

        public void DebugSimulateIroningAndFinish()
        {
            if (_grid.PlacedBeadCount == 0)
            {
                DebugFillCell(0, 0, 2);
                DebugFillCell(1, 0, 2);
                DebugFillCell(0, 1, 2);
            }

            CurrentTool = ToolMode.Iron;
            _ironingSystem?.Reset();
            _lastIroningResult = IroningResult.Perfect;
            _phase = WorkshopPhase.Result;
            _ironingUIController?.ShowResult(_lastIroningResult);
        }

        public void DebugLoadStressGrid(int size)
        {
            _gridSize = size;
            BuildGrid(_beadFactory);
            RefreshPresentation();

            var colors = _paletteRepository?.BaseColors;
            if (colors == null || colors.Length == 0)
            {
                return;
            }

            for (var y = 0; y < size; y++)
            {
                for (var x = 0; x < size; x++)
                {
                    var color = colors[((x + y) * 3) % colors.Length];
                    var cell = new Vector2Int(x, y);
                    _grid.TryPlaceBead(cell, BeadInstance.CreatePlaced(cell, color, _beadSize), out _);
                }
            }
        }

        private void Update()
        {
            if (_phase != WorkshopPhase.Ironing || _ironingSystem == null || _ironingTool == null)
            {
                return;
            }

            _ironingSystem.Tick(
                _ironingTool.WorldPosition,
                _ironingTool.HeatRadius * _grid.CellSize,
                _ironingTool.IronPower,
                _ironingTool.IsDraggingIron,
                _ironingTool.MoveSpeed,
                Time.deltaTime);

            _ironingUIController?.UpdateIroningStats(_ironingSystem.GetStats());
        }

        public void SelectTool(ToolMode tool)
        {
            CurrentTool = tool;
            _uiController?.RefreshToolbar(_currentTool);
        }

        public void SelectColor(int colorId)
        {
            SelectedColorId = colorId;
        }

        public void HandlePointerDown(Vector2 screenPosition)
        {
            if (_phase == WorkshopPhase.Showcase || _phase == WorkshopPhase.Result)
            {
                return;
            }

            if (_currentTool == ToolMode.Eraser)
            {
                _eraserTool?.TryEraseAtScreen(screenPosition);
                return;
            }

            if (_currentTool == ToolMode.Iron && _phase == WorkshopPhase.Ironing)
            {
                _ironingTool?.BeginDrag(screenPosition);
            }
        }

        public void HandlePointerMove(Vector2 screenPosition)
        {
            if (_currentTool == ToolMode.Tweezers && IsHoldingBead)
            {
                _tweezersTool.UpdateDrag(screenPosition);
                return;
            }

            if (_currentTool == ToolMode.Iron && _phase == WorkshopPhase.Ironing)
            {
                _ironingTool?.UpdateDrag(screenPosition);
            }
        }

        public void HandlePointerUp(Vector2 screenPosition)
        {
            if (_currentTool == ToolMode.Tweezers && IsHoldingBead)
            {
                _tweezersTool.EndDrag(screenPosition);
                return;
            }

            if (_currentTool == ToolMode.Iron && _phase == WorkshopPhase.Ironing)
            {
                _ironingTool?.EndDrag(screenPosition);
            }
        }

        private void OnPickBegin(BeadColorData color, Vector2 screenPosition)
        {
            if (_currentTool != ToolMode.Tweezers || _phase != WorkshopPhase.Placing)
            {
                return;
            }

            SelectedColorId = color.id;
            _tweezersTool.BeginPick(color, screenPosition);
        }

        private void OnPickMove(Vector2 screenPosition)
        {
            _tweezersTool?.UpdateDrag(screenPosition);
        }

        private void OnPickEnd(Vector2 screenPosition)
        {
            _tweezersTool?.EndDrag(screenPosition);
        }

        private void BindIroningUi()
        {
            if (_ironingUIController == null)
            {
                return;
            }

            _ironingUIController.FinishRequested += FinishIroning;
            _ironingUIController.RetryRequested += RetryIroning;
            _ironingUIController.ShowcaseRequested += EnterShowcase;
            _ironingUIController.BackToWorkshopRequested += BackToPlacing;
        }

        private void OnDestroy()
        {
            if (_ironingUIController == null)
            {
                return;
            }

            _ironingUIController.FinishRequested -= FinishIroning;
            _ironingUIController.RetryRequested -= RetryIroning;
            _ironingUIController.ShowcaseRequested -= EnterShowcase;
            _ironingUIController.BackToWorkshopRequested -= BackToPlacing;
        }

        private void FinishIroning()
        {
            if (_phase != WorkshopPhase.Ironing || _ironingSystem == null)
            {
                return;
            }

            _ironingTool?.CancelDrag();
            _feedback?.StopIroningAudio();
            _lastIroningResult = _ironingSystem.EvaluateResult();
            _phase = WorkshopPhase.Result;
            _ironingUIController?.ShowResult(_lastIroningResult);
            StatusChanged?.Invoke(_lastIroningResult.DisplayMessage());
        }

        private void RetryIroning()
        {
            _ironingSystem?.Reset();
            _phase = WorkshopPhase.Ironing;
            _ironingUIController?.ShowIroningHud();
            _ironingUIController?.UpdateIroningStats(_ironingSystem?.GetStats() ?? default);
            StatusChanged?.Invoke("重新熨烫 — 拖动熨斗均匀加热");
        }

        private void EnterShowcase()
        {
            _phase = WorkshopPhase.Showcase;
            _ironingUIController?.HideAll();
            _uiController?.SetPaletteVisible(false);
            _uiController?.SetEditingPanelsVisible(false);
            StatusChanged?.Invoke("成品展示");
        }

        private void BackToPlacing()
        {
            _phase = WorkshopPhase.Placing;
            _currentTool = ToolMode.Tweezers;
            _ironingTool?.CancelDrag();
            _feedback?.StopIroningAudio();
            _ironingUIController?.HideAll();
            _uiController?.SetPaletteVisible(true);
            _uiController?.RefreshToolbar(_currentTool);
            StatusChanged?.Invoke(BuildStatusMessage());
        }

        private void EnterPhaseForTool(ToolMode tool)
        {
            if (tool == ToolMode.Iron)
            {
                if (_grid.PlacedBeadCount == 0)
                {
                    _phase = WorkshopPhase.Placing;
                    _ironingUIController?.HideAll();
                    _uiController?.SetPaletteVisible(true);
                    StatusChanged?.Invoke("请先摆放豆子，再进入熨烫模式");
                    return;
                }

                _phase = WorkshopPhase.Ironing;
                _ironingUIController?.ShowIroningHud();
                _ironingUIController?.UpdateIroningStats(_ironingSystem?.GetStats() ?? default);
                _uiController?.SetPaletteVisible(false);
                return;
            }

            if (_phase == WorkshopPhase.Ironing)
            {
                _ironingTool?.CancelDrag();
                _feedback?.StopIroningAudio();
                _ironingUIController?.HideAll();
            }

            if (_phase != WorkshopPhase.Showcase && _phase != WorkshopPhase.Result)
            {
                _phase = WorkshopPhase.Placing;
            }

            _uiController?.SetPaletteVisible(_phase == WorkshopPhase.Placing);
        }

        private void EnsureSceneRoots(Transform pegboardRoot)
        {
            if (_beadsRoot == null)
            {
                var beadsGo = new GameObject("BeadsRoot");
                beadsGo.transform.SetParent(pegboardRoot, false);
                _beadsRoot = beadsGo.transform;
            }

            if (_toolsRoot == null)
            {
                var toolsGo = new GameObject("ToolsRoot");
                toolsGo.transform.SetParent(pegboardRoot, false);
                _toolsRoot = toolsGo.transform;
            }

            if (_gridOrigin == null)
            {
                var originGo = new GameObject("GridOrigin");
                originGo.transform.SetParent(pegboardRoot, false);
                _gridOrigin = originGo.transform;
            }
        }

        private void BuildGrid(BeadFactory beadFactory)
        {
            var cellSize = _beadSize.CellWorldSize();
            var half = (_gridSize - 1) * cellSize * 0.5f;
            _gridOrigin.localPosition = new Vector3(-half, -half, 0f);

            _grid?.ClearAll();
            _grid = new PegboardGrid(
                _gridOrigin,
                _gridSize,
                _gridSize,
                cellSize,
                beadFactory,
                _beadsRoot);

            _tweezersTool?.SetGrid(_grid);
            _eraserTool?.SetGrid(_grid);
            _ironingTool?.SetCellSize(cellSize);
            _ironingSystem = new IroningSystem(_grid, _feedback);
        }

        private void BuildTools(
            BeadFactory beadFactory,
            WorkshopFeedback feedback,
            Transform pegboardRoot,
            Camera camera)
        {
            _tweezersTool = new TweezersTool(
                _grid,
                beadFactory,
                feedback,
                _beadsRoot,
                camera,
                pegboardRoot);
            _tweezersTool.SetBeadSize(_beadSize);
            _tweezersTool.OnBeadPlaced = () => BeadPlaced?.Invoke();

            _eraserTool = new EraserTool(_grid, feedback, camera, pegboardRoot);
            _eraserTool.OnBeadRemoved = () => BeadRemoved?.Invoke();
            _ironingTool = new IroningTool(camera, pegboardRoot, _toolsRoot);
            _ironingTool.SetCellSize(_grid.CellSize);
            _ironingSystem = new IroningSystem(_grid, feedback);
        }

        private void RefreshPresentation()
        {
            _pegboardPresenter?.Build(_gridSize, _beadSize);
            _uiController?.RefreshPalette(_paletteRepository);
            _uiController?.RefreshToolbar(_currentTool);
            _uiController?.HighlightColor(_selectedColorId);
        }

        private string BuildStatusMessage()
        {
            var color = _paletteRepository?.GetById(_selectedColorId);
            var colorName = color != null ? color.displayName : "Unknown";
            return $"{_currentTool.DisplayName()} | {colorName} | {_beadSize.DisplayName()} | {_gridSize}x{_gridSize}";
        }
    }
}
