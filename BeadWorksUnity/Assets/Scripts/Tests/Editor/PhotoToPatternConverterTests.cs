using System;
using System.Collections.Generic;
using BeadWorks.Data;
using NUnit.Framework;
using UnityEngine;

namespace BeadWorks.Tests.Editor
{
    public class PhotoToPatternConverterTests
    {
        private static BeadPaletteRepository CreatePalette()
        {
            var palette = new BeadPaletteRepository();
            palette.Load(null); // no TextAsset -> falls back to the built-in 8-color palette
            return palette;
        }

        private static Texture2D CreateSolidTexture(int width, int height, Color color)
        {
            var texture = new Texture2D(width, height, TextureFormat.RGBA32, false);
            var pixels = new Color[width * height];
            for (var i = 0; i < pixels.Length; i++)
            {
                pixels[i] = color;
            }

            texture.SetPixels(pixels);
            texture.Apply();
            return texture;
        }

        [Test]
        public void Convert_ProducesCellsMatchingGridArea()
        {
            var palette = CreatePalette();
            var texture = CreateSolidTexture(64, 64, Color.red);

            var pattern = PhotoToPatternConverter.Convert(texture, palette, 16);

            Assert.AreEqual(16 * 16, pattern.cells.Length);
            Assert.AreEqual(16, pattern.width);
            Assert.AreEqual(16, pattern.height);

            UnityEngine.Object.DestroyImmediate(texture);
        }

        [Test]
        public void Convert_CellsAreValidPaletteIdsOrEmpty()
        {
            var palette = CreatePalette();
            var texture = CreateSolidTexture(40, 40, new Color(0.9f, 0.2f, 0.2f));

            var pattern = PhotoToPatternConverter.Convert(texture, palette, 12);

            var validIds = new HashSet<int>();
            foreach (var color in palette.Colors)
            {
                validIds.Add(color.id);
            }

            foreach (var cell in pattern.cells)
            {
                Assert.IsTrue(cell == -1 || validIds.Contains(cell), $"Unexpected cell value {cell}");
            }

            UnityEngine.Object.DestroyImmediate(texture);
        }

        [Test]
        public void Convert_TransparentTexture_ProducesAllEmptyCells()
        {
            var palette = CreatePalette();
            var texture = CreateSolidTexture(20, 20, new Color(1f, 1f, 1f, 0f));

            var pattern = PhotoToPatternConverter.Convert(texture, palette, 8);

            foreach (var cell in pattern.cells)
            {
                Assert.AreEqual(-1, cell);
            }

            UnityEngine.Object.DestroyImmediate(texture);
        }

        [Test]
        public void Convert_OnePixelTexture_DoesNotThrow()
        {
            var palette = CreatePalette();
            var texture = CreateSolidTexture(1, 1, Color.blue);

            BeadPatternData pattern = null;
            Assert.DoesNotThrow(() => pattern = PhotoToPatternConverter.Convert(texture, palette, 8));
            Assert.AreEqual(8 * 8, pattern.cells.Length);

            UnityEngine.Object.DestroyImmediate(texture);
        }

        [Test]
        public void Convert_NonSquareTexture_DoesNotThrow()
        {
            var palette = CreatePalette();
            var texture = CreateSolidTexture(50, 20, Color.green);

            Assert.DoesNotThrow(() => PhotoToPatternConverter.Convert(texture, palette, 10));

            UnityEngine.Object.DestroyImmediate(texture);
        }

        [Test]
        public void Convert_NullSource_Throws()
        {
            var palette = CreatePalette();
            Assert.Throws<ArgumentNullException>(() => PhotoToPatternConverter.Convert(null, palette, 8));
        }

        [Test]
        public void Convert_EmptyPalette_Throws()
        {
            var palette = new BeadPaletteRepository();
            var texture = CreateSolidTexture(4, 4, Color.white);

            Assert.Throws<ArgumentException>(() => PhotoToPatternConverter.Convert(texture, palette, 4));

            UnityEngine.Object.DestroyImmediate(texture);
        }
    }
}
