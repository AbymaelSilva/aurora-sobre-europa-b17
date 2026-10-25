using UnityEngine;

namespace B17
{
    public sealed class MissionSimulation
    {
        public readonly FlightModel Flight = new FlightModel();
        public readonly BombModel Bomb = new BombModel();
        public readonly DamageModel Damage = new DamageModel();
        public readonly FlakModel Flak = new FlakModel();
        public readonly MissionModel Mission = new MissionModel();

        public bool AutoPilot = true;
        public bool Paused = false;
        public bool LastFlakBurst = false;

        public float PitchInput = 0;
        public float TurnInput = 0;
        public float ThrottleInput = 0;
        public float FlakDamage = 1.1f;

        public void Reset()
        {
            Flight.Reset();
            Bomb.Reset();
            Damage.Reset();
            Flak.Reset();
            Mission.Reset();
            Paused = false;
            LastFlakBurst = false;
            PitchInput = TurnInput = ThrottleInput = 0;
        }

        public bool ReleaseBomb()
        {
            if (Mission.Phase != MissionPhase.BombRun)
                return false;
            else
                return Bomb.Release(Flight.Position, Flight.Forward * Flight.Speed);
        }

        public void Step(float dt)
        {
            LastFlakBurst = false;
            if (Paused || Mission.Phase == MissionPhase.Complete || Mission.Phase == MissionPhase.Failed)
                return;

            dt = Mathf.Clamp(dt, 0, 0.05f);
            Mission.Step(dt, Flight.Position, Bomb.Result, Damage.Destroyed);

            float pitch = PitchInput;
            float turn = TurnInput;
            float throttle = ThrottleInput;

            if (AutoPilot)
            {
                Vector3 offset = Mission.NavigationTarget() - Flight.Position;
                float desiredYaw = Mathf.Atan2(offset.x, offset.z) * Mathf.Rad2Deg;
                turn = Mathf.Clamp(Mathf.DeltaAngle(Flight.HeadingDegrees, desiredYaw) / 25, -1, 1);
                pitch = Mathf.Clamp((1200 - Flight.Position.y) / 80, -1, 1);
                throttle = 0;
            }

            Flight.Speed = Mathf.MoveTowards(Flight.Speed, 85 * Damage.ThrustFactor, dt * 2);
            Flight.Step(pitch, turn, throttle, dt);

            bool inZone = Flight.Position.z > 13000 && Flight.Position.z < 26500 && Mathf.Abs(Flight.Position.x) < 1000;
            LastFlakBurst = Flak.Step(dt, inZone);

            if (LastFlakBurst && Flak.BurstCount % 3 != 0)
                Damage.Apply(FlakDamage, Flak.BurstCount % 4);

            if (Mission.Phase == MissionPhase.BombRun && AutoPilot && !Bomb.Spent)
            {
                Vector3 velocity = Flight.Forward * Flight.Speed;
                float falltime = (velocity.y + Mathf.Sqrt(velocity.y * velocity.y + 19.62f * Flight.Position.y)) / 9.81f;
                Vector3 predicted = Flight.Position + velocity * falltime;
                float horizontalDistance = Vector2.Distance(new Vector2(predicted.x,predicted.z),new Vector2(Mission.Target.x,Mission.Target.z));

                if (horizontalDistance < 45)
                    ReleaseBomb();

            }

            Bomb.Step(dt, Mission.Target, 120);
            Mission.Step(0, Flight.Position, Bomb.Result, Damage.Destroyed);
        }
    }
}
