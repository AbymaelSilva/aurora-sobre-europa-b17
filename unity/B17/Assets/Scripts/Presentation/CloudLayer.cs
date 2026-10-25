using UnityEngine;

namespace B17
{
    public sealed class CloudLayer : MonoBehaviour
    {
        public Transform Follow;
        private Transform[] clouds = new Transform[18];

        private void Awake()
        {
            System.Random rng = new System.Random(74);
            for (int i = 0; i < 18; i++)
            {
                Transform cluster = new GameObject("CloudCluster").transform;
                cluster.SetParent(transform);
                for (int j = 0; j < 3; j++)
                {
                    PartFactory.Make(cluster, "Cloud", PrimitiveType.Sphere, new Vector3(j * 130, 0, j * 40), new Vector3(500, 110, 350), new Color(.85f, .88f, .9f));
                }
                cluster.localPosition = new Vector3(((float)rng.NextDouble() - .5f) * 14000, 1800 + (float)rng.NextDouble() * 500, ((float)rng.NextDouble() - .5f) * 14000);
                clouds[i] = cluster;
            }
        }

        private void LateUpdate()
        {
            if (Follow != null)
            {
                for (int i = 0; i < 18; i++)
                {
                    Transform cloud = clouds[i];
                    if (cloud.position.z < Follow.position.z - 7000)
                        cloud.position += Vector3.forward * 14000;
                    if (cloud.position.x < Follow.position.x - 7000)
                        cloud.position += Vector3.right * 14000;
                    if (cloud.position.x > Follow.position.x + 7000)
                        cloud.position -= Vector3.right * 14000;
                }
            }
        }
    }
}
