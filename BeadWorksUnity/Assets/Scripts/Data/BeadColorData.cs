using System;
using UnityEngine;

namespace BeadWorks.Data
{
    [Serializable]
    public class BeadColorData
    {
        public int id;
        public string displayName;
        public string hex = "#FFFFFF";
        public float roughness = 0.35f;
        public string rarity = "common";

        public Color Color
        {
            get
            {
                if (ColorUtility.TryParseHtmlString(hex, out var color))
                {
                    return color;
                }

                return Color.magenta;
            }
        }

        public float Smoothness => Mathf.Clamp01(1f - roughness);
    }

    [Serializable]
    public class BeadPaletteJson
    {
        public BeadColorData[] colors = Array.Empty<BeadColorData>();
    }
}
