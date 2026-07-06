using System;
using UnityEngine;

namespace BeadWorks.Data
{
    [Serializable]
    public class BeadPatternData
    {
        public string id;
        public string title;
        public int width;
        public int height;
        public BeadSizeType beadSize = BeadSizeType.Standard5mm;
        public int[] cells = Array.Empty<int>();
        public int[] palette = Array.Empty<int>();

        public int GetCell(int x, int y)
        {
            if (x < 0 || y < 0 || x >= width || y >= height)
            {
                return -1;
            }

            var index = (y * width) + x;
            return index >= 0 && index < cells.Length ? cells[index] : -1;
        }
    }
}
