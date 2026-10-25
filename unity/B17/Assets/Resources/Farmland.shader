Shader "B17/Farmland"
{
    Properties
    {
        _Color ("Field tint", Color) = (0.46,0.50,0.30,1)
        _Scale ("Field scale", Float) = 0.004
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0
        struct Input { float3 worldPos; };
        fixed4 _Color;
        float _Scale;
        float hash(float2 p) { return frac(sin(dot(p,float2(127.1,311.7)))*43758.5453); }
        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv=IN.worldPos.xz*_Scale;
            float2 cell=floor(uv);
            float noise=hash(cell);
            fixed3 grass=lerp(fixed3(.13,.23,.09),fixed3(.40,.43,.18),noise);
            fixed3 soil=lerp(fixed3(.25,.21,.13),fixed3(.48,.40,.22),noise);
            fixed3 baseColor=lerp(grass,soil,step(.62,hash(cell+17)));
            float2 edges=min(frac(uv),1-frac(uv));
            float hedge=1-smoothstep(.004,.015,min(edges.x,edges.y));
            baseColor=lerp(baseColor,fixed3(.08,.13,.055),hedge*.75);
            float furrows=.94+.06*sin((uv.x+uv.y*step(.5,noise))*400);
            baseColor*=furrows;
            float riverX=4000+1500*sin(IN.worldPos.z*.00012)+500*sin(IN.worldPos.z*.00047);
            float river=1-smoothstep(95,130,abs(IN.worldPos.x-riverX));
            baseColor=lerp(baseColor,fixed3(.12,.26,.32),river);
            float road=1-smoothstep(4,7,abs(IN.worldPos.x-350-150*sin(IN.worldPos.z*.0001)));
            baseColor=lerp(baseColor,fixed3(.30,.28,.23),road*(1-river));
            o.Albedo=baseColor*_Color.rgb*2;
            o.Metallic=river*.2;
            o.Smoothness=lerp(.12,.7,river);
            o.Alpha=1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
