using UnityEngine;

namespace B17
{
    public sealed class FlakModel
    {
        public float Timer = 0;
        public float Interval = 2.8f;
        public int BurstCount = 0;

        public void Reset()
        {
            Timer = 0;
            BurstCount = 0;
        }

        public bool Step(float dt, bool inZone)
        {
            if (!inZone)
            {
                Timer = 0;
                return false;
            }

            Timer += Mathf.Clamp(dt, 0, 0.05f);
            if (Timer >= Interval)
            {
                Timer -= Interval;
                BurstCount++;
                return true;
            }

            return false;
        }
    }
}
