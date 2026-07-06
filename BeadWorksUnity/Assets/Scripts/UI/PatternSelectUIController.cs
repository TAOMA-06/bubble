using System;
using System.Collections.Generic;
using BeadWorks.Data;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Pattern selection screen with built-in original designs.
    /// </summary>
    public class PatternSelectUIController : MonoBehaviour
    {
        [SerializeField] private GameObject _panel;
        [SerializeField] private RectTransform _listContainer;
        [SerializeField] private Button _backButton;
        [SerializeField] private TextMeshProUGUI _headerLabel;

        public event Action BackRequested;
        public event Action<BeadPatternData> PatternSelected;

        private readonly List<GameObject> _rows = new();

        private void Awake()
        {
            EnsureBuilt();
            _backButton?.onClick.AddListener(() => BackRequested?.Invoke());
        }

        public void Show(IReadOnlyList<BeadPatternData> patterns, BeadPaletteRepository palette)
        {
            if (_panel != null)
            {
                _panel.SetActive(true);
            }

            RebuildList(patterns, palette);
        }

        public void Hide()
        {
            if (_panel != null)
            {
                _panel.SetActive(false);
            }
        }

        private void RebuildList(IReadOnlyList<BeadPatternData> patterns, BeadPaletteRepository palette)
        {
            foreach (var row in _rows)
            {
                if (row != null)
                {
                    Destroy(row);
                }
            }

            _rows.Clear();

            if (patterns == null || _listContainer == null)
            {
                return;
            }

            var y = 0f;
            foreach (var pattern in patterns)
            {
                var row = CreatePatternRow(pattern, palette, y);
                _rows.Add(row);
                y -= 140f;
            }
        }

        private GameObject CreatePatternRow(BeadPatternData pattern, BeadPaletteRepository palette, float yOffset)
        {
            var row = new GameObject($"Pattern_{pattern.id}");
            row.transform.SetParent(_listContainer, false);
            var rect = row.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 1f);
            rect.anchorMax = new Vector2(0.5f, 1f);
            rect.pivot = new Vector2(0.5f, 1f);
            rect.anchoredPosition = new Vector2(0, yOffset);
            rect.sizeDelta = new Vector2(920, 120);

            var bg = row.AddComponent<Image>();
            bg.color = new Color(0.14f, 0.16f, 0.2f, 0.9f);

            var button = row.AddComponent<Button>();
            button.targetGraphic = bg;
            button.onClick.AddListener(() => PatternSelected?.Invoke(pattern));

            var thumb = new GameObject("Thumb");
            thumb.transform.SetParent(row.transform, false);
            var thumbRect = thumb.AddComponent<RectTransform>();
            thumbRect.anchorMin = new Vector2(0f, 0.5f);
            thumbRect.anchorMax = new Vector2(0f, 0.5f);
            thumbRect.pivot = new Vector2(0f, 0.5f);
            thumbRect.anchoredPosition = new Vector2(16, 0);
            thumbRect.sizeDelta = new Vector2(96, 96);
            var thumbImage = thumb.AddComponent<RawImage>();
            thumbImage.texture = PatternThumbnailBuilder.Build(pattern, palette, 96);

            UiBuilder.CreateLabel(row.transform, "Name", new Vector2(-120, 16), 30, pattern.title);
            UiBuilder.CreateLabel(row.transform, "Size", new Vector2(-120, -24), 20, $"{pattern.width}×{pattern.height}");

            return row;
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

            _panel = UiBuilder.CreatePanel(canvas, "PatternSelectPanel", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var bg = _panel.GetComponent<Image>();
            if (bg != null)
            {
                bg.color = new Color(0.08f, 0.09f, 0.12f, 0.96f);
            }

            _headerLabel = UiBuilder.CreateLabel(_panel.transform, "Header", new Vector2(0, 780), 40, "选择图纸");
            _backButton = UiBuilder.CreateButton(_panel.transform, "Back", new Vector2(0, -780), new Vector2(280, 64), "返回");

            var scrollGo = new GameObject("PatternList");
            scrollGo.transform.SetParent(_panel.transform, false);
            _listContainer = scrollGo.AddComponent<RectTransform>();
            _listContainer.anchorMin = new Vector2(0.5f, 0.5f);
            _listContainer.anchorMax = new Vector2(0.5f, 0.5f);
            _listContainer.pivot = new Vector2(0.5f, 0.5f);
            _listContainer.anchoredPosition = new Vector2(0, -40);
            _listContainer.sizeDelta = new Vector2(920, 1400);
        }
    }
}
