using UnityEngine;
using System.Collections.Generic;

namespace B17
{
    // Scene integration by Codex; simulation and aircraft builders by Qwen.
    public sealed class MissionDirector : MonoBehaviour
    {
        public MissionSimulation Simulation = new MissionSimulation();
        public Camera View;
        public Transform Player;
        public WorldBuilder World;
        public MissionEffects Effects;
        public bool Demonstration = true;
        public float SimulationRate = 1f;
        public string RadioMessage = "Escuadrilla Aurora, mantengan la formación.";
        public float RadioUntil = 14f;
        readonly List<Transform> allies = new List<Transform>();
        readonly List<Transform> fighters = new List<Transform>();
        Transform bombVisual;
        AudioSource engines;
        AudioSource explosions;
        MissionPhase previousPhase;
        float lastHeading;

        void Awake()
        {
            QualitySettings.antiAliasing = 4;
            QualitySettings.shadowDistance = 750f;
            QualitySettings.vSyncCount = 1;
            Application.targetFrameRate = 60;
            Time.fixedDeltaTime = 1f / 60f;
            World = new GameObject("Landscape").AddComponent<WorldBuilder>();
            Player = CreateBomber("Aurora One");
            allies.Add(CreateBomber("Aurora Two"));
            allies.Add(CreateBomber("Aurora Three"));
            for (int i=0;i<2;i++)
                fighters.Add(new GameObject("Interceptor "+i).AddComponent<FighterAircraft>().transform);
            World.Clouds.Follow = Player;
            View = new GameObject("Mission Camera").AddComponent<Camera>();
            View.tag = "MainCamera";
            View.fieldOfView = 58f;
            View.nearClipPlane = .3f;
            View.farClipPlane = 80000f;
            View.clearFlags = CameraClearFlags.Skybox;
            View.gameObject.AddComponent<AudioListener>();
            Effects = new GameObject("Mission Effects").AddComponent<MissionEffects>();
            bombVisual = PartFactory.Make(transform,"Bomb",PrimitiveType.Capsule,Vector3.zero,new Vector3(.5f,1.4f,.5f),new Color(.18f,.2f,.17f)).transform;
            if (!Application.isBatchMode)
            {
                engines = Player.gameObject.AddComponent<AudioSource>();
                engines.clip = ProceduralAudio.Engine();
                engines.loop = true;
                engines.volume = .25f;
                engines.Play();
                explosions = View.gameObject.AddComponent<AudioSource>();
                explosions.clip = ProceduralAudio.Explosion();
                explosions.volume = .4f;
            }
            gameObject.AddComponent<MissionHud>().Director = this;
            previousPhase = Simulation.Mission.Phase;
        }

        Transform CreateBomber(string name)
        {
            return new GameObject(name).AddComponent<BomberAircraft>().transform;
        }

        public void ResetMission()
        {
            Simulation.Reset();
            Simulation.AutoPilot = Demonstration;
            previousPhase = MissionPhase.Formation;
            lastHeading = 0f;
            Effects.Clear();
            World.Yard.SetDestroyed(false);
            RadioMessage = "Escuadrilla Aurora, mantengan la formación.";
            RadioUntil = 14f;
        }

        void FixedUpdate()
        {
            int steps = Mathf.Clamp(Mathf.RoundToInt(SimulationRate),1,12);
            for(int i=0;i<steps;i++)
            {
                Simulation.AutoPilot = Demonstration;
                Simulation.Step(Time.fixedDeltaTime);
                if(Simulation.LastFlakBurst)
                {
                    float n = Simulation.Flak.BurstCount;
                    Vector3 offset = new Vector3(Mathf.Sin(n*2.3f)*45f,Mathf.Cos(n)*22f,90f);
                    Effects.Burst(Simulation.Flight.Position+Quaternion.Euler(0,Simulation.Flight.HeadingDegrees,0)*offset);
                    if(explosions!=null) explosions.PlayOneShot(explosions.clip,.65f);
                }
                if(!Simulation.Paused && Simulation.Mission.Phase==MissionPhase.Approach && Simulation.Flight.Position.z>14000 && Simulation.Flight.Position.z<24000)
                {
                    for(int fighter=0;fighter<2;fighter++)
                        if(FighterPattern.IsFiring(Simulation.Mission.Clock,fighter))
                            Simulation.Damage.Apply(.3f*Time.fixedDeltaTime,fighter);
                }
            }
            if(previousPhase!=Simulation.Mission.Phase)
            {
                previousPhase = Simulation.Mission.Phase;
                RadioMessage = PhaseRadio(previousPhase);
                RadioUntil = Simulation.Mission.Clock+12f;
            }
        }

