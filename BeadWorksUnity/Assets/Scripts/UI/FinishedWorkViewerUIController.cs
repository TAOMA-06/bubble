using System;
using BeadWorks.Data;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Finished work viewer UI: product type, share, save, navigation.
    /// </summary>
    public class FinishedWorkViewerUIController : MonoBehaviour
    {
        [SerializeField] private GameObject _panel;
        [SerializeField] private TextMeshProUGUI _titleLabel;
        [SerializeField] private TextMeshProUGUI _metaLabel;
        [SerializeField] private Button _magnetButton;
        [SerializeField] private Button _keychainButton;
        [SerializeField] private Button _pendantButton;
        [SerializeField] private Button _shareButton;
        [SerializeField] private Button _saveButton;
        [SerializeField] private Button _menuButton;
        [SerializeField] private TextMeshProUGUI _hintLabel;

        public event Action<FinishedProductType> ProductTypeSelected;
        public event Action ShareRequested;
        public event Action SaveRequested;
        public event Action MenuRequested;

        private FinishedProductType _currentType = FinishedProductType.FridgeMagnet;

        private void Awake()
        {
            EnsureBuilt();

            _magnetButton?.onClick.AddListener(() => SelectProduct(FinishedProductType.FridgeMagnet));
            _keychainButton?.onClick.AddListener(() => SelectProduct(FinishedProductType.Keychain));
            _pendantButton?.onClick.AddListener(() => SelectProduct(FinishedProductType.Pendant));
            _shareButton?.onClick.AddListener(() => ShareRequested?.Invoke());
            _saveButton?.onClick.AddListener(() => SaveRequested?.Invoke());
            _menuButton?.onClick.AddListener(() => MenuRequested?.Invoke());
        }

        public void Show(string title, int beadCount, IroningResult ironingResult, DateTime completedAt)
        {
            if (_panel != null)
            {
                _panel.SetActive(true);
            }

            if (_titleLabel != null)
            {
                _titleLabel.text = title ?? "拼豆作品";
            }

            if (_metaLabel != null)
            {
                _metaLabel.text = $"用豆 {beadCount} 颗 · {ironingResult.DisplayMessage()} · {completedAt.ToLocalTime():yyyy-MM-dd HH:mm}";
            }

            SelectProduct(_currentType);
        }

        public void Hide()
        {
            if (_panel != null)
            {
                _panel.SetActive(false);
            }
        }

        public void SetShareStatus(string message)
        {
            if (_hintLabel != null)
            {
                _hintLabel.text = message;
            }
        }

        private void SelectProduct(FinishedProductType type)
        {
            _currentType = type;
            ProductTypeSelected?.Invoke(type);
            HighlightProductButton(_magnetButton, type == FinishedProductType.FridgeMagnet);
            HighlightProductButton(_keychainButton, type == FinishedProductType.Keychain);
            HighlightProductButton(_pendantButton, type == FinishedProductType.Pendant);
        }

        private static void HighlightProductButton(Button button, bool selected)
        {
            if (button == null)
            {
                return;
            }

            var image = button.GetComponent<Image>();
            if (image != null)
            {
                image.color = selected
                    ? new Color(0.22f, 0.52f, 0.82f)
                    : new Color(0.18f, 0.2f, 0.24f);
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

            _panel = UiBuilder.CreatePanel(canvas, "FinishedViewerPanel",
                new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0, 0), new Vector2(0, 320));
            var rect = _panel.GetComponent<RectTransform>();
            rect.pivot = new Vector2(0.5f, 0f);
            rect.offsetMin = new Vector2(0, 0);
            rect.offsetMax = new Vector2(0, 320);

            var bg = _panel.GetComponent<Image>();
            if (bg != null)
            {
                bg.color = new Color(0.08f, 0.09f, 0.12f, 0.88f);
            }

            _titleLabel = UiBuilder.CreateLabel(_panel.transform, "Title", new Vector2(0, 250), 30, "成品");
            _metaLabel = UiBuilder.CreateLabel(_panel.transform, "Meta", new Vector2(0, 210), 20, string.Empty);
            _hintLabel = UiBuilder.CreateLabel(_panel.transform, "Hint", new Vector2(0, 40), 18, "拖动旋转 · 双指缩放");
            _hintLabel.color = new Color(0.7f, 0.72f, 0.75f);

            _magnetButton = UiBuilder.CreateButton(_panel.transform, "Magnet", new Vector2(-280, 150), new Vector2(180, 52), "冰箱贴");
            _keychainButton = UiBuilder.CreateButton(_panel.transform, "Keychain", new Vector2(-80, 150), new Vector2(180, 52), "钥匙扣");
            _pendantButton = UiBuilder.CreateButton(_panel.transform, "Pendant", new Vector2(120, 150), new Vector2(180, 52), "挂件");

            _shareButton = UiBuilder.CreateButton(_panel.transform, "Share", new Vector2(-150, 80), new Vector2(240, 56), "分享图片");
            _saveButton = UiBuilder.CreateButton(_panel.transform, "Save", new Vector2(150, 80), new Vector2(240, 56), "保存作品");
            _menuButton = UiBuilder.CreateButton(_panel.transform, "Menu", new Vector2(0, 10), new Vector2(200, 48), "返回主菜单");
        }
    }
}
