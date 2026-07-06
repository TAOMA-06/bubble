using System.Collections.Generic;
using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Presentation
{
    /// <summary>
    /// Semi-transparent guide overlay on the pegboard for pattern replication.
    /// </summary>
    public class PatternGuidePresenter : MonoBehaviour
    {
        [SerializeField] private Color _guideTint = new(1f, 1f, 1f, 0.35f);
        [SerializeField] private Color _errorTint = new(1f, 0.2f, 0.2f, 0.55f);
        [SerializeField] private Color _missingTint = new(1f, 0.85f, 0.2f, 0.4f);

        private Transform _guideRoot;
        private Transform _errorRoot;
        private readonly Dictionary<Vector2Int, GameObject> _guideCells = new();
        private readonly Dictionary<Vector2Int, GameObject> _errorMarkers = new();
        private BeadPatternData _pattern;
        private BeadPaletteRepository _palette;
        private float _cellSize;
        private int _gridSize;
        private bool _guideVisible = true;
        private bool _errorsVisible;

        public bool GuideVisible => _guideVisible;
        public bool ErrorsVisible => _errorsVisible;

        public void Build(
            BeadPatternData pattern,
            BeadPaletteRepository palette,
            Transform pegboardRoot,
            float cellSize,
            int gridSize)
        {
            Clear();
            _pattern = pattern;
            _palette = palette;
            _cellSize = cellSize;
            _gridSize = gridSize;

            if (pattern == null)
            {
                return;
            }

            _guideRoot = new GameObject("PatternGuide").transform;
            _guideRoot.SetParent(pegboardRoot, false);

            _errorRoot = new GameObject("PatternErrors").transform;
            _errorRoot.SetParent(pegboardRoot, false);

            for (var y = 0; y < pattern.height; y++)
            {
                for (var x = 0; x < pattern.width; x++)
                {
                    var colorId = pattern.GetCell(x, y);
                    if (colorId < 0)
                    {
                        continue;
                    }

                    var color = palette?.GetById(colorId);
                    var tint = color != null
                        ? new Color(color.Color.r, color.Color.g, color.Color.b, _guideTint.a)
                        : _guideTint;

                    var cell = new Vector2Int(x, y);
                    var quad = CreateQuad($"Guide_{x}_{y}", _guideRoot, CellToLocal(x, y), tint);
                    _guideCells[cell] = quad;
                }
            }

            SetGuideVisible(true);
            SetErrorsVisible(false);
        }

        public void SetGuideVisible(bool visible)
        {
            _guideVisible = visible;
            if (_guideRoot != null)
            {
                _guideRoot.gameObject.SetActive(visible);
            }
        }

        public void SetErrorsVisible(bool visible)
        {
            _errorsVisible = visible;
            if (_errorRoot != null)
            {
                _errorRoot.gameObject.SetActive(visible);
            }
        }

        public void UpdateErrorMarkers(List<Vector2Int> wrongCells, List<Vector2Int> missingCells)
        {
            ClearErrorMarkers();

            if (!_errorsVisible || _errorRoot == null)
            {
                return;
            }

            if (wrongCells != null)
            {
                foreach (var cell in wrongCells)
                {
                    var quad = CreateQuad($"Err_{cell.x}_{cell.y}", _errorRoot, CellToLocal(cell.x, cell.y), _errorTint);
                    _errorMarkers[cell] = quad;
                }
            }

            if (missingCells != null)
            {
                foreach (var cell in missingCells)
                {
                    if (_errorMarkers.ContainsKey(cell))
                    {
                        continue;
                    }

                    var quad = CreateQuad($"Miss_{cell.x}_{cell.y}", _errorRoot, CellToLocal(cell.x, cell.y), _missingTint);
                    _errorMarkers[cell] = quad;
                }
            }
        }

        public void Clear()
        {
            ClearErrorMarkers();
            _guideCells.Clear();

            if (_guideRoot != null)
            {
                Destroy(_guideRoot.gameObject);
                _guideRoot = null;
            }

            if (_errorRoot != null)
            {
                Destroy(_errorRoot.gameObject);
                _errorRoot = null;
            }

            _pattern = null;
        }

        private void ClearErrorMarkers()
        {
            foreach (var marker in _errorMarkers.Values)
            {
                if (marker != null)
                {
                    Destroy(marker);
                }
            }

            _errorMarkers.Clear();
        }

        private Vector3 CellToLocal(int x, int y)
        {
            var offsetX = (x * _cellSize) - ((_gridSize - 1) * _cellSize * 0.5f);
            var offsetY = (y * _cellSize) - ((_gridSize - 1) * _cellSize * 0.5f);
            return new Vector3(offsetX, offsetY, 0.02f);
        }

        private GameObject CreateQuad(string name, Transform parent, Vector3 localPos, Color color)
        {
            var quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            quad.name = name;
            quad.transform.SetParent(parent, false);
            quad.transform.localPosition = localPos;
            quad.transform.localScale = Vector3.one * (_cellSize * 0.85f);

            var renderer = quad.GetComponent<MeshRenderer>();
            var shader = Shader.Find("Universal Render Pipeline/Unlit");
            var mat = shader != null ? new Material(shader) : new Material(Shader.Find("Sprites/Default"));
            mat.color = color;
            renderer.sharedMaterial = mat;

            Destroy(quad.GetComponent<Collider>());
            return quad;
        }
    }
}
