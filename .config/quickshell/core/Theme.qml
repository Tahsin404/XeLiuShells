// ~/.config/quickshell/core/Theme.qml
pragma Singleton
import QtQuick

Item {
    id: theme

    property var cachedPalette: null

    // --- BASE COLORS ---
    property color bgBase: "#413D38"
    property color bgDark: "#34302c"
    property color bgHover: "#4f4a44"
    property color bgButton: "#413D38"

    // --- ACCENT COLORS ---
    property color accent: "#C5BAA8"
    property color hardwareRam: "#a39a8c"
    property color hardwareGpu: "#797065"

    // --- TEXT & BORDERS ---
    property color textMain: "#dfdad2"
    property color textMuted: "#9c9893"
    property color border: "#dfdad2"

    // --- STATUS COLORS ---
    property color error: "#e06c75"
    property color warning: "#e5c07b"
    property color success: "#98c379"

    // --- GLOBAL SMOOTH COLOR TRANSITIONS ---
    Behavior on bgBase {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on bgDark {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on bgHover {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on bgButton {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on accent {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on hardwareRam {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on hardwareGpu {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on textMain {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on textMuted {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on border {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }
    Behavior on error {
        ColorAnimation {
            duration: 650
            easing.type: Easing.OutCubic
        }
    }

    function updateFromData(data, useDark) {
        if (!data)
            return;
        cachedPalette = data;
        applyPolarity(useDark);
    }

    function applyPolarity(useDark) {
        if (!cachedPalette)
            return;
        let pal = useDark ? cachedPalette.dark : cachedPalette.light;
        if (!pal)
            return;

        if (pal.bgBase)
            bgBase = pal.bgBase;
        if (pal.bgDark)
            bgDark = pal.bgDark;
        if (pal.bgHover)
            bgHover = pal.bgHover;
        if (pal.bgButton)
            bgButton = pal.bgButton;
        if (pal.accent)
            accent = pal.accent;
        if (pal.hardwareRam)
            hardwareRam = pal.hardwareRam;
        if (pal.hardwareGpu)
            hardwareGpu = pal.hardwareGpu;
        if (pal.textMain)
            textMain = pal.textMain;
        if (pal.textMuted)
            textMuted = pal.textMuted;
        if (pal.border)
            border = pal.border;
        if (pal.error)
            error = pal.error;
    }

    // --- METRICS ---
    readonly property int radiusPill: 20
    readonly property int radiusBlock: 12

    // --- GLOBAL FONT ---
    FontLoader {
        id: mainFont
        source: "../assets/fonts/BigBlueTermPlusNerdFont-Regular.ttf"
    }
    readonly property string fontName: mainFont.name
}
