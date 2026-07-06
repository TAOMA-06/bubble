using System;
using System.Collections.Generic;
using System.IO;
using BeadWorks.Data;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Local gallery of saved finished works.
    /// </summary>
    public class GalleryUIController : MonoBehaviour
    {
        [SerializeField] private GameObject _panel;
        [SerializeField] private RectTransform _gridContainer;
        [SerializeField] private Button _backButton;
        [SerializeField] private TextMeshProUGUI _headerLabel;
        [SerializeField] private TextMeshProUGUI _emptyLabel;

        public event Action BackRequested;
        public event Action<FinishedWorkRecord> WorkSelected;

        private readonly List<GameObject> _cells = new();
        private GalleryRepository _gallery;

        private void Awake()
        {
            EnsureBuilt();
            _backButton?.onClick.AddListener(() => BackRequested?.Invoke());
        }

        public void Bind(GalleryRepository gallery)
        {
            _gallery = gallery;
        }

        public void Show()
        {
            if (_panel != null)
            {
                _panel.SetActive(true);
            }

            Refresh();
        }

        public void Hide()
        {
            if (_panel != null)
            {
                _panel.SetActive(false);
            }
        }

        public void Refresh()
        {
            foreach (var cell in _cells)
            {
                if (cell != null)
                {
                    Destroy(cell);
                }
            }

            _cells.Clear();

            var works = _gallery?.Works;
            var isEmpty = works == null || works.Count == 0;
            if (_emptyLabel != null)
            {
                _emptyLabel.gameObject.SetActive(isEmpty);
            }

            if (isEmpty || _gridContainer == null)
            {
                return;
            }

            var col = 0;
            var row = 0;
            const int columns = 2;
            const float cellSize = 200f;
            const float spacing = 24f;

            foreach (var work in works)
            {
                var cell = CreateGalleryCell(work, col, row, cellSize, spacing);
                _cells.Add(cell);
                col++;
                if (col >= columns)
                {
                    col = 0;
                    row++;
                }
            }
        }

        private GameObject CreateGalleryCell(FinishedWorkRecord work, int col, int row, float cellSize, float spacing)
        {
            var go = new GameObject($"Gallery_{work.id}");
            go.transform.SetParent(_gridContainer, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0f, 1f);
            rect.anchorMax = new Vector2(0f, 1f);
            rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(col * (cellSize + spacing), -row * (cellSize + spacing + 40));
            rect.sizeDelta = new Vector2(cellSize, cellSize + 40);

            var bg = go.AddComponent<Image>();
            bg.color = new Color(0.16f, 0.18f, 0.22f);

            var button = go.AddComponent<Button>();
            button.targetGraphic = bg;
            button.onClick.AddListener(() => WorkSelected?.Invoke(work));

            var thumbGo = new GameObject("Thumb");
            thumbGo.transform.SetParent(go.transform, false);
            var thumbRect = thumbGo.AddComponent<RectTransform>();
            thumbRect.anchorMin = new Vector2(0.5f, 1f);
            thumbRect.anchorMax = new Vector2(0.5f, 1f);
            thumbRect.pivot = new Vector2(0.5f, 1f);
            thumbRect.anchoredPosition = new Vector2(0, -8);
            thumbRect.sizeDelta = new Vector2(cellSize - 16, cellSize - 16);
            var thumbImage = thumbGo.AddComponent<RawImage>();

            var thumbPath = _gallery?.GetThumbnailPath(work);
            if (!string.IsNullOrEmpty(thumbPath) && File.Exists(thumbPath))
            {
                var bytes = File.ReadAllBytes(thumbPath);
                var tex = new Texture2D(2, 2);
                tex.LoadImage(bytes);
                thumbImage.texture = tex;
            }

            var title = UiBuilder.CreateLabel(go.transform, "Title", new Vector2(0, -cellSize + 8), 18, work.title ?? "作品");
            title.rectTransform.sizeDelta = new Vector2(cellSize - 8, 32);

            return go;
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

            _panel = UiBuilder.CreatePanel(canvas, "GalleryPanel", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            var bg = _panel.GetComponent<Image>();
            if (bg != null)
            {
                bg.color = new Color(0.08f, 0.09f, 0.12f, 0.96f);
            }

            _headerLabel = UiBuilder.CreateLabel(_panel.transform, "Header", new Vector2(0, 780), 40, "作品库");
            _emptyLabel = UiBuilder.CreateLabel(_panel.transform, "Empty", new Vector2(0, 0), 24, "还没有保存的作品");
            _backButton = UiBuilder.CreateButton(_panel.transform, "Back", new Vector2(0, -780), new Vector2(280, 64), "返回");

            var gridGo = new GameObject("GalleryGrid");
            gridGo.transform.SetParent(_panel.transform, false);
            _gridContainer = gridGo.AddComponent<RectTransform>();
            _gridContainer.anchorMin = new Vector2(0.5f, 0.5f);
            _gridContainer.anchorMax = new Vector2(0.5f, 0.5f);
            _gridContainer.pivot = new Vector2(0.5f, 1f);
            _gridContainer.anchoredPosition = new Vector2(-220, 700);
            _gridContainer.sizeDelta = new Vector2(920, 1400);
        }
    }
}
