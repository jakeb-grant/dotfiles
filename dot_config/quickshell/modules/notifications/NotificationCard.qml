import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.services as Services
import qs.utils as Utils

Rectangle {
    id: root

    required property Notification notification
    property bool historyMode: false

    readonly property bool isCritical: notification.urgency === NotificationUrgency.Critical

    // Relative timestamp for history mode
    readonly property string _relativeTime: {
        if (!historyMode) return "";
        const created = Services.Notifications._timestamps[notification.id];
        if (!created) return "";
        const delta = Math.floor((Date.now() - created) / 1000);
        if (delta < 60) return "now";
        if (delta < 3600) return Math.floor(delta / 60) + "m ago";
        if (delta < 86400) return Math.floor(delta / 3600) + "h ago";
        return Math.floor(delta / 86400) + "d ago";
    }

    // Refresh timestamp every 30s
    Timer {
        running: root.historyMode
        interval: 30000
        repeat: true
        onTriggered: root._relativeTimeChanged()
    }

    // Dismissal state — driven by service, survives Repeater recreation
    // In history mode, cards are never in dismissing state
    readonly property bool dismissing: !historyMode && Services.Notifications.isDismissing(notification)

    color: cardHover.hovered ? Utils.Theme.surface1 : Utils.Theme.surface0
    radius: Utils.Theme.roundingSmall

    Behavior on color {
        ColorAnimation { duration: Utils.Theme.animDurationFast }
    }
    implicitHeight: content.implicitHeight + Utils.Theme.spacingLarge * 2

    // Entrance: new cards start transparent+small; recreated cards start full.
    // Dismissing cards start invisible (exit animation already ran or will skip).
    readonly property bool _isNew: Services.Notifications.isNew(notification)

    opacity: dismissing ? 0 : _isNew ? 0 : 1
    scale: dismissing ? 0.85 : _isNew ? 0.85 : 1
    transformOrigin: Item.Right

    Component.onCompleted: {
        if (!dismissing) { opacity = 1; scale = 1 }
    }

    // Exit: fade out + scale down
    onDismissingChanged: {
        if (dismissing) { opacity = 0; scale = 0.85 }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.dismissing ? 200 : 300
            easing.type: root.dismissing ? Easing.InCubic : Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.dismissing ? 200 : 350
            easing.type: root.dismissing ? Easing.InCubic : Easing.OutBack
        }
    }

    // Finish removal after exit animation completes
    Timer {
        id: finishTimer
        running: root.dismissing
        interval: Utils.Theme.animDurationSmall + 20
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

    // Auto-dismiss timer (disabled in history/expanded mode)
    Timer {
        id: expireTimer
        interval: Services.Notifications.remainingTimeout(root.notification)
        running: !root.dismissing && !root.historyMode
        onTriggered: Services.Notifications.animatedRemove(root.notification)
    }

    // Remove if app closes the notification (not in history mode)
    Connections {
        target: root.notification
        enabled: !root.historyMode
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

            // App name + timestamp row
            RowLayout {
                Layout.fillWidth: true
                visible: root.notification.appName !== "" || root.historyMode
                spacing: Utils.Theme.spacingSmall

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

                Text {
                    visible: root.historyMode
                    text: root._relativeTime
                    font.family: Utils.Theme.fontFamily
                    font.pixelSize: Utils.Theme.fontSizeXSmall
                    color: Utils.Theme.overlay1
                }
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
                    if (root.historyMode)
                        Services.Notifications.dismissFromHistory(root.notification);
                    else if (!root.dismissing)
                        Services.Notifications.animatedDismiss(root.notification);
                }
            }
        }
    }
}
