using UnityEngine;

namespace B17
{
    public sealed class MissionEffects : MonoBehaviour
    {
        readonly Transform[] clouds = new Transform[24];
        readonly float[] ages = new float[24];
        readonly LineRenderer[] tracers = new LineRenderer[2];
        int next;

        void Awake()
        {
            for(int i=0;i<clouds.Length;i++)
            {
                clouds[i]=PartFactory.Make(transform,"Flak cloud",PrimitiveType.Sphere,Vector3.zero,Vector3.one,new Color(.10f,.105f,.11f,.8f)).transform;
                clouds[i].gameObject.SetActive(false);
                ages[i]=10f;
            }
            for(int i=0;i<tracers.Length;i++)
            {
                var beam=new GameObject("Tracer");
                beam.transform.SetParent(transform,false);
                var line=beam.AddComponent<LineRenderer>();
                line.sharedMaterial=new Material(Shader.Find("Sprites/Default"));
                line.startColor=new Color(1f,.7f,.25f);
                line.endColor=new Color(1f,.2f,.05f,0f);
                line.startWidth=.35f;
                line.endWidth=.1f;
                line.positionCount=2;
                line.enabled=false;
                tracers[i]=line;
            }
        }

        public void Burst(Vector3 position)
        {
            for(int i=0;i<6;i++)
            {
                int index=next++%clouds.Length;
                clouds[index].position=position+new Vector3((i%3-1)*13f,(i%2)*9f,(i-3)*8f);
                ages[index]=0f;
                clouds[index].gameObject.SetActive(true);
            }
        }

        public void Tracer(int index,Vector3 from,Vector3 to)
        {
            var line=tracers[index%tracers.Length];
            line.SetPosition(0,from);
            line.SetPosition(1,Vector3.Lerp(from,to,.7f));
            line.enabled=true;
        }

        public void Clear()
        {
            for(int i=0;i<clouds.Length;i++)
            {
                ages[i]=10f;
                clouds[i].gameObject.SetActive(false);
            }
        }

        void Update()
        {
            for(int i=0;i<clouds.Length;i++)
            {
                ages[i]+=Time.deltaTime;
                if(ages[i]>3f) clouds[i].gameObject.SetActive(false);
                else clouds[i].localScale=Vector3.one*(3f+ages[i]*7f);
            }
            for(int i=0;i<tracers.Length;i++) tracers[i].enabled=false;
        }
    }
}
