#include "MainComponent.h"

namespace gae
{
namespace
{
class RowTestButton : public juce::TextButton
{
public:
    int row { -1 };
};
} // namespace

MainComponent::MainComponent(std::function<void()> createScene,
                             std::function<void(const juce::String&, float)> spawn,
                             std::function<void()> stop,
                             std::function<juce::String()> statusFn,
                             std::function<void(const juce::String&, const juce::String&, int, float, float, int, bool, const juce::String&)> upsertMapping,
                             std::function<void(const juce::String&)> removeMapping,
                             std::function<std::vector<EventRule>()> getRulesFn,
                             std::function<std::vector<juce::String>()> getSynthDefsFn,
                             std::function<std::map<juce::String, double>()> getRecentEventTimesFn,
                             std::function<void()> saveConfigFn,
                             std::function<void()> loadConfigFn)
    : onCreateScene(std::move(createScene)),
      onSpawn(std::move(spawn)),
      onStop(std::move(stop)),
      getStatus(std::move(statusFn)),
      onUpsertMapping(std::move(upsertMapping)),
      onRemoveMapping(std::move(removeMapping)),
      getRules(std::move(getRulesFn)),
      getSynthDefs(std::move(getSynthDefsFn)),
      getRecentEventTimes(std::move(getRecentEventTimesFn)),
      onSaveConfig(std::move(saveConfigFn)),
      onLoadConfig(std::move(loadConfigFn))
{
    title.setText("Game Audio Engine", juce::dontSendNotification);
    title.setJustificationType(juce::Justification::centredLeft);
    addAndMakeVisible(title);

    status.setText("Starting...", juce::dontSendNotification);
    status.setJustificationType(juce::Justification::centredLeft);
    addAndMakeVisible(status);

    synthType.addItem("proc_hit (engine default)", 1);
    synthType.addItem("default (if available)", 2);
    synthType.setSelectedId(1);
    addAndMakeVisible(synthType);

    gain.setSliderStyle(juce::Slider::LinearHorizontal);
    gain.setTextBoxStyle(juce::Slider::TextBoxRight, false, 60, 20);
    gain.setRange(0.0, 1.0, 0.01);
    gain.setValue(0.25);
    addAndMakeVisible(gain);

    createSceneButton.addListener(this);
    stopButton.addListener(this);
    upsertButton.addListener(this);
    removeButton.addListener(this);
    addAndMakeVisible(createSceneButton);
    addAndMakeVisible(stopButton);

    mappingHeader.setText("Event Mapping Table", juce::dontSendNotification);
    addAndMakeVisible(mappingHeader);

    auto& h = mappingsTable.getHeader();
    h.addColumn("On", colEnabled, 40);
    h.addColumn("Incoming Event", colIncoming, 140);
    h.addColumn("SynthDef", colSynth, 130);
    h.addColumn("Rx", colRx, 40);
    h.addColumn("Test", colTest, 56);
    h.addColumn("Behavior", colBehavior, 110);
    h.addColumn("Gain", colGainScale, 70);
    h.addColumn("Send", colSend, 70);
    h.addColumn("Release", colReleaseMs, 70);
    h.addColumn("Notes", colNotes, 220);
    mappingsTable.setMultipleSelectionEnabled(false);
    addAndMakeVisible(mappingsTable);

    incomingEvent.setText("footstep");
    incomingEvent.setTextToShowWhenEmpty("incoming event", juce::Colours::grey);
    addAndMakeVisible(incomingEvent);

    targetSynth.setEditableText(true);
    targetSynth.addItem("footstep", 1);
    targetSynth.setText("footstep");
    addAndMakeVisible(targetSynth);

    behavior.addItem("one-shot", 1);
    behavior.addItem("gate-hold", 2);
    behavior.addItem("timed-release", 3);
    behavior.setSelectedId(2);
    addAndMakeVisible(behavior);

    gainScale.setSliderStyle(juce::Slider::LinearHorizontal);
    gainScale.setTextBoxStyle(juce::Slider::TextBoxRight, false, 60, 20);
    gainScale.setRange(0.0, 2.0, 0.01);
    gainScale.setValue(1.0);
    addAndMakeVisible(gainScale);

    defaultSend.setSliderStyle(juce::Slider::LinearHorizontal);
    defaultSend.setTextBoxStyle(juce::Slider::TextBoxRight, false, 60, 20);
    defaultSend.setRange(-1.0, 1.0, 0.01);
    defaultSend.setValue(-1.0);
    addAndMakeVisible(defaultSend);

    timedReleaseMs.setSliderStyle(juce::Slider::LinearHorizontal);
    timedReleaseMs.setTextBoxStyle(juce::Slider::TextBoxRight, false, 60, 20);
    timedReleaseMs.setRange(10, 5000, 1);
    timedReleaseMs.setValue(250);
    addAndMakeVisible(timedReleaseMs);

    enabled.setButtonText("enabled");
    enabled.setToggleState(true, juce::dontSendNotification);
    addAndMakeVisible(enabled);

    notes.setTextToShowWhenEmpty("notes (comments only)", juce::Colours::grey);
    addAndMakeVisible(notes);

    addAndMakeVisible(upsertButton);
    addAndMakeVisible(removeButton);
    saveConfigButton.addListener(this);
    loadConfigButton.addListener(this);
    addAndMakeVisible(saveConfigButton);
    addAndMakeVisible(loadConfigButton);

    refreshRules();
    startTimerHz(4);
}

void MainComponent::resized()
{
    auto r = getLocalBounds().reduced(12);

    title.setBounds(r.removeFromTop(28));
    status.setBounds(r.removeFromTop(24));
    r.removeFromTop(8);

    auto topControls = r.removeFromTop(32);
    synthType.setBounds(topControls.removeFromLeft(280));
    gain.setBounds(topControls.removeFromLeft(180));
    topControls.removeFromLeft(8);
    createSceneButton.setBounds(topControls.removeFromLeft(140));
    topControls.removeFromLeft(6);
    stopButton.setBounds(topControls.removeFromLeft(120));
    r.removeFromTop(8);

    mappingHeader.setBounds(r.removeFromTop(24));
    mappingsTable.setBounds(r.removeFromTop(230));
    r.removeFromTop(8);

    auto row1 = r.removeFromTop(28);
    incomingEvent.setBounds(row1.removeFromLeft(180));
    row1.removeFromLeft(6);
    targetSynth.setBounds(row1.removeFromLeft(170));
    row1.removeFromLeft(6);
    behavior.setBounds(row1.removeFromLeft(140));
    row1.removeFromLeft(8);
    enabled.setBounds(row1.removeFromLeft(90));

    r.removeFromTop(6);
    auto row2 = r.removeFromTop(32);
    gainScale.setBounds(row2.removeFromLeft(230));
    row2.removeFromLeft(6);
    defaultSend.setBounds(row2.removeFromLeft(230));
    row2.removeFromLeft(6);
    timedReleaseMs.setBounds(row2.removeFromLeft(230));

    r.removeFromTop(8);
    auto row3 = r.removeFromTop(30);
    upsertButton.setBounds(row3.removeFromLeft(140));
    row3.removeFromLeft(6);
    removeButton.setBounds(row3.removeFromLeft(120));
    row3.removeFromLeft(10);
    saveConfigButton.setBounds(row3.removeFromLeft(120));
    row3.removeFromLeft(6);
    loadConfigButton.setBounds(row3.removeFromLeft(120));
    r.removeFromTop(6);
    notes.setBounds(r.removeFromTop(28));
}

void MainComponent::buttonClicked(juce::Button* button)
{
    if (button == &createSceneButton)
    {
        if (onCreateScene)
            onCreateScene();
        return;
    }

    if (button == &stopButton)
    {
        if (onStop)
            onStop();
        return;
    }

    if (button == &upsertButton)
    {
        if (onUpsertMapping)
        {
            onUpsertMapping(incomingEvent.getText().trim(),
                            targetSynth.getText().trim(),
                            behavior.getSelectedId(),
                            static_cast<float> (gainScale.getValue()),
                            static_cast<float> (defaultSend.getValue()),
                            static_cast<int> (timedReleaseMs.getValue()),
                            enabled.getToggleState(),
                            notes.getText());
            refreshRules();
        }
        return;
    }

    if (button == &removeButton)
    {
        if (onRemoveMapping)
        {
            onRemoveMapping(incomingEvent.getText().trim());
            refreshRules();
        }
        return;
    }

    if (button == &saveConfigButton)
    {
        if (onSaveConfig)
            onSaveConfig();
        return;
    }

    if (button == &loadConfigButton)
    {
        if (onLoadConfig)
            onLoadConfig();
    }
}

void MainComponent::timerCallback()
{
    if (getStatus)
        status.setText(getStatus(), juce::dontSendNotification);

    if (getSynthDefs)
    {
        const auto defs = getSynthDefs();
        const auto currentText = targetSynth.getText();
        targetSynth.clear(juce::dontSendNotification);
        int id = 1;
        for (const auto& d : defs)
            targetSynth.addItem(d, id++);
        targetSynth.setText(currentText.isNotEmpty() ? currentText : "proc_hit", juce::dontSendNotification);
    }

    if (getRecentEventTimes)
        recentEventTimesMs = getRecentEventTimes();

    refreshRules();
}

int MainComponent::getNumRows()
{
    return static_cast<int> (rulesCache.size());
}

void MainComponent::paintRowBackground(juce::Graphics& g, int rowNumber, int /*width*/, int /*height*/, bool rowIsSelected)
{
    const auto alt = (rowNumber % 2) == 0;
    g.fillAll(rowIsSelected ? juce::Colours::darkcyan.withAlpha(0.45f)
                            : (alt ? juce::Colours::black.withAlpha(0.08f) : juce::Colours::transparentBlack));
}

void MainComponent::paintCell(juce::Graphics& g, int rowNumber, int columnId, int width, int height, bool /*rowIsSelected*/)
{
    if (rowNumber < 0 || rowNumber >= static_cast<int> (rulesCache.size()))
        return;

    const auto& r = rulesCache[static_cast<size_t> (rowNumber)];

    juce::String text;
    if (columnId == colEnabled) text = r.enabled ? "Y" : "N";
    if (columnId == colIncoming) text = r.incomingEvent;
    if (columnId == colSynth) text = r.synthDef;
    if (columnId == colRx) text = "";
    if (columnId == colTest) text = "";
    if (columnId == colBehavior) text = behaviorName(r.behavior);
    if (columnId == colGainScale) text = juce::String(r.gainScale, 2);
    if (columnId == colSend) text = juce::String(r.defaultSend, 2);
    if (columnId == colReleaseMs) text = juce::String(r.timedReleaseMs);
    if (columnId == colNotes) text = r.notes;

    g.setColour(juce::Colours::white.withAlpha(0.95f));
    g.setFont(13.0f);
    g.drawText(text, 4, 0, width - 8, height, juce::Justification::centredLeft, true);

    g.setColour(juce::Colours::white.withAlpha(0.08f));
    g.drawVerticalLine(width - 1, 0.0f, static_cast<float> (height));

    if (columnId == colRx)
    {
        const auto nowMs = juce::Time::getMillisecondCounterHiRes();
        const auto it = recentEventTimesMs.find(r.incomingEvent);
        const bool isRecent = (it != recentEventTimesMs.end()) && ((nowMs - it->second) <= 400.0);
        const auto dot = isRecent ? juce::Colours::limegreen : juce::Colours::dimgrey;
        g.setColour(dot.withAlpha(isRecent ? 0.95f : 0.55f));
        const float d = 10.0f;
        const float x = (width - d) * 0.5f;
        const float y = (height - d) * 0.5f;
        g.fillEllipse(x, y, d, d);
    }
}

juce::Component* MainComponent::refreshComponentForCell(int rowNumber,
                                                        int columnId,
                                                        bool /*isRowSelected*/,
                                                        juce::Component* existingComponentToUpdate)
{
    if (columnId != colTest)
        return nullptr;

    auto* button = dynamic_cast<RowTestButton*> (existingComponentToUpdate);
    if (button == nullptr)
    {
        button = new RowTestButton();
        button->setButtonText("Test");
        button->onClick = [this, button] { testMappingRow(button->row); };
    }

    button->row = rowNumber;
    return button;
}

void MainComponent::selectedRowsChanged(int lastRowSelected)
{
    if (lastRowSelected < 0 || lastRowSelected >= static_cast<int> (rulesCache.size()))
        return;

    populateEditorsFromSelectedRow();
}

void MainComponent::refreshRules()
{
    if (! getRules)
        return;

    rulesCache = getRules();
    mappingsTable.updateContent();
    mappingsTable.repaint();
}

void MainComponent::populateEditorsFromSelectedRow()
{
    const auto row = mappingsTable.getSelectedRow();
    if (row < 0 || row >= static_cast<int> (rulesCache.size()))
        return;

    const auto& r = rulesCache[static_cast<size_t> (row)];
    incomingEvent.setText(r.incomingEvent, juce::dontSendNotification);
    targetSynth.setText(r.synthDef, juce::dontSendNotification);
    if (r.behavior == EventRule::Behavior::oneShot) behavior.setSelectedId(1, juce::dontSendNotification);
    if (r.behavior == EventRule::Behavior::gateHold) behavior.setSelectedId(2, juce::dontSendNotification);
    if (r.behavior == EventRule::Behavior::timedRelease) behavior.setSelectedId(3, juce::dontSendNotification);
    gainScale.setValue(r.gainScale, juce::dontSendNotification);
    defaultSend.setValue(r.defaultSend, juce::dontSendNotification);
    timedReleaseMs.setValue(r.timedReleaseMs, juce::dontSendNotification);
    enabled.setToggleState(r.enabled, juce::dontSendNotification);
    notes.setText(r.notes, juce::dontSendNotification);
}

void MainComponent::testMappingRow(int row)
{
    if (row < 0 || row >= static_cast<int> (rulesCache.size()))
        return;

    if (! onSpawn)
        return;

    const auto& r = rulesCache[static_cast<size_t> (row)];
    const auto testGain = juce::jlimit(0.05f, 1.0f, 0.25f * r.gainScale);
    onSpawn(r.synthDef, testGain);
}

juce::String MainComponent::behaviorName(EventRule::Behavior b)
{
    if (b == EventRule::Behavior::oneShot) return "one-shot";
    if (b == EventRule::Behavior::gateHold) return "gate-hold";
    if (b == EventRule::Behavior::timedRelease) return "timed-release";
    return "unknown";
}
} // namespace gae
