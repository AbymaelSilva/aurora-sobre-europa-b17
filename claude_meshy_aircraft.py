#!/usr/bin/env python3
"""Claude: aviones 3D con Meshy image-to-3D a partir de las referencias de OpenArt.

La clave se pide oculta en esta terminal y no se guarda. Primero hace una prueba piloto con el caza
(el más barato). Solo sigue con el resto si la prueba termina bien. Registra cada cargo real.
"""
from pathlib import Path
import base64
import getpass
import json
import os
import sys
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'art/meshy/aircraft'
MANIFEST = ROOT / 'art/openart/refs/manifest.json'
API = 'https://api.meshy.ai'

# (nombre, endpoint, claves de imagen del manifiesto, caras objetivo)
JOBS = [
    ('bf109g', 'image-to-3d', ['AV2'], 15000),
    ('b17g', 'multi-image-to-3d', ['AV1', 'AV1-side', 'AV1-top'], 30000),
    ('fw190a', 'image-to-3d', ['AV3'], 15000),
    ('p51d', 'image-to-3d', ['AV4'], 15000),
]


def call(key: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, headers={'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f'Meshy {exc.code} en {path}: {exc.read().decode(errors="replace")[:800]}') from None


def balance(key: str) -> int:
    return int(call(key, '/openapi/v1/balance').get('balance', 0))


def run_job(key: str, refs: dict, name: str, endpoint: str, ref_keys: list, polycount: int) -> dict:
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    sub = folder / 'submission.json'
    if sub.exists() and json.loads(sub.read_text()).get('task_id'):
        task_id = json.loads(sub.read_text())['task_id']
        print(f'[{name}] retomando tarea existente {task_id} (sin nuevo cargo)', flush=True)
    else:
        # Data URI desde el archivo local: el CDN de OpenArt responde 403 a clientes que no son navegador.
        urls = ['data:image/png;base64,' + base64.b64encode((ROOT / refs[k]).read_bytes()).decode() for k in ref_keys]
        # Parámetros comprobados en docs.meshy.ai (2026-10-24): symmetry_mode está obsoleto.
        body = {'ai_model': 'latest', 'topology': 'triangle', 'target_polycount': polycount,
                'should_remesh': True, 'should_texture': True, 'enable_pbr': True, 'target_formats': ['glb']}
        body.update({'image_url': urls[0]} if endpoint == 'image-to-3d' else {'image_urls': urls})
        logged = {k: (v if k not in ('image_url', 'image_urls') else ref_keys) for k, v in body.items()}
        sub.write_text(json.dumps({'attempted': time.time(), 'request': logged}, indent=2))
        before = balance(key)
        task_id = call(key, f'/openapi/v1/{endpoint}', body)['result']
        sub.write_text(json.dumps({'task_id': task_id, 'request': logged, 'balance_before': before}, indent=2))
        print(f'[{name}] tarea {task_id} enviada; saldo antes {before}', flush=True)
    while True:
        task = call(key, f'/openapi/v1/{endpoint}/{task_id}')
        (folder / 'task.json').write_text(json.dumps(task, indent=2))
        status = task.get('status')
        print(f'[{name}] {status} {task.get("progress", 0)}%', flush=True)
        if status in ('SUCCEEDED', 'FAILED', 'CANCELED'):
            break
        time.sleep(15)
    if status != 'SUCCEEDED':
        raise RuntimeError(f'[{name}] terminó en {status}: {task.get("task_error")}')
    for label, url in [('model.glb', task['model_urls']['glb']), ('preview.png', task.get('thumbnail_url', ''))]:
        if url:
            urllib.request.urlretrieve(url, folder / label)
    after = balance(key)
    record = {'name': name, 'task_id': task_id, 'consumed_credits': task.get('consumed_credits'), 'balance_after': after}
    print(f'[{name}] OK → {folder / "model.glb"}; créditos {record["consumed_credits"]}; saldo {after}', flush=True)
    return record


def main() -> None:
    refs = json.loads(MANIFEST.read_text())
    key = os.environ.get('MESHY_API_KEY', '').strip() or getpass.getpass('Clave API Meshy (oculta, no se guardará): ').strip()
    if not key:
        raise SystemExit('Sin clave: no se genera nada.')
    print('Saldo Meshy:', balance(key), flush=True)
    log = OUT / 'charges.json'
    OUT.mkdir(parents=True, exist_ok=True)
    charges = json.loads(log.read_text()) if log.exists() else []
    only = sys.argv[1:]
    for index, (name, endpoint, ref_keys, polycount) in enumerate(JOBS):
        if only and name not in only:
            continue
        if (OUT / name / 'model.glb').exists():
            print(f'[{name}] ya existe; se omite', flush=True)
            continue
        if any(k not in refs for k in ref_keys):
            print(f'[{name}] faltan referencias {ref_keys}; se omite', flush=True)
            continue
        try:
            charges.append(run_job(key, refs, name, endpoint, ref_keys, polycount))
        except RuntimeError as exc:
            print('ERROR:', exc, flush=True)
            charges.append({'name': name, 'error': str(exc)})
            if index == 0:
                log.write_text(json.dumps(charges, indent=2))
                raise SystemExit('La prueba piloto falló: no se envía nada más. Claude revisará el error.')
        log.write_text(json.dumps(charges, indent=2))
    print('\nTerminado. Claude inspeccionará los GLB antes de usarlos.', flush=True)


if __name__ == '__main__':
    main()
