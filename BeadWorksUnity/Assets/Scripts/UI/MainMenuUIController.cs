using System;
using BeadWorks.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Main menu: free create, pattern replicate, gallery.
    /// </summary>
    public class MainMenuUIController : MonoBehaviour
    {
        [SerializeField] private GameObject _panel;
        [SerializeField] private Button _freeCreateButton;
        [SerializeField] private Button _patternReplicateButton;
        [SerializeField] private Button _galleryButton;
        [SerializeField] private TextMeshProUGUI _titleLabel;

        public event Action FreeCreateRequested;
        public event Action PatternReplicateRequested;
        public event Action GalleryRequested;

        private void Awake()
        {
            EnsureBuilt();

            _freeCreateButton?.onClick.AddListener(() => FreeCreateRequested?.Invoke());
            _patternReplicateButton?.onClick.AddListener(() => PatternReplicateRequested?.Invoke());
            _galleryButton?.onClick.AddListener(() => GalleryRequested?.Invoke());
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
            var bg = _panel.GetComponent<Image>();
            if (bg != null)
            {
                bg.color = new Color(0.08f, 0.09f, 0.12f, 0.96f);
            }

            _titleLabel = UiBuilder.CreateLabel(_panel.transform, "Title", new Vector2(0, 420), 56, "拼豆工坊");
            _freeCreateButton = UiBuilder.CreateButton(_panel.transform, "FreeCreate", new Vector2(0, 120), new Vector2(520, 88), "自由创作");
            _patternReplicateButton = UiBuilder.CreateButton(_panel.transform, "PatternReplicate", new Vector2(0, 0), new Vector2(520, 88), "图纸复刻");
            _galleryButton = UiBuilder.CreateButton(_panel.transform, "Gallery", new Vector2(0, -120), new Vector2(520, 88), "作品库");
        }
    }
}
