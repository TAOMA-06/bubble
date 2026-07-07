using System;
using System.IO;
using System.Runtime.InteropServices;
using UnityEngine;

namespace BeadWorks.Services
{
    /// <summary>
    /// Cross-platform photo picker abstraction.
    /// - iOS device/simulator: native PHPickerViewController bridge (Assets/Plugins/iOS/BeadWorksPhotoPicker.mm).
    /// - Unity Editor: a local file dialog, for fast iteration without a device.
    /// - Other platforms: a procedural fallback texture (no bundled asset required).
    ///
    /// Must live on a GameObject named exactly <see cref="GameObjectName"/> so the native
    /// plugin can find it via UnitySendMessage.
    /// </summary>
    public class PhotoImportService : MonoBehaviour
    {
        public const string GameObjectName = "PhotoImportService";

#if UNITY_IOS && !UNITY_EDITOR
        [DllImport("__Internal")]
        private static extern void BeadWorks_PresentPhotoPicker(string gameObjectName);
#endif

        private Action<Texture2D> _onPicked;
        private Action<string> _onError;

        public bool IsPicking { get; private set; }

        public static PhotoImportService EnsureInstance(Transform parent)
        {
            var existing = parent.Find(GameObjectName);
            if (existing != null)
            {
                var existingComponent = existing.GetComponent<PhotoImportService>();
                if (existingComponent != null)
                {
                    return existingComponent;
                }
            }

            var go = new GameObject(GameObjectName);
            go.transform.SetParent(parent, false);
            return go.AddComponent<PhotoImportService>();
        }

        /// <summary>
        /// Clears any pending pick state and callbacks, e.g. when the hosting screen is
        /// hidden. Guards against a stuck <see cref="IsPicking"/> flag (which would
        /// permanently block further picks) if a native/editor callback never arrives, and
        /// against acting on a stale callback for a pick the user has already navigated away
        /// from.
        /// </summary>
        public void CancelPick()
        {
            IsPicking = false;
            _onPicked = null;
            _onError = null;
        }

        public void RequestPickPhoto(Action<Texture2D> onPicked, Action<string> onError)
        {
            if (IsPicking)
            {
                onError?.Invoke("正在选择图片，请稍候");
                return;
            }

            _onPicked = onPicked;
            _onError = onError;
            IsPicking = true;

#if UNITY_IOS && !UNITY_EDITOR
            BeadWorks_PresentPhotoPicker(gameObject.name);
#elif UNITY_EDITOR
            PickFromEditorFileDialog();
#else
            PickFallbackTexture();
#endif
        }

        /// <summary>Invoked by the native iOS plugin via UnitySendMessage with a temp PNG file path.</summary>
        private void OnNativePhotoPicked(string pngFilePath)
        {
            IsPicking = false;
            LoadFromFile(pngFilePath);
        }

        /// <summary>Invoked by the native iOS plugin via UnitySendMessage when the user cancels.</summary>
        private void OnNativePhotoPickCancelled(string _)
        {
            IsPicking = false;
            _onError?.Invoke("已取消选择");
        }

        /// <summary>Invoked by the native iOS plugin via UnitySendMessage on picker/read failure.</summary>
        private void OnNativePhotoPickFailed(string message)
        {
            IsPicking = false;
            _onError?.Invoke(string.IsNullOrEmpty(message) ? "图片选择失败" : message);
        }

#if UNITY_EDITOR
        private void PickFromEditorFileDialog()
        {
            var path = UnityEditor.EditorUtility.OpenFilePanel("选择测试图片", string.Empty, "png,jpg,jpeg");
            IsPicking = false;
            if (string.IsNullOrEmpty(path))
            {
                _onError?.Invoke("已取消选择");
                return;
            }

            LoadFromFile(path);
        }
#endif

        private void PickFallbackTexture()
        {
            IsPicking = false;
            _onPicked?.Invoke(CreateFallbackTexture());
        }

        private void LoadFromFile(string path)
        {
            try
            {
                if (string.IsNullOrEmpty(path) || !File.Exists(path))
                {
                    _onError?.Invoke("找不到图片文件");
                    return;
                }

                var bytes = File.ReadAllBytes(path);
                var texture = new Texture2D(2, 2, TextureFormat.RGBA32, false);
                if (!texture.LoadImage(bytes))
                {
                    Destroy(texture);
                    _onError?.Invoke("图片解码失败");
                    return;
                }

                _onPicked?.Invoke(texture);
            }
            catch (Exception e)
            {
                Debug.LogError($"[PhotoImportService] Failed to load picked image: {e}");
                _onError?.Invoke("读取图片失败");
            }
        }

        private static Texture2D CreateFallbackTexture()
        {
            // Procedural placeholder used only where no picker/file dialog is available
            // (e.g. non-iOS standalone builds without a bundled test asset).
            const int size = 64;
            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false);
            var colorA = new Color(0.95f, 0.55f, 0.35f);
            var colorB = new Color(0.35f, 0.55f, 0.85f);
            for (var y = 0; y < size; y++)
            {
                for (var x = 0; x < size; x++)
                {
                    var t = (x + y) / (float)(size * 2);
                    texture.SetPixel(x, y, Color.Lerp(colorA, colorB, t));
                }
            }

            texture.Apply();
            return texture;
        }
    }
}
