#pragma once

#include "EngineConfig.h"
#include "EventMappingManager.h"
#include "MainComponent.h"
#include "OscRouter.h"
#include "ScServerClient.h"
#include "SceneManager.h"
#include "Scheduler.h"
#include "VoiceManager.h"

#include <juce_events/juce_events.h>
#include <juce_gui_basics/juce_gui_basics.h>
#include <map>

namespace gae
{
class EngineApp : public juce::JUCEApplication,
                  private juce::Timer
{
public:
    EngineApp();
    ~EngineApp() override;

    const juce::String getApplicationName() override;
    const juce::String getApplicationVersion() override;
    bool moreThanOneInstanceAllowed() override;

    void initialise(const juce::String& commandLine) override;
    void shutdown() override;
    void anotherInstanceStarted(const juce::String& commandLine) override;

    void handleOsc(const juce::OSCMessage& message);

private:
    class MainWindow : public juce::DocumentWindow
    {
    public:
        explicit MainWindow(std::unique_ptr<juce::Component> content);
        void closeButtonPressed() override;
    };

    struct TransportState
    {
        double unrealSeconds {};
        int frame {};
        double tempo {};
        double beat {};
    };

    void applyBusGain(const juce::String& busName, float gainDb);
    void timerCallback() override;
    void sendPong();
    void setupScGraph();
    void createTestScene();
    void spawnTestEvent(const juce::String& synthName, float gain);
    void stopLastTestEvent();
    void upsertMappingRule(const juce::String& incomingEvent,
                           const juce::String& synthDef,
                           int behaviorId,
                           float gainScale,
                           float defaultSend,
                           int timedReleaseMs,
                           bool enabled,
                           const juce::String& notes);
    void removeMappingRule(const juce::String& incomingEvent);
    juce::String getStatusText() const;
    std::vector<EventRule> getMappingRules() const;
    std::vector<juce::String> getAvailableSynthDefs() const;
    void ensureDefaultMappings();
    void refreshSynthDefCatalogFromDisk();
    void saveMappingConfig();
    void loadMappingConfig();

    EngineConfig config;

    std::unique_ptr<ScServerClient> sc;
    std::unique_ptr<SceneManager> scenes;
    std::unique_ptr<VoiceManager> voices;
    std::unique_ptr<Scheduler> scheduler;
    std::unique_ptr<OscRouter> router;
    std::unique_ptr<MainWindow> window;

    TransportState transport;
    std::map<juce::String, float> busDbByName;
    std::map<juce::String, std::map<juce::String, float>> snapshots;
    std::vector<juce::String> synthDefCatalog;
    EventMappingManager mappings;
    int testSceneId { -1 };
    juce::String lastTestEventId;
    int loadRetryTicks { 0 };
    juce::String lastScProcessLine;
    juce::String startupError;
    juce::String lastUiError;
};
} // namespace gae
