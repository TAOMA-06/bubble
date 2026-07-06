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

            _ironingPanel = CreatePanel(canvas, "IroningPanel", new Vector2(0.5f, 0f), new Vector2(0, 260), new Vector2(920, 180));
            _progressSlider = CreateSlider(_ironingPanel.transform, new Vector2(0, 48), new Vector2(820, 28));
            _progressLabel = CreateLabel(_ironingPanel.transform, "ProgressLabel", new Vector2(0, 92), 22, "熨烫进度 0%");
            _temperatureLabel = CreateLabel(_ironingPanel.transform, "TemperatureLabel", new Vector2(-180, 20), 20, "温度 0%");
            _riskLabel = CreateLabel(_ironingPanel.transform, "RiskLabel", new Vector2(120, 20), 20, "拖动熨斗均匀加热");
            _finishButton = CreateButton(_ironingPanel.transform, "FinishButton", new Vector2(0, -52), new Vector2(260, 52), "完成熨烫");

            _resultPanel = CreatePanel(canvas, "IroningResultPanel", new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(760, 420));
            _resultTitle = CreateLabel(_resultPanel.transform, "ResultTitle", new Vector2(0, 100), 34, "结果");
            _resultDetail = CreateLabel(_resultPanel.transform, "ResultDetail", new Vector2(0, 20), 22, string.Empty);
            _retryButton = CreateButton(_resultPanel.transform, "RetryButton", new Vector2(-150, -120), new Vector2(240, 56), "重新熨烫");
            _showcaseButton = CreateButton(_resultPanel.transform, "ShowcaseButton", new Vector2(150, -120), new Vector2(240, 56), "查看成品");

            _showcasePanel = CreatePanel(canvas, "ShowcasePanel", new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(760, 320));
            _showcaseTitle = CreateLabel(_showcasePanel.transform, "ShowcaseTitle", new Vector2(0, 60), 32, "成品展示");
            _backToWorkshopButton = CreateButton(_showcasePanel.transform, "BackButton", new Vector2(0, -80), new Vector2(280, 56), "返回工作台");
        }

        private static GameObject CreatePanel(Transform parent, string name, Vector2 anchor, Vector2 position, Vector2 size)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = anchor;
            rect.anchorMax = anchor;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;

            var image = go.AddComponent<Image>();
            image.color = new Color(0.08f, 0.09f, 0.11f, 0.82f);
            return go;
        }

        private static Slider CreateSlider(Transform parent, Vector2 position, Vector2 size)
        {
            var go = new GameObject("ProgressSlider");
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;

            var background = new GameObject("Background");
            background.transform.SetParent(go.transform, false);
            var bgRect = background.AddComponent<RectTransform>();
            bgRect.anchorMin = Vector2.zero;
            bgRect.anchorMax = Vector2.one;
            bgRect.offsetMin = Vector2.zero;
            bgRect.offsetMax = Vector2.zero;
            var bgImage = background.AddComponent<Image>();
            bgImage.color = new Color(0.2f, 0.22f, 0.25f);

            var fillArea = new GameObject("Fill Area");
            fillArea.transform.SetParent(go.transform, false);
            var fillAreaRect = fillArea.AddComponent<RectTransform>();
            fillAreaRect.anchorMin = Vector2.zero;
            fillAreaRect.anchorMax = Vector2.one;
            fillAreaRect.offsetMin = new Vector2(8, 8);
            fillAreaRect.offsetMax = new Vector2(-8, -8);

            var fill = new GameObject("Fill");
            fill.transform.SetParent(fillArea.transform, false);
            var fillRect = fill.AddComponent<RectTransform>();
            fillRect.anchorMin = Vector2.zero;
            fillRect.anchorMax = Vector2.one;
            fillRect.offsetMin = Vector2.zero;
            fillRect.offsetMax = Vector2.zero;
            var fillImage = fill.AddComponent<Image>();
            fillImage.color = new Color(1f, 0.55f, 0.18f);

            var slider = go.AddComponent<Slider>();
            slider.fillRect = fillRect;
            slider.targetGraphic = fillImage;
            slider.minValue = 0f;
            slider.maxValue = 1f;
            return slider;
        }

        private static TextMeshProUGUI CreateLabel(Transform parent, string name, Vector2 position, float fontSize, string text)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = new Vector2(680, 48);

            var label = go.AddComponent<TextMeshProUGUI>();
            label.alignment = TextAlignmentOptions.Center;
            label.fontSize = fontSize;
            label.color = new Color(0.92f, 0.94f, 0.96f);
            label.text = text;
            return label;
        }

        private static Button CreateButton(Transform parent, string name, Vector2 position, Vector2 size, string labelText)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = size;

            var image = go.AddComponent<Image>();
            image.color = new Color(0.18f, 0.42f, 0.72f);

            var button = go.AddComponent<Button>();
            button.targetGraphic = image;

            var labelGo = new GameObject("Label");
            labelGo.transform.SetParent(go.transform, false);
            var labelRect = labelGo.AddComponent<RectTransform>();
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero;
            labelRect.offsetMax = Vector2.zero;

            var label = labelGo.AddComponent<TextMeshProUGUI>();
            label.alignment = TextAlignmentOptions.Center;
            label.fontSize = 22;
            label.color = Color.white;
            label.text = labelText;
            return button;
        }
    }
}
