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

    // ── Theme transition ──
    readonly property int _tt: 400

    // ── Palette: Neutral Scale ──
    property color crust:    _p.crust    ?? "#11111b"
    property color mantle:   _p.mantle   ?? "#181825"
    property color base:     _p.base     ?? "#1e1e2e"
    property color surface0: _p.surface0 ?? "#313244"
    property color surface1: _p.surface1 ?? "#45475a"
    property color surface2: _p.surface2 ?? "#585b70"
    property color overlay0: _p.overlay0 ?? "#6c7086"
    property color overlay1: _p.overlay1 ?? "#7f849c"
    property color overlay2: _p.overlay2 ?? "#9399b2"
    property color subtext0: _p.subtext0 ?? "#a6adc8"
    property color subtext1: _p.subtext1 ?? "#bac2de"
    property color text:     _p.text     ?? "#cdd6f4"

    Behavior on crust    { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on mantle   { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on base     { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on surface0 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on surface1 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on surface2 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on overlay0 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on overlay1 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on overlay2 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on subtext0 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on subtext1 { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on text     { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }

    // ── Palette: Accent Hues ──
    property color rosewater: _p.rosewater ?? "#f5e0dc"
    property color flamingo:  _p.flamingo  ?? "#f2cdcd"
    property color pink:      _p.pink      ?? "#f5c2e7"
    property color mauve:     _p.mauve     ?? "#cba6f7"
    property color red:       _p.red       ?? "#f38ba8"
    property color maroon:    _p.maroon    ?? "#eba0ac"
    property color peach:     _p.peach     ?? "#fab387"
    property color yellow:    _p.yellow    ?? "#f9e2af"
    property color green:     _p.green     ?? "#a6e3a1"
    property color teal:      _p.teal      ?? "#94e2d5"
    property color sky:       _p.sky       ?? "#89dceb"
    property color sapphire:  _p.sapphire  ?? "#74c7ec"
    property color blue:      _p.blue      ?? "#89b4fa"
    property color lavender:  _p.lavender  ?? "#b4befe"

    Behavior on rosewater { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on flamingo  { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on pink      { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on mauve     { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on red       { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on maroon    { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on peach     { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on yellow    { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on green     { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on teal      { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on sky       { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on sapphire  { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on blue      { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on lavender  { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }

    // ── Semantic Roles (app-specific overrides from palette JSON) ──
    // Reference raw _p values to avoid chasing animated intermediates
    readonly property var _qs: _p._quickshell ?? {}
    property color accent:       _qs.accent       ?? (_p.blue     ?? "#89b4fa")
    property color disabledText: _qs.disabledText ?? (_p.overlay0 ?? "#6c7086")
    property color subtleText:   _qs.subtleText   ?? (_p.overlay1 ?? "#7f849c")
    property color separator:    _qs.separator    ?? (_p.surface1 ?? "#45475a")
    property color pillBg:       _qs.pillBg       ?? (_p.base     ?? "#1e1e2e")
    property color hoverBg:      _qs.hoverBg      ?? (_p.surface1 ?? "#45475a")
    property color frameShadow:  _qs.frameShadow  ?? (_p.crust    ?? "#11111b")

    Behavior on accent       { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on disabledText { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on subtleText   { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on separator    { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on pillBg       { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on hoverBg      { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }
    Behavior on frameShadow  { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }

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
    // bezelIntensity: 0 = none, 1 = subtle, 2 = normal, 3 = heavy
    // Controls default border geometry; individual properties can be overridden in palette JSON.
    readonly property int bezelIntensity: Math.max(0, Math.min(3, _qs.bezelIntensity ?? 2))
    readonly property int borderThickness: _qs.borderThickness ?? [0, 4, 10, 16][bezelIntensity]
    readonly property int borderRounding: _qs.borderRounding ?? [0, 4, 8, 12][bezelIntensity]

    // ── Inner Glow ──
    // Soft colored glow rendered on the content-facing edges of the frame+popout silhouette.
    // frameGlowEnabled: whether the inner glow is active (bool in palette JSON)
    // frameGlow:        glow color (falls back to frameShadow)
    // frameGlowBlur:    maximum blur radius in pixels — larger = softer/wider glow
    // frameGlowSpread:  blur softness 0.0 (max blur) to 1.0 (sharp edge)
    // frameGlowOpacity: glow intensity 0.0 (invisible) to 1.0 (full strength)
    readonly property bool frameGlowEnabled: _qs.frameGlowEnabled ?? false
    property color frameGlow: _qs.frameGlow ?? (_qs.frameShadow ?? (_p.crust ?? "#11111b"))
    readonly property int frameGlowBlur: _qs.frameGlowBlur ?? 0
    readonly property real frameGlowSpread: _qs.frameGlowSpread ?? 0.6
    readonly property real frameGlowOpacity: _qs.frameGlowOpacity ?? 1.0

    Behavior on frameGlow { ColorAnimation { duration: root._tt; easing.type: Easing.OutCubic } }

    // ── Rounding ──
    readonly property int roundingSmall: 10
    readonly property int roundingNormal: 16
    readonly property int roundingFull: 999
    readonly property int popoutRounding: 20

    // ── Popout Dimensions ──
    readonly property int popoutWidth: 280
    readonly property int popoutWidthNarrow: 180
    readonly property int popoutListHeight: 180

    // ── Notifications ──
    readonly property int notificationWidth: 360
    readonly property int notificationCenterMaxHeight: 480

    // ── Launcher ──
    readonly property int launcherWidth: 560
    readonly property int launcherItemHeight: 40
    readonly property int launcherInputHeight: 40
    readonly property int launcherMaxHeight: 420

    // ── Wallpaper Picker ──
    readonly property int wallpaperPickerWidth: 800

    // ── Sliders ──
    readonly property int sliderHeight: 24
    readonly property int sliderTrackHeight: 6
    readonly property int sliderThumbSize: 16

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
