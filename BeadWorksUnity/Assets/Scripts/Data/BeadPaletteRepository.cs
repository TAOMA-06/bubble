using System.Linq;
using UnityEngine;

namespace BeadWorks.Data
{
    /// <summary>
    /// Loads bead color definitions from Resources or a TextAsset.
    /// </summary>
    public class BeadPaletteRepository
    {
        public const int DefaultColorCount = 8;

        private BeadPaletteJson _palette;

        public BeadColorData[] Colors => _palette?.colors ?? System.Array.Empty<BeadColorData>();

        public BeadColorData[] BaseColors
        {
            get
            {
                var colors = Colors;
                if (colors.Length <= DefaultColorCount)
                {
                    return colors;
                }

                var subset = new BeadColorData[DefaultColorCount];
                for (var i = 0; i < DefaultColorCount; i++)
                {
                    subset[i] = colors[i];
                }

                return subset;
            }
        }

        public void Load(TextAsset paletteJson)
        {
            if (paletteJson == null)
            {
                Debug.LogWarning("[BeadPaletteRepository] No palette asset assigned; using fallback colors.");
                _palette = CreateFallbackPalette();
                return;
            }

            _palette = JsonUtility.FromJson<BeadPaletteJson>(paletteJson.text);
            if (_palette?.colors == null || _palette.colors.Length == 0)
            {
                Debug.LogWarning("[BeadPaletteRepository] Palette JSON was empty; using fallback colors.");
                _palette = CreateFallbackPalette();
            }
        }

        public BeadColorData GetById(int id)
        {
            return Colors.FirstOrDefault(c => c.id == id) ?? Colors.FirstOrDefault();
        }

        /// <summary>
        /// Returns the palette color closest to <paramref name="target"/> by RGB distance.
        /// Used by <see cref="PhotoToPatternConverter"/> to quantize imported photos onto
        /// the existing bead palette (no palette expansion).
        /// </summary>
        public BeadColorData FindNearestColor(Color target)
        {
            var colors = Colors;
            if (colors.Length == 0)
            {
                return null;
            }

            var closest = colors[0];
            var closestDistance = ColorDistanceSquared(target, closest.Color);
            for (var i = 1; i < colors.Length; i++)
            {
                var distance = ColorDistanceSquared(target, colors[i].Color);
                if (distance < closestDistance)
                {
                    closestDistance = distance;
                    closest = colors[i];
                }
            }

            return closest;
        }

        private static float ColorDistanceSquared(Color a, Color b)
        {
            var dr = a.r - b.r;
            var dg = a.g - b.g;
            var db = a.b - b.b;
            return (dr * dr) + (dg * dg) + (db * db);
        }

        private static BeadPaletteJson CreateFallbackPalette()
        {
            return new BeadPaletteJson
            {
                colors = new[]
                {
                    new BeadColorData { id = 0, displayName = "Black", hex = "#1A1A1A", roughness = 0.42f, rarity = "common" },
                    new BeadColorData { id = 1, displayName = "White", hex = "#F5F5F5", roughness = 0.28f, rarity = "common" },
                    new BeadColorData { id = 2, displayName = "Red", hex = "#E53935", roughness = 0.35f, rarity = "common" },
                    new BeadColorData { id = 3, displayName = "Blue", hex = "#1E88E5", roughness = 0.33f, rarity = "common" },
                    new BeadColorData { id = 4, displayName = "Yellow", hex = "#FDD835", roughness = 0.30f, rarity = "common" },
                    new BeadColorData { id = 5, displayName = "Green", hex = "#43A047", roughness = 0.34f, rarity = "common" },
                    new BeadColorData { id = 6, displayName = "Orange", hex = "#FB8C00", roughness = 0.32f, rarity = "common" },
                    new BeadColorData { id = 7, displayName = "Purple", hex = "#8E24AA", roughness = 0.36f, rarity = "common" }
                }
            };
        }
    }
}
