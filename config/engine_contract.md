# OSC Contract (Unreal/Godot <-> JUCE Engine)

## Engine

- `/engine/ping` -> `/engine/pong` `(engineMs, scConnected, activeVoices)`
- `/engine/time` `(unrealSeconds, frame, tempo, beat)`
- `/engine/snapshot/save` `(name)`
- `/engine/snapshot/load` `(name, fadeMs)`

## Scene

- `/scene/create` `(sceneName, seed)` -> `/scene/created` `(sceneId, sceneName)`
- `/scene/destroy` `(sceneId, fadeMs)`
- `/scene/param` `(sceneId, key, value)`

## Events

- `/event/spawn` `(sceneId, eventType, eventId, x, y, z, gain, seed)`
- `/event/param` `(eventId, key, value, rampMs)`
- `/event/stop` `(eventId, releaseMs)`

Recommended `eventType` values in this starter:
- `proc_hit`: short procedural hit
  params: `amp gate seed x y z bright size damp send fxBus`
- `footstep`: short thud step
  params: `amp gate seed x y z hardness damp send fxBus`
- `impact`: heavier transient impact
  params: `amp gate seed x y z force metal damp send fxBus`
- `ui_blip`: short UI tone
  params: `amp gate seed x y z pitch bright send fxBus`
- `wind_loop`: continuous wind bed
  params: `amp gate seed x y z speed bright damp send fxBus`
- `ambience_grain`: continuous granular ambience
  params: `amp gate seed x y z density spread tone send fxBus`
- `music_pulse`: simple tonal pulse loop
  params: `amp gate seed x y z freq rate tone send fxBus`

Notes:
- Core params are shared for generic engine code: `amp gate seed x y z send fxBus`.
- `x/y/z` are normalized to `[-1, 1]`.
- One-shot events should still accept `gate` for consistency.

## Mix

- `/mix/bus` `(busName, gainDb, rampMs)`
- `/mix/send` `(eventId, sendName, amount, rampMs)`

## Debug

- `/debug/voices` -> `/debug/voices/reply` `(count)`
- `/debug/nodeTree`
