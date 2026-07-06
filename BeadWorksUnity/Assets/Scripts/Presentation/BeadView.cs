using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Presentation
{
    /// <summary>
    /// Visual component for a single bead with placement bounce animation.
    /// </summary>
    public class BeadView : MonoBehaviour
    {
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

        [SerializeField] private float _bounceDuration = 0.22f;
        [SerializeField] private float _bounceScale = 1.18f;

        private Vector3 _restScale;
        private Coroutine _bounceRoutine;

        public BeadInstance Instance { get; private set; }
        public BeadVisualController VisualController { get; private set; }

        public void Initialize(BeadInstance instance, Material material, float cellScale)
        {
            Instance = instance;

            var renderer = GetComponent<MeshRenderer>();
            if (renderer != null && material != null)
            {
                renderer.sharedMaterial = material;
            }

            VisualController = GetComponent<BeadVisualController>();
            if (VisualController == null)
            {
                VisualController = gameObject.AddComponent<BeadVisualController>();
            }

            VisualController.Initialize(instance, material, cellScale);
            _restScale = transform.localScale;
        }

        public void SyncInstance(BeadInstance instance)
        {
            Instance = instance;
        }

        public void PlayPlaceBounce()
        {
            if (_bounceRoutine != null)
            {
                StopCoroutine(_bounceRoutine);
            }

            _bounceRoutine = StartCoroutine(BounceRoutine());
        }

        public void SetPreviewMode(bool isPreview)
        {
            var renderer = GetComponent<MeshRenderer>();
            if (renderer == null || renderer.sharedMaterial == null)
            {
                return;
            }

            var color = renderer.sharedMaterial.GetColor(BaseColorId);
            color.a = 1f;
            renderer.sharedMaterial.SetColor(BaseColorId, isPreview ? color * 0.55f : Instance.color.Color);
            transform.localScale = isPreview ? _restScale * 1.06f : _restScale;
        }

        private System.Collections.IEnumerator BounceRoutine()
        {
            var elapsed = 0f;
            while (elapsed < _bounceDuration)
            {
                elapsed += Time.deltaTime;
                var t = elapsed / _bounceDuration;
                var curve = Mathf.Sin(t * Mathf.PI);
                var scale = 1f + ((_bounceScale - 1f) * curve);
                transform.localScale = _restScale * scale;
                yield return null;
            }

            transform.localScale = _restScale;
            _restScale = transform.localScale;
            _bounceRoutine = null;
        }
    }
}
