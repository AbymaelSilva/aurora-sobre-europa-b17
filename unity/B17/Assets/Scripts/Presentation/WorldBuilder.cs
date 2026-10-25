using UnityEngine;

namespace B17
{
    public sealed class WorldBuilder : MonoBehaviour
    {
        public RailYard Yard;
        public CloudLayer Clouds;

        void Awake()
        {
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.000035f;
            RenderSettings.fogColor = new Color(0.66f, 0.73f, 0.79f);
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.55f, 0.62f, 0.72f);
            RenderSettings.ambientEquatorColor = new Color(0.38f, 0.4f, 0.42f);
            RenderSettings.ambientGroundColor = new Color(0.2f, 0.22f, 0.18f);

            Material sky = new Material(Shader.Find("Skybox/Procedural"));
            sky.SetFloat("_AtmosphereThickness", 1.1f);
            sky.SetColor("_SkyTint", new Color(0.45f, 0.55f, 0.65f));
            RenderSettings.skybox = sky;

            GameObject sun = new GameObject("Sun");
            sun.transform.parent = transform;
            Light light = sun.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.25f;
            light.color = new Color(1f, 0.88f, 0.7f);
            light.shadows = LightShadows.Soft;
            light.transform.rotation = Quaternion.Euler(25f, -35f, 0f);
            RenderSettings.sun = light;

            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Ground";
            ground.transform.parent = transform;
            ground.transform.localPosition = Vector3.zero;
            ground.transform.localScale = new Vector3(10000f, 1f, 10000f);
            if (Application.isPlaying) Object.Destroy(ground.GetComponent<Collider>());
            else Object.DestroyImmediate(ground.GetComponent<Collider>());

            Renderer renderer = ground.GetComponent<Renderer>();
            Shader terrainShader = Resources.Load<Shader>("Farmland");
            renderer.sharedMaterial = new Material(terrainShader != null ? terrainShader : Shader.Find("Standard"));
            if (terrainShader == null) renderer.sharedMaterial.color = new Color(0.25f, 0.35f, 0.16f);

            GameObject railYard = new GameObject("RailYard");
            railYard.transform.parent = transform;
            railYard.transform.localPosition = new Vector3(0f, 0f, 30000f);
            Yard = railYard.AddComponent<RailYard>();

            GameObject cloudLayer = new GameObject("CloudLayer");
            cloudLayer.transform.parent = transform;
            Clouds = cloudLayer.AddComponent<CloudLayer>();
        }
    }
}
