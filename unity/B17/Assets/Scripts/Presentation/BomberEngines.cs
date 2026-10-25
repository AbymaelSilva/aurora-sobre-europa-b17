using UnityEngine;

namespace B17
{
    public sealed class BomberEngines : MonoBehaviour
    {
        private Transform[] propellers = new Transform[4];

        private void Awake()
        {
            float[] xPositions = { -9.4f, -4.4f, 4.4f, 9.4f };
            for (int i = 0; i < xPositions.Length; i++)
            {
                float x = xPositions[i];
                Transform nacelle = PartFactory.Make(transform, "Nacelle", PrimitiveType.Cylinder, new Vector3(x, -0.05f, 2.8f), new Vector3(1.8f, 1.55f, 1.8f), new Color(0.27f, 0.3f, 0.17f)).transform;
                nacelle.localRotation = Quaternion.Euler(90, 0, 0);
                Transform spinner = PartFactory.Make(transform, "Spinner", PrimitiveType.Sphere, new Vector3(x, 0, 4.5f), new Vector3(0.8f, 0.8f, 1f), new Color(0.2f, 0.2f, 0.2f)).transform;
                Transform propeller = new GameObject("Propeller").transform;
                propeller.SetParent(transform);
                propeller.localPosition = new Vector3(x, 0, 5f);
                for (int j = 0; j < 3; j++)
                {
                    Transform blade = PartFactory.Make(propeller, "Blade", PrimitiveType.Cube, Vector3.zero, new Vector3(0.18f, 2.1f, 0.08f), new Color(0.07f, 0.07f, 0.07f)).transform;
                    blade.localPosition = Quaternion.Euler(0, 0, j * 120f) * Vector3.up * 1.05f;
                    blade.localRotation = Quaternion.Euler(0, 0, j * 120f);
                }
                propellers[i] = propeller;
            }
        }

        private void Update()
        {
            if (Application.isPlaying)
            {
                for (int i = 0; i < propellers.Length; i++)
                {
                    if (propellers[i] != null)
                    {
                        propellers[i].Rotate(0, 0, 1800f * Time.deltaTime, Space.Self);
                    }
                }
            }
        }
    }
}
