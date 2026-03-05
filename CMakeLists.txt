cmake_minimum_required(VERSION 3.22)
project(GameAudioEngine VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Prefer a local JUCE checkout in this repo; fallback to explicit JUCE_DIR.
if(NOT DEFINED JUCE_DIR OR JUCE_DIR STREQUAL "")
    if(EXISTS "${CMAKE_SOURCE_DIR}/JUCE/extras/Build/CMake/JUCEUtils.cmake")
        set(JUCE_DIR "${CMAKE_SOURCE_DIR}/JUCE")
    else()
        message(FATAL_ERROR "Set JUCE_DIR to your JUCE root (contains extras/Build/CMake/JUCEUtils.cmake)")
    endif()
endif()

include("${JUCE_DIR}/extras/Build/CMake/JUCEUtils.cmake")
add_subdirectory(${JUCE_DIR} juce)

juce_add_gui_app(GameAudioEngineApp
    PRODUCT_NAME "Game Audio Engine"
    VERSION "0.1.0"
    COMPANY_NAME "Local"
    BUNDLE_ID com.local.gameaudioengine
)

target_sources(GameAudioEngineApp
    PRIVATE
        Source/main.cpp
        Source/EngineApp.h
        Source/EngineApp.cpp
        Source/EngineConfig.h
        Source/EventMappingManager.h
        Source/EventMappingManager.cpp
        Source/MainComponent.h
        Source/MainComponent.cpp
        Source/OscRouter.h
        Source/OscRouter.cpp
        Source/ScServerClient.h
        Source/ScServerClient.cpp
        Source/SceneManager.h
        Source/SceneManager.cpp
        Source/VoiceManager.h
        Source/VoiceManager.cpp
        Source/Scheduler.h
        Source/Scheduler.cpp
        Source/Ids.h
)

target_compile_definitions(GameAudioEngineApp
    PRIVATE
        JUCE_WEB_BROWSER=0
        JUCE_USE_CURL=0
        GAE_PROJECT_DIR=\"${CMAKE_SOURCE_DIR}\"
)

target_link_libraries(GameAudioEngineApp
    PRIVATE
        juce::juce_core
        juce::juce_events
        juce::juce_data_structures
        juce::juce_gui_basics
        juce::juce_gui_extra
        juce::juce_osc
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_warning_flags
)
