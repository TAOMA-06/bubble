using UnityEngine;

namespace BeadWorks.Data
{
    public struct BeadInstance
    {
        public Vector2Int gridPosition;
        public BeadColorData color;
        public BeadSizeType beadSize;
        public float heat;
        public float meltAmount;
        public float flattenAmount;
        public float burnAmount;
        public float bondStrength;
        public bool isPlaced;

        public static BeadInstance CreatePlaced(
            Vector2Int gridPosition,
            BeadColorData color,
            BeadSizeType beadSize)
        {
            return new BeadInstance
            {
                gridPosition = gridPosition,
                color = color,
                beadSize = beadSize,
                heat = 0f,
                meltAmount = 0f,
                flattenAmount = 0f,
                burnAmount = 0f,
                bondStrength = 0f,
                isPlaced = true
            };
        }

        public static BeadInstance CreateHeld(BeadColorData color, BeadSizeType beadSize)
        {
            return new BeadInstance
            {
                gridPosition = new Vector2Int(-1, -1),
                color = color,
                beadSize = beadSize,
                isPlaced = false
            };
        }

        public BeadInstance ResetIroningState()
        {
            heat = 0f;
            meltAmount = 0f;
            flattenAmount = 0f;
            burnAmount = 0f;
            bondStrength = 0f;
            return this;
        }
    }
}
