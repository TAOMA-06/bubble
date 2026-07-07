using System;
using BeadWorks.Data;

namespace BeadWorks.Core
{
    /// <summary>
    /// Where a session's pattern (if any) originated from.
    /// </summary>
    public enum PatternSource
    {
        None,
        Builtin,
        Imported
    }

    /// <summary>
    /// Runtime context for a single workshop run (free create, builtin pattern replicate, or imported photo pattern).
    /// </summary>
    public class WorkshopSession
    {
        public bool IsFreeMode { get; set; }
        public BeadPatternData Pattern { get; set; }
        public PatternSource Source { get; set; } = PatternSource.None;
        public int? RequestedGridSize { get; set; }
        public string SourceLabel { get; set; }
        public string Title { get; set; } = "自由创作";
        public DateTime StartTime { get; set; } = DateTime.UtcNow;

        public static WorkshopSession FreeCreate(int gridSize)
        {
            return new WorkshopSession
            {
                IsFreeMode = true,
                Pattern = null,
                Source = PatternSource.None,
                RequestedGridSize = gridSize,
                Title = "自由创作",
                StartTime = DateTime.UtcNow
            };
        }

        public static WorkshopSession FromPattern(BeadPatternData pattern)
        {
            return new WorkshopSession
            {
                IsFreeMode = false,
                Pattern = pattern,
                Source = PatternSource.Builtin,
                Title = pattern?.title ?? "图纸复刻",
                StartTime = DateTime.UtcNow
            };
        }

        public static WorkshopSession FromImportedPattern(BeadPatternData pattern, string sourceLabel)
        {
            return new WorkshopSession
            {
                IsFreeMode = false,
                Pattern = pattern,
                Source = PatternSource.Imported,
                SourceLabel = sourceLabel,
                Title = string.IsNullOrEmpty(sourceLabel) ? "照片拼豆" : sourceLabel,
                StartTime = DateTime.UtcNow
            };
        }
    }
}
