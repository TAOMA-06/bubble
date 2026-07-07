using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Presentation
{
    /// <summary>
    /// Procedural pegboard background behind the bead grid.
    /// </summary>
    public class WorkbenchBackground : MonoBehaviour
    {
        [SerializeField] private Material _surfaceMaterial;
        [SerializeField] private Color _surfaceColor = new(0.93f, 0.91f, 0.86f);
        [SerializeField] private float _paddingCells = 2.5f;

        private Transform _surface;
        private static Texture2D _cachedWoodGrainTexture;

        public void BuildAround(Transform pegboardRoot, int gridSize)
        {
            if (_surface != null)
            {
                Destroy(_surface.gameObject);
            }

            var cellSize = BeadSizeType.Standard5mm.CellWorldSize();
            var boardSize = gridSize * cellSize;
            var totalSize = boardSize + _paddingCells * cellSize * 2f;

            var surfaceObject = GameObject.CreatePrimitive(PrimitiveType.Quad);
            surfaceObject.name = "WorkbenchSurface";
            surfaceObject.transform.SetParent(transform, false);
            surfaceObject.transform.position = pegboardRoot.position;
            surfaceObject.transform.localScale = new Vector3(totalSize, totalSize, 1f);

            var renderer = surfaceObject.GetComponent<MeshRenderer>();
            var material = _surfaceMaterial != null
                ? new Material(_surfaceMaterial)
                : new Material(Shader.Find("Universal Render Pipeline/Lit"));

            material.color = _surfaceColor;
            material.mainTexture = GetOrCreateWoodGrainTexture();
            var tiling = Mathf.Max(1f, totalSize / cellSize / 4f);
            material.mainTextureScale = new Vector2(tiling, tiling);
            renderer.sharedMaterial = material;

            var collider = surfaceObject.GetComponent<Collider>();
            if (collider != null)
            {
                Destroy(collider);
            }

            _surface = surfaceObject.transform;
        }

        /// <summary>
        /// Procedural warm wood-grain shading multiplier (bands + fine grain noise), tiled and
        /// tinted by <see cref="_surfaceColor"/> in the material. No external texture asset.
        /// </summary>
        private static Texture2D GetOrCreateWoodGrainTexture()
        {
            if (_cachedWoodGrainTexture != null)
            {
                return _cachedWoodGrainTexture;
            }

            const int size = 256;
            const float bandFrequency = 0.15f;
            const float grainFrequency = 0.06f;
            const float noiseOffset = 12.3f;

            var texture = new Texture2D(size, size, TextureFormat.RGBA32, false)
            {
                name = "BeadWorksWorkbenchWoodGrain",
                wrapMode = TextureWrapMode.Repeat,
                filterMode = FilterMode.Bilinear
            };

            for (var y = 0; y < size; y++)
            {
                for (var x = 0; x < size; x++)
                {
                    var band = Mathf.PerlinNoise(noiseOffset, y * bandFrequency);
                    var grain = Mathf.PerlinNoise(x * grainFrequency, (y * 0.01f) + noiseOffset);
                    var shade = Mathf.Lerp(0.82f, 1.08f, (band * 0.65f) + (grain * 0.35f));
                    texture.SetPixel(x, y, new Color(shade, shade, shade, 1f));
                }
            }

            texture.Apply();
            _cachedWoodGrainTexture = texture;
            return texture;
        }
    }
}
