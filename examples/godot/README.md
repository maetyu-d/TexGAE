# Godot Integration (OSC)

This project supports Godot via the same OSC contract used for Unreal.

## Setup

1. Add `GameAudioClient.gd` to your Godot project.
2. Create a node with this script.
3. Ensure JUCE engine is running and listening on `127.0.0.1:9000`.

## Example usage

```gdscript
# In any script with a reference to the client node:
var id = $GameAudioClient.spawn_hit(Vector3(0.1, 0.0, -0.2), 0.8)
$GameAudioClient.set_event_param(id, "bright", 0.6, 20)
$GameAudioClient.stop_event(id, 80)
```

## Notes

- Keep positions in normalized range `[-1, 1]` for `x/y/z`.
- `proc_hit` is the built-in test event in this repo.
- For robust scene id roundtrip, add an OSC receiver and consume `/scene/created`.
