using UnityEngine;

namespace BeadWorks.Presentation
{
    public static class BeadMeshBuilder
    {
        public const float BaseOuterRadius = 0.44f;
        public const float BaseInnerRadius = 0.17f;
        public const float BaseHalfThickness = 0.06f;

        public static Mesh BuildRingMesh(
            int segments,
            float outerRadius = BaseOuterRadius,
            float innerRadius = BaseInnerRadius,
            float halfThickness = BaseHalfThickness)
        {
            var vertexCount = segments * 4;
            var triangleCount = segments * 18;
            var vertices = new Vector3[vertexCount];
            var normals = new Vector3[vertexCount];
            var uvs = new Vector2[vertexCount];
            var triangles = new int[triangleCount];

            for (var i = 0; i < segments; i++)
            {
                var angle = (i / (float)segments) * Mathf.PI * 2f;
                var cos = Mathf.Cos(angle);
                var sin = Mathf.Sin(angle);

                var outer = new Vector3(cos * outerRadius, sin * outerRadius, 0f);
                var inner = new Vector3(cos * innerRadius, sin * innerRadius, 0f);
                var baseIndex = i * 4;

                vertices[baseIndex] = outer + new Vector3(0f, 0f, halfThickness);
                vertices[baseIndex + 1] = inner + new Vector3(0f, 0f, halfThickness);
                vertices[baseIndex + 2] = outer - new Vector3(0f, 0f, halfThickness);
                vertices[baseIndex + 3] = inner - new Vector3(0f, 0f, halfThickness);

                var topNormal = Vector3.back;
                normals[baseIndex] = topNormal;
                normals[baseIndex + 1] = topNormal;

                var bottomNormal = Vector3.forward;
                normals[baseIndex + 2] = bottomNormal;
                normals[baseIndex + 3] = bottomNormal;

                var next = (i + 1) % segments;
                var nextBase = next * 4;

                var tri = i * 12;
                AddQuad(triangles, tri, baseIndex, baseIndex + 1, nextBase + 1, nextBase);
                AddQuad(triangles, tri + 6, baseIndex + 2, nextBase + 2, nextBase + 3, baseIndex + 3);
                AddQuad(triangles, tri + 12, baseIndex, nextBase, nextBase + 2, baseIndex + 2);

                uvs[baseIndex] = new Vector2(1f, 1f);
                uvs[baseIndex + 1] = new Vector2(0.5f, 0.5f);
                uvs[baseIndex + 2] = new Vector2(1f, 0f);
                uvs[baseIndex + 3] = new Vector2(0.5f, 0.5f);
            }

            var mesh = new Mesh { name = "PlasticBeadRing" };
            mesh.vertices = vertices;
            mesh.normals = normals;
            mesh.uv = uvs;
            mesh.triangles = triangles;
            mesh.RecalculateBounds();
            return mesh;
        }

        public static Mesh BuildFusionBridge(float width, float length)
        {
            var halfW = width * 0.5f;
            var halfL = length * 0.5f;
            var mesh = new Mesh { name = "FusionBridge" };
            mesh.vertices = new[]
            {
                new Vector3(-halfL, -halfW, 0f),
                new Vector3(halfL, -halfW, 0f),
                new Vector3(halfL, halfW, 0f),
                new Vector3(-halfL, halfW, 0f)
            };
            mesh.normals = new[] { Vector3.back, Vector3.back, Vector3.back, Vector3.back };
            mesh.uv = new[] { Vector2.zero, Vector2.right, Vector2.one, Vector2.up };
            mesh.triangles = new[] { 0, 1, 2, 0, 2, 3 };
            mesh.RecalculateBounds();
            return mesh;
        }

        private static void AddQuad(int[] triangles, int offset, int a, int b, int c, int d)
        {
            triangles[offset] = a;
            triangles[offset + 1] = b;
            triangles[offset + 2] = c;
            triangles[offset + 3] = a;
            triangles[offset + 4] = c;
            triangles[offset + 5] = d;
        }
    }
}
