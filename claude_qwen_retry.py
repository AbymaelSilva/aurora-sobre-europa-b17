#!/usr/bin/env python3
"""Ronda 2 de Claude a Qwen: mismos contratos más el diagnóstico literal de las pruebas de comportamiento."""
from pathlib import Path
import shutil
import sys
import time
import claude_qwen_batch as batch

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT / 'godot/B17'
NOTES = {
    'world/target_ground.gd': 'PREVIOUS ATTEMPT FAILED: Godot error "Assigned value for constant GroundMaterial isn\'t a constant expression" because you wrote const GroundMaterial=preload(...).rail_yard(). The const must be ONLY preload("res://world/ground_material.gd"); call GroundMaterial.rail_yard() inside _ready().',
    'visuals/tracer_pool.gd': 'PREVIOUS ATTEMPT FAILED: Godot parse error "Expected closing )" in active_count(): you wrote Python sum(1 for age in ages if ...). GDScript has no generator expressions. Use var n:int=0; for age in ages: if age<lifetime: n+=1; return n.',
    'visuals/fighter.gd': 'PREVIOUS ATTEMPT FAILED behavior test "missing member rotor": rotor must be a MEMBER declared at top as var rotor:Node3D and assigned in _ready (rotor=Node3D.new()), not a local var. Do NOT define any add_mesh function in this file: only call Parts.add_mesh. _process uses the member rotor.',
}

def main() -> None:
    names = sys.argv[1:] or list(NOTES)
    archive = ROOT / 'logs/claude-qwen-batch/rejected' / time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
    archive.mkdir(parents=True, exist_ok=True)
    jobs = []
    for name, contract in batch.JOBS:
        if name in names:
            target = PROJECT / name
            if target.exists():
                shutil.move(str(target), str(archive / name.replace('/', '__')))
            jobs.append((name, contract + ' ' + NOTES.get(name, '')))
    batch.JOBS = jobs
    batch.worker()

if __name__ == '__main__':
    main()
