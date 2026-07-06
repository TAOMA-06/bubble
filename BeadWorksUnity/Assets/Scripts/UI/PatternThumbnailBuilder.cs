using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.UI
{
    /// <summary>
    /// Builds small preview textures for pattern list thumbnails.
    /// </summary>
    public static class PatternThumbnailBuilder
    {
        public static Texture2D Build(BeadPatternData pattern, BeadPaletteRepository palette, int size)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var bg = new Color(0.2f, 0.22f, 0.25f, 1f);

            for (var y = 0; y < size; y++)
            {
                for (var x = 0; x < size; x++)
                {
                    tex.SetPixel(x, y, bg);
                }
            }

            if (pattern == null)
            {
                tex.Apply();
                return tex;
            }

            var cellW = (float)size / pattern.width;
            var cellH = (float)size / pattern.height;

            for (var py = 0; py < pattern.height; py++)
            {
                for (var px = 0; px < pattern.width; px++)
                {
                    var colorId = pattern.GetCell(px, py);
                    if (colorId < 0)
                    {
                        continue;
                    }

                    var color = palette?.GetById(colorId);
                    var c = color != null ? color.Color : Color.magenta;
                    var startX = Mathf.FloorToInt(px * cellW);
                    var startY = Mathf.FloorToInt(py * cellH);
                    var endX = Mathf.FloorToInt((px + 1) * cellW);
                    var endY = Mathf.FloorToInt((py + 1) * cellH);

                    for (var y = startY; y < endY && y < size; y++)
                    {
                        for (var x = startX; x < endX && x < size; x++)
                        {
                            tex.SetPixel(x, y, c);
                        }
                    }
                }
            }

            tex.Apply();
            return tex;
        }
    }
}
