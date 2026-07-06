using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Shared UI construction helpers for runtime-built panels.
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
            image.color = new Color(0.08f, 0.09f, 0.11f, 0.82f);
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
            label.color = new Color(0.92f, 0.94f, 0.96f);
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
            label.fontSize = 26;
            label.color = Color.white;
            label.text = labelText;
            return button;
        }
    }
}
