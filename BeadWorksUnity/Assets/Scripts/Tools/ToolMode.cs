namespace BeadWorks.Tools
{
    /// <summary>
    /// Active editing tool in the workshop.
    /// </summary>
    public enum ToolMode
    {
        Tweezers,
        Eraser,
        Iron,
        Inspect
    }

    public static class ToolModeExtensions
    {
        public static string DisplayName(this ToolMode mode)
        {
            return mode switch
            {
                ToolMode.Tweezers => "Tweezers",
                ToolMode.Eraser => "Eraser",
                ToolMode.Iron => "Iron",
                ToolMode.Inspect => "Inspect",
                _ => mode.ToString()
            };
        }

        public static string IconLabel(this ToolMode mode)
        {
            return mode switch
            {
                ToolMode.Tweezers => "✂",
                ToolMode.Eraser => "⌫",
                ToolMode.Iron => "♨",
                ToolMode.Inspect => "🔍",
                _ => "?"
            };
        }
    }
}
