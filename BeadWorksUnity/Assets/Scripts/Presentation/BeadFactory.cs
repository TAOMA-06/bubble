using BeadWorks.Data;
using UnityEngine;

namespace BeadWorks.Presentation
{
    /// <summary>
    /// Builds plastic fusible-bead meshes: ring body, center hole, glossy finish, slight thickness.
    /// </summary>
    public class BeadFactory : MonoBehaviour
    {
        [SerializeField] private Material _beadMaterial;
        [SerializeField] private int _ringSegments = 36;

        public Material BeadMaterial => _beadMaterial;

        public BeadView CreateBead(BeadInstance instance, Vector3 worldPosition, Transform parent, bool isPreview = false)
        {
            var beadGo = new GameObject(isPreview ? "BeadPreview" : $"Bead_{instance.gridPosition.x}_{instance.gridPosition.y}");
            beadGo.transform.SetParent(parent, false);
            beadGo.transform.position = worldPosition;
            beadGo.transform.rotation = Quaternion.identity;

            var cellSize = instance.beadSize.CellWorldSize();
            beadGo.transform.localScale = Vector3.one * cellSize;

            var filter = beadGo.AddComponent<MeshFilter>();
            filter.sharedMesh = MeshStore.GetOrCreate(_ringSegments);

            var renderer = beadGo.AddComponent<MeshRenderer>();
            renderer.sharedMaterial = ResolveMaterial(instance.color);
            renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            renderer.receiveShadows = false;

            var view = beadGo.AddComponent<BeadView>();
            view.Initialize(instance, renderer.sharedMaterial, cellSize);

            if (isPreview)
            {
                view.SetPreviewMode(true);
            }

            return view;
        }

        private Material ResolveMaterial(BeadColorData color)
        {
            if (_beadMaterial == null)
            {
                _beadMaterial = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            }

            var material = new Material(_beadMaterial);
            material.SetColor("_BaseColor", color.Color);
            // Boost the smoothness floor and add a touch of metallic so beads read as
            // glossy fused plastic instead of a flat matte disc, even for the more matte
            // palette entries (higher roughness).
            material.SetFloat("_Smoothness", Mathf.Lerp(0.55f, 0.95f, color.Smoothness));
            material.SetFloat("_Metallic", 0.05f);
            return material;
        }

        public BeadView CreateHeldBead(BeadColorData color, BeadSizeType beadSize, Vector3 worldPosition, Transform parent)
        {
            var instance = BeadInstance.CreateHeld(color, beadSize);
            var view = CreateBead(instance, worldPosition, parent);
            view.transform.position = worldPosition + new Vector3(0f, 0f, -0.08f);
            return view;
        }

        private static class MeshStore
        {
            private static Mesh _sharedBeadMesh;

            public static Mesh GetOrCreate(int segments)
            {
                if (_sharedBeadMesh != null)
                {
                    return _sharedBeadMesh;
                }

                _sharedBeadMesh = BeadMeshBuilder.BuildRingMesh(segments);
                return _sharedBeadMesh;
            }
        }
    }
}
