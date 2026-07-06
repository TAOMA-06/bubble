using System;

namespace BeadWorks.Data
{
    [Serializable]
    public class FinishedWorkRecord
    {
        public string id;
        public string title;
        public string patternId;
        public int width;
        public int height;
        public int beadCount;
        public int ironingResult;
        public int productType;
        public string completedAtUtc;
        public int[] cells = Array.Empty<int>();
        public string thumbnailFileName;
    }

    [Serializable]
    public class GalleryIndex
    {
        public FinishedWorkRecord[] works = Array.Empty<FinishedWorkRecord>();
    }
}
