#include "ScServerClient.h"

namespace
{
int argToInt(const juce::OSCMessage& m, int idx, int fallback = 0)
{
    if (idx >= m.size())
        return fallback;

    const auto& a = m[idx];
    if (a.isInt32())
        return a.getInt32();
    if (a.isFloat32())
        return static_cast<int> (a.getFloat32());
    return fallback;
}

juce::String argToString(const juce::OSCMessage& m, int idx, juce::String fallback = {})
{
    if (idx >= m.size())
        return fallback;

    const auto& a = m[idx];
    if (a.isString())
        return a.getString();
    if (a.isInt32())
        return juce::String(a.getInt32());
    if (a.isFloat32())
        return juce::String(a.getFloat32());
    return fallback;
}
} // namespace

namespace gae
{
ScServerClient::ScServerClient(EngineConfig cfg) : config(std::move(cfg)) {}

ScServerClient::~ScServerClient()
{
    stop();
}

bool ScServerClient::start()
{
    {
        const juce::ScopedLock lock(stateLock);
        lastStartError.clear();
    }

    if (! launchScsynth())
    {
        const juce::ScopedLock lock(stateLock);
        lastStartError = "launchScsynth failed (continuing in connect-only mode)";
    }

    if (! sharedSocket.bindToPort(config.scReplyPort))
    {
        // Fallback: use any free ephemeral UDP port instead of failing startup.
        if (! sharedSocket.bindToPort(0))
        {
            const juce::ScopedLock lock(stateLock);
            lastStartError = "failed to bind reply UDP port";
            return false;
        }
    }

    if (! connectToSocket(sharedSocket))
    {
        const juce::ScopedLock lock(stateLock);
        lastStartError = "failed to attach OSC receiver socket";
        return false;
    }

    if (! sender.connectToSocket(sharedSocket, config.scHost, config.scPort))
    {
        const juce::ScopedLock lock(stateLock);
        lastStartError = "failed to connect OSC sender socket";
        return false;
    }

    addListener(this);
    connected.store(true);
    return true;
}

void ScServerClient::stop()
{
    if (connected.load())
    {
        juce::OSCMessage quit("/quit");
        sender.send(quit);
        juce::Thread::sleep(30);
    }

    connected.store(false);
    booted.store(false);

    sender.disconnect();
    disconnect();
    removeListener(this);
    sharedSocket.shutdown();

    if (scProcess.isRunning())
        scProcess.kill();
}

bool ScServerClient::isConnected() const noexcept
{
    return connected.load();
}

bool ScServerClient::isBooted() const noexcept
{
    return booted.load();
}

bool ScServerClient::send(const juce::OSCMessage& message)
{
    if (! connected.load())
        return false;

    return sender.send(message);
}

void ScServerClient::sendStatusPing()
{
    juce::OSCMessage m("/status");
    send(m);
}

juce::String ScServerClient::drainProcessOutput()
{
    juce::String out;
    char buffer[512] {};

    for (;;)
    {
        const auto bytes = scProcess.readProcessOutput(buffer, static_cast<int> (sizeof(buffer) - 1));
        if (bytes <= 0)
            break;

        buffer[bytes] = '\0';
        out += buffer;
    }

    return out;
}

juce::String ScServerClient::getLastOscFailure() const
{
    const juce::ScopedLock lock(stateLock);
    return lastOscFailure;
}

juce::String ScServerClient::getLastOscDone() const
{
    const juce::ScopedLock lock(stateLock);
    return lastOscDone;
}

juce::String ScServerClient::getStartError() const
{
    const juce::ScopedLock lock(stateLock);
    return lastStartError;
}

void ScServerClient::oscMessageReceived(const juce::OSCMessage& message)
{
    const auto addr = message.getAddressPattern().toString();
    booted.store(true);

    if (addr == "/status.reply")
    {
        return;
    }

    if (addr == "/fail")
    {
        const auto command = argToString(message, 0);
        const auto reason = argToString(message, 1);

        const bool benignNotFound = reason.containsIgnoreCase("not found")
                                 && (reason.containsIgnoreCase("node") || reason.containsIgnoreCase("group"));
        if (benignNotFound)
            return;

        const juce::ScopedLock lock(stateLock);
        lastOscFailure = command + ": " + reason;
        return;
    }

    if (addr == "/done")
    {
        const juce::ScopedLock lock(stateLock);
        lastOscDone = argToString(message, 0) + " " + argToString(message, 1);
        return;
    }

    if (addr == "/n_end")
    {
        const auto nodeId = argToInt(message, 0, -1);
        if (nodeId >= 0 && onNodeEnded)
            onNodeEnded(nodeId);
    }
}

bool ScServerClient::launchScsynth()
{
    if (scProcess.isRunning())
        return true;

    juce::StringArray args;
    args.add(config.scsynthExecutable);
    args.add("-u");
    args.add(juce::String(config.scPort));
    if (config.scPluginDir.isNotEmpty())
    {
        args.add("-U");
        args.add(config.scPluginDir);
    }

    return scProcess.start(args);
}
} // namespace gae
