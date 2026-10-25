#!/usr/bin/env python3
"""Contextual v4: local sources only, stdlib, never renders or writes M2.
Default builds candidates; --pilot selects four; --promote validates all before copy.
No playback. See sources/README.md for licensing and perspective limitations.
"""
import argparse
import array
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import random
import shutil
import struct
import sys
import wave
import zlib

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'art/audio/redesign_v4'
SOURCES = BASE / 'sources'
CANDIDATES = BASE / 'candidates'
LOG = ROOT / 'logs/audio_redesign'
ACTIVE = ROOT / 'godot/B17/assets/audio/sfx'
SR = 44100
# Explicit authorization boundary: no wildcard bank generation.
TARGETS = '''engine_b17_ext_loop.wav engine_b17_int_loop.wav engine_b17_damaged_loop.wav
engine_sputter_01.wav engine_sputter_02.wav engine_fire_loop.wav wind_altitude_loop.wav
formation_drone_loop.wav hit_hull_01.wav hit_hull_02.wav hit_hull_03.wav
shrapnel_rattle_01.wav damage_alarm_bell.wav fighter_flyby_01.wav fighter_flyby_02.wav
fighter_engine_loop.wav fighter_falling_whine.wav fighter_guns_distant.wav fighter_explosion.wav
flak_near_01.wav flak_near_02.wav flak_near_03.wav flak_far_01.wav flak_far_02.wav
bomb_bay_doors_open.wav bomb_release.wav bomb_impact_distant.wav bomb_secondary_explosions.wav
ui_navigate.wav ui_accept.wav ui_back.wav ui_pause.wav ui_profile_change.wav station_switch.wav
cue_release_tick.wav cue_release_now.wav cue_course_correction.wav radio_squelch_open.wav
radio_squelch_close.wav radio_static_loop.wav stinger_mission_complete.wav stinger_mission_failed.wav'''.split()
PROTECTED = json.loads((LOG / 'm2_protected_hashes.json').read_text())
PILOTS = ['engine_b17_ext_loop.wav','engine_b17_int_loop.wav','flak_near_01.wav','station_switch.wav']
assert len(TARGETS) == 42 and len(set(TARGETS)) == 42
assert not set(TARGETS) & {Path(p).name for p in PROTECTED}


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def guard():
    for p, expected in PROTECTED.items():
        if sha(ROOT / p) != expected:
            raise RuntimeError('M2 protected hash mismatch: ' + p)
    for p, expected in json.loads((LOG / 'immutable_baseline.json').read_text()).items():
        if sha(ROOT / p) != expected:
            raise RuntimeError('Protected integration/source changed: ' + p)


