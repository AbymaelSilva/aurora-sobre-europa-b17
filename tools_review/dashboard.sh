#!/usr/bin/env bash
# Abre el dashboard de operaciones B17 (datos y proceso: Qwen; vista: Claude). Se refresca cada 3 s; ESC para cerrar.
cd /home/test-bench/Documents/B17-project
exec tools/godot --path godot/B17 --resolution 1280x720 --script res://tools/dashboard/dashboard_main.gd
