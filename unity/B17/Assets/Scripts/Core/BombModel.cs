using UnityEngine;

namespace B17
{
    public sealed class BombModel
    {
        public bool Active = false;
        public bool Spent = false;
        public Vector3 Position = Vector3.zero;
        public Vector3 Velocity = Vector3.zero;
        public string Result = "READY";

        public void Reset()
        {
            Active = false;
            Spent = false;
            Position = Vector3.zero;
            Velocity = Vector3.zero;
            Result = "READY";
        }

        public bool Release(Vector3 position, Vector3 velocity)
        {
            if (Spent)
                return false;
            Spent = true;
            Active = true;
            Position = position;
            Velocity = velocity;
            Result = "AIRBORNE";
            return true;
        }

        public void Step(float dt, Vector3 target, float radius)
        {
            if (!Active)
                return;
            dt = Mathf.Clamp(dt, 0, 0.05f);
            Position += Velocity * dt + Vector3.down * (4.905f * dt * dt);
            Velocity += Vector3.down * (9.81f * dt);
            if (Position.y <= target.y)
            {
                Position.y = target.y;
                Active = false;
                Vector2 distance = new Vector2(Position.x - target.x, Position.z - target.z);
                Result = distance.magnitude <= radius ? "HIT" : "MISS";
            }
        }
    }
}
