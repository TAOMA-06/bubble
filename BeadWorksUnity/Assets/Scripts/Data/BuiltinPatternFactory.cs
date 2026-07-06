using System;
using System.Collections.Generic;

namespace BeadWorks.Data
{
    /// <summary>
    /// Generates five original 16×16 bead patterns for the vertical slice.
    /// </summary>
    public static class BuiltinPatternFactory
    {
        public const int PatternSize = 16;

        public static BeadPatternData[] CreateAll()
        {
            return new[]
            {
                CreateHeart(),
                CreateStar(),
                CreateGuofengCloud(),
                CreateMilkTeaCup(),
                CreateSupportSign()
            };
        }

        public static BeadPatternData CreateHeart()
        {
            var cells = EmptyGrid();
            FillHeart(cells, 8, 10, 2);
            return Build("heart", "爱心", cells, new[] { 1, 2 });
        }

        public static BeadPatternData CreateStar()
        {
            var cells = FillAll(3);
            FillStar(cells, 8, 8, 6, 4);
            return Build("star", "星星", cells, new[] { 3, 4, 6 });
        }

        public static BeadPatternData CreateGuofengCloud()
        {
            var cells = FillAll(0);
            DrawCloudSwirl(cells, 8, 8, 2, 4, 1);
            return Build("guofeng_cloud", "国风云纹", cells, new[] { 0, 1, 2, 4 });
        }

        public static BeadPatternData CreateMilkTeaCup()
        {
            var cells = FillAll(1);
            DrawMilkTeaCup(cells);
            return Build("milk_tea_cup", "奶茶杯", cells, new[] { 0, 1, 6, 4 });
        }

        public static BeadPatternData CreateSupportSign()
        {
            var cells = FillAll(1);
            DrawSupportSign(cells);
            return Build("support_sign", "应援字牌", cells, new[] { 0, 1, 2, 4 });
        }

        private static BeadPatternData Build(string id, string title, int[] cells, int[] palette)
        {
            return new BeadPatternData
            {
                id = id,
                title = title,
                width = PatternSize,
                height = PatternSize,
                beadSize = BeadSizeType.Standard5mm,
                cells = cells,
                palette = palette
            };
        }

        private static int[] EmptyGrid()
        {
            var cells = new int[PatternSize * PatternSize];
            for (var i = 0; i < cells.Length; i++)
            {
                cells[i] = -1;
            }

            return cells;
        }

        private static int[] FillAll(int colorId)
        {
            var cells = new int[PatternSize * PatternSize];
            for (var i = 0; i < cells.Length; i++)
            {
                cells[i] = colorId;
            }

            return cells;
        }

        private static void Set(int[] cells, int x, int y, int color)
        {
            if (x < 0 || y < 0 || x >= PatternSize || y >= PatternSize)
            {
                return;
            }

            cells[(y * PatternSize) + x] = color;
        }

        private static void FillHeart(int[] cells, int cx, int cy, int color)
        {
            var offsets = new (int dx, int dy)[]
            {
                (0, 2), (-1, 1), (1, 1), (-2, 0), (2, 0),
                (-2, -1), (2, -1), (-1, -2), (1, -2), (0, -3),
                (-1, -3), (1, -3), (0, -4), (-1, -4), (1, -4),
                (0, -5), (-1, -5), (1, -5), (0, -6)
            };

            foreach (var (dx, dy) in offsets)
            {
                Set(cells, cx + dx, cy + dy, color);
            }

            for (var y = -7; y <= -2; y++)
            {
                for (var x = -3; x <= 3; x++)
                {
                    if (Math.Abs(x) + Math.Abs(y + 4) <= 4)
                    {
                        Set(cells, cx + x, cy + y, color);
                    }
                }
            }
        }

        private static void FillStar(int[] cells, int cx, int cy, int fillColor, int bgColor)
        {
            var points = new List<(int x, int y)>();
            for (var i = 0; i < 10; i++)
            {
                var angle = (i * 36f - 90f) * (float)(Math.PI / 180.0);
                var radius = i % 2 == 0 ? 6f : 2.8f;
                points.Add((
                    cx + (int)Math.Round(Math.Cos(angle) * radius),
                    cy + (int)Math.Round(Math.Sin(angle) * radius)));
            }

            for (var y = 0; y < PatternSize; y++)
            {
                for (var x = 0; x < PatternSize; x++)
                {
                    if (PointInPolygon(x, y, points))
                    {
                        Set(cells, x, y, fillColor);
                    }
                    else
                    {
                        Set(cells, x, y, bgColor);
                    }
                }
            }
        }

