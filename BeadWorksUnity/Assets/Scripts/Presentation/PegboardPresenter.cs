using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Presentation
{
    /// <summary>
    /// Renders pegboard backing and peg holes. Bead visuals are owned by PegboardGrid + BeadFactory.
    /// </summary>
    public class PegboardPresenter : MonoBehaviour
    {
        [SerializeField] private Material _holeMaterial;
        [SerializeField] private Color _boardColor = new(0.94f, 0.84f, 0.67f);
        [SerializeField] private Color _holeColor = new(0.44f, 0.31f, 0.20f);

        private Transform _gridRoot;
        private int _gridSize;
        private float _cellSize;
        private Material _sharedHoleMaterial;

        public Transform GridOrigin => _gridRoot != null ? _gridRoot : transform;

        public void Build(int gridSize, BeadSizeType beadSize)
        {
            _gridSize = gridSize;
            _cellSize = beadSize.CellWorldSize();

            if (_gridRoot != null)
            {
                Destroy(_gridRoot.gameObject);
            }

            if (_sharedHoleMaterial != null)
            {
                Destroy(_sharedHoleMaterial);
                _sharedHoleMaterial = null;
            }

            _gridRoot = new GameObject("PegboardVisual").transform;
            _gridRoot.SetParent(transform, false);
            _gridRoot.localPosition = Vector3.zero;

            CreateBoardBacking(gridSize);
            CreateHoles(gridSize);
        }

        private void CreateBoardBacking(int gridSize)
        {
            var board = GameObject.CreatePrimitive(PrimitiveType.Quad);
            board.name = "PegboardBacking";
            board.transform.SetParent(_gridRoot, false);
            board.transform.localPosition = Vector3.zero;

            var size = gridSize * _cellSize;
            board.transform.localScale = new Vector3(size, size, 1f);

            var renderer = board.GetComponent<MeshRenderer>();
            var material = _holeMaterial != null
                ? new Material(_holeMaterial)
                : new Material(Shader.Find("Universal Render Pipeline/Lit"));
            material.color = _boardColor;
            renderer.sharedMaterial = material;

            Destroy(board.GetComponent<Collider>());
        }

        private void CreateHoles(int gridSize)
        {
            var holesRoot = new GameObject("Holes").transform;
            holesRoot.SetParent(_gridRoot, false);

            // One shared material for every hole quad: identical color/shading per hole, so
            // there is no need to clone a material per cell (matters a lot at 29x29-48x48+).
            var holeMaterial = _holeMaterial != null ? new Material(_holeMaterial) : new Material(Shader.Find("Universal Render Pipeline/Lit"));
            holeMaterial.color = _holeColor;
            _sharedHoleMaterial = holeMaterial;

            for (var y = 0; y < gridSize; y++)
            {
                for (var x = 0; x < gridSize; x++)
                {
                    var hole = GameObject.CreatePrimitive(PrimitiveType.Quad);
                    hole.name = $"Hole_{x}_{y}";
                    hole.transform.SetParent(holesRoot, false);

                    var center = CellToLocalCenter(x, y);
                    hole.transform.localPosition = new Vector3(center.x, center.y, -0.01f);
                    // Real pegboard holes are small points, not filled grid squares. Keeping
                    // these quads compact makes the board read as craft material instead of
                    // a checkerboard in iPhone portrait framing.
                    hole.transform.localScale = Vector3.one * (_cellSize * 0.28f);

                    hole.GetComponent<MeshRenderer>().sharedMaterial = holeMaterial;
                    Destroy(hole.GetComponent<Collider>());
                }
            }
        }

        private Vector2 CellToLocalCenter(int x, int y)
        {
            var offsetX = (x * _cellSize) - ((_gridSize - 1) * _cellSize * 0.5f);
            var offsetY = (y * _cellSize) - ((_gridSize - 1) * _cellSize * 0.5f);
            return new Vector2(offsetX, offsetY);
        }
    }
}
