using System.Collections.Generic;
using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Presentation
{
    /// <summary>
    /// Morphs bead visuals based on melt, flatten, burn, and neighbor fusion.
    /// </summary>
    public class BeadVisualController : MonoBehaviour
    {
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int SmoothnessId = Shader.PropertyToID("_Smoothness");
        private const int MeshMorphSteps = 24;
        private static readonly Dictionary<int, Mesh> MeshCache = new();

        [SerializeField] private int _ringSegments = 36;

        private MeshFilter _meshFilter;
        private MeshRenderer _meshRenderer;
        private Material _material;
        private Color _baseColor;
        private float _baseSmoothness;
        private float _cellScale;
        private Transform _bridgeRoot;
        private GameObject _bridgeX;
        private GameObject _bridgeY;
        private int _lastMeshKey = -1;

        public void Initialize(BeadInstance instance, Material material, float cellScale)
        {
            _cellScale = cellScale;
            _meshFilter = GetComponent<MeshFilter>();
            _meshRenderer = GetComponent<MeshRenderer>();
            _material = material;
            _baseColor = instance.color.Color;
            _baseSmoothness = instance.color.Smoothness;

            _meshFilter.sharedMesh = GetCachedRingMesh(_ringSegments, 0, 0);

            _bridgeRoot = new GameObject("FusionBridges").transform;
            _bridgeRoot.SetParent(transform, false);
            _bridgeRoot.localPosition = Vector3.zero;

            ApplyVisual(instance, 0f);
        }

        public void ApplyVisual(BeadInstance instance, float neighborBondMax)
        {
            if (_meshFilter == null)
            {
                return;
            }

            var melt = Mathf.Clamp01(instance.meltAmount);
            var flatten = Mathf.Clamp01(instance.flattenAmount);
            var burn = Mathf.Clamp01(instance.burnAmount);

            var meltStep = Mathf.RoundToInt(melt * MeshMorphSteps);
            var flattenStep = Mathf.RoundToInt(flatten * MeshMorphSteps);
            var meshKey = MeshKey(_ringSegments, meltStep, flattenStep);

            if (_lastMeshKey != meshKey)
            {
                _meshFilter.sharedMesh = GetCachedRingMesh(_ringSegments, meltStep, flattenStep);
                _lastMeshKey = meshKey;
            }

            var spread = 1f + (melt * 0.08f);
            var squash = 1f - (flatten * 0.55f);
            transform.localScale = new Vector3(_cellScale * spread, _cellScale * spread, _cellScale * squash);

            if (_material != null)
            {
                var smoothness = Mathf.Clamp01(_baseSmoothness + (melt * 0.38f) + (flatten * 0.12f));
                _material.SetFloat(SmoothnessId, smoothness);

                var burnTint = Color.Lerp(_baseColor, new Color(0.45f, 0.28f, 0.08f), burn * 0.75f);
                burnTint = Color.Lerp(burnTint, _baseColor * 0.55f, burn * 0.35f);
                _material.SetColor(BaseColorId, burnTint);
            }

            UpdateBridge(ref _bridgeX, Vector3.right, neighborBondMax, melt);
            UpdateBridge(ref _bridgeY, Vector3.up, neighborBondMax, melt);
        }

        private void UpdateBridge(ref GameObject bridge, Vector3 direction, float bond, float melt)
        {
            if (bond < 0.25f)
            {
                if (bridge != null)
                {
                    bridge.SetActive(false);
                }

                return;
            }

            if (bridge == null)
            {
                bridge = new GameObject($"Bridge_{direction}");
                bridge.transform.SetParent(_bridgeRoot, false);
                var filter = bridge.AddComponent<MeshFilter>();
                filter.sharedMesh = BeadMeshBuilder.BuildFusionBridge(0.18f, 0.42f);
                var renderer = bridge.AddComponent<MeshRenderer>();
                renderer.sharedMaterial = _material;
                renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            }

            bridge.SetActive(true);
            bridge.transform.localPosition = direction * 0.44f;
            bridge.transform.localRotation = direction.x > 0f
                ? Quaternion.identity
                : Quaternion.Euler(0f, 0f, 90f);

            var alpha = Mathf.Clamp01((bond - 0.25f) / 0.75f);
            bridge.transform.localScale = new Vector3(1f + melt * 0.35f, alpha, 1f);
        }

        private static Mesh GetCachedRingMesh(int segments, int meltStep, int flattenStep)
        {
            var key = MeshKey(segments, meltStep, flattenStep);
            if (MeshCache.TryGetValue(key, out var mesh))
            {
                return mesh;
            }

            var melt = meltStep / (float)MeshMorphSteps;
            var flatten = flattenStep / (float)MeshMorphSteps;
            var outerRadius = Mathf.Lerp(BeadMeshBuilder.BaseOuterRadius, 0.49f, melt);
            var innerRadius = Mathf.Lerp(BeadMeshBuilder.BaseInnerRadius, outerRadius * 0.82f, flatten);
            var halfThickness = Mathf.Lerp(BeadMeshBuilder.BaseHalfThickness, 0.012f, flatten);

            mesh = BeadMeshBuilder.BuildRingMesh(segments, outerRadius, innerRadius, halfThickness);
            MeshCache[key] = mesh;
            return mesh;
        }

        private static int MeshKey(int segments, int meltStep, int flattenStep)
        {
            return (segments << 16) ^ (meltStep << 8) ^ flattenStep;
        }
    }
}
