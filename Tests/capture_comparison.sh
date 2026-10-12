#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
gameplay_engine="${GODOT_BIN:-godot}"
baseline_revision="${BASE_REVISION:-177067b}"
review_root="$PWD/artifacts/gameplay_polish"
baseline_checkout="$(mktemp -d "${TMPDIR:-/tmp}/moonward-original.XXXXXX")"
mkdir -p "$review_root/before" "$review_root/after" "$baseline_checkout/Tests"
git archive "$baseline_revision" | tar -x -C "$baseline_checkout"
cp Tests/{MovementTest.tscn,movement_test.gd,Replay.tscn,replay.gd,Benchmark.tscn,benchmark.gd,TowerCapture.tscn,tower_capture.gd} "$baseline_checkout/Tests/"
# Godot 4.6 stable was used for the reference run. Use the same engine for both.
"$gameplay_engine" --headless --path "$baseline_checkout" --editor --import --quit --log-file "$review_root/before/import.engine.log" > "$review_root/before/import.log" 2>&1
for variant in before after; do
  gameplay_path="$PWD"
  baseline_args=()
  if [[ "$variant" == before ]]; then
    gameplay_path="$baseline_checkout"
    baseline_args=(--baseline)
  fi
  "$gameplay_engine" --headless --path "$gameplay_path" --fixed-fps 60 --log-file "$review_root/$variant/benchmark.engine.log" res://Tests/Benchmark.tscn -- "${baseline_args[@]}" --output "$review_root/$variant/benchmark.json" > "$review_root/$variant/benchmark.log" 2>&1
  "$gameplay_engine" --path "$gameplay_path" --windowed --resolution 1152x648 --fixed-fps 60 --log-file "$review_root/$variant/replay.engine.log" res://Tests/Replay.tscn -- "${baseline_args[@]}" --capture --output "$review_root/$variant" > "$review_root/$variant/replay.log" 2>&1
  "$gameplay_engine" --path "$gameplay_path" --windowed --resolution 1152x648 --fixed-fps 60 --log-file "$review_root/$variant/tower.engine.log" res://Tests/TowerCapture.tscn -- --output "$review_root/$variant" > "$review_root/$variant/tower.log" 2>&1
done
python3 Tests/build_comparison.py
echo "Original checkout preserved at: $baseline_checkout"
