import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services as Services
import qs.utils as Utils

ColumnLayout {
    id: root

    spacing: Utils.Theme.spacingNormal

    // Width spacer
    Item {
        implicitWidth: Utils.Theme.popoutWidth
        implicitHeight: 0
    }

    // Distro + kernel
    Text {
        Layout.alignment: Qt.AlignLeft
        text: "Arch Linux"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.popoutTitleSize
        font.bold: true
        color: Utils.Theme.text
    }

    Text {
        Layout.alignment: Qt.AlignLeft
        text: "kernel " + kernelProc.output
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.subtext0

        Process {
            id: kernelProc
            property string output: ""
            command: ["uname", "-r"]
            running: true

            stdout: SplitParser {
                onRead: data => kernelProc.output = data.trim()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Utils.Theme.separator
    }

    // Uptime
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "schedule"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: uptimeProc.output
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text

            Process {
                id: uptimeProc
                property string output: ""
                command: ["sh", "-c", "uptime -p | sed 's/up //'"]
                running: true

                stdout: SplitParser {
                    onRead: data => uptimeProc.output = data.trim()
                }
            }
        }
    }

    // Host
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "computer"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: hostnameProc.output
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text

            Process {
                id: hostnameProc
                property string output: ""
                command: ["cat", "/etc/hostname"]
                running: true

                stdout: SplitParser {
                    onRead: data => hostnameProc.output = data.trim()
                }
            }
        }
    }

    // Shell
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "terminal"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: shellProc.output
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text

            Process {
                id: shellProc
                property string output: ""
                command: ["sh", "-c", "basename $SHELL"]
                running: true

                stdout: SplitParser {
                    onRead: data => shellProc.output = data.trim()
                }
            }
        }
    }

    // Packages
    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: "inventory_2"
            font.pixelSize: Utils.Theme.iconSize
            color: Utils.Theme.subtext0
        }

        Text {
            text: nativeProc.output + " native, " + aurProc.output + " AUR"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.fontSizeSmall
            color: Utils.Theme.text

            Process {
                id: nativeProc
                property string output: ""
                command: ["sh", "-c", "pacman -Qn | wc -l"]
                running: true

                stdout: SplitParser {
                    onRead: data => nativeProc.output = data.trim()
                }
            }

            Process {
                id: aurProc
                property string output: ""
                command: ["sh", "-c", "pacman -Qm | wc -l"]
                running: true

                stdout: SplitParser {
                    onRead: data => aurProc.output = data.trim()
                }
            }
        }
    }
}
