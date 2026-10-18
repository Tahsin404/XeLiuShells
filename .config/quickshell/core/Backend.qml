// ~/.config/quickshell/core/Backend.qml
pragma Singleton
import QtQuick
import Quickshell.Io
import "../core"

Item {
    id: backendEngine
    signal candidateWallpapersFound(var files)
    // --- 1. CENTRALIZED COMMAND RUNNER ---
    Process {
        id: globalCmd
    }

    function run(commandStr) {
        globalCmd.command = ["bash", "-c", commandStr];
        globalCmd.running = true;
    }

    // --- 2. THE HEARTBEAT (Continuous Sync) ---
    // Runs the init() function every 2 seconds to keep the UI perfectly synced with Linux
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: backendEngine.init()
    }

    // --- 3. CLOCK TICKER & CALENDAR API ---
    // Standard XMLHttpRequest for Nager.Date API (Bangladesh)
    function fetchEvents(year) {
        var xhr = new XMLHttpRequest();
        var url = "https://date.nager.at/api/v3/PublicHolidays/" + year + "/BD";

        GlobalState.apiStatus = "API: Fetching...";

        xhr.open("GET", url);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText);
                    var dates = [];
                    for (var i = 0; i < response.length; i++) {
                        dates.push(response[i].date);
                    }
                    GlobalState.eventDates = [].concat(dates);
                    GlobalState.apiStatus = "API: Success (" + dates.length + ")";
                } else {
                    GlobalState.apiStatus = "API: Error HTTP " + xhr.status;
                }
            }
        };
        xhr.send();
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            GlobalState.timeString = Qt.formatTime(d, "h:mm AP");
            GlobalState.dayString = Qt.formatDate(d, "dddd");
            GlobalState.upperDayString = GlobalState.dayString.toUpperCase();

            if (GlobalState.apiStatus === "API: Waiting...") {
                fetchEvents(d.getFullYear());
            }
        }
    }

    function init() {
        btSync.running = true;
        dndSync.running = true;
        micSync.running = true;
        fetchVolumeProcess.running = true;
    }

    // Checks true Bluetooth state
    Process {
        id: btSync
        command: ["bash", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 'true' || echo 'false'"]
        stdout: SplitParser {
            onRead: data => GlobalState.btOn = (data.trim() === 'true')
        }
    }

    // Checks true Dunst state
    Process {
        id: dndSync
        command: ["bash", "-c", "dunstctl is-paused"]
        stdout: SplitParser {
            onRead: data => GlobalState.dndOn = (data.trim() === 'true')
        }
    }

    // Checks true Microphone state
    Process {
        id: micSync
        command: ["bash", "-c", "out=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>&1); [[ $out == *MUTED* || $out == *[Ee]rror* ]] && echo 'true' || echo 'false'"]
        stdout: SplitParser {
            onRead: data => GlobalState.micMuted = (data.trim() === 'true')
        }
    }

    // --- 4. DMENU / APP LAUNCHER & WALLPAPER ENGINE ---

    // Reads your click history to dynamically sort recommended apps
    Process {
        id: historyReader
        command: ["bash", "-c", "cat $HOME/.cache/quickshell_history.log 2>/dev/null || true"]
        stdout: SplitParser {
            onRead: data => {
                let app = data.trim();
                if (app !== "") {
                    let temp = GlobalState.historyCounts;
                    temp[app] = (temp[app] || 0) + 1;
                    GlobalState.historyCounts = temp;
                }
            }
        }
    }

    // Fetches apps
    Process {
        id: fetchAppsProcess
        command: ["bash", "-c", "$HOME/.config/quickshell/scripts/get_apps.sh"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("\t");
                if (parts.length >= 3 && GlobalState.allAppsModel && GlobalState.filteredAppsModel) {
                    let appObj = {
                        "name": parts[0],
                        "icon": parts[1],
                        "execCmd": parts[2],
                        "searchTags": parts[3] || ""
                    };
                    GlobalState.allAppsModel.append(appObj);
                }
            }
        }
    }

    // Scans wallpapers, caches 640x400 thumbnails, and only updates the model if files changed
    Process {
        id: fetchWallpapersProcess
        command: ["bash", "-c", "WALL_DIR=\"$HOME/.config/quickshell/assets/wallpapers\"; " + "THUMB_DIR=\"$HOME/.cache/quickshell_thumbs\"; " + "mkdir -p \"$WALL_DIR\" \"$THUMB_DIR\"; " + "find \"$WALL_DIR\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort -V | while IFS= read -r img; do " + "  fname=$(basename \"$img\"); " + "  thumb=\"$THUMB_DIR/${fname}.jpg\"; " + "  if [ ! -f \"$thumb\" ] || [ \"$img\" -nt \"$thumb\" ]; then " + "    magick \"$img\" -thumbnail 640x400^ -gravity center -extent 640x400 -quality 90 \"$thumb\" 2>/dev/null || cp \"$img\" \"$thumb\"; " + "  fi; " + "  printf '%s\\t%s\\n' \"$img\" \"$thumb\"; " + "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!GlobalState.wallpapersModel)
                    return;

                let out = text.trim();
                let lines = out === "" ? [] : out.split("\n");
                let newItems = [];

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line === "")
                        continue;
                    let parts = line.split("\t");
                    let path = parts[0];
                    let thumb = parts[1] || path;
                    let filename = path.split("/").pop();
                    let baseName = filename.replace(/\.[^/.]+$/, "");
                    newItems.push({
                        "name": "Theme " + baseName,
                        "path": path,
                        "fileUrl": "file://" + thumb
                    });
                }

                // Compare against existing model so we NEVER clear/reload unchanged cards!
                let isSame = (GlobalState.wallpapersModel.count === newItems.length);
                if (isSame) {
                    for (let i = 0; i < newItems.length; i++) {
                        if (GlobalState.wallpapersModel.get(i).path !== newItems[i].path) {
                            isSame = false;
                            break;
                        }
                    }
                }

                if (!isSame) {
                    GlobalState.wallpapersModel.clear();
                    for (let i = 0; i < newItems.length; i++) {
                        GlobalState.wallpapersModel.append(newItems[i]);
                    }
                }
            }
        }
    }
    // Copies a user-specified image into assets/wallpapers/ and pre-builds its 640x400 thumbnail
    Process {
        id: installWallpaperProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out.includes("INSTALLED_OK")) {
                    backendEngine.reloadWallpapers();
                    GlobalState.isWallpaperMode = true;
                }
            }
        }
    }

    // Live-scans a directory (defaults to ~/Downloads) for candidate wallpaper images during '> install wallpaper'
    Process {
        id: candidateWallpapersProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                let list = out === "" ? [] : out.split("\n");
                backendEngine.candidateWallpapersFound(list);
            }
        }
    }
    Process {
        id: appLauncherProcess
    }

    Process {
        id: themeRunnerProcess
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out.length > 0) {
                    try {
                        let data = JSON.parse(out);
                        if (data.isDark !== undefined) {
                            GlobalState.darkTheme = data.isDark;
                        }
                        Theme.updateFromData(data, GlobalState.darkTheme);
                    } catch (e) {
                        console.log("Theme JSON parse error:", e);
                    }
                }
            }
        }
    }

    Process {
        id: loadSavedThemeProcess
        command: ["bash", "-c", "cat $HOME/.cache/quickshell_theme.json 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out.length > 0) {
                    try {
                        let data = JSON.parse(out);
                        if (data.isDark !== undefined) {
                            GlobalState.darkTheme = data.isDark;
                        }
                        Theme.updateFromData(data, GlobalState.darkTheme);
                    } catch (e) {}
                }
            }
        }
    }

    Process {
        id: clientCheckProcess
        property string targetName: ""
        property string targetExec: ""
        property string jsonBuffer: ""

        command: ["bash", "-c", "hyprctl clients -j"]
        stdout: SplitParser {
            onRead: data => {
                clientCheckProcess.jsonBuffer += data;
            }
        }

        onExited: {
            if (jsonBuffer.length > 0) {
                let foundWorkspace = -1;
                try {
                    let clients = JSON.parse(jsonBuffer);
                    let searchName = targetName.toLowerCase();
                    for (let i = 0; i < clients.length; i++) {
                        let c = clients[i];
                        let cClass = c.class.toLowerCase();
                        let cTitle = c.title.toLowerCase();
                        if (cClass.includes(searchName) || searchName.includes(cClass) || cTitle.includes(searchName)) {
                            foundWorkspace = c.workspace.id;
                            break;
                        }
                    }
                } catch (e) {}

                if (foundWorkspace !== -1) {
                    backendEngine.run("hyprctl dispatch workspace " + foundWorkspace);
                } else {
                    appLauncherProcess.command = ["bash", "-c", targetExec + " &"];
                    appLauncherProcess.running = true;
                }
                jsonBuffer = "";
                clientCheckProcess.running = false;
            }
        }
    }

    function initDmenu(allModel, filteredModel, wallModel) {
        GlobalState.allAppsModel = allModel;
        GlobalState.filteredAppsModel = filteredModel;
        GlobalState.wallpapersModel = wallModel;
        historyReader.running = true;
        fetchAppsProcess.running = true;
        fetchWallpapersProcess.running = true;
    }

    function reloadWallpapers() {
        if (GlobalState.wallpapersModel) {
            fetchWallpapersProcess.running = true;
        }
    }
    function installWallpaper(rawPath) {
        let cleaned = rawPath.trim().replace(/^["']|["']$/g, "");
        if (cleaned === "")
            return;

        installWallpaperProcess.command = ["bash", "-c", "SRC=\"$1\"; " + "SRC=\"${SRC/#\\~/$HOME}\"; " + "WALL_DIR=\"$HOME/.config/quickshell/assets/wallpapers\"; " + "THUMB_DIR=\"$HOME/.cache/quickshell_thumbs\"; " + "mkdir -p \"$WALL_DIR\" \"$THUMB_DIR\"; " + "if [ -f \"$SRC\" ]; then " + "  fname=$(basename \"$SRC\"); " + "  dest=\"$WALL_DIR/$fname\"; " + "  cp -f \"$SRC\" \"$dest\" && " + "  thumb=\"$THUMB_DIR/${fname}.jpg\"; " + "  (magick \"$dest\" -thumbnail 640x400^ -gravity center -extent 640x400 -quality 90 \"$thumb\" 2>/dev/null || cp \"$dest\" \"$thumb\") && " + "  (command -v notify-send >/dev/null 2>&1 && notify-send 'Quickshell' \"Installed wallpaper: $fname\" || true); " + "  echo 'INSTALLED_OK'; " + "else " + "  (command -v notify-send >/dev/null 2>&1 && notify-send -u critical 'Quickshell' \"File not found: $SRC\" || true); " + "  echo 'ERR_NOT_FOUND'; " + "fi", "--", cleaned];
        installWallpaperProcess.running = true;
    }

    function scanCandidateWallpapers(rawArg) {
        let cleaned = rawArg.trim().replace(/^["']|["']$/g, "");
        candidateWallpapersProcess.command = ["bash", "-c", "ARG=\"$1\"; " + "ARG=\"${ARG/#\\~/$HOME}\"; " + "if [ -z \"$ARG\" ]; then " + "  SEARCH_DIR=\"$HOME/Downloads\"; PREFIX=\"\"; " + "elif [ -d \"$ARG\" ]; then " + "  SEARCH_DIR=\"${ARG%/}\"; PREFIX=\"\"; " + "else " + "  SEARCH_DIR=$(dirname \"$ARG\"); PREFIX=$(basename \"$ARG\"); " + "fi; " + "if [ -d \"$SEARCH_DIR\" ]; then " + "  find \"$SEARCH_DIR\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | cut -f2- | while IFS= read -r f; do " + "    b=$(basename \"$f\"); " + "    if [ -z \"$PREFIX\" ] || [[ \"${b,,}\" == *\"${PREFIX,,}\"* ]]; then " + "      echo \"${f/#$HOME/~}\"; " + "    fi; " + "  done | head -n 15; " + "fi", "--", cleaned];
        candidateWallpapersProcess.running = true;
    }
    function applyTheme(wallpaperPath) {
        themeRunnerProcess.command = ["bash", "-c", "$HOME/.config/quickshell/scripts/set_theme.sh '" + wallpaperPath + "'"];
        themeRunnerProcess.running = true;
    }

    function toggleThemePolarity() {
        GlobalState.darkTheme = !GlobalState.darkTheme;
        Theme.applyPolarity(GlobalState.darkTheme);
        let themeCmd = GlobalState.darkTheme ? "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'" : "gsettings set org.gnome.desktop.interface color-scheme 'default'";
        backendEngine.run(themeCmd);
    }

    function smartLaunch(appName, execCmd) {
        backendEngine.run("echo '" + appName + "' >> ~/.cache/quickshell_history.log");
        let temp = GlobalState.historyCounts;
        temp[appName] = (temp[appName] || 0) + 1;
        GlobalState.historyCounts = temp;

        clientCheckProcess.targetName = appName;
        clientCheckProcess.targetExec = execCmd;
        clientCheckProcess.running = true;
    }

    // --- 5. MEDIA & AUDIO HARDWARE ENGINE ---

    // Initial system volume fetch using wpctl (Now handles [MUTED] tags safely!)
    Process {
        id: fetchVolumeProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim();
                var parts = output.split(':');
                if (parts.length > 1) {
                    var valStr = parts[1].trim().split(" ")[0]; // Safely strip [MUTED]
                    var val = parseFloat(valStr);
                    if (!isNaN(val)) {
                        GlobalState.currentVolume = val;
                    }
                }
            }
        }
    }

    // Single-shot background check for display backlights
    Process {
        id: fetchBrightnessProcess
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = text.trim();
                if (output.length > 0) {
                    var parts = output.split(',');
                    if (parts.length >= 4) {
                        GlobalState.hasBrightness = true;
                        var pct = parseFloat(parts[3].replace('%', ''));
                        if (!isNaN(pct)) {
                            GlobalState.currentBrightness = pct / 100.0;
                        }
                    }
                }
            }
        }
    }

    Process {
        id: volSetProc
    }

    Process {
        id: brightnessSetProc
    }

    // Initialize media & theme states on startup
    Component.onCompleted: {
        fetchVolumeProcess.running = true;
        fetchBrightnessProcess.running = true;
        loadSavedThemeProcess.running = true;
    }

    // Abstracted setter functions for the UI Sliders to call
    function setVolume(pct) {
        volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct];
        volSetProc.running = true;
    }

    function setBrightness(pctString) {
        brightnessSetProc.command = ["brightnessctl", "set", pctString];
        brightnessSetProc.running = true;
    }
    function syncVolume() {
        fetchVolumeProcess.running = true;
    }
}
