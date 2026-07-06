using System.Collections.Generic;
using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Workshop
{
    /// <summary>
    /// Compares placed beads against a target pattern for guide error hints.
    /// </summary>
    public static class PatternMatcher
    {
        public struct MatchStats
        {
            public int requiredCells;
            public int correctCells;
            public int wrongCells;
            public int missingCells;
            public int extraCells;
            public float completion;

            public string Summary =>
                $"完成度 {Mathf.RoundToInt(completion * 100f)}% | 正确 {correctCells} 错误 {wrongCells} 缺失 {missingCells}";
        }

        public static MatchStats Evaluate(PegboardGrid grid, BeadPatternData pattern)
        {
            var stats = new MatchStats();
            if (grid == null || pattern == null)
            {
                stats.completion = 1f;
                return stats;
            }

            var wrongCells = new List<Vector2Int>();
            var missingCells = new List<Vector2Int>();

            for (var y = 0; y < pattern.height; y++)
            {
                for (var x = 0; x < pattern.width; x++)
                {
                    var expected = pattern.GetCell(x, y);
                    var placed = grid.GetBeadAt(new Vector2Int(x, y));

                    if (expected < 0)
                    {
                        if (placed.HasValue)
                        {
                            stats.extraCells++;
                        }

                        continue;
                    }

                    stats.requiredCells++;

                    if (!placed.HasValue)
                    {
                        stats.missingCells++;
                        missingCells.Add(new Vector2Int(x, y));
                        continue;
                    }

                    if (placed.Value.color.id == expected)
                    {
                        stats.correctCells++;
                    }
                    else
                    {
                        stats.wrongCells++;
                        wrongCells.Add(new Vector2Int(x, y));
                    }
                }
            }

            stats.completion = stats.requiredCells > 0
                ? (float)stats.correctCells / stats.requiredCells
                : 1f;

            return stats;
        }

        public static void CollectErrorCells(
            PegboardGrid grid,
            BeadPatternData pattern,
            List<Vector2Int> wrongCells,
            List<Vector2Int> missingCells)
        {
            wrongCells?.Clear();
            missingCells?.Clear();

            if (grid == null || pattern == null)
            {
                return;
            }

            for (var y = 0; y < pattern.height; y++)
            {
                for (var x = 0; x < pattern.width; x++)
                {
                    var expected = pattern.GetCell(x, y);
                    if (expected < 0)
                    {
                        continue;
                    }

                    var cell = new Vector2Int(x, y);
                    var placed = grid.GetBeadAt(cell);
                    if (!placed.HasValue)
                    {
                        missingCells?.Add(cell);
                    }
                    else if (placed.Value.color.id != expected)
                    {
                        wrongCells?.Add(cell);
                    }
                }
            }
        }
    }
}
