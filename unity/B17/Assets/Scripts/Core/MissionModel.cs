using UnityEngine;

namespace B17
{
    public enum MissionPhase { Formation, Approach, BombRun, Return, Complete, Failed }

    public sealed class MissionModel
    {
        public MissionPhase Phase = MissionPhase.Formation;
        public int WaypointIndex = 0;
        public float Clock = 0;
        public Vector3[] Waypoints = { new Vector3(0, 1200, 6000), new Vector3(0, 1200, 14000), new Vector3(0, 1200, 22000) };
        public Vector3 Target = new Vector3(0, 0, 30000);
        public Vector3 ExitPoint = new Vector3(28000, 1200, 15000);

        public void Reset()
        {
            Phase = MissionPhase.Formation;
            WaypointIndex = 0;
            Clock = 0;
        }

        public void Step(float dt, Vector3 position, string bombResult, bool destroyed)
        {
            if (Phase == MissionPhase.Complete || Phase == MissionPhase.Failed)
                return;

            if (destroyed)
            {
                Phase = MissionPhase.Failed;
                return;
            }

            Clock += Mathf.Max(0, dt);

            if (Phase == MissionPhase.Formation && Clock >= 35)
                Phase = MissionPhase.Approach;

            if (Phase == MissionPhase.Approach && WaypointIndex < Waypoints.Length && Vector3.Distance(position, Waypoints[WaypointIndex]) < 300)
            {
                WaypointIndex++;
                if (WaypointIndex >= Waypoints.Length)
                    Phase = MissionPhase.BombRun;
            }

            if (Phase == MissionPhase.BombRun && bombResult == "HIT")
                Phase = MissionPhase.Return;
            else if (Phase == MissionPhase.BombRun && bombResult == "MISS")
                Phase = MissionPhase.Failed;

            if (Phase == MissionPhase.Return && Vector3.Distance(position, ExitPoint) < 500)
                Phase = MissionPhase.Complete;
        }

        public Vector3 NavigationTarget()
        {
            switch (Phase)
            {
                case MissionPhase.Formation:
                    return Waypoints[0];
                case MissionPhase.Approach:
                    return Waypoints[Mathf.Min(WaypointIndex, Waypoints.Length - 1)];
                case MissionPhase.Return:
                    return ExitPoint;
                default:
                    return Target + new Vector3(0, 1200, 4000);
            }
        }
    }
}
