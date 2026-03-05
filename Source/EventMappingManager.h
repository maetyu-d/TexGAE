#pragma once

#include <juce_core/juce_core.h>

#include <map>
#include <vector>

namespace gae
{
struct EventRule
{
    enum class Behavior
    {
        oneShot = 0,
        gateHold,
        timedRelease
    };

    juce::String incomingEvent;
    juce::String synthDef;
    Behavior behavior { Behavior::gateHold };
    float gainScale { 1.0f };
    float defaultSend { -1.0f }; // negative means don't override
    int timedReleaseMs { 250 };
    bool enabled { true };
    juce::String notes;
};

class EventMappingManager
{
public:
    void upsertRule(EventRule rule);
    bool removeRule(const juce::String& incomingEvent);

    bool resolveRule(const juce::String& incomingEvent, EventRule& outRule) const;
    std::vector<EventRule> getRules() const;
    void setRules(const std::vector<EventRule>& rules);
    void clear();

    juce::String dumpText() const;

private:
    std::map<juce::String, EventRule> rulesByIncoming;
};
} // namespace gae
