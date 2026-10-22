// ~/.config/quickshell/core/GlobalState.qml
pragma Singleton
import QtQuick

Item {
    id: globalState

    // --- EXPANDED PILL STATES ---
    property bool mediaExpanded: false
    property bool clockExpanded: false
    property bool utilityExpanded: false

    function closeAllPills() {
        mediaExpanded = false;
        clockExpanded = false;
        utilityExpanded = false;
    }

    // --- SYSTEM TOGGLES ---
    property bool wifiOn: true
    property bool btOn: false
    property bool dndOn: false
    property bool micMuted: true
    property bool darkTheme: true
    property bool nightLightOn: false

    // --- HARDWARE MONITORS ---
    property bool isLaptop: false
    property real batteryLevel: 0.75
    property real cpuLevel: 0.65
    property real ramLevel: 0.82
    property real gpuLevel: 0.35

    // --- ACTIVE WINDOW DATA ---
    property string activeAppName: "Desktop"
    property string activeAppTitle: ""

    // --- CLOCK & CALENDAR STATES ---
    property string timeString: "..."
    property string dayString: "..."
    property string upperDayString: "..."
    property int currentMonth: 0
    property int currentYear: 0
    property var eventDates: []
    property var eventNames: ({})
    property string apiStatus: "API: Waiting..."

    // --- DMENU / APP LAUNCHER STATES ---
    property var allAppsModel: null
    property var filteredAppsModel: null
    property var historyCounts: ({})
    property bool isWallpaperMode: false
    property bool isKeybindsMode: false
    property bool isSyncMode: false
    property bool keybindsSourceConfigured: true
    property bool isRecordingKeybind: false
    property var keybindConflicts: []
    property var wallpapersModel: null

    // --- HARDWARE & MEDIA STATES ---
    property bool hasBrightness: false
    property real currentBrightness: 0.0
    property real currentVolume: -1.0
}
