using UnityEngine;

namespace B17
{
    public sealed class FighterAircraft : MonoBehaviour
    {
        private Transform propeller;

        private void Awake()
        {
            var fuselage = PartFactory.Make(transform, "Fuselage", PrimitiveType.Sphere, new Vector3(0, 0, 0), new Vector3(1.3f, 1.4f, 8f), new Color(0.25f, 0.27f, 0.25f));
            var wings = PartFactory.Make(transform, "Wings", PrimitiveType.Cube, new Vector3(0, 0, 0.5f), new Vector3(9f, 0.15f, 1.6f), Color.black);
            var tail = PartFactory.Make(transform, "Tail", PrimitiveType.Cube, new Vector3(0, 0.4f, -3f), new Vector3(3.5f, 0.15f, 1f), Color.black);
            var fin = PartFactory.Make(transform, "Fin", PrimitiveType.Sphere, new Vector3(0, 1f, -3f), new Vector3(0.15f, 1.8f, 1.4f), Color.black);
            var cockpit = PartFactory.Make(transform, "Cockpit", PrimitiveType.Sphere, new Vector3(0, 0.8f, 0.3f), new Vector3(0.8f, 0.8f, 1.8f), new Color(0.15f, 0.3f, 0.4f, 0.8f));

            propeller = new GameObject("Propeller").transform;
            propeller.SetParent(transform, false);
            propeller.localPosition = new Vector3(0, 0, 4.3f);

            var blade1 = PartFactory.Make(transform, "Blade1", PrimitiveType.Cube, Vector3.zero, new Vector3(0.12f, 3f, 0.06f), Color.black);
            var blade2 = PartFactory.Make(transform, "Blade2", PrimitiveType.Cube, Vector3.zero, new Vector3(3f, 0.12f, 0.06f), Color.black);

            blade1.transform.SetParent(propeller, false);
            blade2.transform.SetParent(propeller, false);
        }

        private void Update()
        {
            if (propeller != null)
            {
                propeller.Rotate(Vector3.forward, 1900f * Time.deltaTime);
            }
        }
    }

}
