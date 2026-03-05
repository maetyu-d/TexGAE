#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCLANG_BIN="${SCLANG_BIN:-$ROOT_DIR/bin/sclang}"
SC_CLASSLIB="${SC_CLASSLIB:-/tmp/supercollider/SCClassLibrary}"
DEFS_DIR="$ROOT_DIR/SuperCollider/defs"

EXPECTED_DEFS=(
  "proc_hit"
  "footstep"
  "impact"
  "ui_blip"
  "wind_loop"
  "ambience_grain"
  "music_pulse"
)

if [[ ! -x "$SCLANG_BIN" ]]; then
  echo "sclang not found at: $SCLANG_BIN" >&2
  exit 1
fi

if [[ ! -d "$SC_CLASSLIB" ]]; then
  echo "SCClassLibrary not found at: $SC_CLASSLIB" >&2
  exit 1
fi

export HOME="$ROOT_DIR/.sc-home"
export GAE_DEFS_DIR="$DEFS_DIR"
mkdir -p "$HOME/Library/Application Support/SuperCollider"
mkdir -p "$DEFS_DIR"

# Remove expected outputs first so validation reflects this run, not stale files.
for def in "${EXPECTED_DEFS[@]}"; do
  rm -f "$DEFS_DIR/$def.scsyndef"
done

LOG_FILE="$ROOT_DIR/.sc-home/compile_defs.log"
"$SCLANG_BIN" -u 0 -a --include-path "$SC_CLASSLIB" "$ROOT_DIR/SuperCollider/CompileDefs.scd" >"$LOG_FILE" 2>&1 &
SCLANG_PID=$!

all_written=0
deadline=$((SECONDS + 20))
while (( SECONDS < deadline )); do
  if ! kill -0 "$SCLANG_PID" 2>/dev/null; then
    break
  fi

  all_written=1
  for def in "${EXPECTED_DEFS[@]}"; do
    if [[ ! -f "$DEFS_DIR/$def.scsyndef" ]]; then
      all_written=0
      break
    fi
  done

  if [[ "$all_written" -eq 1 ]]; then
    break
  fi

  sleep 0.25
done

# Avoid leaving interactive sclang sessions around.
if kill -0 "$SCLANG_PID" 2>/dev/null; then
  kill "$SCLANG_PID" 2>/dev/null || true
fi
wait "$SCLANG_PID" 2>/dev/null || true

echo "SynthDef compile summary:"
missing=0
for def in "${EXPECTED_DEFS[@]}"; do
  file="$DEFS_DIR/$def.scsyndef"
  if [[ -f "$file" ]]; then
    size="$(wc -c <"$file" | tr -d ' ')"
    echo "  [ok]   $def ($size bytes)"
  else
    echo "  [miss] $def"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "ERROR: Missing one or more expected .scsyndef files in $DEFS_DIR" >&2
  echo "---- sclang log tail ----" >&2
  tail -n 80 "$LOG_FILE" >&2 || true
  exit 1
fi

echo "All expected defs generated. Log: $LOG_FILE"
