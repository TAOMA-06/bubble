using System;
using System.Collections.Generic;
using BeadWorks.Data;
using BeadWorks.Presentation;
using UnityEngine;

namespace BeadWorks.Workshop
{
    /// <summary>
    /// Logical pegboard grid with strict cell occupancy and bead placement rules.
    /// </summary>
    public class PegboardGrid
    {
        private readonly Transform _origin;
        private readonly BeadInstance?[,] _cells;
        private readonly Dictionary<Vector2Int, BeadView> _beadViews = new();
        private readonly BeadFactory _beadFactory;
        private readonly Transform _beadsRoot;

        public int Width { get; }
        public int Height { get; }
        public float CellSize { get; }

        public PegboardGrid(
            Transform origin,
            int width,
            int height,
            float cellSize,
            BeadFactory beadFactory,
            Transform beadsRoot)
        {
            _origin = origin;
            Width = width;
            Height = height;
            CellSize = cellSize;
            _beadFactory = beadFactory;
            _beadsRoot = beadsRoot;
            _cells = new BeadInstance?[width, height];
        }

        public int PlacedBeadCount
        {
            get
            {
                var count = 0;
                ForEachBead((_, __) => count++);
                return count;
            }
        }

        public void ClearAll()
        {
            foreach (var view in _beadViews.Values)
            {
                if (view != null)
                {
                    UnityEngine.Object.Destroy(view.gameObject);
                }
            }

            _beadViews.Clear();

            for (var x = 0; x < Width; x++)
            {
                for (var y = 0; y < Height; y++)
                {
                    _cells[x, y] = null;
                }
            }
        }

        public void ForEachBead(Action<Vector2Int, BeadInstance> visitor)
        {
            for (var x = 0; x < Width; x++)
            {
                for (var y = 0; y < Height; y++)
                {
                    if (_cells[x, y] is { } bead)
                    {
                        visitor(new Vector2Int(x, y), bead);
                    }
                }
            }
        }

        public bool WorldToCell(Vector3 worldPosition, out Vector2Int cell)
        {
            var local = worldPosition - _origin.position;
            var x = Mathf.RoundToInt(local.x / CellSize);
            var y = Mathf.RoundToInt(local.y / CellSize);
            cell = new Vector2Int(x, y);
            return IsInside(cell);
        }

        public Vector3 CellToWorld(Vector2Int cell)
        {
            var local = new Vector3(cell.x * CellSize, cell.y * CellSize, -0.02f);
            return _origin.position + local;
        }

        public bool IsInside(Vector2Int cell)
        {
            return cell.x >= 0 && cell.y >= 0 && cell.x < Width && cell.y < Height;
        }

        public bool IsOccupied(Vector2Int cell)
        {
            return IsInside(cell) && _cells[cell.x, cell.y].HasValue;
        }

        public BeadInstance? GetBeadAt(Vector2Int cell)
        {
            if (!IsInside(cell))
            {
                return null;
            }

            return _cells[cell.x, cell.y];
        }

        public BeadView GetBeadView(Vector2Int cell)
        {
            return _beadViews.TryGetValue(cell, out var view) ? view : null;
        }

        public bool TryPlaceBead(Vector2Int cell, BeadInstance bead, out BeadView view)
        {
            view = null;

            if (!IsInside(cell) || IsOccupied(cell) || bead.color == null)
            {
                return false;
            }

            var placed = BeadInstance.CreatePlaced(cell, bead.color, bead.beadSize);
            _cells[cell.x, cell.y] = placed;

            var world = CellToWorld(cell);
            view = _beadFactory.CreateBead(placed, world, _beadsRoot);
            _beadViews[cell] = view;
            return true;
        }

        public void UpdateBead(Vector2Int cell, BeadInstance bead)
        {
            if (!IsInside(cell))
            {
                return;
            }

            _cells[cell.x, cell.y] = bead;

            if (_beadViews.TryGetValue(cell, out var view) && view != null)
            {
                view.SyncInstance(bead);
            }
        }

        public void ResetIroningState()
        {
            for (var x = 0; x < Width; x++)
            {
                for (var y = 0; y < Height; y++)
                {
                    if (_cells[x, y] is { } bead)
                    {
                        var reset = bead.ResetIroningState();
                        _cells[x, y] = reset;

                        if (_beadViews.TryGetValue(new Vector2Int(x, y), out var view) && view != null)
                        {
                            view.SyncInstance(reset);
                            view.VisualController?.ApplyVisual(reset, 0f);
                        }
                    }
                }
            }
        }

        public bool RemoveBead(Vector2Int cell)
        {
            if (!IsInside(cell) || !IsOccupied(cell))
            {
                return false;
            }

            _cells[cell.x, cell.y] = null;

            if (_beadViews.TryGetValue(cell, out var view) && view != null)
            {
                UnityEngine.Object.Destroy(view.gameObject);
            }

            _beadViews.Remove(cell);
            return true;
        }

        public Vector2Int FindNearestCell(Vector3 worldPosition)
        {
            var local = worldPosition - _origin.position;
            var x = Mathf.RoundToInt(local.x / CellSize);
            var y = Mathf.RoundToInt(local.y / CellSize);
            return new Vector2Int(x, y);
        }

        public float ComputePairBond(BeadInstance a, BeadInstance b)
        {
            return Mathf.Min(a.meltAmount, b.meltAmount) * 0.6f + ((a.meltAmount + b.meltAmount) * 0.5f) * 0.4f;
        }

        public int[] ExportCellColors()
        {
            var cells = new int[Width * Height];
            for (var y = 0; y < Height; y++)
            {
                for (var x = 0; x < Width; x++)
                {
                    var bead = _cells[x, y];
                    cells[(y * Width) + x] = bead.HasValue && bead.Value.color != null
                        ? bead.Value.color.id
                        : -1;
                }
            }

            return cells;
        }

        public void LoadFromCellColors(int[] cells, int width, int height, BeadPaletteRepository palette)
        {
            ClearAll();
            if (cells == null || palette == null)
            {
                return;
            }

            for (var y = 0; y < height && y < Height; y++)
            {
                for (var x = 0; x < width && x < Width; x++)
                {
                    var index = (y * width) + x;
                    if (index < 0 || index >= cells.Length)
                    {
                        continue;
                    }

                    var colorId = cells[index];
                    if (colorId < 0)
                    {
                        continue;
                    }

                    var color = palette.GetById(colorId);
                    if (color == null)
                    {
                        continue;
                    }

                    var cell = new Vector2Int(x, y);
                    TryPlaceBead(cell, BeadInstance.CreatePlaced(cell, color, BeadSizeType.Standard5mm), out _);
                }
            }
        }
    }
}