        static string PhaseRadio(MissionPhase phase)
        {
            switch(phase)
            {
                case MissionPhase.Approach: return "Navegante: rumbo al objetivo. Mantengan altura y velocidad.";
                case MissionPhase.BombRun: return "Bombardero: objetivo a la vista. Preparados para la suelta.";
                case MissionPhase.Return: return "Impactos confirmados. Reagrúpense y salgamos de aquí.";
                case MissionPhase.Complete: return "Zona segura alcanzada. Buen trabajo, Aurora.";
                case MissionPhase.Failed: return "Aurora uno, respondan. Aurora uno...";
                default: return "Mantengan la formación.";
            }
        }

        void LateUpdate()
        {
            FlightModel flight = Simulation.Flight;
            Quaternion heading = Quaternion.Euler(0,flight.HeadingDegrees,0);
            float bank = Mathf.Clamp(Mathf.DeltaAngle(lastHeading,flight.HeadingDegrees)*20f,-25f,25f);
            lastHeading = flight.HeadingDegrees;
            Player.position = flight.Position;
            Player.rotation = Quaternion.Euler(-flight.PitchDegrees,flight.HeadingDegrees,-bank);
            for(int i=0;i<allies.Count;i++)
            {
                float side = i==0 ? -1f : 1f;
                allies[i].position = flight.Position+heading*new Vector3(side*55f,4f,-30f);
                allies[i].rotation = Player.rotation;
            }
            bool threat = flight.Position.z>11000f && flight.Position.z<24500f && Simulation.Mission.Phase==MissionPhase.Approach;
            for(int i=0;i<fighters.Count;i++)
            {
                Transform fighter = fighters[i];
                fighter.gameObject.SetActive(threat);
                if(!threat) continue;
                Vector3 position = flight.Position+heading*FighterPattern.LocalOffset(Simulation.Mission.Clock,i);
                Vector3 direction = position-fighter.position;
                fighter.position = position;
                if(direction.sqrMagnitude>.01f) fighter.rotation = Quaternion.LookRotation(direction);
                if(FighterPattern.IsFiring(Simulation.Mission.Clock,i)) Effects.Tracer(i,position,Player.position);
            }
            bombVisual.gameObject.SetActive(Simulation.Bomb.Active);
            bombVisual.position = Simulation.Bomb.Position;
            bombVisual.rotation = Quaternion.Euler(0,0,0);
            World.Yard.SetDestroyed(Simulation.Bomb.Result=="HIT");
            Vector3 focus = flight.Position+Vector3.up*1.2f;
            Vector3 cameraPosition = flight.Position+heading*new Vector3(0,9,-37);
            if(Simulation.Bomb.Active)
            {
                focus = Simulation.Bomb.Position;
                cameraPosition = focus+new Vector3(30,24,-45);
            }
            float blend = 1f-Mathf.Exp(-Time.unscaledDeltaTime*4f);
            if(View.transform.position.sqrMagnitude<1f) blend=1f;
            View.transform.position = Vector3.Lerp(View.transform.position,cameraPosition,blend);
            View.transform.LookAt(focus);
            if(engines!=null) engines.pitch = Mathf.Clamp(flight.Speed/85f,.6f,1.4f);
        }
    }
}
