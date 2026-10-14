#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
gameplay_engine="${GODOT_BIN:-godot}"
review_output="$PWD/artifacts/gameplay_polish/after"
mkdir -p "$review_output"

run_checked() {
  local label="$1"
  shift
  "$gameplay_engine" --headless --path "$PWD" --log-file "$review_output/$label.engine.log" "$@" > "$review_output/$label.log" 2>&1
  if rg -n 'SCRIPT ERROR|Parse Error|Failed loading resource|Cannot open file|FAIL:' "$review_output/$label.log"; then
    exit 1
  fi
}

run_checked import --editor --import --quit
run_checked tests --fixed-fps 60 res://Tests/GameplayTests.tscn -- --output "$review_output/tests.json"
run_checked tower_audit --fixed-fps 60 res://Tests/TowerAudit.tscn
run_checked cavern --fixed-fps 60 --quit-after 2000 res://Tests/CavernTerrainTests.tscn
run_checked stone --fixed-fps 60 --quit-after 2000 res://Tests/StoneSheetTests.tscn
run_checked gothic --fixed-fps 60 --quit-after 2000 res://Tests/GothicTerrainTests.tscn -- --output "$review_output/gothic.json"
rg -q "GOTHIC RESULT: .* checks, 0 failures" "$review_output/gothic.log"
run_checked blackspire --fixed-fps 60 --quit-after 2000 res://Tests/BlackSpireTests.tscn
rg -q "BLACKSPIRE RESULT: .* checks, 0 failures" "$review_output/blackspire.log"
run_checked character --fixed-fps 60 --quit-after 2000 res://Tests/CharacterAnimationTests.tscn
rg -q "CHARACTER RESULT: .* checks, 0 failures" "$review_output/character.log"
run_checked startup --quit-after 120
rg 'RESULT:' "$review_output/tests.log" "$review_output/tower_audit.log" "$review_output/cavern.log" "$review_output/stone.log" "$review_output/gothic.log" "$review_output/blackspire.log" "$review_output/character.log"
echo "Import, controller tests, tower checkpoint audit, terrain tests, and main startup passed."