        private static bool PointInPolygon(int px, int py, List<(int x, int y)> polygon)
        {
            var inside = false;
            for (int i = 0, j = polygon.Count - 1; i < polygon.Count; j = i++)
            {
                var (xi, yi) = polygon[i];
                var (xj, yj) = polygon[j];
                if ((yi > py) != (yj > py) &&
                    px < ((xj - xi) * (py - yi) / (float)(yj - yi + 0.0001f)) + xi)
                {
                    inside = !inside;
                }
            }

            return inside;
        }

        private static void DrawCloudSwirl(int[] cells, int cx, int cy, int lineColor, int accentColor, int bgColor)
        {
            for (var y = 0; y < PatternSize; y++)
            {
                for (var x = 0; x < PatternSize; x++)
                {
                    Set(cells, x, y, bgColor);
                }
            }

            for (var t = 0; t < 360; t += 4)
            {
                var rad = t * (float)(Math.PI / 180.0);
                var radius = 1.5f + t * 0.018f;
                var px = cx + (int)Math.Round(Math.Cos(rad) * radius);
                var py = cy + (int)Math.Round(Math.Sin(rad) * radius);
                Set(cells, px, py, lineColor);
                Set(cells, px + 1, py, lineColor);
                if (t % 40 == 0)
                {
                    Set(cells, px, py, accentColor);
                }
            }

            DrawCloudBlob(cells, cx - 4, cy + 3, lineColor);
            DrawCloudBlob(cells, cx + 5, cy - 2, lineColor);
            DrawCloudBlob(cells, cx - 1, cy - 5, accentColor);
        }

        private static void DrawCloudBlob(int[] cells, int cx, int cy, int color)
        {
            for (var dy = -1; dy <= 1; dy++)
            {
                for (var dx = -2; dx <= 2; dx++)
                {
                    if (Math.Abs(dx) + Math.Abs(dy) <= 2)
                    {
                        Set(cells, cx + dx, cy + dy, color);
                    }
                }
            }
        }

        private static void DrawMilkTeaCup(int[] cells)
        {
            for (var y = 3; y <= 12; y++)
            {
                for (var x = 5; x <= 10; x++)
                {
                    Set(cells, x, y, 6);
                }
            }

            for (var x = 4; x <= 11; x++)
            {
                Set(cells, x, 3, 0);
                Set(cells, x, 12, 0);
            }

            for (var y = 3; y <= 12; y++)
            {
                Set(cells, 4, y, 0);
                Set(cells, 11, y, 0);
            }

            for (var y = 5; y <= 9; y++)
            {
                for (var x = 6; x <= 9; x++)
                {
                    Set(cells, x, y, 4);
                }
            }

            Set(cells, 12, 4, 0);
            Set(cells, 13, 3, 0);
            Set(cells, 14, 2, 0);
            Set(cells, 12, 5, 0);
            Set(cells, 13, 5, 0);

            for (var x = 5; x <= 10; x++)
            {
                Set(cells, x, 13, 0);
            }
        }

        private static void DrawSupportSign(int[] cells)
        {
            for (var y = 2; y <= 13; y++)
            {
                for (var x = 2; x <= 13; x++)
                {
                    Set(cells, x, y, 1);
                }
            }

            for (var y = 3; y <= 12; y++)
            {
                for (var x = 3; x <= 12; x++)
                {
                    Set(cells, x, y, 2);
                }
            }

            DrawBlockCharJia(cells, 4, 5);
            DrawBlockCharYou(cells, 9, 5);
        }

        private static void DrawBlockCharJia(int[] cells, int ox, int oy)
        {
            for (var x = 0; x < 3; x++)
            {
                Set(cells, ox + x, oy, 4);
                Set(cells, ox + x, oy + 4, 4);
            }

            for (var y = 0; y < 5; y++)
            {
                Set(cells, ox + 1, oy + y, 4);
            }
        }

        private static void DrawBlockCharYou(int[] cells, int ox, int oy)
        {
            for (var y = 0; y < 5; y++)
            {
                Set(cells, ox, oy + y, 4);
                Set(cells, ox + 2, oy + y, 4);
            }

            for (var x = 0; x < 3; x++)
            {
                Set(cells, ox + x, oy + 2, 4);
            }
        }
    }
}
