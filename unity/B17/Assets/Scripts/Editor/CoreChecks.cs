using System;
using UnityEngine;

namespace B17.Editor
{
    public static class CoreChecks
    {
        static void Require(bool value,string message)
        {
            if(!value) throw new Exception("B17_TEST_FAIL: "+message);
        }
        public static void Run()
        {
            CheckAll();
            Debug.Log("B17_CORE_TESTS_PASS: core logic verified. Scene and rendering require separate tests.");
        }

        public static void CheckAll()
        {
            var bomb=new BombModel();
            Require(bomb.Release(new Vector3(0,100,0),new Vector3(0,0,50)),"first release");
            Require(!bomb.Release(Vector3.zero,Vector3.zero),"single ammunition");
            bomb.Step(1f/60f,new Vector3(0,0,226),12f);
            Require(bomb.Active&&bomb.Result=="AIRBORNE","no result before ground contact");
            for(int i=0;i<600;i++) bomb.Step(1f/60f,new Vector3(0,0,226),12f);
            Require(bomb.Result=="HIT"&&!bomb.Active,"ballistic hit");
            bomb.Reset();
            bomb.Release(new Vector3(0,100,0),new Vector3(0,0,50));
            for(int i=0;i<600;i++) bomb.Step(1f/60f,new Vector3(1000,0,226),12f);
            Require(bomb.Result=="MISS","ballistic miss");
            var damage=new DamageModel();
            damage.Apply(-10,0);
            Require(damage.Hull==100,"negative damage");
            damage.Apply(20,2);
            Require(damage.Hull==80&&damage.Engines[2]==50&&damage.ThrustFactor<1,"engine damage");
            damage.Apply(1000,2);
            Require(damage.Destroyed&&damage.Hull==0&&damage.Engines[2]==0,"lethal damage");
            foreach(int rate in new[]{30,60,120})
            {
                var sim=new MissionSimulation();
                sim.Paused=true;
                sim.Step(1f/rate);
                Require(sim.Mission.Clock==0&&sim.Flight.Position==new Vector3(0,1200,0),"pause");
                sim.Paused=false;
                for(int i=0;i<rate*1600;i++)
                {
                    sim.Step(1f/rate);
                    Require(!float.IsNaN(sim.Flight.Position.x)&&!float.IsNaN(sim.Flight.Position.z),"finite flight");
                    if(sim.Mission.Phase==MissionPhase.Complete||sim.Mission.Phase==MissionPhase.Failed) break;
                }
                Require(sim.Mission.Phase==MissionPhase.Complete,"complete mission at "+rate+" phase="+sim.Mission.Phase+" bomb="+sim.Bomb.Result+" position="+sim.Flight.Position);
                Require(sim.Bomb.Result=="HIT"&&sim.Flak.BurstCount>20&&sim.Damage.Hull<100,"threats and successful bombing");
                Require(sim.Mission.Clock>600&&sim.Mission.Clock<1200,"mission length "+sim.Mission.Clock);
                Console.WriteLine("Mission {0} steps/s: {1:0.00}s, hull {2:0.0}%, bursts {3}, result {4}",rate,sim.Mission.Clock,sim.Damage.Hull,sim.Flak.BurstCount,sim.Bomb.Result);
                sim.Reset();
                Require(sim.Damage.Hull==100&&!sim.Bomb.Spent&&sim.Flak.BurstCount==0,"full reset");
                sim.FlakDamage=100;
                for(int i=0;i<rate*700;i++)
                {
                    sim.Step(1f/rate);
                    if(sim.Mission.Phase==MissionPhase.Failed) break;
                }
                Require(sim.Mission.Phase==MissionPhase.Failed&&sim.Damage.Destroyed,"mission failure");
            }
            Console.WriteLine("B17_CORE_TESTS_PASS: airborne result invariant, ballistic hit/miss, damage, pause, reset, mission success/failure at 30/60/120 steps/s.");
        }
    }
}
