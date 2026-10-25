#!/usr/bin/env python3
"""TTS local Piper y partitura original renderizada con FluidSynth/TimGM6mb.

No escribe assets/audio/sfx. Guarda las voces brutas como fuente reproducible.
LD_LIBRARY_PATH=tools_voice/runtime/usr/lib/x86_64-linux-gnu python3 -I tools_voice/build_scene_audio.py
"""
import array
import ctypes as c
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import random
import subprocess
import sys
import wave

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('sfx_utilities', ROOT / 'tools_audio/synth_sfx.py')
s = importlib.util.module_from_spec(spec)
spec.loader.exec_module(s)
VOICE = ROOT / 'godot/B17/assets/audio/voice'
MUSIC = ROOT / 'godot/B17/assets/audio/music'
RAW = ROOT / 'art/dialogue/raw'
RAW.mkdir(parents=True, exist_ok=True)


def voices():
    catalog = json.loads((VOICE / 'dialogue_catalog.json').read_text())
    for name, locale in [('joe', 'en_US'), ('john', 'en_US')]:
        requests = []
        for ident, entry in catalog.items():
            if entry['voice'] != name:
                continue
            spoken = entry.get('spoken_text', entry['text'])
            digest = hashlib.sha256((name + spoken).encode()).hexdigest()[:12]
            entry['raw'] = str((RAW / f'{ident}_{digest}.wav').relative_to(ROOT))
            path = ROOT / entry['raw']
            if not path.exists():
                requests.append(json.dumps({'text': spoken, 'output_file': str(path)}, ensure_ascii=False))
        if requests:
            subprocess.run([str(ROOT / 'tools_voice/piper/piper'), '--model',
                            str(ROOT / f'tools_voice/{locale}-{name}-medium.onnx'),
                            '--json-input', '--length_scale', '1.03' if name == 'joe' else '0.98',
                            '--sentence_silence', '0.12', '--quiet'],
                           input='\n'.join(requests)+'\n', text=True, check=True)
    for ident, entry in catalog.items():
        with wave.open(str(ROOT / entry['raw'])) as w:
            assert w.getnchannels() == 1 and w.getsampwidth() == 2
            rate = w.getframerate()
            raw = array.array('h', w.readframes(w.getnframes()))
        source = [v / 32768 for v in raw]
        # Recortar silencio manteniendo margen para consonantes suaves.
        start = next((i for i,v in enumerate(source) if abs(v) > .008), 0)
        end = next((len(source)-i for i,v in enumerate(reversed(source)) if abs(v) > .008), len(source))
        source = source[max(0,start-int(rate*.035)):min(len(source),end+int(rate*.09))]
        n = int(len(source) * s.SR / rate)
        x = []
        for i in range(n):
            p = i * rate / s.SR
            k = min(len(source)-1, int(p))
            u = p-k
            x.append(source[k]*(1-u) + source[min(k+1,len(source)-1)]*u)
        x = s.lowpass(s.highpass(x, 220, .7), 3500, .7)
        x = s.soft_clip(x, 1.15)
        x = s.finalize([x], -18.0)[0]
        rng = random.Random(ident)
        hiss = s.bandpass(s.white(len(x), rng), 1800, .6)
        x = [(v + h*.00035) for v,h in zip(x,hiss)]
        x = s.fade_edges(x, .004, .012)
        s.write_wav(str(VOICE / entry['file']), [x])
        entry['duration'] = round(len(x)/s.SR, 4)
        entry['sha256'] = hashlib.sha256((VOICE/entry['file']).read_bytes()).hexdigest()
        print('VOICE', ident, entry['duration'], flush=True)
    (VOICE / 'dialogue_catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2))


def fluid_api():
    lib = c.CDLL(str(ROOT / 'tools_voice/runtime/usr/lib/x86_64-linux-gnu/libfluidsynth.so.3'))
    signatures = {
        'new_fluid_settings': (c.c_void_p, []),
        'fluid_settings_setnum': (c.c_int,[c.c_void_p,c.c_char_p,c.c_double]),
        'fluid_settings_setint': (c.c_int,[c.c_void_p,c.c_char_p,c.c_int]),
        'new_fluid_synth': (c.c_void_p,[c.c_void_p]),
        'fluid_synth_sfload': (c.c_int,[c.c_void_p,c.c_char_p,c.c_int]),
        'fluid_synth_program_change': (c.c_int,[c.c_void_p,c.c_int,c.c_int]),
        'fluid_synth_cc': (c.c_int,[c.c_void_p,c.c_int,c.c_int,c.c_int]),
        'fluid_synth_noteon': (c.c_int,[c.c_void_p,c.c_int,c.c_int,c.c_int]),
        'fluid_synth_noteoff': (c.c_int,[c.c_void_p,c.c_int,c.c_int]),
        'fluid_synth_write_s16': (c.c_int,[c.c_void_p,c.c_int,c.c_void_p,c.c_int,c.c_int,c.c_void_p,c.c_int,c.c_int]),
        'delete_fluid_synth': (None,[c.c_void_p]),
        'delete_fluid_settings': (None,[c.c_void_p]),
    }
    for name,(restype,args) in signatures.items():
        fn=getattr(lib,name);fn.restype=restype;fn.argtypes=args
    return lib


def music():
    lib=fluid_api()
    progressions={
        'formation':[(50,57,60,65),(46,53,58,62),(41,53,57,60),(48,55,60,64)],
        'approach':[(50,57,60,64),(46,53,58,62),(43,50,55,58),(45,52,57,61)],
        'combat':[(38,50,57,60),(38,50,56,60),(46,53,58,61),(45,52,57,61)],
        'bombing':[(50,57,60,64),(50,57,60,65),(46,53,58,62),(45,52,57,61)],
        'return':[(41,53,57,60),(48,55,60,64),(46,53,58,62),(41,53,57,62)],
        'complete':[(41,53,57,60),(46,53,58,62),(48,55,60,64),(41,53,57,60)],
        'failed':[(38,50,53,57),(46,53,58,60),(43,50,55,58),(38,50,53,57)],
    }
    manifest={}
    for key,chords in progressions.items():
        loop=key not in ('complete','failed')
        duration=32.0 if loop else (16.0 if key=='complete' else 12.0)
        setting=lib.new_fluid_settings()
        lib.fluid_settings_setnum(setting,b'synth.sample-rate',44100)
        lib.fluid_settings_setnum(setting,b'synth.gain',.45)
        lib.fluid_settings_setnum(setting,b'synth.reverb.room-size',.65)
        lib.fluid_settings_setnum(setting,b'synth.reverb.damp',.55)
        lib.fluid_settings_setnum(setting,b'synth.reverb.level',.24)
        lib.fluid_settings_setint(setting,b'synth.chorus.active',0)
        lib.fluid_settings_setint(setting,b'synth.cpu-cores',1)
        synth=lib.new_fluid_synth(setting)
        sf=ROOT/'tools_voice/runtime/usr/share/sounds/sf2/TimGM6mb.sf2'
        assert lib.fluid_synth_sfload(synth,os.fsencode(sf),1)>=0
        for ch,prog,panning in [(0,48,38),(1,42,78),(2,60,60),(3,0,50),(4,68,85)]:
            lib.fluid_synth_program_change(synth,ch,prog)
            lib.fluid_synth_cc(synth,ch,10,panning)
            lib.fluid_synth_cc(synth,ch,7,85)
        events=[]
        def note(t,length,ch,pitch,vel):
            events.append((s.ns(t),1,ch,pitch,vel))
            events.append((s.ns(t+length),0,ch,pitch,0))
        rng=random.Random(1944+sum(map(ord,key)))
        for rep in range(3 if loop else 1):
            base=rep*duration
            bar=duration/4
            for baridx,chord in enumerate(chords):
                t=base+baridx*bar
                for j,p in enumerate(chord[1:]):
                    note(t+.025*j,bar*.92,0,p,43 if key!='combat' else 54)
                note(t,bar*.90,1,chord[0],51)
                if key in ('combat','bombing','approach'):
                    step=.5 if key=='combat' else 1.0
                    for beat in range(int(bar/step)):
                        note(t+beat*step,step*.65,3,chord[1]+(12 if beat%2 else 0),37+rng.randrange(10))
                        if key=='combat' and beat%2==0:
                            note(t+beat*step,.18,9,41,43+rng.randrange(7))
                else:
                    for beat,p in enumerate([chord[1]+12,chord[2]+12,chord[3]+12,chord[2]+12]):
                        note(t+beat*bar/4,bar/4*.8,3,p,34+rng.randrange(7))
                if baridx%2==1:
                    note(t+bar*.25,bar*.6,2,chord[2],36)
                if key in ('formation','return','complete'):
                    note(t+bar*.50,bar*.35,4,chord[3]+12,34)
        events.sort()
        total=s.ns(duration*2+.6 if loop else duration)
        L=array.array('h');R=array.array('h');pos=0;ei=0
        while pos<total:
            while ei<len(events) and events[ei][0]<=pos:
                _,kind,ch,p,v=events[ei]
                if kind:lib.fluid_synth_noteon(synth,ch,p,v)
                else:lib.fluid_synth_noteoff(synth,ch,p)
                ei+=1
            end=min(total,pos+2048,events[ei][0] if ei<len(events) else total)
            count=end-pos
            if count<=0:continue
            lb=(c.c_short*count)();rb=(c.c_short*count)()
            lib.fluid_synth_write_s16(synth,count,lb,0,1,rb,0,1)
            L.extend(lb);R.extend(rb);pos=end
        lib.delete_fluid_synth(synth);lib.delete_fluid_settings(setting)
        channels=[[v/32768 for v in buf] for buf in [L,R]]
        if loop:
            channels=[buf[s.ns(duration):] for buf in channels]
            channels=s.make_loop(channels,s.ns(duration),s.ns(.5))
        else:
            channels=[s.fade_edges(buf,.10,1.3) for buf in channels]
        channels=s.finalize(channels,-23.0)
        name=key+('_loop.wav' if loop else '.wav')
        s.write_wav(str(MUSIC/name),channels,loop)
        manifest[key]={'file':name,'duration':duration,'loop':loop,'sha256':hashlib.sha256((MUSIC/name).read_bytes()).hexdigest(),'composition':'Original Codex; chamber orchestral instruments rendered with FluidSynth + TimGM6mb'}
        print('MUSIC',key,duration,flush=True)
    (MUSIC/'music_catalog.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))


if __name__=='__main__':
    if '--music-only' not in sys.argv:voices()
    if '--voice-only' not in sys.argv:music()
