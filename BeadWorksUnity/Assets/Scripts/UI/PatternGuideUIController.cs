using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Pattern guide controls: toggle guide overlay and error hints.
    /// </summary>
    public class PatternGuideUIController : MonoBehaviour
    {
        [SerializeField] private GameObject _panel;
        [SerializeField] private Toggle _guideToggle;
        [SerializeField] private Toggle _errorToggle;
        [SerializeField] private TextMeshProUGUI _progressLabel;
        [SerializeField] private Button _menuButton;

        public event Action<bool> GuideVisibilityChanged;
        public event Action<bool> ErrorHintsChanged;
        public event Action MenuRequested;

        private void Awake()
        {
            EnsureBuilt();

            _guideToggle?.onValueChanged.AddListener(v => GuideVisibilityChanged?.Invoke(v));
            _errorToggle?.onValueChanged.AddListener(v => ErrorHintsChanged?.Invoke(v));
            _menuButton?.onClick.AddListener(() => MenuRequested?.Invoke());
        }

        public void Show()
        {
            if (_panel != null)
            {
                _panel.SetActive(true);
            }
        }

        public void Hide()
        {
            if (_panel != null)
            {
                _panel.SetActive(false);
            }
        }

        public void SetProgress(string message)
        {
            if (_progressLabel != null)
            {
                _progressLabel.text = message;
            }
        }

        public void SetGuideVisible(bool visible)
        {
            if (_guideToggle != null)
            {
                _guideToggle.isOn = visible;
            }
        }

        public void SetErrorsVisible(bool visible)
        {
            if (_errorToggle != null)
            {
                _errorToggle.isOn = visible;
            }
        }

        private void EnsureBuilt()
        {
            if (_panel != null)
            {
                return;
            }

            var canvas = GetComponent<RectTransform>();
            if (canvas == null)
            {
                return;
            }

            _panel = UiBuilder.CreatePanel(canvas, "PatternGuidePanel",
                new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0, -80), new Vector2(920, 72));
            var bg = _panel.GetComponent<Image>();
            if (bg != null)
            {
                bg.color = new Color(BeadWorksUiTheme.PanelSurface.r, BeadWorksUiTheme.PanelSurface.g, BeadWorksUiTheme.PanelSurface.b, 0.82f);
            }

            _progressLabel = UiBuilder.CreateLabel(_panel.transform, "Progress", new Vector2(0, 0), 20, "图纸模式");
            _progressLabel.rectTransform.sizeDelta = new Vector2(360, 40);
            _progressLabel.alignment = TextAlignmentOptions.Left;

            _guideToggle = CreateToggle(_panel.transform, "GuideToggle", new Vector2(-280, 0), "底图");
            _errorToggle = CreateToggle(_panel.transform, "ErrorToggle", new Vector2(-80, 0), "错误提示");
            _menuButton = UiBuilder.CreateButton(_panel.transform, "Menu", new Vector2(360, 0), new Vector2(120, 48), "菜单");
        }

        private static Toggle CreateToggle(Transform parent, string name, Vector2 position, string label)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = new Vector2(160, 40);

            var toggle = go.AddComponent<Toggle>();
            toggle.isOn = true;

            var bg = new GameObject("Background");
            bg.transform.SetParent(go.transform, false);
            var bgRect = bg.AddComponent<RectTransform>();
            bgRect.anchorMin = Vector2.zero;
            bgRect.anchorMax = Vector2.one;
            bgRect.offsetMin = Vector2.zero;
            bgRect.offsetMax = Vector2.zero;
            var bgImage = bg.AddComponent<Image>();
            BeadWorksUiTheme.ApplyRounded(bgImage, BeadWorksUiTheme.ChipUnselected);

            var check = new GameObject("Checkmark");
            check.transform.SetParent(bg.transform, false);
            var checkRect = check.AddComponent<RectTransform>();
            checkRect.anchorMin = new Vector2(0f, 0.5f);
            checkRect.anchorMax = new Vector2(0f, 0.5f);
            checkRect.pivot = new Vector2(0f, 0.5f);
            checkRect.anchoredPosition = new Vector2(6, 0);
            checkRect.sizeDelta = new Vector2(24, 24);
            var checkImage = check.AddComponent<Image>();
            BeadWorksUiTheme.ApplyRounded(checkImage, BeadWorksUiTheme.ChipSelected);

            toggle.targetGraphic = bgImage;
            toggle.graphic = checkImage;

            var labelGo = new GameObject("Label");
            labelGo.transform.SetParent(go.transform, false);
            var labelRect = labelGo.AddComponent<RectTransform>();
            labelRect.anchorMin = new Vector2(0f, 0.5f);
            labelRect.anchorMax = new Vector2(1f, 0.5f);
            labelRect.offsetMin = new Vector2(36, -16);
            labelRect.offsetMax = new Vector2(0, 16);
            var tmp = labelGo.AddComponent<TextMeshProUGUI>();
            tmp.text = label;
            tmp.fontSize = 18;
            tmp.color = BeadWorksUiTheme.TextPrimary;
            tmp.alignment = TextAlignmentOptions.Left;

            return toggle;
        }
    }
}
