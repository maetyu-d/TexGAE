#include "VoiceManager.h"

namespace
{
float clamp01(float v)
{
    if (v < 0.0f)
        return 0.0f;
    if (v > 1.0f)
        return 1.0f;
    return v;
}
} // namespace

namespace gae
{
VoiceManager::VoiceManager(ScServerClient& scClient, SceneManager& sceneManager)
    : sc(scClient), scenes(sceneManager)
{
}

bool VoiceManager::spawnEvent(int sceneId,
                              const juce::String& eventType,
                              const juce::String& eventId,
                              float x, float y, float z,
                              float gain,
                              int seed,
                              double nowMs)
{
    auto* scene = scenes.getScene(sceneId);
    if (scene == nullptr)
        return false;

    enforceVoiceLimit(eventType);

    if (const auto existing = byEventId.find(eventId); existing != byEventId.end())
        releaseNode(existing->second.nodeId, 30);

    VoiceState v;
    v.nodeId = nodeAllocator.allocate();
    v.sceneId = sceneId;
    v.eventId = eventId;
    v.eventType = eventType;
    v.createdMs = nowMs;

    byEventId[eventId] = v;
    byNodeId[v.nodeId] = eventId;

    // eventType maps directly to SynthDef name.
    juce::OSCMessage spawn("/s_new");
    spawn.addString(eventType);
    spawn.addInt32(v.nodeId);
    spawn.addInt32(0); // add to head
    spawn.addInt32(scene->groupId);
    spawn.addString("amp");
    spawn.addFloat32(clamp01(gain));
    spawn.addString("x");
    spawn.addFloat32(x);
    spawn.addString("y");
    spawn.addFloat32(y);
    spawn.addString("z");
    spawn.addFloat32(z);
    spawn.addString("seed");
    spawn.addInt32(seed);

    return sc.send(spawn);
}

bool VoiceManager::setEventParam(const juce::String& eventId,
                                 const juce::String& key,
                                 float value,
                                 int rampMs)
{
    const auto it = byEventId.find(eventId);
    if (it == byEventId.end())
        return false;

    juce::OSCMessage m("/n_set");
    m.addInt32(it->second.nodeId);
    m.addString(key);
    m.addFloat32(value);

    if (! sc.send(m))
        return false;

    if (rampMs > 0)
    {
        // Optional extension point: route via control buses and apply Lag/VarLag in SC.
    }

    return true;
}

bool VoiceManager::setMixSend(const juce::String& eventId,
                              const juce::String& sendName,
                              float amount,
                              int rampMs)
{
    if (sendName == "fx")
        return setEventParam(eventId, "send", amount, rampMs);

    return false;
}

bool VoiceManager::stopEvent(const juce::String& eventId, int releaseMs)
{
    const auto it = byEventId.find(eventId);
    if (it == byEventId.end())
        return false;

    releaseNode(it->second.nodeId, releaseMs);
    return true;
}

void VoiceManager::stopAll(int releaseMs)
{
    std::vector<juce::String> eventIds;
    eventIds.reserve(byEventId.size());
    for (const auto& [eventId, _] : byEventId)
        eventIds.push_back(eventId);

    for (const auto& eventId : eventIds)
        stopEvent(eventId, releaseMs);
}

bool VoiceManager::hasEvent(const juce::String& eventId) const
{
    return byEventId.find(eventId) != byEventId.end();
}

void VoiceManager::onNodeEnded(int nodeId)
{
    const auto it = byNodeId.find(nodeId);
    if (it == byNodeId.end())
        return;

    byEventId.erase(it->second);
    byNodeId.erase(it);
}

int VoiceManager::getActiveVoiceCount() const noexcept
{
    return static_cast<int> (byEventId.size());
}

juce::String VoiceManager::getDebugSummary() const
{
    std::map<juce::String, int> byType;
    for (const auto& [_, v] : byEventId)
        ++byType[v.eventType];

    juce::String summary = "voices=" + juce::String(byEventId.size());
    for (const auto& [type, count] : byType)
        summary << " " << type << ":" << juce::String(count);

    return summary;
}

void VoiceManager::enforceVoiceLimit(const juce::String& eventType)
{
    const auto maxIt = maxVoicesByType.find(eventType);
    if (maxIt == maxVoicesByType.end())
        return;

    const auto maxVoices = maxIt->second;

    int count = 0;
    for (const auto& [_, v] : byEventId)
        if (v.eventType == eventType)
            ++count;

    if (count < maxVoices)
        return;

    const VoiceState* oldest = nullptr;
    for (const auto& [_, v] : byEventId)
    {
        if (v.eventType != eventType)
            continue;

        if (oldest == nullptr || v.createdMs < oldest->createdMs)
            oldest = &v;
    }

    if (oldest != nullptr)
        releaseNode(oldest->nodeId, 20);
}

void VoiceManager::releaseNode(int nodeId, int /*releaseMs*/)
{
    juce::OSCMessage m("/n_set");
    m.addInt32(nodeId);
    m.addString("gate");
    m.addFloat32(0.0f);
    sc.send(m);

    onNodeEnded(nodeId);
}
} // namespace gae
