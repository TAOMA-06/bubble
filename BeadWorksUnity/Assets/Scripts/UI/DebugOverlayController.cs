using System.Text;
using BeadWorks.Workshop;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Debug overlay: FPS display and workshop test utilities.
    /// </summary>
    public class DebugOverlayController : MonoBehaviour
    {
        [SerializeField] private bool _showFps = true;
        [SerializeField] private KeyCode _toggleFpsKey = KeyCode.F1;
        [SerializeField] private KeyCode _togglePanelKey = KeyCode.BackQuote;

        private GameObject _panel;
        private TextMeshProUGUI _fpsLabel;
        private TextMeshProUGUI _logLabel;
        private WorkshopController _workshop;
        private readonly StringBuilder _log = new();
        private float _fpsTimer;
        private int _frameCount;
        private float _currentFps;

        public bool ShowFps
        {
            get => _showFps;
            set
            {
                _showFps = value;
                if (_fpsLabel != null)
                {
                    _fpsLabel.gameObject.SetActive(value);
                }
            }
        }

        public void Bind(WorkshopController workshop)
        {
            _workshop = workshop;
        }

        private void Awake()
        {
            BuildUi();
        }

        private void Update()
        {
            _frameCount++;
            _fpsTimer += Time.unscaledDeltaTime;
            if (_fpsTimer >= 0.5f)
            {
                _currentFps = _frameCount / _fpsTimer;
                _frameCount = 0;
                _fpsTimer = 0f;
                if (_fpsLabel != null && _showFps)
                {
                    _fpsLabel.text = $"FPS {_currentFps:0}";
                }
            }

            if (UnityEngine.Input.GetKeyDown(_toggleFpsKey))
            {
                ShowFps = !ShowFps;
            }

            if (UnityEngine.Input.GetKeyDown(_togglePanelKey))
            {
                if (_panel != null)
                {
                    _panel.SetActive(!_panel.activeSelf);
                }
            }
        }

        public void RunGridCoordinateTest()
        {
            if (_workshop?.Grid == null)
            {
                AppendLog("Grid test: no grid");
                return;
            }

            var grid = _workshop.Grid;
            var center = new Vector2Int(grid.Width / 2, grid.Height / 2);
            var world = grid.CellToWorld(center);
            grid.WorldToCell(world, out var back);
            AppendLog($"Grid test: ({center.x},{center.y}) → world → ({back.x},{back.y})");
        }

        public void RunRepeatPlacementTest()
        {
            if (_workshop == null)
            {
                return;
            }

            _workshop.DebugFillCell(0, 0, 2);
            var first = _workshop.Grid.IsOccupied(new Vector2Int(0, 0));
            var rejected = !_workshop.DebugTryPlaceDuplicate(0, 0, 2);
            AppendLog($"Repeat place: first={first} reject={rejected}");
        }

        public void RunIroningResultTest()
        {
            if (_workshop == null)
            {
                return;
            }

            _workshop.DebugSimulateIroningAndFinish();
            AppendLog("Ironing test: simulated finish");
        }

        public void RunStressTest64()
        {
            if (_workshop == null)
            {
                return;
            }

            _workshop.DebugLoadStressGrid(64);
            AppendLog("Stress: loaded 64×64 grid");
        }

        private void AppendLog(string message)
        {
            _log.Insert(0, message + "\n");
            if (_log.Length > 400)
            {
                _log.Length = 400;
            }

            if (_logLabel != null)
            {
                _logLabel.text = _log.ToString();
            }

            Debug.Log($"[Debug] {message}");
        }

        private void BuildUi()
        {
            var canvas = GetComponent<RectTransform>();
            if (canvas == null)
            {
                return;
            }

            var fpsGo = new GameObject("FpsLabel");
            fpsGo.transform.SetParent(canvas, false);
            var fpsRect = fpsGo.AddComponent<RectTransform>();
            fpsRect.anchorMin = new Vector2(1f, 1f);
            fpsRect.anchorMax = new Vector2(1f, 1f);
            fpsRect.pivot = new Vector2(1f, 1f);
            fpsRect.anchoredPosition = new Vector2(-16, -16);
            fpsRect.sizeDelta = new Vector2(120, 32);
            _fpsLabel = fpsGo.AddComponent<TextMeshProUGUI>();
            _fpsLabel.fontSize = 20;
            _fpsLabel.alignment = TextAlignmentOptions.TopRight;
            _fpsLabel.color = new Color(0.4f, 0.9f, 0.5f);

            _panel = UiBuilder.CreatePanel(canvas, "DebugPanel",
                new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(16, -60), new Vector2(280, 360));
            _panel.GetComponent<Image>().color = new Color(0f, 0f, 0f, 0.65f);
            var panelRect = _panel.GetComponent<RectTransform>();
            panelRect.pivot = new Vector2(0f, 1f);

            var y = -20f;
            CreateDebugButton("Grid坐标", new Vector2(0, y), () => RunGridCoordinateTest());
            y -= 48f;
            CreateDebugButton("重复放置", new Vector2(0, y), () => RunRepeatPlacementTest());
            y -= 48f;
            CreateDebugButton("熨烫结果", new Vector2(0, y), () => RunIroningResultTest());
            y -= 48f;
            CreateDebugButton("64×64压力", new Vector2(0, y), () => RunStressTest64());
            y -= 48f;
            CreateDebugButton("FPS开关", new Vector2(0, y), () => ShowFps = !ShowFps);

            var logGo = new GameObject("Log");
            logGo.transform.SetParent(_panel.transform, false);
            var logRect = logGo.AddComponent<RectTransform>();
            logRect.anchorMin = new Vector2(0.5f, 0f);
            logRect.anchorMax = new Vector2(0.5f, 0f);
            logRect.pivot = new Vector2(0.5f, 0f);
            logRect.anchoredPosition = new Vector2(0, 8);
            logRect.sizeDelta = new Vector2(260, 80);
            _logLabel = logGo.AddComponent<TextMeshProUGUI>();
            _logLabel.fontSize = 14;
            _logLabel.alignment = TextAlignmentOptions.TopLeft;
            _logLabel.color = new Color(0.8f, 0.85f, 0.9f);

            _panel.SetActive(false);
        }

        private void CreateDebugButton(string label, Vector2 position, UnityEngine.Events.UnityAction onClick)
        {
            var button = UiBuilder.CreateButton(_panel.transform, label, position, new Vector2(240, 40), label);
            button.onClick.AddListener(onClick);
        }
    }
}
