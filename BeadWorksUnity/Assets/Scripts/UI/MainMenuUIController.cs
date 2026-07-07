using System;
using BeadWorks.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Main menu: free create (with canvas size choice), image import, gallery.
    /// Builtin pattern replicate is demoted to a small secondary link (sample/debug content).
    /// </summary>
    public class MainMenuUIController : MonoBehaviour
    {
        public const int SimplifiedGridSize = 16;
        public const int StandardGridSize = 29;

        [SerializeField] private GameObject _panel;
        [SerializeField] private Button _freeCreateButton;
        [SerializeField] private Button _imageImportButton;
        [SerializeField] private Button _galleryButton;
        [SerializeField] private Button _patternReplicateLink;
        [SerializeField] private Button _sizeChipSimplified;
        [SerializeField] private Button _sizeChipStandard;
        [SerializeField] private TextMeshProUGUI _titleLabel;

        private Image _sizeChipSimplifiedImage;
        private Image _sizeChipStandardImage;
        private int _selectedGridSize = StandardGridSize;

        public event Action<int> FreeCreateRequested;
        public event Action ImageImportRequested;
        public event Action PatternReplicateRequested;
        public event Action GalleryRequested;

        private void Awake()
        {
            EnsureBuilt();

            _freeCreateButton?.onClick.AddListener(() => FreeCreateRequested?.Invoke(_selectedGridSize));
            _imageImportButton?.onClick.AddListener(() => ImageImportRequested?.Invoke());
            _galleryButton?.onClick.AddListener(() => GalleryRequested?.Invoke());
            _patternReplicateLink?.onClick.AddListener(() => PatternReplicateRequested?.Invoke());
            _sizeChipSimplified?.onClick.AddListener(() => SelectGridSize(SimplifiedGridSize));
            _sizeChipStandard?.onClick.AddListener(() => SelectGridSize(StandardGridSize));

            RefreshChipVisuals();
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

        private void SelectGridSize(int size)
        {
            if (_selectedGridSize == size)
            {
                return;
            }

            _selectedGridSize = size;
            RefreshChipVisuals();
        }

        private void RefreshChipVisuals()
        {
            if (_sizeChipSimplifiedImage != null)
            {
                _sizeChipSimplifiedImage.color = _selectedGridSize == SimplifiedGridSize
                    ? BeadWorksUiTheme.ChipSelected
                    : BeadWorksUiTheme.ChipUnselected;
            }

            if (_sizeChipStandardImage != null)
            {
                _sizeChipStandardImage.color = _selectedGridSize == StandardGridSize
                    ? BeadWorksUiTheme.ChipSelected
                    : BeadWorksUiTheme.ChipUnselected;
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

            _panel = UiBuilder.CreatePanel(canvas, "MainMenuPanel", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

            BuildWorkbenchBackdrop(_panel.transform);
            BuildHeroPreview(_panel.transform);

            _titleLabel = UiBuilder.CreateLabel(_panel.transform, "Title", new Vector2(0, 690), 64, "拼豆工坊");
            ConfigureLabel(_titleLabel, new Vector2(900, 88), BeadWorksUiTheme.TextPrimary);

            var subtitle = UiBuilder.CreateLabel(_panel.transform, "Subtitle", new Vector2(0, 625), 25, "把照片变成拼豆图纸，也可以从空白板开始创作");
            ConfigureLabel(subtitle, new Vector2(900, 48), BeadWorksUiTheme.TextMuted);

            var sizeHint = UiBuilder.CreateLabel(_panel.transform, "SizeHint", new Vector2(0, -120), 23, "自由创作画布尺寸");
            ConfigureLabel(sizeHint, new Vector2(900, 42), BeadWorksUiTheme.TextMuted);

            _sizeChipSimplified = UiBuilder.CreateButton(
                _panel.transform, "SizeChipSimplified", new Vector2(-125, -180), new Vector2(220, 64),
                $"{SimplifiedGridSize}×{SimplifiedGridSize} 简易");
            _sizeChipSimplifiedImage = _sizeChipSimplified.GetComponent<Image>();

            _sizeChipStandard = UiBuilder.CreateButton(
                _panel.transform, "SizeChipStandard", new Vector2(125, -180), new Vector2(220, 64),
                $"{StandardGridSize}×{StandardGridSize} 标准");
            _sizeChipStandardImage = _sizeChipStandard.GetComponent<Image>();

            _freeCreateButton = UiBuilder.CreateButton(_panel.transform, "FreeCreate", new Vector2(0, -290), new Vector2(600, 92), "自由创作");
            SetButtonColor(_freeCreateButton, new Color(0.80f, 0.42f, 0.18f));

            _imageImportButton = UiBuilder.CreateButton(_panel.transform, "ImageImport", new Vector2(0, -410), new Vector2(600, 92), "导入图片生成模板");
            SetButtonColor(_imageImportButton, new Color(0.32f, 0.58f, 0.50f));

            _galleryButton = UiBuilder.CreateButton(_panel.transform, "Gallery", new Vector2(0, -530), new Vector2(600, 82), "作品库");
            SetButtonColor(_galleryButton, new Color(0.28f, 0.24f, 0.22f));

            _patternReplicateLink = UiBuilder.CreateButton(_panel.transform, "PatternReplicateLink", new Vector2(0, -635), new Vector2(300, 54), "示例图纸");
            SetButtonColor(_patternReplicateLink, new Color(0.22f, 0.18f, 0.16f, 0.78f));
        }

        private static void BuildWorkbenchBackdrop(Transform parent)
        {
            var baseImage = parent.GetComponent<Image>();
            if (baseImage != null)
            {
                baseImage.color = new Color(0.17f, 0.12f, 0.09f, 1f);
            }

            for (var i = 0; i < 11; i++)
            {
                var plank = new GameObject($"WoodPlank_{i}");
                plank.transform.SetParent(parent, false);
                var rect = plank.AddComponent<RectTransform>();
                rect.anchorMin = new Vector2(0.5f, 0.5f);
                rect.anchorMax = new Vector2(0.5f, 0.5f);
                rect.pivot = new Vector2(0.5f, 0.5f);
                rect.anchoredPosition = new Vector2(0, 850 - (i * 180));
                rect.sizeDelta = new Vector2(1180, 92);

                var image = plank.AddComponent<Image>();
                image.color = i % 2 == 0
                    ? new Color(0.31f, 0.20f, 0.13f, 0.38f)
                    : new Color(0.20f, 0.13f, 0.09f, 0.34f);
                image.raycastTarget = false;
            }
        }

        private static void BuildHeroPreview(Transform parent)
        {
            var board = new GameObject("HeroPegboardPreview");
            board.transform.SetParent(parent, false);
            var boardRect = board.AddComponent<RectTransform>();
            boardRect.anchorMin = new Vector2(0.5f, 0.5f);
            boardRect.anchorMax = new Vector2(0.5f, 0.5f);
            boardRect.pivot = new Vector2(0.5f, 0.5f);
            boardRect.anchoredPosition = new Vector2(0, 235);
            boardRect.sizeDelta = new Vector2(590, 590);

            var boardImage = board.AddComponent<Image>();
            BeadWorksUiTheme.ApplyRounded(boardImage, new Color(0.94f, 0.83f, 0.66f, 0.98f));
            boardImage.raycastTarget = false;

            const int grid = 11;
            const float spacing = 43f;
            const float beadSize = 31f;
            var start = -((grid - 1) * spacing * 0.5f);

            for (var y = 0; y < grid; y++)
            {
                for (var x = 0; x < grid; x++)
                {
                    CreateBead(board.transform, $"Hole_{x}_{y}", new Vector2(start + (x * spacing), start + (y * spacing)),
                        beadSize * 0.58f, new Color(0.58f, 0.42f, 0.29f, 0.45f));
                }
            }

            var colors = new[]
            {
                new Color(0.91f, 0.20f, 0.22f),
                new Color(0.98f, 0.59f, 0.34f),
                new Color(0.99f, 0.83f, 0.25f),
                new Color(0.32f, 0.63f, 0.50f),
                new Color(0.25f, 0.50f, 0.82f),
                new Color(0.77f, 0.36f, 0.68f)
            };

            for (var y = 2; y <= 8; y++)
            {
                for (var x = 2; x <= 8; x++)
                {
                    var dx = Mathf.Abs(x - 5);
                    var dy = Mathf.Abs(y - 5);
                    var inHeart = (y >= 5 && dx + dy <= 5) ||
                                  (y >= 3 && y <= 6 && ((x >= 2 && x <= 4) || (x >= 6 && x <= 8)));
                    if (!inHeart)
                    {
                        continue;
                    }

                    var color = colors[(x + y) % colors.Length];
                    CreateBead(board.transform, $"PreviewBead_{x}_{y}", new Vector2(start + (x * spacing), start + (y * spacing)),
                        beadSize, color);
                }
            }

            CreateBead(board.transform, "PreviewSparkA", new Vector2(start + spacing, start + (9 * spacing)), beadSize, colors[2]);
            CreateBead(board.transform, "PreviewSparkB", new Vector2(start + (9 * spacing), start + spacing), beadSize, colors[4]);
        }

        private static void CreateBead(Transform parent, string name, Vector2 position, float size, Color color)
        {
            var bead = new GameObject(name);
            bead.transform.SetParent(parent, false);
            var rect = bead.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = new Vector2(size, size);

            var image = bead.AddComponent<Image>();
            BeadWorksUiTheme.ApplyCircle(image, color);
            image.raycastTarget = false;
        }

        private static void ConfigureLabel(TextMeshProUGUI label, Vector2 size, Color color)
        {
            if (label == null)
            {
                return;
            }

            label.rectTransform.sizeDelta = size;
            label.color = color;
        }

        private static void SetButtonColor(Button button, Color color)
        {
            var image = button != null ? button.GetComponent<Image>() : null;
            if (image != null)
            {
                image.color = color;
            }
        }
    }
}
