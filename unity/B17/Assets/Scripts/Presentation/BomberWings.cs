using UnityEngine;

namespace B17
{
    public sealed class BomberWings : MonoBehaviour
    {
        private void Awake()
        {
            Build(1f);
            Build(-1f);
        }

        private void Build(float side)
        {
            Vector3[] vertices =
            {
                new Vector3(1.1f * side, .2f, 2.2f),
                new Vector3(15.8f * side, 1.0f, .5f),
                new Vector3(15.8f * side, 1.0f, -1.6f),
                new Vector3(1.1f * side, .2f, -3.7f),
                new Vector3(1.1f * side, -.05f, 2.2f),
                new Vector3(15.8f * side, .75f, .5f),
                new Vector3(15.8f * side, .75f, -1.6f),
                new Vector3(1.1f * side, -.05f, -3.7f)
            };

            int[] triangles = {0,1,2,0,2,3,4,6,5,4,7,6,0,4,5,0,5,1,1,5,6,1,6,2,2,6,7,2,7,3,3,7,4,3,4,0};
            if(side<0)
                for(int i=0;i<triangles.Length;i+=3)
                {
                    int temp=triangles[i+1];
                    triangles[i+1]=triangles[i+2];
                    triangles[i+2]=temp;
                }

            Mesh mesh = new Mesh();
            mesh.vertices = vertices;
            mesh.triangles = triangles;
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();

            GameObject wing = new GameObject("Wing");
            wing.transform.SetParent(transform, false);
            wing.transform.localPosition = Vector3.zero;
            wing.AddComponent<MeshFilter>().sharedMesh = mesh;
            wing.AddComponent<MeshRenderer>().sharedMaterial = PartFactory.MaterialFor(new Color(.28f, .33f, .18f));
        }
    }
}
