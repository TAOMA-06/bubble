using System;
using UnityEngine;

namespace BeadWorks.Data
{
    /// <summary>
    /// Converts an arbitrary photo into a square <see cref="BeadPatternData"/> by cropping to a
    /// centered square, box-downsampling to the target grid, and mapping each cell to the
    /// nearest color already present in the bead palette. Pixels whose (box-averaged) alpha
    /// falls below <paramref name="alphaThreshold"/> are left empty, producing a full board
    /// for ordinary opaque photos.
    /// </summary>
    public static class PhotoToPatternConverter
    {
        public const float DefaultAlphaThreshold = 0.1f;

        public static BeadPatternData Convert(
            Texture2D source,
            BeadPaletteRepository palette,
            int gridSize,
            float alphaThreshold = DefaultAlphaThreshold,
            string title = null,
            BeadSizeType beadSize = BeadSizeType.Standard5mm)
        {
            if (source == null)
            {
                throw new ArgumentNullException(nameof(source));
            }

            if (palette == null || palette.Colors.Length == 0)
            {
                throw new ArgumentException("Palette must contain at least one color.", nameof(palette));
            }

            if (gridSize <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(gridSize), "Grid size must be positive.");
            }

            var (cropX, cropY, cropSize) = ComputeCenterSquareCrop(source.width, source.height);

            var cells = new int[gridSize * gridSize];
            for (var gy = 0; gy < gridSize; gy++)
            {
                for (var gx = 0; gx < gridSize; gx++)
                {
                    var averageColor = SampleCellAverage(
                        source,
                        cropX, cropY, cropSize,
                        gx, gy, gridSize);

                    cells[(gy * gridSize) + gx] = averageColor.a < alphaThreshold
                        ? -1
                        : palette.FindNearestColor(averageColor).id;
                }
            }

            return new BeadPatternData
            {
                id = Guid.NewGuid().ToString("N"),
                title = string.IsNullOrEmpty(title) ? "照片拼豆" : title,
                width = gridSize,
                height = gridSize,
                beadSize = beadSize,
                cells = cells,
                palette = Array.Empty<int>()
            };
        }

        private static (int x, int y, int size) ComputeCenterSquareCrop(int width, int height)
        {
            var size = Mathf.Max(1, Mathf.Min(width, height));
            var x = (width - size) / 2;
            var y = (height - size) / 2;
            return (x, y, size);
        }

        /// <summary>
        /// Reads only the sub-rectangle needed for one grid cell instead of the whole photo,
        /// so a full-resolution camera image (tens of megapixels) never has to be materialized
        /// as a single giant <see cref="Color"/> array on the heap.
        /// </summary>
        private static Color SampleCellAverage(
            Texture2D texture,
            int cropX, int cropY, int cropSize,
            int cellX, int cellY, int gridSize)
        {
            var cellPixelSize = cropSize / (float)gridSize;
            var startX = cropX + Mathf.FloorToInt(cellX * cellPixelSize);
            var startY = cropY + Mathf.FloorToInt(cellY * cellPixelSize);
            var endX = cropX + Mathf.CeilToInt((cellX + 1) * cellPixelSize);
            var endY = cropY + Mathf.CeilToInt((cellY + 1) * cellPixelSize);

            startX = Mathf.Clamp(startX, 0, texture.width - 1);
            startY = Mathf.Clamp(startY, 0, texture.height - 1);
            endX = Mathf.Clamp(endX, startX + 1, texture.width);
            endY = Mathf.Clamp(endY, startY + 1, texture.height);

            var blockWidth = endX - startX;
            var blockHeight = endY - startY;
            var block = texture.GetPixels(startX, startY, blockWidth, blockHeight);

            if (block.Length == 0)
            {
                return new Color(0f, 0f, 0f, 0f);
            }

            float r = 0f, g = 0f, b = 0f, a = 0f;
            for (var i = 0; i < block.Length; i++)
            {
                var pixel = block[i];
                r += pixel.r;
                g += pixel.g;
                b += pixel.b;
                a += pixel.a;
            }

            var count = block.Length;
            return new Color(r / count, g / count, b / count, a / count);
        }
    }
}
