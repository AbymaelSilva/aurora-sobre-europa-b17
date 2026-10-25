using UnityEngine;

namespace B17
{
    public sealed class RailYard : MonoBehaviour
    {
        public bool Destroyed = false;
        private Transform buildings;

        public void SetDestroyed(bool value)
        {
            Destroyed = value;
            if (buildings != null)
                buildings.localScale = new Vector3(1, value ? 0.25f : 1, 1);
        }

        private void Awake()
        {
            buildings = new GameObject("Buildings").transform;
            buildings.SetParent(transform, false);

            for (int j = -3; j <= 3; j++)
            {
                PartFactory.Make(transform, "Rail", PrimitiveType.Cube, new Vector3(j * 18 - 3, 0.2f, 0), new Vector3(0.35f, 0.4f, 600f), new Color(0.2f, 0.2f, 0.2f));
                PartFactory.Make(transform, "Rail", PrimitiveType.Cube, new Vector3(j * 18 + 3, 0.2f, 0), new Vector3(0.35f, 0.4f, 600f), new Color(0.2f, 0.2f, 0.2f));
            }

            for (int z = -280; z <= 280; z += 12)
            {
                PartFactory.Make(transform, "Sleeper", PrimitiveType.Cube, new Vector3(0, 0.15f, z), new Vector3(130f, 0.3f, 1f), new Color(0.4f, 0.3f, 0.2f));
            }

            for (int i = 0; i <= 5; i++)
            {
                PartFactory.Make(buildings, "Warehouse", PrimitiveType.Cube, new Vector3(-110 + (i % 3) * 110, 12f, (i / 3) * 160 - 80), new Vector3(75f, 24f, 90f), new Color(0.43f, 0.34f, 0.26f));
                PartFactory.Make(buildings, "Roof", PrimitiveType.Cube, new Vector3(-110 + (i % 3) * 110, 25f, (i / 3) * 160 - 80), new Vector3(78f, 2f, 94f), new Color(0.18f, 0.2f, 0.2f));
            }

            for (int i = 0; i < 3; i++)
            {
                PartFactory.Make(buildings, "Chimney", PrimitiveType.Cylinder, new Vector3(90 + i * 22, 35f, -120f), new Vector3(7f, 35f, 7f), new Color(0.3f, 0.28f, 0.25f));
            }

            for (int i = 0; i < 4; i++)
            {
                PartFactory.Make(transform, "FreightCar", PrimitiveType.Cube, new Vector3(18f, 3f, i * 25 - 40f), new Vector3(8f, 6f, 20f), new Color(0.4f, 0.18f, 0.1f));
            }
        }
    }
}
