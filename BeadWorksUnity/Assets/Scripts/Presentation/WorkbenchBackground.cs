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
            renderer.sharedMaterial = material;

            var collider = surfaceObject.GetComponent<Collider>();
            if (collider != null)
            {
                Destroy(collider);
            }

            _surface = surfaceObject.transform;
        }
    }
}
