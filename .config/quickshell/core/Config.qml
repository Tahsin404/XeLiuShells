// ~/.config/quickshell/core/Config.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // --- XDG STANDARD PATHS ---
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string xdgConfigHome: Quickshell.env("XDG_CONFIG_HOME") || (homeDir + "/.config")
    readonly property string xdgStateHome: Quickshell.env("XDG_STATE_HOME") || (homeDir + "/.local/state")

    readonly property string configDir: xdgConfigHome + "/xeliushells"
    readonly property string configPath: configDir + "/config.json"

    readonly property string stateDir: xdgStateHome + "/xeliushells"
    readonly property string themeStateDir: stateDir + "/theme"
    readonly property string hyprStateDir: stateDir + "/hypr"

    property bool dirsReady: false
    property bool ready: false
    property bool isFirstRun: false
    property bool recentlySaved: false

    // Expose top-level sections cleanly across the shell (e.g., Config.ui.clockFormat)
    readonly property alias options: adapter
    readonly property alias ui: adapter.ui
    readonly property alias localization: adapter.localization
    readonly property alias system: adapter.system
    readonly property alias sync: adapter.sync
    readonly property alias keybinds: adapter.keybinds

    // Ensure XDG config and state directories exist before FileView binds its path
    Process {
        id: initDirsProc
        command: ["mkdir", "-p", root.configDir, root.themeStateDir, root.hyprStateDir]
        running: true
        onExited: {
            root.dirsReady = true;
        }
    }

    // Debounce disk writes (100ms) when QML properties change
    Timer {
        id: saveTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (root.ready) {
                root.recentlySaved = true;
                recentlySavedResetTimer.restart();
                configFileView.writeAdapter();
            }
        }
    }

    // Prevent watchChanges from triggering a redundant reload right after writeAdapter()
    Timer {
        id: recentlySavedResetTimer
        interval: 300
        repeat: false
        onTriggered: root.recentlySaved = false
    }

    // Debounce disk reloads (100ms) when external editors modify config.json
    Timer {
        id: reloadTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (!root.recentlySaved) {
                configFileView.reload();
            }
        }
    }

    function save() {
        if (root.ready) {
            saveTimer.restart();
        }
    }

    FileView {
        id: configFileView
        path: root.dirsReady ? root.configPath : ""
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.ready = true;
            // Backfill any newly added schema keys into the user's config.json
            saveTimer.restart();
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.isFirstRun = true;
                root.ready = true;
                root.recentlySaved = true;
                recentlySavedResetTimer.restart();
                configFileView.writeAdapter();
            } else {
                console.warn("Config.qml: Failed to load config.json, error code:", error);
            }
        }

        onFileChanged: {
            if (root.ready && !root.recentlySaved) {
                reloadTimer.restart();
            }
        }

        onAdapterUpdated: {
            if (root.ready) {
                saveTimer.restart();
            }
        }

        adapter: JsonAdapter {
            id: adapter

            property int version: 1

            property JsonObject ui: JsonObject {
                property bool useSystemFont: false
                property string fontFile: "BigBlueTermPlusNerdFont-Regular.ttf"
                property string fontFamily: "BigBlueTermPlus Nerd Font"
                property string iconFontFile: "BigBlueTermPlusNerdFont-Regular.ttf"
                property string clockFormat: "h:mm AP"
                property string dateFormat: "dddd"
                property int iconSize: 18
            }

            property JsonObject localization: JsonObject {
                property string countryCode: "AUTO"
                property bool allowIpLookup: false
            }

            property JsonObject system: JsonObject {
                property string defaultWallpaper: "~/.config/quickshell/assets/wallpapers/1.png"
                property string terminalEmulator: "kitty"
            }

            property JsonObject sync: JsonObject {
                property bool syncKitty: false
                property bool syncHyprland: false
                property bool syncGlassEffects: false
                property bool syncNeovim: false
                property bool syncGtk: false
            }

            property JsonObject keybinds: JsonObject {
                property JsonObject launcher: JsonObject {
                    property string mods: "SUPER"
                    property string key: "SUPER_L"
                    property string display: "WIN"
                }
                property JsonObject media: JsonObject {
                    property string mods: ""
                    property string key: "F6"
                    property string display: "F6"
                }
                property JsonObject clock: JsonObject {
                    property string mods: ""
                    property string key: "F7"
                    property string display: "F7"
                }
                property JsonObject utility: JsonObject {
                    property string mods: ""
                    property string key: "F8"
                    property string display: "F8"
                }
            }
        }
    }
}
