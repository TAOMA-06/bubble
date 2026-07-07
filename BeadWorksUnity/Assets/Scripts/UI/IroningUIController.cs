using System;
using BeadWorks.Data;
using BeadWorks.Ironing;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Ironing progress, temperature risk, finish flow, and product showcase.
    /// </summary>
    public class IroningUIController : MonoBehaviour
    {
        [Header("Panels")]
        [SerializeField] private GameObject _ironingPanel;
        [SerializeField] private GameObject _resultPanel;
        [SerializeField] private GameObject _showcasePanel;

        [Header("Ironing HUD")]
        [SerializeField] private Slider _progressSlider;
        [SerializeField] private TextMeshProUGUI _progressLabel;
        [SerializeField] private TextMeshProUGUI _temperatureLabel;
        [SerializeField] private TextMeshProUGUI _riskLabel;
        [SerializeField] private Button _finishButton;

        [Header("Result")]
        [SerializeField] private TextMeshProUGUI _resultTitle;
        [SerializeField] private TextMeshProUGUI _resultDetail;
        [SerializeField] private Button _retryButton;
        [SerializeField] private Button _showcaseButton;

        [Header("Showcase")]
        [SerializeField] private TextMeshProUGUI _showcaseTitle;
        [SerializeField] private Button _backToWorkshopButton;

        public event Action FinishRequested;
        public event Action RetryRequested;
        public event Action ShowcaseRequested;
        public event Action BackToWorkshopRequested;

        private void Awake()
        {
            EnsureBuilt();

            if (_finishButton != null)
            {
                _finishButton.onClick.AddListener(() => FinishRequested?.Invoke());
            }

            if (_retryButton != null)
            {
                _retryButton.onClick.AddListener(() => RetryRequested?.Invoke());
            }

            if (_showcaseButton != null)
            {
                _showcaseButton.onClick.AddListener(() => ShowcaseRequested?.Invoke());
            }

            if (_backToWorkshopButton != null)
            {
                _backToWorkshopButton.onClick.AddListener(() => BackToWorkshopRequested?.Invoke());
            }

            HideAll();
        }

        public void ShowIroningHud()
        {
            HideAll();
            if (_ironingPanel != null)
            {
                _ironingPanel.SetActive(true);
            }
        }

        public void UpdateIroningStats(IroningStats stats)
        {
            if (_progressSlider != null)
            {
                _progressSlider.value = stats.progress;
            }

            if (_progressLabel != null)
            {
                _progressLabel.text = $"熨烫进度 {Mathf.RoundToInt(stats.progress * 100f)}%";
            }

            if (_temperatureLabel != null)
            {
                var tempPercent = Mathf.RoundToInt(stats.peakHeat * 100f);
                _temperatureLabel.text = $"温度 {tempPercent}%";
            }

            if (_riskLabel != null)
            {
                _riskLabel.text = string.IsNullOrEmpty(stats.riskMessage)
                    ? "拖动熨斗均匀加热"
                    : stats.riskMessage;
            }
        }

        public void ShowResult(IroningResult result)
        {
            HideAll();
            if (_resultPanel != null)
            {
                _resultPanel.SetActive(true);
                StartCoroutine(UiBuilder.PopInRoutine(_resultPanel.GetComponent<RectTransform>()));
            }

            if (_resultTitle != null)
            {
                _resultTitle.text = result.DisplayMessage();
            }

            if (_resultDetail != null)
            {
                _resultDetail.text = result.DetailMessage();
            }
        }

        public void ShowShowcase(IroningResult result)
        {
            HideAll();
            if (_showcasePanel != null)
            {
                _showcasePanel.SetActive(true);
                StartCoroutine(UiBuilder.PopInRoutine(_showcasePanel.GetComponent<RectTransform>()));
            }

            if (_showcaseTitle != null)
            {
                _showcaseTitle.text = result == IroningResult.Perfect
                    ? "成品展示"
                    : $"成品展示 — {result.DisplayMessage()}";
            }
        }

        public void HideAll()
        {
            if (_ironingPanel != null)
            {
                _ironingPanel.SetActive(false);
            }

            if (_resultPanel != null)
            {
                _resultPanel.SetActive(false);
            }

            if (_showcasePanel != null)
            {
                _showcasePanel.SetActive(false);
            }
        }

        private void EnsureBuilt()
        {
            if (_ironingPanel != null)
            {
                return;
            }

            BuildDefaultUi();
        }

        private void BuildDefaultUi()
        {
            var canvas = GetComponent<RectTransform>();
            if (canvas == null)
            {
                return;
            }

            var ironingPanelGo = UiBuilder.CreatePanel(canvas, "IroningPanel", new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 260), new Vector2(920, 180));
            _ironingPanel = ironingPanelGo;
            _progressSlider = UiBuilder.CreateSlider(_ironingPanel.transform, new Vector2(0, 48), new Vector2(820, 28));
            _progressLabel = UiBuilder.CreateLabel(_ironingPanel.transform, "ProgressLabel", new Vector2(0, 92), 22, "熨烫进度 0%");
            _temperatureLabel = UiBuilder.CreateLabel(_ironingPanel.transform, "TemperatureLabel", new Vector2(-180, 20), 20, "温度 0%");
            _riskLabel = UiBuilder.CreateLabel(_ironingPanel.transform, "RiskLabel", new Vector2(120, 20), 20, "拖动熨斗均匀加热");
            _finishButton = UiBuilder.CreateButton(_ironingPanel.transform, "FinishButton", new Vector2(0, -52), new Vector2(260, 52), "完成熨烫");

            _resultPanel = UiBuilder.CreatePanel(canvas, "IroningResultPanel", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(760, 420));
            _resultTitle = UiBuilder.CreateLabel(_resultPanel.transform, "ResultTitle", new Vector2(0, 100), 34, "结果");
            _resultDetail = UiBuilder.CreateLabel(_resultPanel.transform, "ResultDetail", new Vector2(0, 20), 22, string.Empty);
            _retryButton = UiBuilder.CreateButton(_resultPanel.transform, "RetryButton", new Vector2(-150, -120), new Vector2(240, 56), "重新熨烫");
            _showcaseButton = UiBuilder.CreateButton(_resultPanel.transform, "ShowcaseButton", new Vector2(150, -120), new Vector2(240, 56), "查看成品");

            _showcasePanel = UiBuilder.CreatePanel(canvas, "ShowcasePanel", new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(760, 320));
            _showcaseTitle = UiBuilder.CreateLabel(_showcasePanel.transform, "ShowcaseTitle", new Vector2(0, 60), 32, "成品展示");
            _backToWorkshopButton = UiBuilder.CreateButton(_showcasePanel.transform, "BackButton", new Vector2(0, -80), new Vector2(280, 56), "返回工作台");
        }
    }
}
