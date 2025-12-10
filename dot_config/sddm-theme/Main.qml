import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#1a1a1a"

    property string currentUser: userModel.lastUser
    property int currentSession: sessionModel.lastIndex

    // Time
    Text {
        id: timeLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.25
        color: "#ffffff"
        font.family: "sans-serif"
        font.pointSize: 72
        font.weight: Font.Light
        text: Qt.formatTime(new Date(), "h:mm")

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: timeLabel.text = Qt.formatTime(new Date(), "h:mm")
        }
    }

    // Date
    Text {
        id: dateLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: timeLabel.bottom
        anchors.topMargin: 8
        color: "#888888"
        font.family: "sans-serif"
        font.pointSize: 16
        text: Qt.formatDate(new Date(), "dddd, MMMM d")
    }

    // Login container
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        spacing: 16
        width: 280

        // Username field
        Rectangle {
            width: parent.width
            height: 48
            color: "#2a2a2a"
            radius: 8
            border.color: usernameInput.activeFocus ? "#555555" : "#333333"
            border.width: 1

            TextInput {
                id: usernameInput
                anchors.fill: parent
                anchors.margins: 12
                color: "#ffffff"
                font.family: "sans-serif"
                font.pointSize: 13
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                text: root.currentUser
                clip: true
                KeyNavigation.tab: passwordInput

                onAccepted: passwordInput.forceActiveFocus()
            }

            Text {
                anchors.centerIn: parent
                color: "#666666"
                font.family: "sans-serif"
                font.pointSize: 13
                text: "Username"
                visible: usernameInput.text === "" && !usernameInput.activeFocus
            }
        }

        // Password field
        Rectangle {
            width: parent.width
            height: 48
            color: "#2a2a2a"
            radius: 8
            border.color: passwordInput.activeFocus ? "#555555" : "#333333"
            border.width: 1

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.margins: 12
                color: "#ffffff"
                font.family: "sans-serif"
                font.pointSize: 13
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                clip: true
                KeyNavigation.backtab: usernameInput
                KeyNavigation.tab: usernameInput

                onAccepted: sddm.login(usernameInput.text, passwordInput.text, root.currentSession)
            }

            Text {
                anchors.centerIn: parent
                color: "#666666"
                font.family: "sans-serif"
                font.pointSize: 13
                text: "Password"
                visible: passwordInput.text === "" && !passwordInput.activeFocus
            }
        }

        // Login button
        Rectangle {
            width: parent.width
            height: 48
            radius: 8
            color: loginArea.pressed ? "#444444" : (loginArea.containsMouse ? "#3a3a3a" : "#333333")

            Text {
                anchors.centerIn: parent
                text: "Login"
                font.family: "sans-serif"
                font.pointSize: 13
                font.bold: true
                color: "#ffffff"
            }

            MouseArea {
                id: loginArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.login(usernameInput.text, passwordInput.text, root.currentSession)
            }
        }
    }

    // Error message
    Text {
        id: errorMessage
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.2
        color: "#e59191"
        font.family: "sans-serif"
        font.pointSize: 12
        text: ""
    }

    // Session name (bottom left)
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        color: "#666666"
        font.family: "sans-serif"
        font.pointSize: 11
        text: sessionModel.data(sessionModel.index(root.currentSession, 0), Qt.DisplayRole) || "Hyprland"
    }

    // Power buttons (bottom right)
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        Rectangle {
            width: 36
            height: 36
            radius: 6
            color: rebootArea.pressed ? "#444444" : (rebootArea.containsMouse ? "#333333" : "transparent")

            Text {
                anchors.centerIn: parent
                text: "⟳"
                font.pointSize: 16
                color: "#888888"
            }

            MouseArea {
                id: rebootArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.reboot()
            }
        }

        Rectangle {
            width: 36
            height: 36
            radius: 6
            color: powerArea.pressed ? "#444444" : (powerArea.containsMouse ? "#333333" : "transparent")

            Text {
                anchors.centerIn: parent
                text: "⏻"
                font.pointSize: 16
                color: "#888888"
            }

            MouseArea {
                id: powerArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.powerOff()
            }
        }
    }

    // Handle login failures
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = "Login failed"
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
    }

    Component.onCompleted: {
        if (usernameInput.text !== "") {
            passwordInput.forceActiveFocus()
        } else {
            usernameInput.forceActiveFocus()
        }
    }
}
