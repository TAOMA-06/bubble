using System;
using BeadWorks.Data;
using BeadWorks.Services;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Photo import screen: pick an image, choose a template size, preview the
    /// bead-quantized result, and confirm to start a workshop session from it.
    /// </summary>
    public class ImageImportUIController : MonoBehaviour
    {
        private static readonly int[] SizeOptions = { 16, 24, 32, 48 };
        private const int DefaultSizeIndex = 2; // 32x32, per plan default

        [SerializeField] private GameObject _panel;
        [SerializeField] private Button _pickButton;
        [SerializeField] private Button _confirmButton;
        [SerializeField] private Button _backButton;
        [SerializeField] private RawImage _previewImage;
        [SerializeField] private TextMeshProUGUI _statusLabel;

        private readonly Button[] _sizeChips = new Button[SizeOptions.Length];
        private readonly Image[] _sizeChipImages = new Image[SizeOptions.Length];

        private BeadPaletteRepository _palette;
        private PhotoImportService _photoImportService;
        private Texture2D _sourceTexture;
        private Texture2D _previewTexture;
        private BeadPatternData _pendingPattern;
        private int _selectedSizeIndex = DefaultSizeIndex;

        public event Action<BeadPatternData, string> PatternConfirmed;
        public event Action BackRequested;

        private void Awake()
        {
            EnsureBuilt();

            _pickButton?.onClick.AddListener(OnPickClicked);
            _confirmButton?.onClick.AddListener(OnConfirmClicked);
            _backButton?.onClick.AddListener(() => BackRequested?.Invoke());

            for (var i = 0; i < SizeOptions.Length; i++)
            {
                var index = i;
                _sizeChips[i]?.onClick.AddListener(() => SelectSize(index));
            }

            RefreshChipVisuals();
            SetConfirmInteractable(false);
        }

        public void Show(BeadPaletteRepository palette)
        {
            _palette = palette;
            _photoImportService = PhotoImportService.EnsureInstance(transform);

            ResetState();

            if (_panel != null)
            {
                _panel.SetActive(true);
            }
        }

        public void Hide()
        {
            // Reset any in-flight pick so a missed native/editor callback can't permanently
            // block picking next time this screen is shown, and so a late callback for a
            // pick the user has already left doesn't fire into a hidden screen.
            _photoImportService?.CancelPick();

            if (_panel != null)
            {
                _panel.SetActive(false);
            }
        }

        private void ResetState()
        {
            ClearSourceTexture();
            ClearPreviewTexture();
            _pendingPattern = null;
            SetConfirmInteractable(false);
            SetStatus("选择一张照片，自动生成拼豆模板");
        }

        private void OnPickClicked()
        {
            if (_photoImportService == null)
            {
                return;
            }

            SetStatus("正在选择照片…");
            _photoImportService.RequestPickPhoto(OnPhotoPicked, OnPhotoError);
        }

        private void OnPhotoPicked(Texture2D texture)
        {
            ClearSourceTexture();
            _sourceTexture = texture;
            RegenerateFromSource();
        }

        private void OnPhotoError(string message)
        {
            SetStatus(message);
        }

        private void SelectSize(int index)
        {
            if (_selectedSizeIndex == index)
            {
                return;
            }

            _selectedSizeIndex = index;
            RefreshChipVisuals();

            if (_sourceTexture != null)
            {
                RegenerateFromSource();
            }
        }

        private void RegenerateFromSource()
        {
            if (_sourceTexture == null || _palette == null)
            {
                return;
            }

            var gridSize = SizeOptions[_selectedSizeIndex];

            try
            {
                _pendingPattern = PhotoToPatternConverter.Convert(_sourceTexture, _palette, gridSize);
            }
            catch (Exception e)
            {
                Debug.LogError($"[ImageImportUIController] Conversion failed: {e}");
                _pendingPattern = null;
                SetConfirmInteractable(false);
                SetStatus("图片转换失败，请重新选择");
                return;
            }

            ClearPreviewTexture();
            _previewTexture = PatternThumbnailBuilder.Build(_pendingPattern, _palette, 512);
            if (_previewImage != null)
            {
                _previewImage.texture = _previewTexture;
                _previewImage.color = Color.white;
            }

            SetConfirmInteractable(true);
            SetStatus($"预览 {gridSize}×{gridSize} — 可切换尺寸或确认开始");
        }

        private void OnConfirmClicked()
        {
            if (_pendingPattern == null)
            {
                SetStatus("请先选择照片");
                return;
            }

            PatternConfirmed?.Invoke(_pendingPattern, "照片拼豆");
        }

        private void SetConfirmInteractable(bool interactable)
        {
            if (_confirmButton != null)
            {
                _confirmButton.interactable = interactable;
            }
        }

        private void SetStatus(string message)
        {
            if (_statusLabel != null)
            {
                _statusLabel.text = message;
            }
        }

        private void RefreshChipVisuals()
        {
            for (var i = 0; i < _sizeChipImages.Length; i++)
            {
                if (_sizeChipImages[i] != null)
                {
                    _sizeChipImages[i].color = i == _selectedSizeIndex
                        ? BeadWorksUiTheme.ChipSelected
                        : BeadWorksUiTheme.ChipUnselected;
                }
            }
        }

        private void ClearSourceTexture()
        {
            if (_sourceTexture != null)
            {
                Destroy(_sourceTexture);
                _sourceTexture = null;
            }
        }

        private void ClearPreviewTexture()
        {
            if (_previewTexture != null)
            {
                Destroy(_previewTexture);
                _previewTexture = null;
            }

            if (_previewImage != null)
            {
                _previewImage.texture = null;
                _previewImage.color = new Color(1f, 1f, 1f, 0f);
            }
        }

        private void OnDestroy()
        {
            ClearSourceTexture();
            ClearPreviewTexture();
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

            _panel = UiBuilder.CreatePanel(canvas, "ImageImportPanel", Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);

            UiBuilder.CreateLabel(_panel.transform, "Header", new Vector2(0, 780), 40, "导入图片生成模板");
            _backButton = UiBuilder.CreateButton(_panel.transform, "Back", new Vector2(0, -820), new Vector2(280, 64), "返回");

            _pickButton = UiBuilder.CreateButton(_panel.transform, "Pick", new Vector2(0, 640), new Vector2(420, 88), "选择照片");

            var previewGo = new GameObject("PreviewFrame");
            previewGo.transform.SetParent(_panel.transform, false);
            var previewRect = previewGo.AddComponent<RectTransform>();
            previewRect.anchorMin = new Vector2(0.5f, 0.5f);
            previewRect.anchorMax = new Vector2(0.5f, 0.5f);
            previewRect.pivot = new Vector2(0.5f, 0.5f);
            previewRect.anchoredPosition = new Vector2(0, 180);
            previewRect.sizeDelta = new Vector2(460, 460);
            var previewBg = previewGo.AddComponent<Image>();
            BeadWorksUiTheme.ApplyRounded(previewBg, BeadWorksUiTheme.PanelSurface);

            var previewImageGo = new GameObject("Preview");
            previewImageGo.transform.SetParent(previewGo.transform, false);
            var previewImageRect = previewImageGo.AddComponent<RectTransform>();
            previewImageRect.anchorMin = Vector2.zero;
            previewImageRect.anchorMax = Vector2.one;
            previewImageRect.offsetMin = new Vector2(8, 8);
            previewImageRect.offsetMax = new Vector2(-8, -8);
            _previewImage = previewImageGo.AddComponent<RawImage>();
            _previewImage.color = new Color(1f, 1f, 1f, 0f);

            UiBuilder.CreateLabel(_panel.transform, "SizeHint", new Vector2(0, -140), 24, "模板尺寸");

            var startX = -((SizeOptions.Length - 1) * 0.5f) * 190f;
            for (var i = 0; i < SizeOptions.Length; i++)
            {
                var size = SizeOptions[i];
                var chip = UiBuilder.CreateButton(
                    _panel.transform, $"SizeChip_{size}",
                    new Vector2(startX + (i * 190f), -200),
                    new Vector2(170, 64),
                    $"{size}×{size}");
                _sizeChips[i] = chip;
                _sizeChipImages[i] = chip.GetComponent<Image>();
            }

            _confirmButton = UiBuilder.CreateButton(_panel.transform, "Confirm", new Vector2(0, -320), new Vector2(420, 88), "开始拼豆");
            _statusLabel = UiBuilder.CreateLabel(_panel.transform, "Status", new Vector2(0, -420), 24, "选择一张照片，自动生成拼豆模板");
        }
    }
}
