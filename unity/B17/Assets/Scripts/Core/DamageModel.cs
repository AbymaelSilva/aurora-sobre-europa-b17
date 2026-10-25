using UnityEngine;

namespace B17
{
    public sealed class DamageModel
    {
        public float Hull = 100;
        public float[] Engines = new float[] { 100, 100, 100, 100 };

        public void Reset()
        {
            Hull = 100;
            for (int i = 0; i < Engines.Length; i++)
            {
                Engines[i] = 100;
            }
        }

        public void Apply(float amount, int engineIndex)
        {
            amount = Mathf.Max(0, amount);
            Hull = Mathf.Clamp(Hull - amount, 0, 100);
            if (engineIndex >= 0 && engineIndex < 4)
            {
                Engines[engineIndex] = Mathf.Clamp(Engines[engineIndex] - amount * 2.5f, 0, 100);
            }
        }

        public bool Destroyed
        {
            get { return Hull <= 0; }
        }

        public float ThrustFactor
        {
            get { return 0.6f + 0.4f * (Engines[0] + Engines[1] + Engines[2] + Engines[3]) / 400f; }
        }
    }
}
