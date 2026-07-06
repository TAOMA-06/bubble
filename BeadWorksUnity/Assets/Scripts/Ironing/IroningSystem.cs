using BeadWorks.Data;
using BeadWorks.Feedback;
using BeadWorks.Workshop;
using UnityEngine;

namespace BeadWorks.Ironing
{
    public struct IroningStats
    {
        public float averageMelt;
        public float averageBond;
        public float maxBurn;
        public float peakHeat;
        public float progress;
        public string riskMessage;
    }

    /// <summary>
    /// Simulates heat transfer, melting, flattening, burning, and neighbor bonding.
    /// </summary>
    public class IroningSystem
    {
        public const float MeltHeatThreshold = 0.42f;
        public const float BurnHeatThreshold = 0.82f;
        public const float PerfectMeltMin = 0.52f;
        public const float PerfectMeltMax = 0.88f;
        public const float PerfectBondMin = 0.42f;
        public const float OverBurnThreshold = 0.42f;

        private readonly PegboardGrid _grid;
        private readonly WorkshopFeedback _feedback;

        private float _peakHeat;

        public IroningSystem(PegboardGrid grid, WorkshopFeedback feedback)
        {
            _grid = grid;
            _feedback = feedback;
        }

        public void Reset()
        {
            _peakHeat = 0f;
            _grid.ResetIroningState();
        }

        public void Tick(
            Vector3 ironWorldPosition,
            float heatRadius,
            float ironPower,
            bool isIronActive,
            float moveSpeed,
            float deltaTime)
        {
            if (_grid.PlacedBeadCount == 0)
            {
                return;
            }

            var localPeak = 0f;
            var sizzleIntensity = 0f;

            _grid.ForEachBead((cell, bead) =>
            {
                var updated = bead;
                var world = _grid.CellToWorld(cell);
                var distance = Vector2.Distance(
                    new Vector2(world.x, world.y),
                    new Vector2(ironWorldPosition.x, ironWorldPosition.y));

                if (isIronActive && distance <= heatRadius)
                {
                    var falloff = 1f - Mathf.Pow(distance / heatRadius, 2f);
                    updated.heat += ironPower * falloff * deltaTime;
                    sizzleIntensity = Mathf.Max(sizzleIntensity, falloff);
                }
                else
                {
                    updated.heat -= 0.55f * deltaTime;
                }

                updated.heat = Mathf.Clamp(updated.heat, 0f, 1.2f);
                localPeak = Mathf.Max(localPeak, updated.heat);

                if (updated.heat > MeltHeatThreshold)
                {
                    var meltRate = (updated.heat - MeltHeatThreshold) * 0.85f;
                    updated.meltAmount = Mathf.Clamp01(updated.meltAmount + meltRate * deltaTime);
                }

                updated.flattenAmount = Mathf.Clamp01(Mathf.Lerp(updated.flattenAmount, updated.meltAmount * 0.95f, deltaTime * 3f));

                if (updated.heat > BurnHeatThreshold)
                {
                    var burnRate = (updated.heat - BurnHeatThreshold) * 0.65f;
                    updated.burnAmount = Mathf.Clamp01(updated.burnAmount + burnRate * deltaTime);
                }

                _grid.UpdateBead(cell, updated);
            });

            UpdateBonds();
            UpdateVisuals();

            _peakHeat = Mathf.Max(_peakHeat, localPeak);

            if (isIronActive)
            {
                _feedback.UpdateIroningAudio(sizzleIntensity, moveSpeed);
            }
            else
            {
                _feedback.StopIroningAudio();
            }
        }

        public IroningStats GetStats()
        {
            var meltSum = 0f;
            var bondSum = 0f;
            var maxBurn = 0f;
            var peakHeat = 0f;
            var count = 0;

            _grid.ForEachBead((_, bead) =>
            {
                meltSum += bead.meltAmount;
                bondSum += bead.bondStrength;
                maxBurn = Mathf.Max(maxBurn, bead.burnAmount);
                peakHeat = Mathf.Max(peakHeat, bead.heat);
                count++;
            });

            if (count == 0)
            {
                return default;
            }

            var avgMelt = meltSum / count;
            var avgBond = bondSum / count;
            var progress = Mathf.Clamp01(avgMelt);

            var risk = string.Empty;
            if (maxBurn > 0.28f || peakHeat > BurnHeatThreshold)
            {
                risk = "温度过高，边缘可能烫坏";
            }
            else if (avgMelt < PerfectMeltMin * 0.75f)
            {
                risk = "连接不牢，可能散开";
            }
            else if (avgMelt >= PerfectMeltMin && avgBond >= PerfectBondMin)
            {
                risk = "温度良好，继续均匀熨烫";
            }

            return new IroningStats
            {
                averageMelt = avgMelt,
                averageBond = avgBond,
                maxBurn = maxBurn,
                peakHeat = Mathf.Max(peakHeat, _peakHeat),
                progress = progress,
                riskMessage = risk
            };
        }

        public IroningResult EvaluateResult()
        {
            var stats = GetStats();

            if (stats.maxBurn >= OverBurnThreshold || stats.averageMelt > PerfectMeltMax)
            {
                return IroningResult.OverIroned;
            }

            if (stats.averageMelt < PerfectMeltMin || stats.averageBond < PerfectBondMin)
            {
                return IroningResult.UnderIroned;
            }

            return IroningResult.Perfect;
        }

        private void UpdateBonds()
        {
            _grid.ForEachBead((cell, bead) =>
            {
                var bondSum = 0f;
                var bondCount = 0;

                TryAccumulateBond(cell + Vector2Int.right, bead, ref bondSum, ref bondCount);
                TryAccumulateBond(cell + Vector2Int.up, bead, ref bondSum, ref bondCount);
                TryAccumulateBond(cell + Vector2Int.left, bead, ref bondSum, ref bondCount);
                TryAccumulateBond(cell + Vector2Int.down, bead, ref bondSum, ref bondCount);

                var updated = bead;
                updated.bondStrength = bondCount > 0 ? bondSum / bondCount : 0f;
                _grid.UpdateBead(cell, updated);
            });
        }

        private void TryAccumulateBond(Vector2Int neighborCell, BeadInstance bead, ref float bondSum, ref int bondCount)
        {
            if (!_grid.IsOccupied(neighborCell))
            {
                return;
            }

            var neighbor = _grid.GetBeadAt(neighborCell)!.Value;
            bondSum += _grid.ComputePairBond(bead, neighbor);
            bondCount++;
        }

        private void UpdateVisuals()
        {
            _grid.ForEachBead((cell, bead) =>
            {
                var view = _grid.GetBeadView(cell);
                if (view?.VisualController == null)
                {
                    return;
                }

                var maxNeighborBond = 0f;
                foreach (var offset in NeighborOffsets)
                {
                    var neighborCell = cell + offset;
                    if (!_grid.IsOccupied(neighborCell))
                    {
                        continue;
                    }

                    var neighbor = _grid.GetBeadAt(neighborCell)!.Value;
                    maxNeighborBond = Mathf.Max(maxNeighborBond, _grid.ComputePairBond(bead, neighbor));
                }

                view.VisualController.ApplyVisual(bead, maxNeighborBond);
            });
        }

        private static readonly Vector2Int[] NeighborOffsets =
        {
            Vector2Int.right,
            Vector2Int.up
        };
    }
}
