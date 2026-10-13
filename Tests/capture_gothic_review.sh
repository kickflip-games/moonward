#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
terrain_engine="${GODOT_BIN:-godot}"
terrain_review="$PWD/artifacts/gothic_terrain/output"
mkdir -p "$terrain_review"
"$terrain_engine" --path "$PWD" --windowed --resolution 1152x648 --fixed-fps 60 --quit-after 600 --log-file "$terrain_review/capture.engine.log" res://Scenes/TerrainTest/GothicTerrainTest.tscn -- --capture-dir "$terrain_review"
test -s "$terrain_review/00_previous_borders.png"
test -s "$terrain_review/07_player_route.png"
