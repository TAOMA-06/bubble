using System;
using BeadWorks.Data;

namespace BeadWorks.Core
{
    /// <summary>
    /// Runtime context for a single workshop run (free create or pattern replicate).
    /// </summary>
    public class WorkshopSession
    {
        public bool IsFreeMode { get; set; }
        public BeadPatternData Pattern { get; set; }
        public string Title { get; set; } = "自由创作";
        public DateTime StartTime { get; set; } = DateTime.UtcNow;

        public static WorkshopSession FreeCreate()
        {
            return new WorkshopSession
            {
                IsFreeMode = true,
                Pattern = null,
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
                Title = pattern?.title ?? "图纸复刻",
                StartTime = DateTime.UtcNow
            };
        }
    }
}
