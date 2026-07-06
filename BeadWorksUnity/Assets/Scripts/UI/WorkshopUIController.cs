using System.Collections.Generic;
using BeadWorks.Data;
using BeadWorks.Tools;
using BeadWorks.Workshop;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Palette, toolbar, and status text for the workshop.
    /// </summary>
    public class WorkshopUIController : MonoBehaviour
    {
        [Header("Containers")]
        [SerializeField] private RectTransform _paletteContainer;
        [SerializeField] private RectTransform _toolbarContainer;
        [SerializeField] private TextMeshProUGUI _statusText;

        [Header("Prefabs")]
        [SerializeField] private Button _swatchButtonPrefab;
        [SerializeField] private Button _toolButtonPrefab;

        private WorkshopController _workshop;
        private readonly List<Button> _swatchButtons = new();
        private readonly Dictionary<ToolMode, Button> _toolButtons = new();
        private Button _selectedSwatch;
        private Button _menuButton;

        private System.Func<ToolMode> _toolProvider;
        private System.Action<BeadColorData, Vector2> _onPickBegin;
        private System.Action<Vector2> _onPickMove;
        private System.Action<Vector2> _onPickEnd;

        public event System.Action MenuRequested;

        public void Bind(WorkshopController workshop)
        {
            _workshop = workshop;
        }

        public void ConfigureTweezers(
            System.Func<ToolMode> toolProvider,
            System.Action<BeadColorData, Vector2> onPickBegin,
            System.Action<Vector2> onPickMove,
            System.Action<Vector2> onPickEnd)
        {
            _toolProvider = toolProvider;
            _onPickBegin = onPickBegin;
            _onPickMove = onPickMove;
            _onPickEnd = onPickEnd;
        }

        public void SetStatus(string message)
        {
            if (_statusText != null)
            {
                _statusText.text = message;
            }
        }

        public void RefreshPalette(BeadPaletteRepository palette)
        {
            ClearChildren(_paletteContainer);
            _swatchButtons.Clear();
            _selectedSwatch = null;

            if (palette == null || _paletteContainer == null)
            {
                return;
            }

            foreach (var color in palette.BaseColors)
            {
                var button = CreateSwatchButton(color);
                _swatchButtons.Add(button);
            }
        }

        public void RefreshToolbar(ToolMode activeTool)
        {
            ClearChildren(_toolbarContainer);
            _toolButtons.Clear();

            if (_toolbarContainer == null)
            {
                return;
            }

            foreach (ToolMode tool in System.Enum.GetValues(typeof(ToolMode)))
            {
                var button = Instantiate(_toolButtonPrefab, _toolbarContainer);
                button.name = $"Tool_{tool}";
                var label = button.GetComponentInChildren<TextMeshProUGUI>();
                if (label != null)
                {
                    label.text = tool.IconLabel();
                }

                var captured = tool;
                button.onClick.AddListener(() => _workshop?.SelectTool(captured));
                _toolButtons[tool] = button;
            }

            HighlightTool(activeTool);
        }

        public void HighlightColor(int colorId)
        {
            foreach (var button in _swatchButtons)
            {
                var image = button.GetComponent<Image>();
                if (image == null)
                {
                    continue;
                }

                var isSelected = button.name == $"Swatch_{colorId}";
                image.rectTransform.localScale = isSelected ? Vector3.one * 1.15f : Vector3.one;
                if (isSelected)
                {
                    _selectedSwatch = button;
                }
            }
        }

        public void SetPaletteVisible(bool visible)
        {
            if (_paletteContainer != null)
            {
                _paletteContainer.gameObject.SetActive(visible);
            }
        }

        public void SetEditingPanelsVisible(bool visible)
        {
            SetPaletteVisible(visible);

            if (_toolbarContainer != null)
            {
                _toolbarContainer.gameObject.SetActive(visible);
            }

            EnsureMenuButton();
            if (_menuButton != null)
            {
                _menuButton.gameObject.SetActive(visible);
            }
        }

        private void EnsureMenuButton()
        {
            if (_menuButton != null)
            {
                return;
            }

            var canvas = GetComponent<RectTransform>();
            if (canvas == null)
            {
                return;
            }

            _menuButton = UiBuilder.CreateButton(canvas, "WorkshopMenu", new Vector2(-480, 900), new Vector2(100, 48), "菜单");
            _menuButton.onClick.AddListener(() => MenuRequested?.Invoke());
        }

        private void HighlightTool(ToolMode tool)
        {
            foreach (var pair in _toolButtons)
            {
                var colors = pair.Value.colors;
                var block = colors.normalColor;
                block.a = pair.Key == tool ? 1f : 0.55f;
                colors.normalColor = block;
                pair.Value.colors = colors;
            }
        }

        private Button CreateSwatchButton(BeadColorData color)
        {
            var button = Instantiate(_swatchButtonPrefab, _paletteContainer);
            button.name = $"Swatch_{color.id}";

            var image = button.GetComponent<Image>();
            if (image != null)
            {
                image.color = color.Color;
            }

            button.onClick.AddListener(() => _workshop?.SelectColor(color.id));

            var handler = button.gameObject.GetComponent<ColorSwatchHandler>();
            if (handler == null)
            {
                handler = button.gameObject.AddComponent<ColorSwatchHandler>();
            }

            handler.Configure(color, _toolProvider, _onPickBegin, _onPickMove, _onPickEnd);
            return button;
        }

        private static void ClearChildren(RectTransform container)
        {
            if (container == null)
            {
                return;
            }

            for (var i = container.childCount - 1; i >= 0; i--)
            {
                Destroy(container.GetChild(i).gameObject);
            }
        }
    }
}
