#pragma once

#include "Ids.h"
#include "ScServerClient.h"

#include <juce_core/juce_core.h>
#include <map>
#include <unordered_map>

namespace gae
{
struct SceneState
{
    int sceneId {};
    int groupId {};
    juce::String name;
    int seed {};
};

class SceneManager
{
public:
    explicit SceneManager(ScServerClient& scClient);

    SceneState createScene(const juce::String& name, int seed);
    bool destroyScene(int sceneId, int fadeMs);
    bool setSceneParam(int sceneId, const juce::String& key, float value);

    SceneState* getScene(int sceneId);

private:
    ScServerClient& sc;
    IdAllocator sceneIdAllocator { 1 };
    IdAllocator groupIdAllocator { 1000 };
    std::unordered_map<int, SceneState> scenes;
    std::unordered_map<int, std::map<juce::String, float>> paramsByScene;
};
} // namespace gae
