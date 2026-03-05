#pragma once

#include "EventMappingManager.h"

#include <juce_gui_basics/juce_gui_basics.h>
#include <map>

namespace gae
{
class MainComponent : public juce::Component,
                      private juce::Button::Listener,
                      private juce::Timer,
                      private juce::TableListBoxModel
{
public:
    MainComponent(std::function<void()> onCreateScene,
                  std::function<void(const juce::String&, const juce::String&, float)> onToggleRowTest,
                  std::function<void()> onStop,
                  std::function<juce::String()> getStatus,
                  std::function<void(const juce::String&,
                                     const juce::String&,
                                     int,
                                     float,
                                     float,
                                     int,
                                     bool,
                                     const juce::String&)> onUpsertMapping,
                  std::function<void(const juce::String&)> onRemoveMapping,
                  std::function<std::vector<EventRule>()> getRules,
                  std::function<std::vector<juce::String>()> getSynthDefs,
                  std::function<std::map<juce::String, double>()> getRecentEventTimes,
                  std::function<std::map<juce::String, bool>()> getRowTestActiveStates,
                  std::function<void()> onSaveConfig,
                  std::function<void()> onLoadConfig);

    void resized() override;

private:
    enum ColumnId
    {
        colEnabled = 1,
        colIncoming,
        colSynth,
        colRx,
        colTest,
        colBehavior,
        colGainScale,
        colSend,
        colReleaseMs,
        colNotes
    };

    void buttonClicked(juce::Button* button) override;
    void timerCallback() override;

    int getNumRows() override;
    void paintRowBackground(juce::Graphics& g, int rowNumber, int width, int height, bool rowIsSelected) override;
    void paintCell(juce::Graphics& g, int rowNumber, int columnId, int width, int height, bool rowIsSelected) override;
    juce::Component* refreshComponentForCell(int rowNumber, int columnId, bool isRowSelected, juce::Component* existingComponentToUpdate) override;
    void selectedRowsChanged(int lastRowSelected) override;

    void refreshRules();
    void populateEditorsFromSelectedRow();
    void testMappingRow(int row);
    static juce::String behaviorName(EventRule::Behavior b);

    std::function<void()> onCreateScene;
    std::function<void(const juce::String&, const juce::String&, float)> onToggleRowTest;
    std::function<void()> onStop;
    std::function<juce::String()> getStatus;
    std::function<void(const juce::String&, const juce::String&, int, float, float, int, bool, const juce::String&)> onUpsertMapping;
    std::function<void(const juce::String&)> onRemoveMapping;
    std::function<std::vector<EventRule>()> getRules;
    std::function<std::vector<juce::String>()> getSynthDefs;
    std::function<std::map<juce::String, double>()> getRecentEventTimes;
    std::function<std::map<juce::String, bool>()> getRowTestActiveStates;
    std::function<void()> onSaveConfig;
    std::function<void()> onLoadConfig;

    juce::Label title;
    juce::Label status;

    juce::ComboBox synthType;
    juce::Slider gain;

    juce::TextButton createSceneButton { "Create Test Scene" };
    juce::TextButton stopButton { "Stop Last Event" };

    juce::Label mappingHeader;
    juce::TableListBox mappingsTable { "Mappings", this };

    juce::TextEditor incomingEvent;
    juce::ComboBox targetSynth;
    juce::ComboBox behavior;
    juce::Slider gainScale;
    juce::Slider defaultSend;
    juce::Slider timedReleaseMs;
    juce::ToggleButton enabled;
    juce::TextEditor notes;
    juce::TextButton upsertButton { "Save Row" };
    juce::TextButton removeButton { "Delete Row" };
    juce::TextButton saveConfigButton { "Save Config" };
    juce::TextButton loadConfigButton { "Load Config" };

    std::vector<EventRule> rulesCache;
    std::map<juce::String, double> recentEventTimesMs;
    std::map<juce::String, bool> rowTestActiveByIncoming;
};
} // namespace gae
