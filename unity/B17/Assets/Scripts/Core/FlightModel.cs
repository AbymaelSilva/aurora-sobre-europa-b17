using UnityEngine;

namespace B17
{
    public sealed class FlightModel
    {
        public Vector3 Position = new Vector3(0, 1200, 0);
        public float HeadingDegrees = 0;
        public float PitchDegrees = 0;
        public float Speed = 85;

        public Vector3 Forward
        {
            get
            {
                double yaw = HeadingDegrees * System.Math.PI / 180.0;
                double pitch = PitchDegrees * System.Math.PI / 180.0;
                return new Vector3((float)(System.Math.Sin(yaw) * System.Math.Cos(pitch)), (float)System.Math.Sin(pitch), (float)(System.Math.Cos(yaw) * System.Math.Cos(pitch)));
            }
        }

        public void Reset()
        {
            Position = new Vector3(0, 1200, 0);
            HeadingDegrees = 0;
            PitchDegrees = 0;
            Speed = 85;
        }

        public void Step(float pitchInput, float turnInput, float throttleInput, float dt)
        {
            dt = Mathf.Clamp(dt, 0, 0.05f);
            HeadingDegrees += Mathf.Clamp(turnInput, -1, 1) * 18 * dt;
            PitchDegrees = Mathf.MoveTowards(PitchDegrees, Mathf.Clamp(pitchInput, -1, 1) * 10, 8 * dt);
            Speed = Mathf.Clamp(Speed + Mathf.Clamp(throttleInput, -1, 1) * 8 * dt, 55, 110);
            Position += Forward * Speed * dt;
            Position.y = Mathf.Max(Position.y, 30);
        }
    }
}
