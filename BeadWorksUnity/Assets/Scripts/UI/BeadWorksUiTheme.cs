using UnityEngine;
using UnityEngine.UI;

namespace BeadWorks.UI
{
    /// <summary>
    /// Shared warm "handmade workshop" color palette and procedurally generated rounded-rect
    /// sprites used across all runtime-built UI. No external image assets — sprites are
    /// generated once at runtime and 9-sliced so they scale to any button/panel size.
    /// </summary>
    public static class BeadWorksUiTheme
    {
        // Warm terracotta/wood workshop palette instead of flat gray/blue placeholders.
        public static readonly Color ScreenBackground = new(0.13f, 0.10f, 0.09f, 0.97f);
        public static readonly Color PanelSurface = new(0.20f, 0.15f, 0.13f, 0.92f);
        public static readonly Color PanelSurfaceLight = new(0.94f, 0.88f, 0.80f, 0.96f);
        public static readonly Color TextPrimary = new(0.98f, 0.95f, 0.90f);
        public static readonly Color TextOnLight = new(0.22f, 0.16f, 0.13f);
        public static readonly Color TextMuted = new(0.80f, 0.74f, 0.68f);

        public static readonly Color ButtonPrimary = new(0.86f, 0.47f, 0.20f);
        public static readonly Color ButtonPrimaryHighlighted = new(0.92f, 0.56f, 0.30f);
        public static readonly Color ButtonPrimaryPressed = new(0.70f, 0.36f, 0.15f);
        public static readonly Color ButtonDisabled = new(0.42f, 0.38f, 0.36f, 0.6f);

        public static readonly Color ChipSelected = new(0.93f, 0.62f, 0.24f);
        public static readonly Color ChipUnselected = new(0.30f, 0.25f, 0.22f);

        public static readonly Color WorkbenchWoodLight = new(0.62f, 0.44f, 0.29f);
        public static readonly Color WorkbenchWoodDark = new(0.45f, 0.30f, 0.19f);

        private const int SpriteSize = 64;
        private const int CornerRadius = 18;

        private static Sprite _roundedRectSprite;
        private static Sprite _circleSprite;

        /// <summary>A single reusable 9-sliced rounded-rect sprite for panels, buttons and chips.</summary>
        public static Sprite RoundedRectSprite => _roundedRectSprite ??= CreateRoundedRectSprite(SpriteSize, CornerRadius);
        public static Sprite CircleSprite => _circleSprite ??= CreateCircleSprite(SpriteSize);

        public static void ApplyRounded(Image image, Color color)
        {
            if (image == null)
            {
                return;
            }

            image.sprite = RoundedRectSprite;
            image.type = Image.Type.Sliced;
            image.color = color;
        }

        public static void ApplyButtonColors(Button button)
        {
            if (button == null)
            {
                return;
            }

            var colors = button.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = new Color(1.05f, 1.05f, 1.05f, 1f);
            colors.pressedColor = new Color(0.85f, 0.85f, 0.85f, 1f);
            colors.selectedColor = Color.white;
            colors.disabledColor = new Color(0.6f, 0.6f, 0.6f, 0.6f);
            button.colors = colors;
        }

        public static void ApplyCircle(Image image, Color color)
        {
            if (image == null)
            {
                return;
            }

            image.sprite = CircleSprite;
            image.type = Image.Type.Simple;
            image.color = color;
        }

        private static Sprite CreateRoundedRectSprite(int size, int radius)
        {
            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false)
            {
                name = "BeadWorksRoundedRect",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp
            };

            for (var y = 0; y < size; y++)
            {
                for (var x = 0; x < size; x++)
                {
                    var alpha = SampleRoundedAlpha(x, y, size, radius);
                    texture.SetPixel(x, y, new Color(1f, 1f, 1f, alpha));
                }
            }

            texture.Apply();

            var border = new Vector4(radius, radius, radius, radius);
            return Sprite.Create(
                texture,
                new Rect(0, 0, size, size),
                new Vector2(0.5f, 0.5f),
                100f,
                0,
                SpriteMeshType.FullRect,
                border);
        }

        private static float SampleRoundedAlpha(int x, int y, int size, int radius)
        {
            var px = x + 0.5f;
            var py = y + 0.5f;
            var minX = radius;
            var minY = radius;
            var maxX = size - radius;
            var maxY = size - radius;

            var dx = px < minX ? minX - px : (px > maxX ? px - maxX : 0f);
            var dy = py < minY ? minY - py : (py > maxY ? py - maxY : 0f);

            var distance = Mathf.Sqrt((dx * dx) + (dy * dy));
            return Mathf.Clamp01(radius - distance + 0.5f);
        }

        private static Sprite CreateCircleSprite(int size)
        {
            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false)
            {
                name = "BeadWorksCircle",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp
            };

            var center = (size - 1) * 0.5f;
            var radius = center - 1f;
            for (var y = 0; y < size; y++)
            {
                for (var x = 0; x < size; x++)
                {
                    var dx = x - center;
                    var dy = y - center;
                    var distance = Mathf.Sqrt((dx * dx) + (dy * dy));
                    var alpha = Mathf.Clamp01(radius - distance + 1f);
                    texture.SetPixel(x, y, new Color(1f, 1f, 1f, alpha));
                }
            }

            texture.Apply();
            return Sprite.Create(
                texture,
                new Rect(0, 0, size, size),
                new Vector2(0.5f, 0.5f),
                100f);
        }
    }
}
