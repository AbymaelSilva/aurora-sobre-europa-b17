using UnityEngine;

namespace B17
{
    public sealed class BomberBody : MonoBehaviour
    {
        private void Awake()
        {
            PartFactory.Make(transform, "Fuselage", PrimitiveType.Sphere, Vector3.zero, new Vector3(2.7f, 3f, 20f), new Color(0.28f, 0.33f, 0.18f));
            PartFactory.Make(transform, "Rear", PrimitiveType.Sphere, new Vector3(0f, 0.2f, -6f), new Vector3(1.8f, 2f, 10f), new Color(0.28f, 0.33f, 0.18f));
            PartFactory.Make(transform, "Nose", PrimitiveType.Sphere, new Vector3(0f, 0f, 9.8f), new Vector3(2.5f, 2.7f, 3f), new Color(0.22f, 0.36f, 0.44f, 0.7f));
            PartFactory.Make(transform, "Cockpit", PrimitiveType.Sphere, new Vector3(0f, 1.35f, 5.8f), new Vector3(2.2f, 1.5f, 3.4f), new Color(0.22f, 0.36f, 0.44f, 0.7f));
            PartFactory.Make(transform, "CabinFrame", PrimitiveType.Cube, new Vector3(0f, 1.4f, 5.8f), new Vector3(0.12f, 1.3f, 3.4f), new Color(0.08f, 0.09f, 0.08f));
            PartFactory.Make(transform, "UpperTurret", PrimitiveType.Sphere, new Vector3(0f, 2.1f, 2f), new Vector3(1.6f, 1.3f, 1.6f), new Color(0.28f, 0.33f, 0.18f));
            PartFactory.Make(transform, "BellyTurret", PrimitiveType.Sphere, new Vector3(0f, -1.8f, -0.5f), new Vector3(1.4f, 1.3f, 1.4f), new Color(0.28f, 0.33f, 0.18f));
            PartFactory.Make(transform, "HorizontalTail", PrimitiveType.Cube, new Vector3(0f, 1f, -8.5f), new Vector3(10f, 0.3f, 2.4f), new Color(0.28f, 0.33f, 0.18f));
            PartFactory.Make(transform, "VerticalTail", PrimitiveType.Sphere, new Vector3(0f, 2.4f, -8.7f), new Vector3(0.3f, 4.3f, 3.8f), new Color(0.28f, 0.33f, 0.18f));
            PartFactory.Make(transform, "TailGun", PrimitiveType.Cube, new Vector3(0f, 0.3f, -11f), new Vector3(0.35f, 0.35f, 2f), new Color(0.08f, 0.09f, 0.08f));
        }
    }
}
