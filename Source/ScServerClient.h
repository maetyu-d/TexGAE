#pragma once

#include "EngineConfig.h"

#include <juce_core/juce_core.h>
#include <juce_events/juce_events.h>
#include <juce_osc/juce_osc.h>

namespace gae
{
class ScServerClient : private juce::OSCReceiver,
                       private juce::OSCReceiver::Listener<juce::OSCReceiver::MessageLoopCallback>
{
public:
    explicit ScServerClient(EngineConfig config);
    ~ScServerClient() override;

    bool start();
    void stop();

    bool isConnected() const noexcept;
    bool isBooted() const noexcept;

    bool send(const juce::OSCMessage& message);

    void sendStatusPing();
    juce::String drainProcessOutput();
    juce::String getLastOscFailure() const;
    juce::String getLastOscDone() const;
    juce::String getStartError() const;

    std::function<void(int nodeId)> onNodeEnded;

private:
    void oscMessageReceived(const juce::OSCMessage& message) override;
    bool launchScsynth();

    EngineConfig config;
    juce::OSCSender sender;
    juce::DatagramSocket sharedSocket { false };
    juce::ChildProcess scProcess;
    std::atomic<bool> connected { false };
    std::atomic<bool> booted { false };
    juce::String lastOscFailure;
    juce::String lastOscDone;
    juce::String lastStartError;
    mutable juce::CriticalSection stateLock;
};
} // namespace gae
