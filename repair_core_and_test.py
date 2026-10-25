#!/usr/bin/env python3
"""Encargos de corrección a Qwen seguidos de una compilación real de C#."""
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parent

def main():
    for source,diagnostic in [('Assets/Scripts/Core/FlightModel.cs','FLIGHT_FORWARD_REPAIR.txt'),('Assets/Scripts/Core/BombModel.cs','BOMB_RESULT_REPAIR.txt')]:
        subprocess.run([sys.executable,'-u',str(ROOT/'repair_unity.py'),source,str(ROOT/'planning'/diagnostic)],check=True,timeout=320)
    simulation=ROOT/'unity/B17/Assets/Scripts/Core/MissionSimulation.cs'
    text=simulation.read_text()
    text=text.replace('Quaternion.Euler(-Flight.PitchDegrees, Flight.HeadingDegrees, 0) * Vector3.forward * Flight.Speed','Flight.Forward * Flight.Speed')
    simulation.write_text(text)
    subprocess.run([sys.executable,'-u',str(ROOT/'compile_unity_sources.py')],check=True,timeout=100)
    print('Correcciones y compilación terminadas. Aún falta ejecutar las pruebas de lógica.',flush=True)

if __name__=='__main__': main()
