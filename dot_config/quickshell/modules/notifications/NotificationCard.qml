import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.services as Services
import qs.utils as Utils

Rectangle {
    id: root

    required property Notification notification

    readonly property bool isCritical: notification.urgency === NotificationUrgency.Critical

    // Dismissal state — driven by service, survives Repeater recreation
    readonly property bool dismissing: Services.Notifications.isDismissing(notification)

    // Exit duration must match the Behaviors below so the layout collapse and
    // the visual fade end together.
    readonly property int _exitDuration: Utils.Theme.animDurationSmall
    readonly property int _enterDuration: Utils.Theme.animDuration - 100

    color: cardHover.hovered ? Utils.Theme.surface0 : Utils.Theme.mantle
    radius: Utils.Theme.islandRounding

    Behavior on color {
        ColorAnimation { duration: Utils.Theme.animDurationFast }
    }
    implicitHeight: content.implicitHeight + Utils.Theme.spacingLarge * 2

    // Layout.preferredHeight tracks implicitHeight while alive; on dismiss we
    // animate it down to 0 explicitly (no Behavior — that would either fire
    // on async implicitHeight changes during entrance, or race with its own
    // enabled-gate). Once collapseAnim starts, the binding is severed for
    // the card's remaining lifetime, which is fine — it's about to be
    // destroyed by finishRemoval.
    Layout.preferredHeight: implicitHeight

    NumberAnimation {
        id: collapseAnim
        target: root
        property: "Layout.preferredHeight"
        to: 0
        duration: root._exitDuration
        easing.type: Easing.InCubic
    }

    // Drop shadow — each card is its own floating island (no container wrapper).
    layer.enabled: visible
    layer.smooth: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Utils.Theme.islandShadowColor
        shadowOpacity: Utils.Theme.islandShadowOpacity
        blurMax: Utils.Theme.islandShadowBlur
        shadowVerticalOffset: Utils.Theme.islandShadowY
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true
    }

    // Entrance one-shot: fresh notifications start at 0/0.85 from the binding
    // eval, then Component.onCompleted imperatively assigns 1/1 which is what
    // the Behaviors animate. Repeater-recreated cards (markSeen already ran)
    // skip the imperative writes and just stay at 1/1 from the binding.
    //
    // The imperative writes are necessary: a binding re-evaluation triggered
    // synchronously inside Component.onCompleted is treated by Qt as part of
    // initialization and the Behavior does NOT fire — so a pure-binding
    // approach silently skips the entrance animation.
    readonly property bool _wasNew: Services.Notifications.isNew(notification)
    opacity: dismissing ? 0 : _wasNew ? 0 : 1
    scale: dismissing ? 0.85 : _wasNew ? 0.85 : 1
    transformOrigin: Item.Right

    Component.onCompleted: {
        Services.Notifications.markSeen(notification);
        if (!dismissing) { opacity = 1; scale = 1 }
    }

    // Exit imperatives — triggering them via onDismissingChanged guarantees
    // the Behaviors fire (binding-driven changes inside the dismissal flow
    // are reliable, but going imperative is consistent with the entrance).
    onDismissingChanged: {
        if (dismissing) {
            opacity = 0;
            scale = 0.85;
            collapseAnim.start();
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.dismissing ? root._exitDuration : root._enterDuration
            easing.type: root.dismissing ? Easing.InCubic : Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.dismissing ? root._exitDuration : root._enterDuration
            easing.type: root.dismissing ? Easing.InCubic : Easing.OutCubic
        }
    }

    // Finish removal after exit animation completes (small grace for the layout
    // collapse to finish too).
    Timer {
        id: finishTimer
        running: root.dismissing
        interval: root._exitDuration + 40
        onTriggered: Services.Notifications.finishRemoval(root.notification)
        Component.onDestruction: stop()
    }

    // Critical urgency left accent
    Rectangle {
        visible: root.isCritical
        width: 4
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: Utils.Theme.spacingSmall
        anchors.topMargin: Utils.Theme.spacingNormal
        anchors.bottomMargin: Utils.Theme.spacingNormal
        radius: width / 2
        color: Utils.Theme.red
    }

    // Auto-dismiss timer
    Timer {
        id: expireTimer
        interval: Services.Notifications.remainingTimeout(root.notification)
        running: !root.dismissing
        onTriggered: Services.Notifications.animatedRemove(root.notification)
    }

    // Remove if app closes the notification
    Connections {
        target: root.notification
        function onClosed() {
            if (!root.dismissing)
                Services.Notifications.animatedRemove(root.notification);
        }
    }

    // Pause timer on hover (non-blocking — doesn't consume clicks)
    HoverHandler {
        id: cardHover
        onHoveredChanged: {
            if (root.dismissing) return;
            if (hovered) expireTimer.stop();
            else expireTimer.restart();
        }
    }

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.margins: Utils.Theme.spacingLarge
        spacing: Utils.Theme.spacingNormal

        // App icon — prefer notification image, then appIcon, then fallback
        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignTop
            radius: width / 2
            color: Utils.Theme.surface1
            clip: true

            Image {
                id: notifImage
                anchors.fill: parent
                anchors.margins: 4
                source: {
                    const img = root.notification.image;
                    if (!img) return "";
                    // File paths and data URIs work directly
                    if (img.startsWith("/") || img.startsWith("file:") || img.startsWith("data:"))
                        return img;
                    // image://icon/ URIs: extract name and resolve via icon theme
                    // (passing them through directly shows checkerboard for missing icons)
                    const iconName = img.startsWith("image://icon/")
                        ? img.substring(13) : img;
                    return Quickshell.iconPath(iconName) ?? "";
                }
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                asynchronous: true
                sourceSize: Qt.size(48, 48)
            }

            Image {
                id: iconImg
                anchors.fill: parent
                source: (!notifImage.visible && root.notification.appIcon)
                    ? (Quickshell.iconPath(root.notification.appIcon) ?? "") : ""
                fillMode: Image.PreserveAspectFit
                visible: !notifImage.visible && status === Image.Ready
                sourceSize: Qt.size(28, 28)
            }

            Utils.MaterialIcon {
                anchors.centerIn: parent
                text: "notifications"
                font.pixelSize: Utils.Theme.iconSize
                color: Utils.Theme.subtext0
                visible: !notifImage.visible && !iconImg.visible
            }
        }

        // Text content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Utils.Theme.spacingTiny

            // App name
            Text {
                Layout.fillWidth: true
                text: root.notification.appName
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext1
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text !== ""
            }

            // Summary
            Text {
                Layout.fillWidth: true
                text: root.notification.summary
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.listFontSize
                font.bold: true
                color: Utils.Theme.text
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            // Body
            Text {
                Layout.fillWidth: true
                text: root.notification.body
                font.family: Utils.Theme.fontFamily
                font.pixelSize: Utils.Theme.fontSizeSmall
                color: Utils.Theme.subtext0
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: text !== ""
            }

            // Action buttons
            Row {
                Layout.fillWidth: true
                Layout.topMargin: Utils.Theme.spacingSmall
                spacing: Utils.Theme.spacingSmall
                visible: root.notification.actions.length > 0

                Repeater {
                    model: root.notification.actions

                    delegate: Rectangle {
                        required property NotificationAction modelData

                        visible: modelData.text.trim() !== ""
                        width: actionLabel.implicitWidth + Utils.Theme.spacingNormal * 2
                        height: visible ? Utils.Theme.pillHeight : 0
                        radius: Utils.Theme.roundingFull
                        color: actionMouse.containsMouse
                            ? Utils.Theme.hoverBg : Utils.Theme.surface1

                        Behavior on color {
                            ColorAnimation { duration: Utils.Theme.animDurationFast }
                        }

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            font.family: Utils.Theme.fontFamily
                            font.pixelSize: Utils.Theme.pillFontSize
                            color: Utils.Theme.text
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }

        // Close button
        Utils.MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "close"
            font.pixelSize: Utils.Theme.iconSizeSmall
            color: closeMouse.containsMouse ? Utils.Theme.text : Utils.Theme.subtext0

            Behavior on color {
                ColorAnimation { duration: Utils.Theme.animDurationFast }
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.dismissing)
                        Services.Notifications.animatedDismiss(root.notification);
                }
            }
        }
    }
}
