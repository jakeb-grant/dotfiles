pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ── Theme File ──
    FileView {
        id: themeFile
        path: root.palettePath + "/active.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: {
            reload()
            root._rev++
        }
    }

    property int _rev: 0
    readonly property var _p: {
        void root._rev
        try { return JSON.parse(themeFile.text()) }
        catch(e) { return {} }
    }

    // ── Palette Meta ──
    readonly property string palettePath: Quickshell.env("HOME") + "/.config/palette"
    readonly property string themeName: _p._name ?? "Unknown"

    // ── Palette: Neutral Scale ──
    readonly property color crust:    _p.crust    ?? "#11111b"
    readonly property color mantle:   _p.mantle   ?? "#181825"
    readonly property color base:     _p.base     ?? "#1e1e2e"
    readonly property color surface0: _p.surface0 ?? "#313244"
    readonly property color surface1: _p.surface1 ?? "#45475a"
    readonly property color surface2: _p.surface2 ?? "#585b70"
    readonly property color overlay0: _p.overlay0 ?? "#6c7086"
    readonly property color overlay1: _p.overlay1 ?? "#7f849c"
    readonly property color overlay2: _p.overlay2 ?? "#9399b2"
    readonly property color subtext0: _p.subtext0 ?? "#a6adc8"
    readonly property color subtext1: _p.subtext1 ?? "#bac2de"
    readonly property color text:     _p.text     ?? "#cdd6f4"

    // ── Semantic Roles (app-specific overrides from palette JSON) ──
    readonly property var _qs: _p._quickshell ?? {}
    readonly property color disabledText: _qs.disabledText ?? overlay0
    readonly property color subtleText:   _qs.subtleText   ?? overlay1
    readonly property color separator:    _qs.separator    ?? surface1
    readonly property color pillBg:       _qs.pillBg       ?? base
    readonly property color hoverBg:      _qs.hoverBg      ?? surface1
    readonly property color frameShadow:  _qs.frameShadow  ?? crust

    // ── Palette: Accent Hues ──
    readonly property color rosewater: _p.rosewater ?? "#f5e0dc"
    readonly property color flamingo:  _p.flamingo  ?? "#f2cdcd"
    readonly property color pink:      _p.pink      ?? "#f5c2e7"
    readonly property color mauve:     _p.mauve     ?? "#cba6f7"
    readonly property color red:       _p.red       ?? "#f38ba8"
    readonly property color maroon:    _p.maroon    ?? "#eba0ac"
    readonly property color peach:     _p.peach     ?? "#fab387"
    readonly property color yellow:    _p.yellow    ?? "#f9e2af"
    readonly property color green:     _p.green     ?? "#a6e3a1"
    readonly property color teal:      _p.teal      ?? "#94e2d5"
    readonly property color sky:       _p.sky       ?? "#89dceb"
    readonly property color sapphire:  _p.sapphire  ?? "#74c7ec"
    readonly property color blue:      _p.blue      ?? "#89b4fa"
    readonly property color lavender:  _p.lavender  ?? "#b4befe"

    // ── Bar Dimensions ──
    readonly property int barWidth: 56
    readonly property int barInnerWidth: 38
    readonly property int barPadding: 6

    // ── Sizes ──
    readonly property int iconSize: 20
    readonly property int iconSizeSmall: 14
    readonly property int fontSize: 14
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeXSmall: 9

    // ── Spacing ──
    readonly property int spacingTiny: 2
    readonly property int spacingSmall: 4
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 12

    // ── Border (screen frame) ──
    readonly property int borderThickness: 10
    readonly property int borderRounding: 8
    readonly property int frameShadowBlur: 24
    readonly property real frameShadowOpacity: 1.0

    // ── Rounding ──
    readonly property int roundingSmall: 10
    readonly property int roundingNormal: 16
    readonly property int roundingFull: 999
    readonly property int popoutRounding: 20

    // ── Popout Dimensions ──
    readonly property int popoutWidth: 280
    readonly property int popoutWidthNarrow: 180
    readonly property int popoutListHeight: 180

    // ── List Items ──
    readonly property int listItemHeight: 32
    readonly property int listItemRadius: 6
    readonly property int listItemMargin: 8
    readonly property int listFontSize: 13

    // ── Pill Buttons ──
    readonly property int pillHeight: 30
    readonly property int pillFontSize: 12
    readonly property int pillSpacing: 4

    // ── Header ──
    readonly property int headerFontSize: 16
    readonly property int popoutTitleSize: 18
    readonly property int headerActionIconSize: popoutTitleSize
    readonly property int headerIconSize: 24
    readonly property int headerIconSizeLarge: 28

    // ── Tray Menu ──
    readonly property int trayMenuMinWidth: 200
    readonly property int trayMenuMaxWidth: 400
    readonly property int trayMenuItemHeight: listItemHeight - 6

    // ── Calendar ──
    readonly property int calendarHeaderFontSize: 10
    readonly property int calendarDayFontSize: 12

    // ── Action Items ──
    readonly property int actionItemHeight: 36

    // ── Font ──
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string iconFontFamily: "Material Symbols Rounded"

    // ── Animation Curves (MD3 BezierSpline) ──
    readonly property var animCurveEmphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property var animCurveStandard: [0.2, 0, 0, 1, 1, 1]
    readonly property var animCurveEmphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var animCurveEmphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]

    // ── Animation Durations ──
    readonly property int animDuration: 400
    readonly property int animDurationSmall: 200
    readonly property int animDurationFast: 150
    readonly property int animDurationSpin: 800
}
