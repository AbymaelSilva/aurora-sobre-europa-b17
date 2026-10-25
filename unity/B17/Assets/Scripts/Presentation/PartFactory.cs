using System.Collections.Generic;
using UnityEngine;

namespace B17
{
    public static class PartFactory
    {
        private static Dictionary<Color, Material> materials = new Dictionary<Color, Material>();

        public static Material MaterialFor(Color color)
        {
            if (materials.ContainsKey(color))
                return materials[color];

            Material material = new Material(Shader.Find("Standard"));
            material.color = color;
            material.SetFloat("_Metallic", 0.35f);
            material.SetFloat("_Glossiness", 0.4f);
            material.enableInstancing = true;

            if (color.a < 0.99f)
            {
                material.SetFloat("_Mode", 3);
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.EnableKeyword("_ALPHABLEND_ON");
                material.renderQueue = 3000;
            }

            materials[color] = material;
            return material;
        }

        public static GameObject Make(Transform parent, string name, PrimitiveType type, Vector3 position, Vector3 scale, Color color)
        {
            GameObject obj = GameObject.CreatePrimitive(type);
            obj.name = name;
            obj.transform.SetParent(parent, false);
            obj.transform.localPosition = position;
            obj.transform.localScale = scale;

            Renderer renderer = obj.GetComponent<Renderer>();
            renderer.sharedMaterial = MaterialFor(color);

            Collider collider = obj.GetComponent<Collider>();
            if (Application.isPlaying)
                Object.Destroy(collider);
            else
                Object.DestroyImmediate(collider);

            return obj;
        }
    }
}
