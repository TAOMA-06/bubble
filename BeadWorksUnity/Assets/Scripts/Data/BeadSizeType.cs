namespace BeadWorks.Data
{
    /// <summary>
    /// Physical bead sizes supported in the workshop vertical slice.
    /// </summary>
    public enum BeadSizeType
    {
        Mini2_6mm,
        Standard5mm
    }

    public static class BeadSizeTypeExtensions
    {
        public static float CellWorldSize(this BeadSizeType size)
        {
            return size switch
            {
                BeadSizeType.Mini2_6mm => 0.26f,
                BeadSizeType.Standard5mm => 0.5f,
                _ => 0.5f
            };
        }

        public static string DisplayName(this BeadSizeType size)
        {
            return size switch
            {
                BeadSizeType.Mini2_6mm => "Mini (2.6mm)",
                BeadSizeType.Standard5mm => "Standard (5mm)",
                _ => size.ToString()
            };
        }
    }
}
