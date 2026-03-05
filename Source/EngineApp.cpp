#include "EngineApp.h"

#include <cmath>
#include <set>

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

float argToFloat(const juce::OSCMessage& m, int idx, float fallback = 0.0f)
{
    if (idx >= m.size())
        return fallback;

    const auto& a = m[idx];
    if (a.isFloat32())
        return a.getFloat32();
    if (a.isInt32())
        return static_cast<float> (a.getInt32());
    return fallback;
}

juce::String argToString(const juce::OSCMessage& m, int idx, juce::String fallback = {})
{
    if (idx >= m.size())
        return fallback;

    const auto& a = m[idx];
    if (a.isString())
        return a.getString();
    return fallback;
}

float dbToGain(float db)
{
    return std::pow(10.0f, db / 20.0f);
}

float clampf(float v, float lo, float hi)
{
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}
} // namespace

namespace gae
{
EngineApp::MainWindow::MainWindow(std::unique_ptr<juce::Component> content)
    : juce::DocumentWindow("Game Audio Engine",
                           juce::Colours::darkgrey,
                           juce::DocumentWindow::allButtons)
{
    setUsingNativeTitleBar(true);
    setResizable(true, true);
    setContentOwned(content.release(), true);
    centreWithSize(720, 760);
    setVisible(true);
}

void EngineApp::MainWindow::closeButtonPressed()
{
    juce::JUCEApplication::getInstance()->systemRequestedQuit();
}

EngineApp::EngineApp() = default;
EngineApp::~EngineApp() = default;

const juce::String EngineApp::getApplicationName() { return "GameAudioEngine"; }
const juce::String EngineApp::getApplicationVersion() { return "0.1.0"; }
bool EngineApp::moreThanOneInstanceAllowed() { return false; }

void EngineApp::initialise(const juce::String& /*commandLine*/)
{
    auto ui = std::make_unique<MainComponent>(
        [this] { createTestScene(); },
        [this] (const juce::String& incomingEvent, const juce::String& synthName, float gain) { toggleRowTestEvent(incomingEvent, synthName, gain); },
        [this] { stopLastTestEvent(); },
        [this] { return getStatusText(); },
        [this] (const juce::String& incomingEvent,
                const juce::String& synthDef,
                int behaviorId,
                float gainScale,
                float defaultSend,
                int timedReleaseMs,
                bool enabled,
                const juce::String& notes)
        {
            upsertMappingRule(incomingEvent, synthDef, behaviorId, gainScale, defaultSend, timedReleaseMs, enabled, notes);
        },
        [this] (const juce::String& incomingEvent) { removeMappingRule(incomingEvent); },
        [this] { return getMappingRules(); },
        [this] { return getAvailableSynthDefs(); },
        [this] { return getRecentEventTimes(); },
        [this] { return getRowTestActiveStates(); },
        [this] { saveMappingConfig(); },
        [this] { loadMappingConfig(); });
    window = std::make_unique<MainWindow>(std::move(ui));

    sc = std::make_unique<ScServerClient>(config);
    scenes = std::make_unique<SceneManager>(*sc);
    voices = std::make_unique<VoiceManager>(*sc, *scenes);
    scheduler = std::make_unique<Scheduler>();
    scheduler->setLookaheadMs(config.lookaheadMs);
    router = std::make_unique<OscRouter>(*this);

    sc->onNodeEnded = [this] (int nodeId) { voices->onNodeEnded(nodeId); };

    if (! sc->start())
    {
        startupError = "Failed to start scsynth at: " + config.scsynthExecutable;
        const auto reason = sc->getStartError();
        if (reason.isNotEmpty())
            startupError << " (" << reason << ")";
    }

    if (! router->start(config.unrealRecvPort, config.unrealHost, config.unrealReplyPort))
    {
        startupError = "Failed to start OSC listener on port " + juce::String(config.unrealRecvPort);
    }

    setupScGraph();
    synthDefCatalog = { "proc_hit", "footstep", "impact", "ui_blip", "wind_loop", "ambience_grain", "music_pulse",
                        "ui_click", "laser_zap", "explosion", "pickup_chime", "whoosh", "engine_idle", "rain_loop", "alarm_loop",
                        "gunshot", "jump_blip", "coin_pickup", "error_buzz", "powerup_swirl", "door_thud", "thunder_rumble", "magic_cast",
                        "rifle_shot", "shotgun_blast", "smg_burst", "ricochet_ping", "sword_clash", "bow_release", "reload_click",
                        "rocket_launcher_blast", "pedestrians_loop", "phone_tone", "dtmf_tone", "siren_wail", "telephone_bell",
                        "bouncing_ball", "rolling_can", "creaking_door", "boing_spring", "fire_loop", "bubbles_loop",
                        "running_water", "electricity_arc", "motor_loop", "car_passby", "insects_loop", "transporter_beam",
                        "red_alert_loop", "r2d2_bleeps", "additive_pad" };
    refreshSynthDefCatalogFromDisk();
    ensureDefaultMappings();

    startTimer(5);
}

void EngineApp::shutdown()
{
    stopTimer();

    router.reset();

    if (voices)
        voices->stopAll(30);

    if (sc && sc->isConnected())
    {
        juce::OSCMessage freeAll("/g_freeAll");
        freeAll.addInt32(0);
        sc->send(freeAll);

        juce::OSCMessage clearSched("/clearSched");
        sc->send(clearSched);
    }

    // Give scsynth a brief chance to process release/free messages before teardown.
    juce::Thread::sleep(40);

    window.reset();
    voices.reset();
    scenes.reset();

    if (sc)
        sc->stop();

    // Hard fallback to prevent orphaned audio if a detached scsynth remains alive.
    juce::ChildProcess killAll;
    juce::StringArray killArgs;
    killArgs.add("killall");
    killArgs.add("scsynth");
    killAll.start(killArgs);
    killAll.waitForProcessToFinish(300);

    sc.reset();
    scheduler.reset();
}

void EngineApp::anotherInstanceStarted(const juce::String& /*commandLine*/) {}

void EngineApp::handleOsc(const juce::OSCMessage& message)
{
    const auto addr = message.getAddressPattern().toString();

    if (addr == "/engine/ping")
    {
        sendPong();
        return;
    }

    if (addr == "/scene/create")
    {
        const auto name = argToString(message, 0, "scene");
        const auto seed = argToInt(message, 1, 0);
        const auto scene = scenes->createScene(name, seed);

        juce::OSCMessage created("/scene/created");
        created.addInt32(scene.sceneId);
        created.addString(scene.name);
        router->sendReply(created);
        return;
    }

    if (addr == "/scene/destroy")
    {
        const auto sceneId = argToInt(message, 0, -1);
        const auto fadeMs = argToInt(message, 1, 50);
        scenes->destroyScene(sceneId, fadeMs);
        return;
    }

    if (addr == "/scene/param")
    {
        const auto sceneId = argToInt(message, 0, -1);
        const auto key = argToString(message, 1);
        const auto value = argToFloat(message, 2, 0.0f);
        scenes->setSceneParam(sceneId, key, value);
        return;
    }

    if (addr == "/engine/time")
    {
        transport.unrealSeconds = argToFloat(message, 0, 0.0f);
        transport.frame = argToInt(message, 1, 0);
        transport.tempo = argToFloat(message, 2, 120.0f);
        transport.beat = argToFloat(message, 3, 0.0f);
        return;
    }

    if (addr == "/engine/snapshot/save")
    {
        const auto name = argToString(message, 0, "default");
        snapshots[name] = busDbByName;
        juce::OSCMessage ack("/engine/snapshot/saved");
        ack.addString(name);
        router->sendReply(ack);
        return;
    }

    if (addr == "/engine/snapshot/load")
    {
        const auto name = argToString(message, 0, "default");
        const auto it = snapshots.find(name);
        if (it != snapshots.end())
            for (const auto& [busName, gainDb] : it->second)
                applyBusGain(busName, gainDb);

        juce::OSCMessage ack("/engine/snapshot/loaded");
        ack.addString(name);
        ack.addInt32(it != snapshots.end() ? 1 : 0);
        router->sendReply(ack);
        return;
    }

    if (addr == "/event/spawn")
    {
        const auto sceneId = argToInt(message, 0, -1);
        const auto eventType = argToString(message, 1, "proc_hit");
        const auto eventId = argToString(message, 2, juce::Uuid().toString());
        const auto x = argToFloat(message, 3, 0.0f);
        const auto y = argToFloat(message, 4, 0.0f);
        const auto z = argToFloat(message, 5, 0.0f);
        const auto gain = argToFloat(message, 6, 0.8f);
        const auto seed = argToInt(message, 7, 0);
        recentEventTimesMs[eventType] = juce::Time::getMillisecondCounterHiRes();

        scheduler->scheduleIn(scheduler->getLookaheadMs(), [this, sceneId, eventType, eventId, x, y, z, gain, seed]
        {
            EventRule rule;
            const bool hasRule = mappings.resolveRule(eventType, rule);
            const auto synthDef = (hasRule && rule.enabled) ? rule.synthDef : eventType;
            const auto scaledGain = clampf(gain * ((hasRule && rule.enabled) ? rule.gainScale : 1.0f), 0.0f, 1.0f);
            const auto now = juce::Time::getMillisecondCounterHiRes();
            const bool ok = voices->spawnEvent(sceneId, synthDef, eventId, x, y, z, scaledGain, seed, now);
            if (! ok)
                return;

            if (hasRule && rule.enabled && rule.defaultSend >= 0.0f)
                voices->setEventParam(eventId, "send", clampf(rule.defaultSend, 0.0f, 1.0f), 0);

            if (hasRule && rule.enabled)
            {
                if (rule.behavior == EventRule::Behavior::timedRelease)
                {
                    const auto releaseMs = juce::jmax(10, rule.timedReleaseMs);
                    scheduler->scheduleIn(releaseMs, [this, eventId, releaseMs] { voices->stopEvent(eventId, releaseMs); });
                }
            }
        });
        return;
    }

    if (addr == "/event/param")
    {
        const auto eventId = argToString(message, 0);
        const auto key = argToString(message, 1);
        const auto value = argToFloat(message, 2);
        const auto rampMs = argToInt(message, 3, 0);
        voices->setEventParam(eventId, key, value, rampMs);
        return;
    }

    if (addr == "/event/stop")
    {
        const auto eventId = argToString(message, 0);
        const auto releaseMs = argToInt(message, 1, 50);
        voices->stopEvent(eventId, releaseMs);
        return;
    }

    if (addr == "/mix/bus")
    {
        const auto busName = argToString(message, 0);
        const auto gainDb = argToFloat(message, 1, 0.0f);
        applyBusGain(busName, gainDb);
        return;
    }

    if (addr == "/mix/send")
    {
        const auto eventId = argToString(message, 0);
        const auto sendName = argToString(message, 1);
        const auto amount = argToFloat(message, 2, 0.0f);
        const auto rampMs = argToInt(message, 3, 0);
        voices->setMixSend(eventId, sendName, amount, rampMs);
        return;
    }

    if (addr == "/debug/voices")
    {
        juce::OSCMessage reply("/debug/voices/reply");
        reply.addInt32(voices->getActiveVoiceCount());
        router->sendReply(reply);
        return;
    }

    if (addr == "/debug/nodeTree")
    {
        juce::OSCMessage summary("/debug/nodeTree/reply");
        summary.addString(voices->getDebugSummary());
        router->sendReply(summary);
        return;
    }
}

void EngineApp::timerCallback()
{
    const auto now = juce::Time::getMillisecondCounterHiRes();
    scheduler->pump(now);

    if (++loadRetryTicks >= 400)
    {
        loadRetryTicks = 0;
        setupScGraph();
    }

    static int tick = 0;
    if (++tick >= 40)
    {
        tick = 0;
        sc->sendStatusPing();
    }
}

void EngineApp::sendPong()
{
    const auto now = juce::Time::getMillisecondCounterHiRes();
    juce::OSCMessage pong("/engine/pong");
    pong.addFloat32(static_cast<float> (now));
    pong.addInt32(sc->isConnected() ? 1 : 0);
    pong.addInt32(voices->getActiveVoiceCount());
    router->sendReply(pong);
}

void EngineApp::setupScGraph()
{
    // Root scene master group and SynthDef directory loading.
    juce::OSCMessage group("/g_new");
    group.addInt32(100);
    group.addInt32(0);
    group.addInt32(0);
    sc->send(group);

    const juce::File defFile(config.procHitDefFile);
    if (defFile.existsAsFile())
    {
        juce::MemoryBlock bytes;
        if (defFile.loadFileAsData(bytes) && bytes.getSize() > 0)
        {
            juce::OSCMessage recv("/d_recv");
            recv.addBlob(bytes);
            sc->send(recv);
        }
    }
    else
    {
        juce::OSCMessage loadOne("/d_load");
        loadOne.addString(config.procHitDefFile);
        sc->send(loadOne);
    }

    juce::OSCMessage loadDir("/d_loadDir");
    loadDir.addString(config.synthDefDir);
    sc->send(loadDir);
}

void EngineApp::createTestScene()
{
    if (testSceneId >= 0)
        return;

    const auto scene = scenes->createScene("local_test", 1234);
    testSceneId = scene.sceneId;
}

void EngineApp::spawnTestEvent(const juce::String& synthName, float gain)
{
    createTestScene();

    const auto done = sc->getLastOscDone();
    if (! (done.contains("/d_load") || done.contains("/d_recv")))
    {
        setupScGraph();
        lastUiError = "loading SynthDefs, press Spawn again";
        return;
    }

    lastTestEventId = "local-" + juce::String(juce::Time::getMillisecondCounter());
    const auto now = juce::Time::getMillisecondCounterHiRes();
    const auto spawned = voices->spawnEvent(testSceneId, synthName, lastTestEventId, 0.0f, 0.0f, 0.0f, gain, 1234, now);
    if (! spawned)
    {
        lastUiError = "spawn failed for SynthDef: " + synthName;
        return;
    }
}

void EngineApp::toggleRowTestEvent(const juce::String& incomingEvent, const juce::String& synthName, float gain)
{
    createTestScene();

    const auto done = sc->getLastOscDone();
    if (! (done.contains("/d_load") || done.contains("/d_recv")))
    {
        setupScGraph();
        lastUiError = "loading SynthDefs, press Test again";
        return;
    }

    auto eventId = rowTestEventIdByIncoming[incomingEvent];
    if (eventId.isEmpty())
        eventId = "__rowtest__" + incomingEvent;

    if (voices->hasEvent(eventId))
    {
        voices->stopEvent(eventId, 80);
        rowTestEventIdByIncoming[incomingEvent] = eventId;
        return;
    }

    const auto now = juce::Time::getMillisecondCounterHiRes();
    const auto spawned = voices->spawnEvent(testSceneId, synthName, eventId, 0.0f, 0.0f, 0.0f, gain, 1234, now);
    if (! spawned)
    {
        lastUiError = "spawn failed for SynthDef: " + synthName;
        return;
    }

    rowTestEventIdByIncoming[incomingEvent] = eventId;
}

void EngineApp::stopLastTestEvent()
{
    if (lastTestEventId.isNotEmpty())
        voices->stopEvent(lastTestEventId, 80);
}

juce::String EngineApp::getStatusText() const
{
    if (startupError.isNotEmpty())
        return startupError;

    auto text = "sc:" + juce::String(sc->isConnected() ? "up" : "down")
        + " booted:" + juce::String(sc->isBooted() ? "yes" : "no")
        + " voices:" + juce::String(voices->getActiveVoiceCount())
        + " listen:" + juce::String(config.unrealRecvPort);

    if (lastUiError.isNotEmpty())
        text << " ui:" << lastUiError.substring(0, 60);

    const auto fail = sc->getLastOscFailure().trim();
    if (fail.isNotEmpty())
        text << " fail:" << fail.substring(0, 60);

    const auto done = sc->getLastOscDone().trim();
    if (done.isNotEmpty())
    text << " done:" << done.substring(0, 40);

    return text;
}

std::vector<EventRule> EngineApp::getMappingRules() const { return mappings.getRules(); }

std::vector<juce::String> EngineApp::getAvailableSynthDefs() const
{
    return synthDefCatalog;
}

std::map<juce::String, double> EngineApp::getRecentEventTimes() const
{
    return recentEventTimesMs;
}

std::map<juce::String, bool> EngineApp::getRowTestActiveStates() const
{
    std::map<juce::String, bool> active;
    for (const auto& [incoming, eventId] : rowTestEventIdByIncoming)
    {
        if (eventId.isNotEmpty())
            active[incoming] = voices->hasEvent(eventId);
    }
    return active;
}

void EngineApp::applyBusGain(const juce::String& busName, float gainDb)
{
    busDbByName[busName] = gainDb;

    // Convention: control bus 20..24 carry named stem gains.
    int cBus = -1;
    if (busName == "music") cBus = 20;
    if (busName == "ui") cBus = 21;
    if (busName == "amb") cBus = 22;
    if (busName == "dry") cBus = 23;
    if (busName == "fx") cBus = 24;

    if (cBus >= 0)
    {
        juce::OSCMessage set("/c_set");
        set.addInt32(cBus);
        set.addFloat32(dbToGain(gainDb));
        sc->send(set);
    }
}

void EngineApp::upsertMappingRule(const juce::String& incomingEvent,
                                  const juce::String& synthDef,
                                  int behaviorId,
                                  float gainScale,
                                  float defaultSend,
                                  int timedReleaseMs,
                                  bool enabled,
                                  const juce::String& notes)
{
    EventRule r;
    r.incomingEvent = incomingEvent;
    r.synthDef = synthDef;
    r.gainScale = clampf(gainScale, 0.0f, 2.0f);
    r.defaultSend = clampf(defaultSend, -1.0f, 1.0f);
    r.timedReleaseMs = juce::jmax(10, timedReleaseMs);
    r.enabled = enabled;
    r.notes = notes;

    if (behaviorId == 1) r.behavior = EventRule::Behavior::oneShot;
    if (behaviorId == 2) r.behavior = EventRule::Behavior::gateHold;
    if (behaviorId == 3) r.behavior = EventRule::Behavior::timedRelease;

    mappings.upsertRule(std::move(r));
}

void EngineApp::removeMappingRule(const juce::String& incomingEvent)
{
    mappings.removeRule(incomingEvent);
}

void EngineApp::ensureDefaultMappings()
{
    // Seed table with one row per built-in SynthDef (incoming event == synthdef).
    for (const auto& synth : synthDefCatalog)
    {
        EventRule r;
        r.incomingEvent = synth;
        r.synthDef = synth;
        r.gainScale = 1.0f;
        r.defaultSend = -1.0f;
        r.timedReleaseMs = 220;
        r.enabled = true;
        r.notes = "General";

        if (synth == "proc_hit") r.notes = "Impact: generic procedural hit";
        if (synth == "footstep") r.notes = "Foley: footsteps";
        if (synth == "impact") r.notes = "Combat/physics impact";
        if (synth == "explosion")
        {
            r.notes = "Combat: explosion one-shot";
            r.defaultSend = 0.30f;
            r.timedReleaseMs = 520;
        }

        if (synth == "ui_blip") r.notes = "UI: short confirmation blip";
        if (synth == "ui_click") r.notes = "UI: very short button click";
        if (synth == "pickup_chime")
        {
            r.notes = "UI/gameplay: pickup/reward chime";
            r.defaultSend = 0.18f;
            r.timedReleaseMs = 380;
        }

        if (synth == "laser_zap") r.notes = "Weapon: sci-fi zap";
        if (synth == "gunshot") r.notes = "Weapon: gunshot one-shot";
        if (synth == "rifle_shot") r.notes = "Weapon: rifle shot";
        if (synth == "shotgun_blast")
        {
            r.notes = "Weapon: shotgun blast";
            r.defaultSend = 0.24f;
        }
        if (synth == "smg_burst") r.notes = "Weapon: SMG burst";
        if (synth == "ricochet_ping")
        {
            r.notes = "Weapon: ricochet ping";
            r.defaultSend = 0.16f;
        }
        if (synth == "sword_clash")
        {
            r.notes = "Weapon: sword clash";
            r.defaultSend = 0.18f;
        }
        if (synth == "bow_release") r.notes = "Weapon: bow release";
        if (synth == "reload_click") r.notes = "Weapon: reload click";
        if (synth == "rocket_launcher_blast")
        {
            r.notes = "Weapon: rocket launcher blast";
            r.defaultSend = 0.35f;
            r.timedReleaseMs = 1400;
        }
        if (synth == "pedestrians_loop") r.notes = "Wikibooks: pedestrians";
        if (synth == "phone_tone") r.notes = "Wikibooks: phone tone";
        if (synth == "dtmf_tone") r.notes = "Wikibooks: DTMF";
        if (synth == "siren_wail") r.notes = "Wikibooks: siren";
        if (synth == "telephone_bell") r.notes = "Wikibooks: telephone bell";
        if (synth == "bouncing_ball") r.notes = "Wikibooks: bouncing ball";
        if (synth == "rolling_can") r.notes = "Wikibooks: rolling can";
        if (synth == "creaking_door") r.notes = "Wikibooks: creaking door";
        if (synth == "boing_spring") r.notes = "Wikibooks: boing";
        if (synth == "fire_loop") r.notes = "Wikibooks: fire";
        if (synth == "bubbles_loop") r.notes = "Wikibooks: bubbles";
        if (synth == "running_water") r.notes = "Wikibooks: running water";
        if (synth == "electricity_arc") r.notes = "Wikibooks: electricity";
        if (synth == "motor_loop") r.notes = "Wikibooks: motor";
        if (synth == "car_passby") r.notes = "Wikibooks: car";
        if (synth == "insects_loop") r.notes = "Wikibooks: insects";
        if (synth == "transporter_beam")
        {
            r.notes = "Wikibooks: transporter";
            r.defaultSend = 0.24f;
        }
        if (synth == "red_alert_loop") r.notes = "Wikibooks: red alert";
        if (synth == "r2d2_bleeps") r.notes = "Wikibooks: R2D2-style bleeps";
        if (synth == "additive_pad")
        {
            r.notes = "Wikibooks: additive synthesis pad";
            r.defaultSend = 0.2f;
        }
        if (synth == "jump_blip") r.notes = "Player: jump cue";
        if (synth == "whoosh")
        {
            r.notes = "Motion: pass-by / whoosh";
            r.defaultSend = 0.22f;
            r.timedReleaseMs = 340;
        }
        if (synth == "door_thud") r.notes = "World: door/physics thud";
        if (synth == "magic_cast") r.notes = "Ability: magic cast";

        if (synth == "wind_loop")
        {
            r.notes = "Ambience: wind bed (loop)";
            r.defaultSend = 0.25f;
        }
        if (synth == "rain_loop")
        {
            r.notes = "Ambience: rain bed (loop)";
            r.defaultSend = 0.24f;
        }
        if (synth == "ambience_grain")
        {
            r.notes = "Ambience: granular texture (loop)";
            r.defaultSend = 0.20f;
        }

        if (synth == "engine_idle")
        {
            r.notes = "Vehicle: engine idle loop";
            r.defaultSend = 0.16f;
        }
        if (synth == "alarm_loop")
        {
            r.notes = "Alert: alarm/siren loop";
            r.defaultSend = 0.12f;
        }
        if (synth == "thunder_rumble")
        {
            r.notes = "Weather: thunder rumble";
            r.defaultSend = 0.35f;
            r.timedReleaseMs = 1200;
        }
        if (synth == "music_pulse")
        {
            r.notes = "Music: rhythmic pulse";
            r.defaultSend = 0.15f;
        }
        if (synth == "coin_pickup") r.notes = "Gameplay: coin pickup";
        if (synth == "error_buzz") r.notes = "UI/system: error buzz";
        if (synth == "powerup_swirl")
        {
            r.notes = "Gameplay: power-up swirl";
            r.defaultSend = 0.2f;
            r.timedReleaseMs = 700;
        }

        if (synth == "proc_hit" || synth == "footstep" || synth == "impact" || synth == "ui_blip"
            || synth == "ui_click" || synth == "laser_zap" || synth == "explosion"
            || synth == "pickup_chime" || synth == "whoosh" || synth == "gunshot"
            || synth == "jump_blip" || synth == "coin_pickup" || synth == "error_buzz"
            || synth == "powerup_swirl" || synth == "door_thud" || synth == "thunder_rumble"
            || synth == "magic_cast" || synth == "rifle_shot" || synth == "shotgun_blast"
            || synth == "smg_burst" || synth == "ricochet_ping" || synth == "sword_clash"
            || synth == "bow_release" || synth == "reload_click" || synth == "rocket_launcher_blast"
            || synth == "dtmf_tone" || synth == "telephone_bell" || synth == "bouncing_ball"
            || synth == "rolling_can" || synth == "creaking_door" || synth == "boing_spring"
            || synth == "car_passby" || synth == "transporter_beam" || synth == "r2d2_bleeps")
            r.behavior = EventRule::Behavior::oneShot;
        else if (synth == "music_pulse")
            r.behavior = EventRule::Behavior::timedRelease;
        else
            r.behavior = EventRule::Behavior::gateHold;

        mappings.upsertRule(std::move(r));
    }
}

void EngineApp::refreshSynthDefCatalogFromDisk()
{
    std::set<juce::String> names;
    for (const auto& n : synthDefCatalog)
        names.insert(n);

    const juce::File defsDir(config.synthDefDir);
    if (! defsDir.isDirectory())
        return;

    juce::Array<juce::File> files;
    defsDir.findChildFiles(files, juce::File::findFiles, false, "*.scsyndef");
    for (const auto& f : files)
        names.insert(f.getFileNameWithoutExtension());

    synthDefCatalog.assign(names.begin(), names.end());
}

void EngineApp::saveMappingConfig()
{
    juce::Array<juce::var> rows;
    const auto rules = mappings.getRules();

    for (const auto& r : rules)
    {
        auto* obj = new juce::DynamicObject();
        obj->setProperty("incomingEvent", r.incomingEvent);
        obj->setProperty("synthDef", r.synthDef);
        obj->setProperty("gainScale", r.gainScale);
        obj->setProperty("defaultSend", r.defaultSend);
        obj->setProperty("timedReleaseMs", r.timedReleaseMs);
        obj->setProperty("enabled", r.enabled);
        obj->setProperty("notes", r.notes);

        juce::String behavior = "gate-hold";
        if (r.behavior == EventRule::Behavior::oneShot) behavior = "one-shot";
        if (r.behavior == EventRule::Behavior::timedRelease) behavior = "timed-release";
        obj->setProperty("behavior", behavior);

        rows.add(juce::var(obj));
    }

    const juce::File configDir(juce::String(GAE_PROJECT_DIR) + "/config");
    configDir.createDirectory();
    const juce::File outFile = configDir.getChildFile("event_mappings.json");

    const auto text = juce::JSON::toString(juce::var(rows), true);
    const bool ok = outFile.replaceWithText(text);
    lastUiError = ok ? "mapping config saved" : "failed to save mapping config";
}

void EngineApp::loadMappingConfig()
{
    const juce::File inFile(juce::String(GAE_PROJECT_DIR) + "/config/event_mappings.json");
    if (! inFile.existsAsFile())
    {
        lastUiError = "mapping config file not found";
        return;
    }

    const auto text = inFile.loadFileAsString();
    juce::var parsed;
    const auto parseResult = juce::JSON::parse(text, parsed);
    if (parseResult.failed() || ! parsed.isArray())
    {
        lastUiError = "invalid mapping config json";
        return;
    }

    std::vector<EventRule> loaded;
    const auto* array = parsed.getArray();
    if (array == nullptr)
    {
        lastUiError = "invalid mapping config structure";
        return;
    }

    loaded.reserve(static_cast<size_t> (array->size()));
    for (const auto& row : *array)
    {
        if (! row.isObject())
            continue;

        EventRule r;
        r.incomingEvent = row.getProperty("incomingEvent", {}).toString();
        r.synthDef = row.getProperty("synthDef", {}).toString();
        r.gainScale = static_cast<float> (row.getProperty("gainScale", 1.0));
        r.defaultSend = static_cast<float> (row.getProperty("defaultSend", -1.0));
        r.timedReleaseMs = juce::jmax(10, static_cast<int> (row.getProperty("timedReleaseMs", 250)));
        r.enabled = static_cast<bool> (row.getProperty("enabled", true));
        r.notes = row.getProperty("notes", {}).toString();

        const auto b = row.getProperty("behavior", "gate-hold").toString();
        if (b == "one-shot")
            r.behavior = EventRule::Behavior::oneShot;
        else if (b == "timed-release")
            r.behavior = EventRule::Behavior::timedRelease;
        else
            r.behavior = EventRule::Behavior::gateHold;

        if (r.incomingEvent.isNotEmpty() && r.synthDef.isNotEmpty())
            loaded.push_back(std::move(r));
    }

    if (loaded.empty())
    {
        lastUiError = "mapping config had no valid rows";
        return;
    }

    mappings.setRules(loaded);
    lastUiError = "mapping config loaded";
}
} // namespace gae
