using BeadWorks.Data;
using NUnit.Framework;
using UnityEngine;

namespace BeadWorks.Tests.Editor
{
    public class BeadPaletteRepositoryTests
    {
        private static BeadPaletteRepository CreatePalette()
        {
            var palette = new BeadPaletteRepository();
            palette.Load(null); // no TextAsset -> falls back to the built-in 8-color palette
            return palette;
        }

        [Test]
        public void FindNearestColor_ReturnsExactMatchWhenPresent()
        {
            var palette = CreatePalette();
            var target = palette.Colors[0];

            var nearest = palette.FindNearestColor(target.Color);

            Assert.AreEqual(target.id, nearest.id);
        }

        [Test]
        public void FindNearestColor_ReturnsClosestByRgbDistance()
        {
            var palette = CreatePalette();
            var red = palette.GetById(2); // fallback palette id 2 == Red (#E53935)
            var nudged = new Color(
                Mathf.Clamp01(red.Color.r - 0.02f),
                Mathf.Clamp01(red.Color.g + 0.01f),
                red.Color.b,
                1f);

            var nearest = palette.FindNearestColor(nudged);

            Assert.AreEqual(red.id, nearest.id);
        }

        [Test]
        public void FindNearestColor_EmptyPalette_ReturnsNull()
        {
            var palette = new BeadPaletteRepository();

            var nearest = palette.FindNearestColor(Color.white);

            Assert.IsNull(nearest);
        }
    }
}
