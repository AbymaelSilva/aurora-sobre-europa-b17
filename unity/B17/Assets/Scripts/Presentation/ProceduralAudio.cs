using UnityEngine;

namespace B17
{
    public static class ProceduralAudio
    {
        public static AudioClip Engine()
        {
            int rate = 22050;
            int count = rate * 2;
            float[] data = new float[count];
            for (int i = 0; i < count; i++)
            {
                float t = (float)i / rate;
                data[i] = 0.12f * Mathf.Sin(2 * Mathf.PI * 70 * t) + 0.07f * Mathf.Sin(2 * Mathf.PI * 140 * t) + 0.035f * Mathf.Sin(2 * Mathf.PI * 35 * t);
            }
            AudioClip clip = AudioClip.Create("Four engines", count, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        public static AudioClip Explosion()
        {
            int rate = 22050;
            int count = rate;
            float[] data = new float[count];
            System.Random rng = new System.Random(17);
            for (int i = 0; i < count; i++)
            {
                float t = (float)i / rate;
                data[i] = ((float)rng.NextDouble() * 2 - 1) * Mathf.Exp(-7 * t) * 0.6f + Mathf.Sin(2 * Mathf.PI * 45 * t) * Mathf.Exp(-10 * t) * 0.3f;
            }
            AudioClip clip = AudioClip.Create("Flak", count, 1, rate, false);
            clip.SetData(data, 0);
            return clip;
        }
    }
}
