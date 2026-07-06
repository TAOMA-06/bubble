namespace BeadWorks.Data
{
    public enum IroningResult
    {
        UnderIroned,
        Perfect,
        OverIroned
    }

    public static class IroningResultExtensions
    {
        public static string DisplayMessage(this IroningResult result)
        {
            return result switch
            {
                IroningResult.UnderIroned => "连接不牢，可能散开",
                IroningResult.Perfect => "融合完美！",
                IroningResult.OverIroned => "边缘烫坏",
                _ => string.Empty
            };
        }

        public static string DetailMessage(this IroningResult result)
        {
            return result switch
            {
                IroningResult.UnderIroned => "豆子熔化不足，相邻连接较弱。可以重新熨烫。",
                IroningResult.Perfect => "豆子已均匀融合，成品牢固平整。",
                IroningResult.OverIroned => "热量过高导致边缘发暗或泛黄。可以重新熨烫。",
                _ => string.Empty
            };
        }
    }
}
