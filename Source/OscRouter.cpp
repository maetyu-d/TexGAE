#include "OscRouter.h"
#include "EngineApp.h"

namespace gae
{
OscRouter::OscRouter(EngineApp& e) : engine(e) {}

OscRouter::~OscRouter()
{
    stop();
}

bool OscRouter::start(int listenPort, const juce::String& replyHost, int replyPort)
{
    if (! connect(listenPort))
        return false;

    addListener(this);

    if (! replySender.connect(replyHost, replyPort))
        return false;

    return true;
}

void OscRouter::stop()
{
    replySender.disconnect();
    removeListener(this);
    disconnect();
}

void OscRouter::sendReply(const juce::OSCMessage& message)
{
    replySender.send(message);
}

void OscRouter::oscMessageReceived(const juce::OSCMessage& message)
{
    engine.handleOsc(message);
}
} // namespace gae
