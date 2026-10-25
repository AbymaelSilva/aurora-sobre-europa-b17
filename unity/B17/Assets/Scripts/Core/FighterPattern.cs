using UnityEngine;

namespace B17
{
    public static class FighterPattern
    {
        public static Vector3 LocalOffset(float elapsed, int index)
        {
            float t = Mathf.Repeat(elapsed + index * 9f, 32f);
            float side = index % 2 == 0 ? 1f : -1f;
            if (t < 10)
                return Vector3.Lerp(new Vector3(side * 900, 180, 1400), new Vector3(side * 70, 10, 80), t / 10f);
            if (t < 14)
                return Vector3.Lerp(new Vector3(side * 70, 10, 80), new Vector3(-side * 120, -20, -220), (t - 10) / 4f);
            return Vector3.Lerp(new Vector3(-side * 120, -20, -220), new Vector3(-side * 1300, 350, -1800), (t - 14) / 18f);
        }

        public static bool IsFiring(float elapsed, int index)
        {
            float t = Mathf.Repeat(elapsed + index * 9f, 32f);
            return t > 9 && t < 12;
        }
    }
}
