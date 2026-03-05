#include "EventMappingManager.h"

namespace
{
juce::String behaviorToString(gae::EventRule::Behavior b)
{
    switch (b)
    {
        case gae::EventRule::Behavior::oneShot: return "one-shot";
        case gae::EventRule::Behavior::gateHold: return "gate-hold";
        case gae::EventRule::Behavior::timedRelease: return "timed-release";
        default: return "unknown";
    }
}
} // namespace

namespace gae
{
void EventMappingManager::upsertRule(EventRule rule)
{
    rule.incomingEvent = rule.incomingEvent.trim();
    rule.synthDef = rule.synthDef.trim();
    if (rule.incomingEvent.isEmpty() || rule.synthDef.isEmpty())
        return;

    rulesByIncoming[rule.incomingEvent] = std::move(rule);
}

bool EventMappingManager::removeRule(const juce::String& incomingEvent)
{
    return rulesByIncoming.erase(incomingEvent.trim()) > 0;
}

bool EventMappingManager::resolveRule(const juce::String& incomingEvent, EventRule& outRule) const
{
    const auto it = rulesByIncoming.find(incomingEvent.trim());
    if (it == rulesByIncoming.end())
        return false;

    outRule = it->second;
    return true;
}

std::vector<EventRule> EventMappingManager::getRules() const
{
    std::vector<EventRule> out;
    out.reserve(rulesByIncoming.size());
    for (const auto& [_, rule] : rulesByIncoming)
        out.push_back(rule);
    return out;
}

void EventMappingManager::setRules(const std::vector<EventRule>& rules)
{
    rulesByIncoming.clear();
    for (const auto& rule : rules)
        upsertRule(rule);
}

void EventMappingManager::clear()
{
    rulesByIncoming.clear();
}

juce::String EventMappingManager::dumpText() const
{
    juce::String text;
    if (rulesByIncoming.empty())
        return "No mapping rules. Incoming eventType maps directly to SynthDef name.";

    for (const auto& [key, rule] : rulesByIncoming)
    {
        text << key << " -> " << rule.synthDef
             << " [" << behaviorToString(rule.behavior) << "]"
             << " gainScale=" << juce::String(rule.gainScale, 2)
             << " send=" << juce::String(rule.defaultSend, 2)
             << " releaseMs=" << juce::String(rule.timedReleaseMs)
             << " enabled=" << (rule.enabled ? "yes" : "no")
             << " notes=\"" << rule.notes << "\""
             << "\n";
    }

    return text;
}
} // namespace gae