def load_module(path):
    spec = importlib.util.spec_from_file_location('audio_check', path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


CHECK = load_module(ROOT / 'tools_audio/check_sfx.py')


def ns(t):
    return round(t * SR)


def rms(x):
    return math.sqrt(sum(v*v for v in x)/max(1,len(x)))


def db(x):
    return 20 * math.log10(max(1e-12,x))


def low(x, hz):
    # Two cascaded real poles: no tuned/oscillatory resonator.
    a = 1-math.exp(-2*math.pi*hz/SR)
    out=[]; y=z=0.0
    for v in x:
        y += a*(v-y); z += a*(y-z); out.append(z)
    return out


def high(x, hz):
    a=1-math.exp(-2*math.pi*hz/SR); y=0; out=[]
    for v in x:
        y += a*(v-y); out.append(v-y)
    return out


def band(x, lo=100, hi=4000):
    return high(low(x,hi),lo)


def fade(x, attack=.001, release=.025):
    x=x[:]; a=max(1,ns(attack)); b=max(1,ns(release))
    for i in range(min(a,len(x))): x[i]*=i/a
    for i in range(min(b,len(x))): x[-1-i]*=i/b
    return x


def mix(dst, src, time=0, gain=1):
    offset=ns(time)
    for i in range(min(len(src),len(dst)-offset)):dst[offset+i]+=gain*src[i]


def unity(x):
    g=1/max(rms(x),1e-9)
    return [v*g for v in x]


CACHE={}
SOURCE_INFO={}
OPS=[]
USED=set()


def source(key, start, duration, channel=None, speed=1):
    USED.add(key)
    if key not in CACHE:
        meta=json.loads((SOURCES/f'{key}.json').read_text())
        assert meta['license'] in [['http://creativecommons.org/publicdomain/zero/1.0/'], ['https://creativecommons.org/licenses/by/4.0/']]
        assert sha(SOURCES/f'{key}-page.html') == meta['individual_page_sha256']
        assert sha(SOURCES/f'{key}-hq.mp3') == meta['original_sha256']
        path=SOURCES/f'{key}-decoded.wav'
        assert sha(path)==meta['decoded_sha256']
        with wave.open(str(path)) as w:
            assert (w.getnchannels(),w.getsampwidth(),w.getframerate())==(2,2,SR)
            raw=array.array('h',w.readframes(w.getnframes()))
            if sys.byteorder!='little':raw.byteswap()
            CACHE[key]=[[v/32768 for v in raw[c::2]] for c in range(2)]
        SOURCE_INFO[key]=meta
    ch=CACHE[key]
    x=ch[channel] if channel is not None else [(a+b)*.5 for a,b in zip(*ch)]
    n=ns(duration); pos=ns(start); out=[]
    for i in range(n):
        p=pos+i*speed; j=int(p); f=p-j
        out.append(x[j]*(1-f)+x[j+1]*f if 0<=j<len(x)-1 else 0.)
    OPS.append(dict(source=key,start_s=start,output_s=duration,speed=speed,channel=channel))
    return out


def transient(key, duration, offset=0, speed=1, channel=None):
    # Remove pre-roll by locating first 4% of peak; retains actual recorded attack.
    probe=source(key,0,20 if key in ('tnt','alarm') else 2.1,channel)
    if key=='alarm':
        win=ns(.05); env=[rms(probe[i:i+win]) for i in range(0,len(probe),win)]
        threshold=max(env)*.4
        first=next(i for i,v in enumerate(env) if v>threshold)*win
    else:
        threshold=max(abs(v) for v in probe)*.04
        first=next(i for i,v in enumerate(probe) if i >= (ns(2.15) if key=='tnt' else 0) and abs(v)>threshold)
    start=max(0,(first-15)/SR+offset)
    # Probe is detection only, remove it from processing log.
    OPS.pop()
    return source(key,start,duration,channel,speed)


def loop_join(x, width=.2):
    # Rotate an overlap crossfade into the centre; boundary remains adjacent source samples.
    f=ns(width); n=len(x)-f
    y=x[f:]
    for i in range(f):
        t=(i+.5)/f
        y[n-f+i]=x[n+i]*(1-t)+x[i]*t
    k=n//2
    return y[k:]+y[:k]


def ambience(key,start,duration,channel=None,cut=3000):
    return loop_join(band(source(key,start,duration+.2,channel),65,cut))


def noise(rng,n,lo,hi):
    return band([rng.uniform(-1,1) for _ in range(n)],lo,hi)


def mechanic(n, times=(0,), weight=1):
    out=[0.]*n
    for i,t in enumerate(times):
        hit=transient('switch',min(.1,n/SR-t),offset=.0008*(i%2),channel=i%2)
        hit=band(hit,160,4800 if weight<1.2 else 1900)
        mix(out,fade(hit,.0003,.009),t,weight)
    return out


def explosion(duration,variant=0,far=False):
    # Actual demolition recording, no synthetic descending-sine body, no added shrapnel.
    x=transient('tnt',duration,channel=variant%2)
    x=band(x,90 if not far else 100, (2600,2000,3200)[variant%3] if not far else (850,1100)[variant%2])
    return fade(x,.0005,.16 if far else .08)


PATTERNS={
'ui_navigate.wav':(0,), 'ui_accept.wav':(0,.045), 'ui_back.wav':(0,.085),
'ui_pause.wav':(0,.02,.16), 'ui_profile_change.wav':(0,.055),
'station_switch.wav':(0,.07), 'cue_release_tick.wav':(0,),
'cue_release_now.wav':(0,.085,.17), 'cue_course_correction.wav':(0,.15)}


def render(name,duration,nch,loop,rng):
    n=ns(duration); tech=''; kind='derivado de grabación'; limits=''
    if name in PATTERNS:
        x=mechanic(n,PATTERNS[name],1.3 if name in ('ui_back.wav','ui_pause.wav') else 1)
        tech='Interruptor real recortado; patrones por ritmo y peso, HP160/LP1900–4800; sin oscilador'
        limits='Señal de accesibilidad, no instrumento histórico documentado'
    elif name.startswith('engine_b17_') and 'damaged' not in name:
        x=ambience('radial',20,duration,cut=3300 if '_ext_' in name else 1250)
        if '_int_' in name:
            # Combustion detail remains, structural component comes from recorded low frequencies.
            body=low(x[-ns(.3):]+x,210)[ns(.3):];x=[a+.65*b for a,b in zip(x,body)]
        tech='DC-3 radial: ventana 20 s, paso alto65; exterior LP3300 / interior LP1250 y estructura LP210; crossfade200ms'
        limits='Dos motores DC-3 en despegue desde tierra; aproximación, no B-17 en crucero ni cabina real'
    elif name=='engine_b17_damaged_loop.wav' or name.startswith('engine_sputter'):
        x=band(source('radial',23 if name.endswith('01.wav') else 26,duration+(.2 if loop else 0)),220,2800)
        # Only intermittent fault layer: no second healthy full engine ensemble.
        gate=[];i=0;state=0.
        while i<len(x):
            span=rng.randint(ns(.025),ns(.16)); target=rng.choice([.04,.08,.15,1.0])
            for j in range(min(span,len(x)-i)):
                state += .009*(target-state);gate.append(state)
            i+=span
        x=[a*g for a,g in zip(x,gate)]
        ratt=unity(band(transient('metal',.15,offset=.025),400,3500))
        for t in ([.12,.74,1.65,2.58,3.12,4.77,5.23] if loop else [0,.27,.82]):mix(x,ratt,t,.0018)
        x=loop_join(x) if loop else fade(x,.0005,.09)
        tech='Combustión grabada troceada con puerta irregular suavizada + vibración metálica; HP220/LP2800'
        limits='Aproximación de avería aditiva, sin duplicar motor sano completo'
    elif name in ('engine_fire_loop.wav','wind_altitude_loop.wav','formation_drone_loop.wav'):
        if name=='engine_fire_loop.wav':
            a=unity(ambience('fire',.5,duration,cut=2500));b=unity(ambience('wind',20,duration,cut=1900));x=[.2*u+.8*v for u,v in zip(a,b)]
            tech='Fuego de campo + viento grabado 20/80 RMS, banda65–2500/1900; crossfade200ms'
            limits='Fuego de campamento adaptado; no combustible aeronáutico grabado'
        elif name=='wind_altitude_loop.wav':
            channels=[ambience('wind',20,duration,c,cut=3600) for c in range(2)]
            tech='Viento de desierto estéreo filtrado65–3600, sin silbido añadido; crossfade200ms'
            limits='Perspectiva terrestre adaptada, no flujo medido a 6000 m'
            return channels,tech,kind,limits
        else:
            channels=[]
            for c in range(2):
                a=unity(ambience('radial',5+c*7,duration,c,cut=850)); b=unity(ambience('radial',18-c*3,duration,1-c,cut=650))
                channels.append([.65*u+.35*v for u,v in zip(a,b)])
            tech='DC-3 radial: cuatro ventanas distintas, campo difuso estéreo LP650/850; sin sincronía entre capas'
            limits='Campo diseñado, no grabación de 300 B-17'
            return channels,tech,kind,limits
    elif name.startswith('hit_hull') or name=='shrapnel_rattle_01.wav':
        index=int(name[-6:-4]) if name.startswith('hit') else 0
        x=[0.]*n
        if name.startswith('hit'):
            a=transient('sheet' if index!=2 else 'metal',duration,channel=index%2)
            x=[v*math.exp(-i/(SR*(.11 if index==1 else .09))) for i,v in enumerate(band(a,150,6500))]
            if index in (1,3):
                body=fade(band(transient('metal',.16,offset=.035,channel=index%2),200,2600),.0003,.05)
                mix(x,body,.012,.55 if index==1 else .8)
        else:
            for i,t in enumerate([0,.023,.071,.125,.19,.28,.395,.53]):
                a=transient('sheet' if i%2 else 'metal',.13,offset=.002*(i%3),channel=i%2)
                mix(x,fade(band(a,450,6500),.0003,.06),t,rng.uniform(.12,.5))
        x=fade(x,.0003,.035)
        tech='Chapa de acero golpeada / golpe metálico: corte seco, amortiguación exponencial aperiódica; rattle montado irregular'
        limits='Fóley de acero, no perforación balística de aluminio'
    elif name=='damage_alarm_bell.wav':
        x=fade(band(transient('alarm',duration),250,4800),.001,.09)
        tech='Timbre electromecánico escolar: selección del inicio del primer toque, HP250/LP4800'
        limits='Sala escolar en grabación; no alarma certificada de B-17'
    elif name.startswith('fighter_') and any(t in name for t in ('flyby','engine','falling')):
        if 'engine_loop' in name:
            x=ambience('radial',25,duration,cut=3700)
            tech='DC-3 radial, ventana25s HP65/LP3700; crossfade200ms'
        elif 'flyby' in name:
            # Recorded takeoff already contains motion. No second Doppler or synthetic pan.
            start=29 if name.endswith('01.wav') else 31.2
            channels=[fade(band(source('radial',start,duration,c),90,4200),.001,.16) for c in range(2)]
            tech='Dos ventanas del paso real del DC-3: 29s y31.2s; estéreo original, sin Doppler/pan adicional'
            limits='Aproximación de paso de pistón radial; no Bf109/Fw190 ni dos pasadas independientes'
            return channels,tech,kind,limits
        else:
            x=fade(band(source('radial',32,duration),140,3200),.001,.25)
            tech='Alejamiento real de pistón, HP140/LP3200; sin silbido de turbina ni caída senoidal'
        limits='DC-3 usado como aproximación de pistón; no modelo de caza ni caída real'
    elif name.startswith('flak_') or name in ('fighter_explosion.wav','bomb_impact_distant.wav','bomb_secondary_explosions.wav'):
        far=('far' in name or name.startswith('bomb_'))
        index=int(name[-6:-4])-1 if name.startswith('flak') else 0
        if name=='bomb_secondary_explosions.wav':
            x=[0.]*n
            for k,(t,g) in enumerate([(0,.8),(.47,.37),(1.24,.62),(2.16,.29)]):mix(x,explosion(1.8,k,True),t,g)
        else:x=explosion(duration,index,far)
        if name=='fighter_explosion.wav':
            a=unity(band(source('fire',5,duration),200,3100));mix(x,a,0,rms(x)*.09)
        tech='Demolición real TNT: ataque/cola recortados, HP90–100; LP2000–3200 cerca /850–1100 lejos; sin metralla añadida en flak'
        limits='Explosión terrestre adaptada, no proyectil88mm ni rotura aérea documentada; variantes comparten toma'
    elif name=='fighter_guns_distant.wav':
        # Explicit synthesis fallback, completely separate from protected M2/source_m2.
        x=[0.]*n
        for k in range(10):
            m=ns(.16); shot=noise(rng,m,180,1750)
            shot=[v*(.7*math.exp(-i/ns(.025))+.3*math.exp(-i/ns(.07))) for i,v in enumerate(shot)]
            mix(x,fade(shot,.0004,.02),k*.096,rng.uniform(.7,1))
        tech='Síntesis aperiódica independiente: ráfaga10 golpes de ruido180–1750Hz, colas25/70ms; no fuente M2'
        kind='síntesis';limits='Sin grabación compatible de cañón aéreo encontrada; no autenticidad MG151/20'
    elif name in ('bomb_bay_doors_open.wav','bomb_release.wav'):
        x=mechanic(n,(0,.075) if 'release' in name else (0,.09,2.27,2.37),1.4)
        if 'doors' in name:
            a=unity(band(source('metal',.36,1.85),220,2400));b=unity(band(source('wind',30,duration),100,2200))
            mix(x,[v*.008 for v in a],.17)
            x=[v+.009*b[i]*min(1,i/ns(.9)) for i,v in enumerate(x)]
        else:
            a=fade(band(transient('sheet',.18),180,3200),.0003,.07);mix(x,a,.014,.35)
            body=fade(band(transient('metal',.28,offset=.035),180,1900),.0004,.1);mix(x,body,.006,.7)
        x=fade(x,.0004,.07)
        tech='Fóley de pestillos con interruptor + metal; puertas añaden fricción y viento progresivo; sin pitido'
        limits='Aproximación mecánica; no motor ni bisagras originales de compuerta B-17'
    elif name.startswith('radio_'):
        x=noise(rng,n+ (ns(.2) if loop else 0),350,2700)
        # Aperiodic fading and sparse bandlimited clicks, no exposed heterodyne sine.
        state=.5
        for i in range(len(x)):
            if i%ns(.073)==0: target=rng.uniform(.15,1)
            state += .0007*(target-state);x[i]*=state
        for k in range(max(2,int(duration*6))):
            m=ns(.009);click=noise(rng,m,600,3000)
            mix(x,[v*math.exp(-i/ns(.0015)) for i,v in enumerate(click)],rng.uniform(0,duration-.012),.35)
        x=[math.tanh(v*1.8) for v in x]
        if loop:x=loop_join(x)
        else:
            x=fade(x,.001,.035);mix(x,mechanic(n,(0,) if 'open' in name else (0,.14)),0,.3)
        tech='Ruido de banda350–2700 con fluctuación aperiódica, chasquidos y saturación tanh suave; interruptor grabado en squelch'
        kind='síntesis' if loop else 'híbrido grabación/síntesis'
        limits='Solo estática y squelch, sin mensajes hablados'
    elif name.startswith('stinger_'):
        failed='failed' in name;channels=[]
        for c in range(2):
            a=unity(band(source('wind',45+c*5,duration,c),90,1200 if failed else 2500))
            b=unity(band(source('radial',33+c,duration,c),80,950))
            x=[]
            for i,(u,v) in enumerate(zip(a,b)):
                t=i/n; env=(1-t)**(1.5 if failed else .7)
                x.append((.72*u+.28*v)*env)
            mix(x,mechanic(n,(0,.12) if failed else (0,)),0,.15)
            channels.append(fade(x,.001,.35))
        tech='Cierre ambiental4s: aire + alejamiento radial + conmutador; fracaso se apaga más rápido y más filtrado'
        limits='Sin música ni voces; lectura emocional pendiente de escucha'
        return channels,tech,kind,limits
    else:raise ValueError(name)
    return [x],tech,kind,limits


def normalize(channels,target,loop=False):
    # Gain only: preserve transient crest; do not limit to force an RMS target.
    channels=[high(c[-ns(.3):]+c,30)[ns(.3):] if loop else high(c,30) for c in channels]
    mean=[sum(c)/len(c) for c in channels]
    channels=[[v-m for v in c] for c,m in zip(channels,mean)]
    r=math.sqrt(sum(v*v for c in channels for v in c)/sum(map(len,channels)))
    peak=max(abs(v) for c in channels for v in c)
    gain=min(10**(target/20)/max(r,1e-12),10**(-1.2/20)/max(peak,1e-12))
    channels=[[v*gain for v in c] for c in channels]
    if loop:
        n=len(channels[0])
        k=min(range(n//4,3*n//4),key=lambda i:max(abs(c[i]-c[i-1]) for c in channels))
        channels=[c[k:]+c[:k] for c in channels]
        OPS.append({'operation':'rotate_loop_after_circular_HP30', 'samples':k})
    return channels,gain


def write(path,channels,loop=False):
    n=len(channels[0]);nch=len(channels);assert all(len(c)==n for c in channels)
    data=array.array('h',(round(channels[c][i]*32767) for i in range(n) for c in range(nch)))
    if sys.byteorder!='little':data.byteswap()
    with wave.open(str(path),'wb') as w:
        w.setparams((nch,2,SR,n,'NONE','not compressed'));w.writeframes(data.tobytes())
    if loop:
        smpl=struct.pack('<9I',0,0,round(1e9/SR),60,0,0,0,1,0)+struct.pack('<6I',0,0,0,n-1,0,0)
        with path.open('r+b') as f:
            f.seek(0,2);f.write(b'smpl'+struct.pack('<I',len(smpl))+smpl);size=f.tell();f.seek(4);f.write(struct.pack('<I',size-8))


def validate(name):
    result=CHECK.analyse(str(CANDIDATES/name),CHECK.EXPECTED[name])
    with wave.open(str(CANDIDATES/name)) as w:
        vals=array.array('h',w.readframes(w.getnframes()))
        if sys.byteorder!='little':vals.byteswap()
        ch=[vals[c::w.getnchannels()] for c in range(w.getnchannels())]
    result['dc_fs']=max(abs(sum(c)/len(c))/32768 for c in ch)
    assert result['dc_fs']<.001,(name,'DC')
    assert not result['errors'],(name,result['errors'])
    if CHECK.EXPECTED[name][2]:
        # Ten repetitions, every join and 50 ms envelope against interior distribution.
        seam=max(abs(c[-1]-c[0])/32768 for c in ch)
        windows=[rms(c[i:i+ns(.05)])/32768 for c in ch for i in range(0,len(c)-ns(.05),ns(.05))]
        boundaries=[rms(c[-ns(.025):]+c[:ns(.025)])/32768 for c in ch]
        result['ten_repeat_analysis']={'joins':9,'max_jump_fs':seam,'boundary_rms_dbfs':[db(v) for v in boundaries],
            'interior_min_dbfs':db(min(windows)),'interior_max_dbfs':db(max(windows)),
            'no_boundary_gap':min(boundaries)>=min(windows)*.65,'method':'identical deterministic periods; all nine joins identical; envelope 50ms'}
        assert result['ten_repeat_analysis']['no_boundary_gap'],name
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--pilot',action='store_true');p.add_argument('--promote',action='store_true');a=p.parse_args()
    assert not(a.pilot and a.promote)
    guard();CANDIDATES.mkdir(parents=True,exist_ok=True)
    names=PILOTS if a.pilot else TARGETS
    manifest={};results=[]
    for name in names:
        OPS.clear();USED.clear()
        spec=CHECK.EXPECTED[name]; duration=spec[0] if isinstance(spec[0],float) else (1.25 if name.startswith('engine_sputter') else .3 if name.startswith('hit') else 3.5 if 'flyby' in name else 1.5)
        channels,tech,kind,limits=render(name,duration,2 if spec[1] else 1,spec[2],random.Random(zlib.crc32(name.encode())))
        if not spec[2]:channels=[fade(c,.0003,.008) for c in channels]
        channels,gain=normalize(channels,CHECK.LEVELS[spec[3]],spec[2])
        write(CANDIDATES/name,channels,spec[2]);r=validate(name);results.append(r)
        manifest[name]={'kind':kind,'sources':[{**SOURCE_INFO[k], 'key':k} for k in sorted(USED)],'cuts':OPS[:],
            'technique':tech,'limitations':limits,'linear_gain':gain,'gain_db':db(gain),'duration_s':duration,
            'channels':len(channels),'sample_rate':SR,'bits':16,'final_processing':'HP30Hz, remove DC, gain-only RMS target capped at -1.2dBFS; no limiter; PCM16 quantization','rms_dbfs':r['rms_dbfs'],'peak_dbfs':r['peak_dbfs'],
            'previous_sha256':sha(LOG/'backup'/name),'final_sha256':sha(CANDIDATES/name),'changed':sha(LOG/'backup'/name)!=sha(CANDIDATES/name)}
        print('VALID',name,r['rms_dbfs'],r['peak_dbfs'],flush=True)
    suffix='pilot' if a.pilot else 'full'
    (BASE/f'manifest_{suffix}.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False))
    (LOG/f'candidate_checks_{suffix}.json').write_text(json.dumps(results,indent=2))
    if a.promote:
        # Stage complete validation before touching active bank; check guard after EVERY copy.
        assert len(manifest)==42
        for name in TARGETS:
            guard();assert name not in {Path(p).name for p in PROTECTED}
            shutil.copyfile(CANDIDATES/name,ACTIVE/name);guard()
        (LOG/'promotion.json').write_text(json.dumps({'changed':[n for n in TARGETS if manifest[n]['changed']],
            'protected':{p:sha(ROOT/p) for p in PROTECTED},'hash_checks_after_each_copy':42},indent=2))
    guard()


if __name__=='__main__':main()
