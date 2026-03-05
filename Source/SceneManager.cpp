#include "SceneManager.h"

namespace gae
{
SceneManager::SceneManager(ScServerClient& scClient) : sc(scClient) {}

SceneState SceneManager::createScene(const juce::String& name, int seed)
{
    SceneState scene;
    scene.sceneId = sceneIdAllocator.allocate();
    scene.groupId = groupIdAllocator.allocate();
    scene.name = name;
    scene.seed = seed;

    scenes[scene.sceneId] = scene;

    // Create a dedicated SC group for this scene under root group 0.
    juce::OSCMessage m("/g_new");
    m.addInt32(scene.groupId);
    m.addInt32(0);
    m.addInt32(0);
    sc.send(m);

    return scene;
}

bool SceneManager::destroyScene(int sceneId, int /*fadeMs*/)
{
    const auto it = scenes.find(sceneId);
    if (it == scenes.end())
        return false;

    juce::OSCMessage m("/g_freeAll");
    m.addInt32(it->second.groupId);
    sc.send(m);
    scenes.erase(it);
    paramsByScene.erase(sceneId);
    return true;
}

bool SceneManager::setSceneParam(int sceneId, const juce::String& key, float value)
{
    const auto it = scenes.find(sceneId);
    if (it == scenes.end())
        return false;

    paramsByScene[sceneId][key] = value;
    return true;
}

SceneState* SceneManager::getScene(int sceneId)
{
    const auto it = scenes.find(sceneId);
    if (it == scenes.end())
        return nullptr;

    return &it->second;
}
} // namespace gae
