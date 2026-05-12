pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import qs.services as Services
import qs.utils as Utils

Rectangle {
    id: band

    property var entries: []
    property int selectedIndex: -1
    property bool isActiveBand: false

    signal activateRequested()

    readonly property int bandHeight: 120
    readonly property int cellWidth: 200
    readonly property int slant: 30

    height: bandHeight
    radius: Utils.Theme.listItemRadius
    color: Utils.Theme.surface0
    clip: true
    visible: entries.length > 0

    function ensureVisible(idx: int): void {
        flick.ensureVisible(idx);
    }

    Flickable {
        id: flick
        anchors.fill: parent
        flickableDirection: Flickable.HorizontalFlick
        contentWidth: {
            const count = band.entries.length;
            return count > 0 ? count * (band.cellWidth - band.slant) + band.slant : 0;
        }
        boundsBehavior: Flickable.StopAtBounds

        Behavior on contentX {
            id: scrollBehavior
            enabled: true
            NumberAnimation {
                duration: Utils.Theme.animDurationFast
                easing.type: Easing.OutCubic
            }
        }

        function ensureVisible(idx: int): void {
            const step = band.cellWidth - band.slant;
            const itemX = idx * step;
            const itemRight = itemX + band.cellWidth;
            if (itemX < contentX)
                contentX = itemX;
            else if (itemRight > contentX + width)
                contentX = itemRight - width;
        }

        function resetScroll(): void {
            scrollBehavior.enabled = false;
            contentX = 0;
            scrollBehavior.enabled = true;
        }

        Item {
            width: flick.contentWidth
            height: band.bandHeight

            Repeater {
                model: band.entries.length

                delegate: Item {
                    id: cell

                    required property int index

                    readonly property var entry: band.entries[index]
                    readonly property string entryName: entry ? entry.name : ""
                    readonly property bool entryIsSet: entry ? entry.isSet : false

                    readonly property bool isFirst: index === 0
                    readonly property bool isSelected: band.isActiveBand && index === band.selectedIndex
                    readonly property bool isCurrent: Services.Wallpaper.currentWallpaper === entryName

                    x: index * (band.cellWidth - band.slant)
                    width: band.cellWidth
                    height: band.bandHeight
                    z: index

                    Item {
                        id: cellMask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true

                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                fillColor: "white"
                                strokeWidth: -1
                                startX: cell.isFirst ? 0 : band.slant
                                startY: 0
                                PathLine { x: band.cellWidth; y: 0 }
                                PathLine { x: band.cellWidth; y: band.bandHeight }
                                PathLine { x: 0; y: band.bandHeight }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: cellMask
                        }

                        Image {
                            anchors.fill: parent
                            source: cell.entry ? "file://" + Services.Wallpaper.previewPath(cell.entry) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(480, 270)
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Utils.Theme.hoverBg
                            opacity: cellMouse.containsMouse || cell.isSelected ? 0.4 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: Utils.Theme.animDurationFast; easing.type: Easing.OutCubic }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 3
                            color: Utils.Theme.accent
                            visible: cell.isCurrent
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: nameLabel.implicitHeight + Utils.Theme.spacingSmall * 2
                            color: Utils.Theme.crust
                            opacity: 0.85
                            visible: (cellMouse.containsMouse || cell.isSelected) && !cell.isCurrent

                            Text {
                                id: nameLabel
                                anchors.centerIn: parent
                                text: cell.entryIsSet ? cell.entryName : cell.entryName.replace(/\.[^.]+$/, "")
                                font.family: Utils.Theme.fontFamily
                                font.pixelSize: Utils.Theme.fontSizeXSmall
                                color: Utils.Theme.text
                                elide: Text.ElideMiddle
                                width: parent.width - Utils.Theme.spacingSmall * 2
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Shape {
                        anchors.fill: parent
                        visible: !cell.isFirst
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Utils.Theme.crust
                            strokeWidth: 2
                            startX: band.slant
                            startY: 0
                            PathLine { x: 0; y: band.bandHeight }
                        }
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cell.entry)
                                Services.Wallpaper.applyEntry(cell.entry);
                        }
                        onContainsMouseChanged: {
                            if (containsMouse) {
                                band.activateRequested();
                                band.selectedIndex = cell.index;
                            }
                        }
                    }
                }
            }
        }
    }

    ScrollBar {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        orientation: Qt.Horizontal
        size: flick.width / Math.max(1, flick.contentWidth)
        position: flick.contentX / Math.max(1, flick.contentWidth)
        visible: flick.contentWidth > flick.width
        contentItem: Rectangle {
            radius: 2
            color: Utils.Theme.overlay0
            opacity: 0.6
        }
    }
}
