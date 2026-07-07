using System.Collections;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Shared UI construction helpers for runtime-built panels. Styling (rounded corners,
    /// colors, press states) comes from <see cref="BeadWorksUiTheme"/> so every screen
    /// stays visually consistent.
    /// </summary>
    public static class UiBuilder
    {
        public static GameObject CreatePanel(
            Transform parent,
            string name,
            Vector2 anchorMin,
            Vector2 anchorMax,
            Vector2 anchoredPosition,
            Vector2 sizeDelta)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = anchoredPosition;
            rect.sizeDelta = sizeDelta;
            rect.offsetMin = anchorMin == Vector2.zero && anchorMax == Vector2.one ? Vector2.zero : rect.offsetMin;
            rect.offsetMax = anchorMin == Vector2.zero && anchorMax == Vector2.one ? Vector2.zero : rect.offsetMax;

            var image = go.AddComponent<Image>();
            var isFullScreenBackdrop = anchorMin == Vector2.zero && anchorMax == Vector2.one;
            if (isFullScreenBackdrop)
            {
                image.color = BeadWorksUiTheme.ScreenBackground;
            }
            else
            {
                BeadWorksUiTheme.ApplyRounded(image, BeadWorksUiTheme.PanelSurface);
            }

            return go;
        }

        public static TextMeshProUGUI CreateLabel(Transform parent, string name, Vector2 position, float fontSize, string text)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.anchoredPosition = position;
            rect.sizeDelta = new Vector2(800, 56);

            var label = go.AddComponent<TextMeshProUGUI>();
            label.alignment = TextAlignmentOptions.Center;
            label.fontSize = fontSize;
            label.color = BeadWorksUiTheme.TextPrimary;
            label.text = text;
            return label;
        }

        public static Button CreateButton(Transform parent, string name, Vector2 position, Vector2 size, string labelText)
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
            BeadWorksUiTheme.ApplyRounded(image, BeadWorksUiTheme.ButtonPrimary);

            var button = go.AddComponent<Button>();
            button.targetGraphic = image;
            BeadWorksUiTheme.ApplyButtonColors(button);

            var labelGo = new GameObject("Label");
            labelGo.transform.SetParent(go.transform, false);
            var labelRect = labelGo.AddComponent<RectTransform>();
            labelRect.anchorMin = Vector2.zero;
            labelRect.anchorMax = Vector2.one;
            labelRect.offsetMin = Vector2.zero;
            labelRect.offsetMax = Vector2.zero;

            var label = labelGo.AddComponent<TextMeshProUGUI>();
            label.alignment = TextAlignmentOptions.Center;
            label.fontSize = 26;
            label.color = BeadWorksUiTheme.TextPrimary;
            label.text = labelText;
            return button;
        }

        public static Slider CreateSlider(Transform parent, Vector2 position, Vector2 size)
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
            BeadWorksUiTheme.ApplyRounded(bgImage, BeadWorksUiTheme.ChipUnselected);

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
            BeadWorksUiTheme.ApplyRounded(fillImage, BeadWorksUiTheme.ButtonPrimary);

            var slider = go.AddComponent<Slider>();
            slider.fillRect = fillRect;
            slider.targetGraphic = fillImage;
            slider.minValue = 0f;
            slider.maxValue = 1f;
            return slider;
        }

        /// <summary>
        /// Small scale "pop" used when a result/completion panel appears (ironing result,
        /// finished-work viewer). Callers run this with StartCoroutine after activating the panel.
        /// </summary>
        public static IEnumerator PopInRoutine(RectTransform rect, float duration = 0.22f, float overshoot = 1.08f)
        {
            if (rect == null)
            {
                yield break;
            }

            var restScale = Vector3.one;
            rect.localScale = restScale * 0.85f;

            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                var t = Mathf.Clamp01(elapsed / duration);
                var eased = Mathf.Sin(t * Mathf.PI * 0.5f);
                rect.localScale = restScale * Mathf.Lerp(0.85f, overshoot, eased);
                yield return null;
            }

            const float settleDuration = 0.1f;
            var startScale = rect.localScale;
            elapsed = 0f;
            while (elapsed < settleDuration)
            {
                elapsed += Time.deltaTime;
                rect.localScale = Vector3.Lerp(startScale, restScale, elapsed / settleDuration);
                yield return null;
            }

            rect.localScale = restScale;
        }
    }
}
