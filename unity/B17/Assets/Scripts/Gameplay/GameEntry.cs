using UnityEngine;

namespace B17
{
    public static class GameEntry
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Start()
        {
            if(UnityEngine.Object.FindFirstObjectByType<MissionDirector>()==null)
                new GameObject("Aurora Mission").AddComponent<MissionDirector>();
        }
    }
}
