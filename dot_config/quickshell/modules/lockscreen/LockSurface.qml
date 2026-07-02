import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services as Services
import qs.utils as Utils

Item {
    id: root

    property int revealDuration: 120

    // UI states
    property real introState: 0.0
    property bool inputActive: false
    property real orbitAngle: 0
    NumberAnimation on orbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    Component.onCompleted: introState = 1.0
    Behavior on introState { NumberAnimation { duration: 1000; easing.type: Easing.OutQuint } }

    // Auto-hide input if empty and idle for 15 seconds
    Timer {
        id: idleTimer
        interval: 15000
        running: root.inputActive && hiddenInput.text.length === 0
        repeat: false
        onTriggered: root.inputActive = false
    }

    // ── Background: wallpaper + blur + vignette ──

    Image {
        id: wallpaperBg
        anchors.fill: parent
        source: Services.Wallpaper.lockScreenImage
            ? "file://" + Services.Wallpaper.lockScreenImage
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

        Behavior on brightness { NumberAnimation { duration: Utils.Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on saturation { NumberAnimation { duration: Utils.Theme.animDuration; easing.type: Easing.OutCubic } }
    }

    // Fallback solid when no wallpaper
    Rectangle {
        anchors.fill: parent
        visible: wallpaperBg.status !== Image.Ready
        color: Utils.Theme.crust
    }

    // Vignette
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.85; color: Utils.Theme.isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, 0.15) }
            GradientStop { position: 1.0; color: Utils.Theme.isDark ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(1, 1, 1, 0.35) }
        }
    }

    // ── Living background ──

    // Orbiting accent blob
    Rectangle {
        width: parent.width * 0.8; height: width; radius: width / 2
        x: (parent.width / 2 - width / 2) + Math.cos(root.orbitAngle * 2) * 200
        y: (parent.height / 2 - height / 2) + Math.sin(root.orbitAngle * 2) * 150
        scale: 1.0 + Math.sin(root.orbitAngle * 6) * 0.05
        opacity: 0.05
        color: Utils.Theme.accent
        Behavior on color { ColorAnimation { duration: 1000 } }
    }

    // Counter-orbiting secondary blob
    Rectangle {
        width: parent.width * 0.9; height: width; radius: width / 2
        x: (parent.width / 2 - width / 2) + Math.sin(root.orbitAngle * 1.5) * -200
        y: (parent.height / 2 - height / 2) + Math.cos(root.orbitAngle * 1.5) * -150
        scale: 1.0 + Math.cos(root.orbitAngle * 5) * 0.05
        opacity: 0.04
        color: Utils.Theme.blue
        Behavior on color { ColorAnimation { duration: 1000 } }
    }

    // Concentric rings (fade in with intro, flash red on failure)
    Item {
        anchors.fill: parent
        opacity: root.introState
        scale: 1.1 - (0.1 * root.introState)

        Repeater {
            model: 4
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -40
                width: 400 + (index * 220)
                height: width
                radius: width / 2
                color: "transparent"
                border.color: Services.LockScreen.showFailure ? Utils.Theme.red : Utils.Theme.accent
                border.width: 1
                opacity: Services.LockScreen.showFailure ? (0.1 - (index * 0.02)) : (0.04 - (index * 0.01))
                Behavior on border.color { ColorAnimation { duration: 600; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            }
        }
    }

    // ── Password character model ──

    ListModel { id: passModel }

    // ── Focus & service connections ──

    Connections {
        target: Services.LockScreen
        function onLockedChanged(): void {
            if (Services.LockScreen.locked)
                focusGrabTimer.restart();
        }
        function onUnlockAccepted(): void {
            exitAnim.start();
        }
        function onClearInput(): void {
            hiddenInput.text = "";
            hiddenInput.oldText = "";
            passModel.clear();
        }
        function onShowFailureChanged(): void {
            if (Services.LockScreen.showFailure)
                shakeAnim.start();
        }
    }

    Timer {
        id: focusGrabTimer
        interval: 100
        onTriggered: hiddenInput.forceActiveFocus()
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: blurredBg; property: "brightness"; to: Utils.Theme.isDark ? -1.0 : 1.0; duration: 400; easing.type: Easing.InCubic }
        onFinished: Services.LockScreen.finishUnlock()
    }

    // ── Click to activate input ──

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: cursorTimer.running ? Qt.ArrowCursor : Qt.BlankCursor
        onPositionChanged: cursorTimer.restart()
        onClicked: {
            if (!root.inputActive) root.inputActive = true;
            hiddenInput.forceActiveFocus();
        }
    }

    Timer {
        id: cursorTimer
        interval: 3000
        running: true
    }

    // ── Main content layer ──

    Item {
        anchors.fill: parent
        opacity: root.introState
        transform: Translate { y: 30 * (1.0 - root.introState) }

        // ── Clock module (idle state) ──
        ColumnLayout {
            id: clockModule
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.inputActive ? -120 : -40
            spacing: -4

            opacity: root.inputActive ? 0.0 : 1.0
            scale: root.inputActive ? 0.9 : 1.0
            visible: opacity > 0.01

            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Services.Clock.hours + ":" + Services.Clock.minutes
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 140
                font.weight: Font.Black
                color: Utils.Theme.text

                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                text: Services.Clock.ampm.toUpperCase() + "  \u2022  " + Services.Clock.format("dddd, MMMM d")
                font.family: Utils.Theme.fontFamily
                font.pixelSize: 28
                font.weight: Font.Bold
                color: Utils.Theme.accent

                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        // ── Auth module (input state) ──
        ColumnLayout {
            id: authModule
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.inputActive ? -40 : 40
            spacing: 20

            opacity: root.inputActive ? 1.0 : 0.0
            scale: root.inputActive ? 1.0 : 0.9
            visible: opacity > 0.01

            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

            // Status row with icon
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: Services.LockScreen.showFailure
                        ? Qt.rgba(Utils.Theme.red.r, Utils.Theme.red.g, Utils.Theme.red.b, 0.2)
                        : (Services.LockScreen.unlockInProgress
                            ? Qt.rgba(Utils.Theme.accent.r, Utils.Theme.accent.g, Utils.Theme.accent.b, 0.2)
                            : "transparent")
                    border.color: Services.LockScreen.showFailure
                        ? Utils.Theme.red
                        : (Services.LockScreen.unlockInProgress
                            ? Utils.Theme.accent
                            : Utils.Theme.surface2)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    Utils.MaterialIcon {
                        anchors.centerIn: parent
                        text: Services.LockScreen.showFailure ? "lock" : (Services.LockScreen.unlockInProgress ? "sync" : "lock_open")
                        font.pixelSize: 18
                        color: Services.LockScreen.showFailure
                            ? Utils.Theme.red
                            : (Services.LockScreen.unlockInProgress
                                ? Utils.Theme.accent
                                : Utils.Theme.subtext0)
                        Behavior on color { ColorAnimation { duration: 300 } }

                        RotationAnimation on rotation {
                            running: Services.LockScreen.status === "unlocking"
                            from: 0; to: 360; duration: 1000
                            loops: Animation.Infinite
                        }
                    }
                }

                Text {
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Services.LockScreen.showFailure
                        ? Utils.Theme.red
                        : (Services.LockScreen.unlockInProgress
                            ? Utils.Theme.accent
                            : Utils.Theme.subtext0)
                    text: {
                        if (Services.LockScreen.showFailure)
                            return Services.LockScreen.failMessage || "Incorrect password";
                        if (Services.LockScreen.unlockInProgress) return "Authenticating...";
                        if (hiddenInput.text.length > 0) return "Enter password";
                        return "Locked";
                    }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            // Password pill
            Rectangle {
                id: inputPill
                Layout.alignment: Qt.AlignHCenter
                width: 280; height: 60; radius: 30
                clip: true

                color: Services.LockScreen.showFailure
                    ? Qt.rgba(Utils.Theme.red.r, Utils.Theme.red.g, Utils.Theme.red.b, 0.1)
                    : Qt.rgba(Utils.Theme.surface0.r, Utils.Theme.surface0.g, Utils.Theme.surface0.b, 0.5)
                border.width: 2
                border.color: {
                    if (Services.LockScreen.showFailure) return Utils.Theme.red;
                    if (Services.LockScreen.unlockInProgress)
                        return Qt.rgba(Utils.Theme.surface1.r, Utils.Theme.surface1.g, Utils.Theme.surface1.b, 0.8);
                    if (hiddenInput.text.length > 0) return Utils.Theme.accent;
                    return Qt.rgba(Utils.Theme.text.r, Utils.Theme.text.g, Utils.Theme.text.b, 0.08);
                }

                Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }

                scale: Services.LockScreen.showFailure ? 1.05
                    : (Services.LockScreen.unlockInProgress ? 0.98 : 1.0)
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                transform: Translate { id: shakeTranslate; x: 0 }

                // Hidden TextInput for native keystroke capture
                TextInput {
                    id: hiddenInput
                    anchors.fill: parent
                    opacity: 0
                    echoMode: TextInput.Password

                    property string oldText: ""

                    Component.onCompleted: forceActiveFocus()

                    onActiveFocusChanged: {
                        if (!activeFocus && Services.LockScreen.locked)
                            forceActiveFocus()
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_CapsLock && !event.isAutoRepeat)
                            Services.LockScreen.capsLockKeyPressed();
                        if (event.key === Qt.Key_Escape) {
                            root.inputActive = false;
                            text = "";
                            passModel.clear();
                            Services.LockScreen.clear();
                            event.accepted = true;
                        } else if (!root.inputActive) {
                            root.inputActive = true;
                        }
                    }

                    onAccepted: {
                        if (text.length > 0 && !Services.LockScreen.unlockInProgress) {
                            Services.LockScreen.tryUnlock(text);
                            text = "";
                            oldText = "";
                            passModel.clear();
                        }
                    }

                    onTextChanged: {
                        if (Services.LockScreen.unlockInProgress) return;

                        if (text.length > 0 && !root.inputActive)
                            root.inputActive = true;

                        idleTimer.restart();

                        if (text !== oldText) {
                            if (text.length > oldText.length) {
                                for (let i = oldText.length; i < text.length; i++)
                                    passModel.append({ charStr: text.charAt(i), isDot: false });
                            } else if (text.length < oldText.length) {
                                let diff = oldText.length - text.length;
                                for (let i = 0; i < diff; i++)
                                    passModel.remove(passModel.count - 1);
                            }
                            oldText = text;
                        }

                        if (Services.LockScreen.showFailure)
                            Services.LockScreen.showFailure = false;

                        Services.LockScreen.currentText = text;
                    }
                }

                // Password characters display
                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    clip: true

                    Row {
                        id: dotRow
                        anchors.verticalCenter: parent.verticalCenter
                        x: width > parent.width ? parent.width - width : (parent.width - width) / 2
                        spacing: -2

                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                        Repeater {
                            model: passModel
                            delegate: Item {
                                width: charText.implicitWidth
                                height: 30

                                Timer {
                                    interval: root.revealDuration
                                    running: !model.isDot
                                    onTriggered: {
                                        if (index >= 0 && index < passModel.count)
                                            passModel.setProperty(index, "isDot", true);
                                    }
                                }

                                Text {
                                    id: charText
                                    anchors.centerIn: parent
                                    text: model.isDot ? "\u2022" : model.charStr
                                    font.family: Utils.Theme.fontFamily
                                    font.pixelSize: model.isDot ? 42 : 28
                                    font.weight: Font.Bold
                                    color: Services.LockScreen.failureFlash
                                        ? Utils.Theme.red
                                        : Utils.Theme.text

                                    NumberAnimation on opacity { from: 0; to: 1; duration: 150 }
                                }
                            }
                        }
                    }
                }

                // Unlocking indicator
                Text {
                    anchors.centerIn: parent
                    text: "Unlocking..."
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: Utils.Theme.subtext0
                    visible: Services.LockScreen.unlockInProgress

                    SequentialAnimation on opacity {
                        running: Services.LockScreen.unlockInProgress
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                    }
                }

                // Shake on failure
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: shakeTranslate; property: "x"; to: -12; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeTranslate; property: "x"; to: 10; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeTranslate; property: "x"; to: -8; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeTranslate; property: "x"; to: 6; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeTranslate; property: "x"; to: -3; duration: 40; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeTranslate; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
                }
            }

            // Caps-lock hint — fades via opacity but always occupies its row,
            // so the pill doesn't jump when caps toggles mid-typing.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                opacity: Services.LockScreen.capsLock ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Utils.MaterialIcon {
                    text: "keyboard_capslock"
                    fill: 1
                    font.pixelSize: 16
                    color: Utils.Theme.yellow
                }
                Text {
                    text: "Caps Lock is on"
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Utils.Theme.yellow
                }
            }
        }
    }
}
