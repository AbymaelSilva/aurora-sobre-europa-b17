using UnityEngine;

namespace B17
{
    public sealed class MissionHud : MonoBehaviour
    {
        public MissionDirector Director;
        GUIStyle heading,body,small,large;
        readonly Color gold=new Color(.88f,.74f,.46f);
        readonly Color panel=new Color(.035f,.05f,.065f,.83f);

        void Setup()
        {
            if(body!=null) return;
            body=new GUIStyle(GUI.skin.label){fontSize=18};
            body.normal.textColor=new Color(.91f,.93f,.92f);
            small=new GUIStyle(body){fontSize=12};
            small.normal.textColor=new Color(.65f,.72f,.75f);
            heading=new GUIStyle(body){fontSize=15,fontStyle=FontStyle.Bold};
            heading.normal.textColor=gold;
            large=new GUIStyle(body){fontSize=34,fontStyle=FontStyle.Bold,alignment=TextAnchor.MiddleCenter};
        }

        static void Fill(Rect rect,Color color)
        {
            Color old=GUI.color;
            GUI.color=color;
            GUI.DrawTexture(rect,Texture2D.whiteTexture);
            GUI.color=old;
        }

        void OnGUI()
        {
            if(Director==null) return;
            Setup();
            float scale=Mathf.Min(Screen.width/1280f,Screen.height/720f);
            GUI.matrix=Matrix4x4.TRS(Vector3.zero,Quaternion.identity,new Vector3(scale,scale,1));
            float width=Screen.width/scale,height=Screen.height/scale;
            MissionSimulation s=Director.Simulation;
            Fill(new Rect(24,24,310,127),panel);
            Fill(new Rect(24,24,3,127),gold);
            GUI.Label(new Rect(42,35,280,22),"EUROPA · 1944",heading);
            GUI.Label(new Rect(42,62,280,26),Phase(s.Mission.Phase),body);
            GUI.Label(new Rect(42,94,280,22),s.Mission.Phase==MissionPhase.Return ? "Regresa a la zona segura" : "Objetivo: nudo ferroviario",small);
            GUI.Label(new Rect(42,117,280,20),Director.Demonstration ? "VUELO DE DEMOSTRACIÓN" : "ESCUADRILLA AURORA",small);
            Fill(new Rect(24,height-104,310,80),panel);
            GUI.Label(new Rect(42,height-95,280,20),"AURORA UNO · ESTADO DEL AVIÓN",heading);
            for(int i=0;i<4;i++)
            {
                Fill(new Rect(42+i*68,height-62,54,6),new Color(.2f,.24f,.25f));
                Fill(new Rect(42+i*68,height-62,54*s.Damage.Engines[i]/100f,6),s.Damage.Engines[i]>40?gold:new Color(.9f,.3f,.2f));
                GUI.Label(new Rect(42+i*68,height-50,60,20),"MOTOR "+(i+1),small);
            }
            Fill(new Rect(width-254,height-104,230,80),panel);
            GUI.Label(new Rect(width-238,height-96,215,26),$"{s.Flight.Speed*1.94384f:0} NUDOS",body);
            GUI.Label(new Rect(width-238,height-65,215,22),$"{s.Flight.Position.y*3.28084f:0} PIES · {s.Damage.Hull:0}%",small);
            GUI.Label(new Rect(width/2-100,26,200,22),$"RUMBO {Mathf.Repeat(s.Flight.HeadingDegrees,360):000}°",heading);
            if(s.Mission.Clock<Director.RadioUntil)
            {
                Fill(new Rect(width/2-330,height-92,660,48),panel);
                GUI.Label(new Rect(width/2-312,height-83,630,36),Director.RadioMessage,body);
            }
            if(s.Mission.Clock<10f)
            {
                GUI.Label(new Rect(width/2-400,height*.25f,800,50),"AURORA SOBRE EUROPA",large);
                GUI.Label(new Rect(width/2-120,height*.25f+54,300,25),"UNA MISIÓN. UNA TRIPULACIÓN.",heading);
            }
            if(s.Mission.Phase==MissionPhase.BombRun)
                GUI.Label(new Rect(width/2-155,height-145,400,30),s.Bomb.Spent?"BOMBAS FUERA":"EN APROXIMACIÓN FINAL",heading);
            if(s.Mission.Phase==MissionPhase.Complete || s.Mission.Phase==MissionPhase.Failed)
            {
                Fill(new Rect(width/2-320,height*.35f,640,170),panel);
                GUI.Label(new Rect(width/2-310,height*.35f+25,620,55),s.Mission.Phase==MissionPhase.Complete?"MISIÓN COMPLETADA":"AVIÓN PERDIDO",large);
                GUI.Label(new Rect(width/2-230,height*.35f+95,500,35),$"Tiempo {s.Mission.Clock/60f:0.0} min · Fuselaje {s.Damage.Hull:0}%",body);
            }
        }

        static string Phase(MissionPhase phase)
        {
            switch(phase)
            {
                case MissionPhase.Formation:return "MANTÉN LA FORMACIÓN";
                case MissionPhase.Approach:return "RUMBO AL OBJETIVO";
                case MissionPhase.BombRun:return "PASADA DE BOMBARDEO";
                case MissionPhase.Return:return "REGRESO A CASA";
                case MissionPhase.Complete:return "ZONA SEGURA";
                default:return "SIN CONTACTO";
            }
        }
    }
}
