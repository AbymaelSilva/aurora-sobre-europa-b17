"""Candidato local B17 (supervisor Claude): staging + manifiesto + restauración en frío verificada."""
import hashlib, json, shutil, subprocess, sys
from datetime import datetime
from pathlib import Path

ROOT = Path('/home/test-bench/Documents/B17-project')
PROJECT = ROOT / 'godot/B17'


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def production_files():
    return [p for p in sorted(PROJECT.rglob('*')) if p.is_file() and '.godot' not in p.relative_to(PROJECT).parts]


def digest(files):
    h = hashlib.sha256()
    for p in files:
        h.update(str(p.relative_to(PROJECT)).encode()); h.update(sha(p).encode())
    return h.hexdigest()


files = production_files()
before = {str(p.relative_to(PROJECT)): sha(p) for p in files}
prod_digest = digest(files)
cid = f"local-{datetime.now():%Y%m%d}-{prod_digest[:12]}"
out = ROOT / 'release' / cid
if out.exists():
    sys.exit(f'Ya existe {out}; no se sobrescribe.')
src = out / 'source'
shutil.copytree(PROJECT, src / 'godot/B17', ignore=shutil.ignore_patterns('.godot'))
(src / 'tools').mkdir(parents=True)
shutil.copy2(ROOT / 'tools/godot', src / 'tools/godot')
if (ROOT / 'tools/godot-version.txt').exists():
    shutil.copy2(ROOT / 'tools/godot-version.txt', src / 'tools/godot-version.txt')
for name in ['INICIAR_B17.sh', 'jugar_b17.py']:
    shutil.copy2(ROOT / name, src / name)
(src / 'logs').mkdir()

manifest = {'candidate_id': cid, 'status': 'CANDIDATO_LOCAL_EN_REVISION_NO_ACEPTADO', 'production_digest': prod_digest,
            'created_at': datetime.now().astimezone().isoformat(), 'built_by': 'supervisor Agy (relevo de Claude)',
            'files': [{'path': str(p.relative_to(out)), 'bytes': p.stat().st_size, 'sha256': sha(p)}
                      for p in sorted(src.rglob('*')) if p.is_file()]}
(out / 'MANIFEST.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + '\n')

after = {str(p.relative_to(PROJECT)): sha(p) for p in production_files()}
if before != after:
    sys.exit('Producción cambió durante el empaquetado; candidato inválido.')

# Restauración en frío: copia desde el staging, sin caché, importación y pruebas sobre la copia.
ev = out / 'evidence/restoration'; ev.mkdir(parents=True)
restore = ROOT / 'snapshots' / ('restoration-' + cid)
shutil.copytree(src, restore)
mismatch = [f['path'] for f in manifest['files'] if sha(restore / Path(f['path']).relative_to('source')) != f['sha256']]
engine = restore / 'tools/godot'; proj = restore / 'godot/B17'
checks = {'hash_mismatch_after_copy': mismatch}
imports = []
for attempt in (1, 2):
    r = subprocess.run([str(engine), '--headless', '--path', str(proj), '--import'], capture_output=True, text=True, timeout=900)
    (ev / f'cold-import-{attempt}.log').write_text(r.stdout + r.stderr)
    imports.append({'rc': r.returncode, 'errors': sum('ERROR' in l for l in (r.stdout + r.stderr).splitlines())})
    if r.returncode == 0:
        break
# Mismo criterio que el lanzador: un reintento ante el abort intermitente de Godot al cerrar tras importar.
checks['cold_import'] = dict(imports[-1], attempts=imports)
tests = ['test_imported_aircraft_integration', 'test_scene_mission', 'test_manual_mission_claude', 'test_local_bombing_usability',
         'test_overlay_integrity', 'test_victory_defeat_pause_reset', 'test_combat_and_engine_damage', 'test_release_acceptance',
         'test_terrain_t1', 'test_sfx_bank', 'test_audio_integration']
for t in tests:
    r = subprocess.run([str(engine), '--headless', '--path', str(proj), '--script', f'res://tests/{t}.gd'], capture_output=True, text=True, timeout=900)
    (ev / f'{t}.log').write_text(r.stdout + r.stderr)
    checks[t] = {'rc': r.returncode, 'pass': 'TEST PASS' in r.stdout}
r = subprocess.run([sys.executable, str(restore / 'jugar_b17.py'), '--check'], capture_output=True, text=True)
checks['launcher_check'] = {'rc': r.returncode, 'out': r.stdout.strip()}
ok = (not mismatch and checks['cold_import']['rc'] == 0 and checks['cold_import']['errors'] == 0
      and all(checks[t]['rc'] == 0 and checks[t]['pass'] for t in tests) and checks['launcher_check']['rc'] == 0)
checks['verified'] = ok
(ev / 'report.json').write_text(json.dumps(checks, ensure_ascii=False, indent=1) + '\n')
status = {'candidate_id': cid, 'status': 'CANDIDATO_LOCAL_VERIFICADO_PENDIENTE_PARTIDA_HUMANA' if ok else 'CANDIDATO_LOCAL_FALLÓ_RESTAURACION',
          'production_digest': prod_digest, 'files': len(manifest['files']), 'restoration_verified': ok,
          'restoration_copy': str(restore.relative_to(ROOT)), 'cache_policy': '.godot excluido; importar en frío antes de jugar',
          'not_claimed': ['Windows', 'AllyX', 'sesión humana', 'FPS garantizados', 'respaldo fuera del disco']}
(out / 'CANDIDATE_STATUS.json').write_text(json.dumps(status, ensure_ascii=False, indent=1) + '\n')
print(json.dumps({k: v for k, v in checks.items()}, ensure_ascii=False))
print(cid, 'VERIFICADO' if ok else 'FALLO')
