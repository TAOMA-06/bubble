using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace BeadWorks.Data
{
    /// <summary>
    /// Provides built-in pattern data for the vertical slice.
    /// </summary>
    public class PatternRepository
    {
        private readonly List<BeadPatternData> _patterns = new();

        public IReadOnlyList<BeadPatternData> Patterns => _patterns;

        public void LoadBuiltins()
        {
            _patterns.Clear();
            _patterns.AddRange(BuiltinPatternFactory.CreateAll());
        }

        public void LoadFromJsonAssets(TextAsset[] jsonAssets)
        {
            if (jsonAssets == null)
            {
                return;
            }

            foreach (var asset in jsonAssets)
            {
                if (asset == null)
                {
                    continue;
                }

                var pattern = JsonUtility.FromJson<BeadPatternData>(asset.text);
                if (pattern != null && pattern.cells != null && pattern.cells.Length > 0)
                {
                    _patterns.Add(pattern);
                }
            }
        }

        public BeadPatternData GetById(string id)
        {
            return _patterns.FirstOrDefault(p => p.id == id);
        }
    }
}
