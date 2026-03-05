# Game Audio Engine (JUCE + scsynth)

Concrete "lightweight but deep" starter architecture with multi-engine control clients:

- C++/JUCE is the control plane: OSC routing, timing, state, reliability, Unreal-facing contract.
- SuperCollider `scsynth` is the audio plane: all synthesis/FX/bus processing.
- Game clients supported: Unreal, Godot, and Unity (same OSC contract).

## Deployment Mode

This starter implements **External Engine** mode:

- Unreal -> OSC/UDP -> JUCE Gateway (`127.0.0.1:9000`)
- Godot -> OSC/UDP -> JUCE Gateway (`127.0.0.1:9000`)
- Unity -> OSC/UDP -> JUCE Gateway (`127.0.0.1:9000`)
- JUCE Gateway -> scsynth OSC (`127.0.0.1:57110`)
- scsynth outputs to the chosen OS audio device

## Features in this scaffold

- OSC contract for `/scene/*`, `/event/*`, `/mix/*`, `/engine/*`
- Scene registry (`sceneId -> sc group`) with deterministic seeds
- Voice registry (`eventId -> sc node`) with per-type voice limits/stealing
- Lookahead scheduler that can timestamp OSC bundles for tighter event timing
- scsynth process lifecycle (launch, health polling, reconnect hooks)
- SuperCollider library with:
  - fixed bus layout (dry/music/ui/amb/fx)
  - procedural primitive synth (`\\proc_hit`)
  - global FX return (`\\fx_verb`)

## Folder Layout

- `Source/` JUCE control-plane engine
- `SuperCollider/EngineLib.scd` SC definitions and boot script
- `config/engine_contract.md` canonical OSC schema
- `examples/godot/` Godot client script + usage notes
- `examples/unity/` Unity client script + usage notes

## Build

```bash
cmake -S . -B build -DJUCE_DIR=/absolute/path/to/JUCE
cmake --build build -j
```

## Runtime

1. Ensure `scsynth` is installed and available in PATH.
2. Start app.
3. Send OSC from Unreal to `127.0.0.1:9000`.
4. Engine forwards commands to scsynth (`127.0.0.1:57110`).
5. Use the app window buttons for local smoke-test playback (`default` synth works without custom defs).

## Compile custom SynthDefs (`proc_hit`)

To use the `proc_hit` option, compile defs once:

```bash
./bin/sclang -u 0 -a --include-path /tmp/supercollider/SCClassLibrary SuperCollider/CompileDefs.scd
```

This writes `.scsyndef` files to `SuperCollider/defs`, which the engine loads at startup with `/d_loadDir`.

## Example OSC

```text
/scene/create "combat" 1234
/event/spawn 1 "proc_hit" "evt-001" 0.1 0.0 -0.2 0.8 42
/event/param "evt-001" "bright" 0.9 30
/event/stop "evt-001" 80
/mix/bus "music" -6.0 50
```

## Notes

- Keep SC parameter names consistent (`amp`, `gate`, `seed`, `x`, `y`, `z`, `send`, etc.).
- Unreal should only use logical `eventId`; JUCE maps to SC node IDs.
- For tighter timing, send events with a small lookahead (20-50ms).
