namespace BeadWorks.Data
{
    public enum FinishedProductType
    {
        FridgeMagnet,
        Keychain,
        Pendant
    }

    public static class FinishedProductTypeExtensions
    {
        public static string DisplayName(this FinishedProductType type)
        {
            return type switch
            {
                FinishedProductType.FridgeMagnet => "冰箱贴",
                FinishedProductType.Keychain => "钥匙扣",
                FinishedProductType.Pendant => "挂件",
                _ => string.Empty
            };
        }
    }
}
