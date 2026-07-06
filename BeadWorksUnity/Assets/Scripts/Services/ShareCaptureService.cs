using System;
using System.IO;
using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Services
{
    /// <summary>
    /// Renders a high-resolution share image with work metadata and watermark.
    /// </summary>
    public class ShareCaptureService
    {
        private const int ShareWidth = 1080;
        private const int ShareHeight = 1920;
        private const string Watermark = "BeadWorks";

        public string LastSavedPath { get; private set; }

        public byte[] CaptureShareImage(
            Camera sourceCamera,
            Transform workTarget,
            string title,
            int beadCount,
            DateTime completedAt,
            FinishedProductType productType)
        {
            var rt = new RenderTexture(ShareWidth, ShareHeight, 24);
            var captureCam = CreateCaptureCamera(sourceCamera, workTarget, rt);

            var previousActive = RenderTexture.active;
            RenderTexture.active = rt;
            var workTexture = new Texture2D(ShareWidth, ShareHeight, TextureFormat.RGB24, false);
            captureCam.Render();
            workTexture.ReadPixels(new Rect(0, 0, ShareWidth, ShareHeight), 0, 0);
            workTexture.Apply();
            RenderTexture.active = previousActive;

            var final = ComposeShareCard(workTexture, title, beadCount, completedAt, productType);

            UnityEngine.Object.Destroy(captureCam.gameObject);
            rt.Release();
            UnityEngine.Object.Destroy(rt);
            UnityEngine.Object.Destroy(workTexture);

            return final.EncodeToPNG();
        }

        public string SaveToLocal(byte[] pngBytes, string fileName = null)
        {
            var dir = Path.Combine(Application.persistentDataPath, "shares");
            Directory.CreateDirectory(dir);
            fileName ??= $"share_{DateTime.UtcNow:yyyyMMdd_HHmmss}.png";
            var path = Path.Combine(dir, fileName);
            File.WriteAllBytes(path, pngBytes);
            LastSavedPath = path;
            Debug.Log($"[ShareCapture] Saved share image to {path}");
            return path;
        }

        public void ShareNative(byte[] pngBytes, string title)
        {
            var path = SaveToLocal(pngBytes);
#if UNITY_IOS || UNITY_ANDROID
            // Native share via file path — no SDK required for first version.
            Debug.Log($"[ShareCapture] Ready for native share: {path}");
#else
            Debug.Log($"[ShareCapture] Editor: image saved to {path}");
#endif
        }

        private static Camera CreateCaptureCamera(Camera sourceCamera, Transform workTarget, RenderTexture rt)
        {
            var camGo = new GameObject("ShareCaptureCamera");
            var cam = camGo.AddComponent<Camera>();
            cam.CopyFrom(sourceCamera);
            cam.targetTexture = rt;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.95f, 0.94f, 0.92f);

            if (workTarget != null)
            {
                var pos = workTarget.position;
                cam.transform.position = new Vector3(pos.x, pos.y, pos.z - 8f);
                cam.transform.LookAt(workTarget);
            }

            cam.orthographicSize = sourceCamera != null ? sourceCamera.orthographicSize * 0.85f : 5f;
            return cam;
        }

        private static Texture2D ComposeShareCard(
            Texture2D workShot,
            string title,
            int beadCount,
            DateTime completedAt,
            FinishedProductType productType)
        {
            var card = new Texture2D(ShareWidth, ShareHeight, TextureFormat.RGB24, false);
            var bg = new Color(0.97f, 0.96f, 0.94f);
            var pixels = new Color[ShareWidth * ShareHeight];
            for (var i = 0; i < pixels.Length; i++)
            {
                pixels[i] = bg;
            }

            card.SetPixels(pixels);

            var workAreaH = (int)(ShareHeight * 0.55f);
            var workAreaW = ShareWidth - 80;
            BlitCentered(card, workShot, 40, (int)(ShareHeight * 0.32f), workAreaW, workAreaH);

            DrawTextBanner(card, title ?? "拼豆作品", 120, ShareHeight - 180, 36);
            DrawTextBanner(card, $"用豆 {beadCount} 颗 · {productType.DisplayName()}", 120, ShareHeight - 240, 24);
            DrawTextBanner(card, completedAt.ToLocalTime().ToString("yyyy-MM-dd HH:mm"), 120, ShareHeight - 290, 22);
            DrawTextBanner(card, Watermark, ShareWidth - 280, 60, 20);

            card.Apply();
            return card;
        }

        private static void BlitCentered(Texture2D dest, Texture2D src, int x, int y, int maxW, int maxH)
        {
            var scale = Mathf.Min((float)maxW / src.width, (float)maxH / src.height);
            var w = Mathf.RoundToInt(src.width * scale);
            var h = Mathf.RoundToInt(src.height * scale);
            var offsetX = x + (maxW - w) / 2;
            var offsetY = y + (maxH - h) / 2;

            var resized = ScaleTexture(src, w, h);
            var destPixels = dest.GetPixels();
            var srcPixels = resized.GetPixels();

            for (var sy = 0; sy < h; sy++)
            {
                for (var sx = 0; sx < w; sx++)
                {
                    var dx = offsetX + sx;
                    var dy = offsetY + sy;
                    if (dx < 0 || dy < 0 || dx >= dest.width || dy >= dest.height)
                    {
                        continue;
                    }

                    destPixels[(dy * dest.width) + dx] = srcPixels[(sy * w) + sx];
                }
            }

            dest.SetPixels(destPixels);
            UnityEngine.Object.Destroy(resized);
        }

        private static Texture2D ScaleTexture(Texture2D src, int w, int h)
        {
            var rt = RenderTexture.GetTemporary(w, h);
            Graphics.Blit(src, rt);
            var prev = RenderTexture.active;
            RenderTexture.active = rt;
            var result = new Texture2D(w, h, TextureFormat.RGB24, false);
            result.ReadPixels(new Rect(0, 0, w, h), 0, 0);
            result.Apply();
            RenderTexture.active = prev;
            RenderTexture.ReleaseTemporary(rt);
            return result;
        }

        private static void DrawTextBanner(Texture2D tex, string text, int x, int y, int size)
        {
            // Simple pixel-font style banner using filled rectangles per character block.
            var color = new Color(0.15f, 0.16f, 0.18f);
            var charW = size / 2;
            var charH = size;
            for (var i = 0; i < text.Length; i++)
            {
                if (text[i] == ' ')
                {
                    continue;
                }

                var cx = x + (i * charW);
                FillRect(tex, cx, y, charW - 2, charH, color);
            }
        }

        private static void FillRect(Texture2D tex, int x, int y, int w, int h, Color color)
        {
            for (var py = y; py < y + h && py < tex.height; py++)
            {
                for (var px = x; px < x + w && px < tex.width; px++)
                {
                    if (px >= 0 && py >= 0)
                    {
                        tex.SetPixel(px, py, color);
                    }
                }
            }
        }
    }
}
