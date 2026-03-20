import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    // ── Background: wallpaper + blur + vignette ──

    Image {
        id: wallpaperBg
        anchors.fill: parent
        source: Services.Wallpaper.currentWallpaper
            ? "file://" + Services.Wallpaper.wallpaperDir + "/" + Services.Wallpaper.currentWallpaper
            : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        id: blurredBg
        source: wallpaperBg
        anchors.fill: parent
        visible: wallpaperBg.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: 0.6
        brightness: Utils.Theme.isDark ? -0.25 : 0.25
        saturation: Utils.Theme.isDark ? -0.1 : -0.25

        Behavior on brightness { NumberAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }
        Behavior on saturation { NumberAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }
    }

    // Fallback solid when no wallpaper
    Rectangle {
        anchors.fill: parent
        visible: wallpaperBg.status !== Image.Ready
        color: Utils.Theme.crust
    }

    // Vignette
    Rectangle {
        id: vignette
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.85; color: Utils.Theme.isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, 0.15) }
            GradientStop { position: 1.0; color: Utils.Theme.isDark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.35) }
        }
    }

    // ── Key input ──

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            Services.LockScreen.tryUnlock();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            Services.LockScreen.clear();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            const t = Services.LockScreen.currentText;
            if (t.length > 0)
                Services.LockScreen.currentText = t.substring(0, t.length - 1);
            event.accepted = true;
        } else if (event.text.length > 0 && !event.modifiers) {
            if (Services.LockScreen.showFailure)
                Services.LockScreen.showFailure = false;
            Services.LockScreen.currentText += event.text;
            inputField._pulseScale = 1.03;
            pulseReset.restart();
            event.accepted = true;
        }
    }

    // ── Focus management ──

    Connections {
        target: Services.LockScreen
        function onLockedChanged(): void {
            if (Services.LockScreen.locked)
                focusGrabTimer.restart();
        }
        function onUnlockAccepted(): void {
            exitAnim.start();
        }
    }

    // Delay focus grab slightly so compositor finishes setting up the lock surface (esp. after sleep resume)
    Timer {
        id: focusGrabTimer
        interval: 100
        onTriggered: root.forceActiveFocus()
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: contentColumn; property: "opacity"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: contentColumn; property: "scale"; to: 1.02; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: blurredBg; property: "brightness"; to: Utils.Theme.isDark ? -1.0 : 1.0; duration: 400; easing.type: Easing.InCubic }
        onFinished: Services.LockScreen.finishUnlock()
    }

    // ── Content ──

    ColumnLayout {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 0
        transformOrigin: Item.Center

        // Clock
        Text {
            id: clockText
            Layout.alignment: Qt.AlignHCenter
            text: Services.Clock.hours + ":" + Services.Clock.minutes
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 96
            font.weight: Font.ExtraLight
            color: Utils.Theme.text

            Behavior on color { ColorAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }

            opacity: 0
            transform: Translate { id: clockTranslate; y: 20 }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.3
                shadowColor: Utils.Theme.isDark ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(0, 0, 0, 0.15)
                shadowVerticalOffset: 2
            }
        }

        // AM/PM
        Text {
            id: ampmText
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -8
            text: Services.Clock.ampm.toUpperCase()
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 16
            font.weight: Font.Medium
            font.letterSpacing: 3
            color: Qt.rgba(Utils.Theme.subtext0.r, Utils.Theme.subtext0.g, Utils.Theme.subtext0.b, 0.7)

            Behavior on color { ColorAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }

            opacity: 0
            transform: Translate { id: ampmTranslate; y: 20 }
        }

        // Date
        Text {
            id: dateText
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            text: Services.Clock.format("dddd, MMMM d")
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 18
            font.letterSpacing: 0.5
            color: Qt.rgba(Utils.Theme.subtext0.r, Utils.Theme.subtext0.g, Utils.Theme.subtext0.b, 0.85)

            Behavior on color { ColorAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }

            opacity: 0
            transform: Translate { id: dateTranslate; y: 15 }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 0.2
                shadowColor: Utils.Theme.isDark ? Qt.rgba(0, 0, 0, 0.4) : Qt.rgba(0, 0, 0, 0.1)
                shadowVerticalOffset: 1
            }
        }

        // Spacer between clock group and input
        Item { Layout.preferredHeight: 48 }

        // ── Password input field ──
        Rectangle {
            id: inputField
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 300
            Layout.preferredHeight: 50
            radius: 25
            color: Qt.rgba(Utils.Theme.crust.r, Utils.Theme.crust.g, Utils.Theme.crust.b, 0.55)
            border.width: 2
            border.color: {
                if (Services.LockScreen.showFailure)
                    return Qt.rgba(Utils.Theme.red.r, Utils.Theme.red.g, Utils.Theme.red.b, 0.8);
                if (Services.LockScreen.unlockInProgress)
                    return Qt.rgba(Utils.Theme.surface1.r, Utils.Theme.surface1.g, Utils.Theme.surface1.b, 0.8);
                if (Services.LockScreen.currentText.length > 0)
                    return Qt.rgba(Utils.Theme.accent.r, Utils.Theme.accent.g, Utils.Theme.accent.b, 0.6);
                return Qt.rgba(Utils.Theme.surface1.r, Utils.Theme.surface1.g, Utils.Theme.surface1.b, 0.5);
            }

            opacity: 0
            transform: [
                Translate { id: inputTranslate; y: 10 },
                Translate { id: shakeTranslate; x: 0 },
                Scale {
                    origin.x: inputField.width / 2
                    origin.y: inputField.height / 2
                    xScale: inputField._pulseScale
                    yScale: inputField._pulseScale
                }
            ]

            property real _pulseScale: 1.0
            Behavior on _pulseScale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Timer {
                id: pulseReset
                interval: 80
                onTriggered: inputField._pulseScale = 1.0
            }

            Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }

            // Inner frost edge
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 24
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(Utils.Theme.overlay0.r, Utils.Theme.overlay0.g, Utils.Theme.overlay0.b, 0.15)
            }

            // Red flash overlay on failure
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Utils.Theme.red
                opacity: Services.LockScreen.showFailure ? 0.15 : 0
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            // Password dots
            Row {
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: Services.LockScreen.currentText.length

                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: Services.LockScreen.failureFlash
                            ? Utils.Theme.red
                            : Qt.rgba(Utils.Theme.text.r, Utils.Theme.text.g, Utils.Theme.text.b, 0.95)

                        // Pop-in animation
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Utils.Theme.animCurveEmphasizedDecel
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // Placeholder
            Text {
                anchors.centerIn: parent
                text: "Enter password"
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 15
                font.letterSpacing: 0.5
                color: Qt.rgba(Utils.Theme.overlay0.r, Utils.Theme.overlay0.g, Utils.Theme.overlay0.b, 0.6)
                opacity: Services.LockScreen.currentText.length === 0
                    && !Services.LockScreen.unlockInProgress ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }
            }

            // Unlocking indicator with pulse
            Text {
                id: unlockingText
                anchors.centerIn: parent
                text: "Unlocking..."
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 15
                color: Utils.Theme.subtext0
                visible: Services.LockScreen.unlockInProgress

                Behavior on color { ColorAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }

                SequentialAnimation on opacity {
                    running: Services.LockScreen.unlockInProgress
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            // Shake animation on failure
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shakeTranslate; property: "x"; to: -12; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 10; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -8; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 6; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: -3; duration: 40; easing.type: Easing.OutQuad }
                NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
            }

            Connections {
                target: Services.LockScreen
                function onShowFailureChanged(): void {
                    if (Services.LockScreen.showFailure)
                        shakeAnim.start();
                }
            }
        }

        // Failure message
        Text {
            id: failText
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            text: Services.LockScreen.failMessage
            font.family: Utils.Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Utils.Theme.red
            opacity: Services.LockScreen.showFailure ? 1 : 0

            property real _offsetY: Services.LockScreen.showFailure ? 0 : 5
            transform: Translate { y: failText._offsetY }

            Behavior on _offsetY { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Utils.Theme._tt; easing.type: Easing.OutCubic } }
        }
    }

    // ── Cursor auto-hide ──

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: cursorTimer.running ? Qt.ArrowCursor : Qt.BlankCursor
        propagateComposedEvents: true
        onPositionChanged: { cursorTimer.restart(); root.forceActiveFocus(); }
        onClicked: mouse => { root.forceActiveFocus(); mouse.accepted = false; }
        z: -1
    }

    Timer {
        id: cursorTimer
        interval: 3000
        running: true
    }

    // ── Staggered entrance animation ──

    Component.onCompleted: entranceAnim.start()

    SequentialAnimation {
        id: entranceAnim

        // Background brighten
        ParallelAnimation {
            NumberAnimation {
                target: blurredBg; property: "brightness"
                from: Utils.Theme.isDark ? -1.0 : 1.0
                to: Utils.Theme.isDark ? -0.25 : 0.25
                duration: 600; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: blurredBg; property: "blur"
                from: 1.0; to: 0.6; duration: 800; easing.type: Easing.OutCubic
            }
        }

        // Stagger in: clock group (overlapped starts via ParallelAnimation + PauseAnimation)
        PauseAnimation { duration: 0 }

        ParallelAnimation {
            // Clock
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: clockText; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: clockTranslate; property: "y"; to: 0; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: Utils.Theme.animCurveEmphasizedDecel }
                }
            }

            // AM/PM (100ms delay)
            SequentialAnimation {
                PauseAnimation { duration: 100 }
                ParallelAnimation {
                    NumberAnimation { target: ampmText; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: ampmTranslate; property: "y"; to: 0; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: Utils.Theme.animCurveEmphasizedDecel }
                }
            }

            // Date (200ms delay)
            SequentialAnimation {
                PauseAnimation { duration: 200 }
                ParallelAnimation {
                    NumberAnimation { target: dateText; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: dateTranslate; property: "y"; to: 0; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: Utils.Theme.animCurveEmphasizedDecel }
                }
            }

            // Input field (300ms delay)
            SequentialAnimation {
                PauseAnimation { duration: 300 }
                ParallelAnimation {
                    NumberAnimation { target: inputField; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
                    NumberAnimation { target: inputTranslate; property: "y"; to: 0; duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: Utils.Theme.animCurveEmphasizedDecel }
                }
            }
        }
    }
}
