using UnityEngine;

namespace B17
{
    public sealed class BomberAircraft : MonoBehaviour
    {
        private void Awake()
        {
            gameObject.AddComponent<BomberBody>();
            gameObject.AddComponent<BomberWings>();
            gameObject.AddComponent<BomberEngines>();
        }
    }

}
