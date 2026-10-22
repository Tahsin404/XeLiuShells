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

    // --- GLOBAL FONTS (Bundled File Path vs. System Font Family + Dedicated Icon Font) ---
    FontLoader {
        id: iconFontLoader
        source: "../assets/fonts/" + (Config.ui.iconFontFile || "BigBlueTermPlusNerdFont-Regular.ttf")
    }

    FontLoader {
        id: mainFont
        source: "../assets/fonts/" + (Config.ui.fontFile || "BigBlueTermPlusNerdFont-Regular.ttf")
    }

    // Always points to a valid Nerd Font for icons
    readonly property string iconFontName: iconFontLoader.status === FontLoader.Ready ? iconFontLoader.name : "BigBlueTermPlus Nerd Font"

    // Switches between a system font family name and a bundled Nerd Font file
    readonly property string fontName: {
        if (Config.ui.useSystemFont && Config.ui.fontFamily.trim() !== "") {
            return Config.ui.fontFamily.trim();
        }
        if (mainFont.status === FontLoader.Ready && mainFont.name !== "") {
            return mainFont.name;
        }
        return iconFontName;
    }

    readonly property int iconSize: Config.ui.iconSize > 0 ? Config.ui.iconSize : 18
}
