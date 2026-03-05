#pragma once

#include <juce_core/juce_core.h>

namespace gae
{
struct EngineConfig
{
    juce::String unrealHost { "127.0.0.1" };
    int unrealRecvPort { 9000 };
    int unrealReplyPort { 9001 };

    juce::String scHost { "127.0.0.1" };
    int scPort { 57110 };
    int scReplyPort { 57121 };

    juce::String scsynthExecutable { juce::SystemStats::getEnvironmentVariable("SCSYNTH_PATH", "/Applications/SuperCollider.app/Contents/Resources/scsynth") };
    juce::String scPluginDir { juce::SystemStats::getEnvironmentVariable("SC_PLUGIN_DIR", "") };
    juce::String synthDefDir { juce::String(GAE_PROJECT_DIR) + "/SuperCollider/defs" };
    juce::String procHitDefFile { juce::String(GAE_PROJECT_DIR) + "/SuperCollider/defs/proc_hit.scsyndef" };

    double lookaheadMs { 25.0 };
};
} // namespace gae
