# Unity Integration (OSC)

This project supports Unity via the same OSC contract used for Unreal and Godot.

## Setup

1. Copy `GameAudioClient.cs` into your Unity project.
2. Add `GameAudioClient` component to a scene object.
3. Ensure JUCE engine is running at `127.0.0.1:9000`.

## Example usage

```csharp
public class AudioTest : MonoBehaviour
{
    public GameAudioClient audioClient;

    void Start()
    {
        string id = audioClient.SpawnHit(new Vector3(0.1f, 0f, -0.2f), 0.8f);
        audioClient.SetEventParam(id, "bright", 0.6f, 20);
        audioClient.StopEvent(id, 80);
    }
}
```

## Notes

- Normalize `x/y/z` to `[-1, 1]` for the default `proc_hit` mapping.
- For strict scene-id sync, add an OSC receiver in Unity for `/scene/created`.
