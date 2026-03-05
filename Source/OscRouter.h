#pragma once

#include <juce_core/juce_core.h>
#include <juce_osc/juce_osc.h>

namespace gae
{
class EngineApp;

class OscRouter : private juce::OSCReceiver,
                  private juce::OSCReceiver::Listener<juce::OSCReceiver::MessageLoopCallback>
{
public:
    explicit OscRouter(EngineApp& engine);
    ~OscRouter() override;

    bool start(int listenPort, const juce::String& replyHost, int replyPort);
    void stop();

    void sendReply(const juce::OSCMessage& message);

private:
    void oscMessageReceived(const juce::OSCMessage& message) override;

    EngineApp& engine;
    juce::OSCSender replySender;
};
} // namespace gae
