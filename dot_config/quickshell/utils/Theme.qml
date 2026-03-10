pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    // Catppuccin Mocha palette
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color blue: "#89b4fa"
    readonly property color green: "#a6e3a1"
    readonly property color red: "#f38ba8"
    readonly property color peach: "#fab387"
    readonly property color mauve: "#cba6f7"
    readonly property color teal: "#94e2d5"
    readonly property color yellow: "#f9e2af"
    readonly property color pink: "#f5c2e7"
    readonly property color sky: "#89dcfe"
    readonly property color lavender: "#b4befe"

    // Bar dimensions
    readonly property int barWidth: 56
    readonly property int barInnerWidth: 38
    readonly property int barPadding: 6

    // Sizes
    readonly property int iconSize: 20          // All Material Symbol icons
    readonly property int fontSize: 14          // Primary text (clock, labels)
    readonly property int fontSizeSmall: 11     // Secondary text (ws number, window title)

    // Spacing
    readonly property int spacingSmall: 4
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 12

    // Border (screen frame)
    readonly property int borderThickness: 10
    readonly property int borderRounding: 8

    // Rounding
    readonly property int roundingSmall: 10
    readonly property int roundingNormal: 16
    readonly property int roundingFull: 999

    // Font
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string iconFontFamily: "Material Symbols Rounded"

    // Animation
    readonly property int animDuration: 250
    readonly property int animDurationFast: 150
}
