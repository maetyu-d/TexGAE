#pragma once

#include "Ids.h"
#include "ScServerClient.h"
#include "SceneManager.h"

#include <juce_core/juce_core.h>
#include <map>

namespace gae
{
struct VoiceState
{
    int nodeId {};
    int sceneId {};
    juce::String eventId;
    juce::String eventType;
    double createdMs {};
};

class VoiceManager
{
public:
    VoiceManager(ScServerClient& scClient, SceneManager& sceneManager);

    bool spawnEvent(int sceneId,
                    const juce::String& eventType,
                    const juce::String& eventId,
                    float x, float y, float z,
                    float gain,
                    int seed,
                    double nowMs);

    bool setEventParam(const juce::String& eventId,
                       const juce::String& key,
                       float value,
                       int rampMs);
    bool setMixSend(const juce::String& eventId,
                    const juce::String& sendName,
                    float amount,
                    int rampMs);

    bool stopEvent(const juce::String& eventId, int releaseMs);
    void stopAll(int releaseMs);
    void onNodeEnded(int nodeId);

    int getActiveVoiceCount() const noexcept;
    juce::String getDebugSummary() const;

private:
    void enforceVoiceLimit(const juce::String& eventType);
    void releaseNode(int nodeId, int releaseMs);

    ScServerClient& sc;
    SceneManager& scenes;
    IdAllocator nodeAllocator { 2000 };

    std::map<juce::String, VoiceState> byEventId;
    std::map<int, juce::String> byNodeId;
    std::map<juce::String, int> maxVoicesByType {
        { "proc_hit", 32 },
        { "wind", 4 },
        { "ui_blip", 16 }
    };
};
} // namespace gae
