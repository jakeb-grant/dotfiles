import QtQuick
import QtQuick.Layouts
import qs.modules.bar.popouts.components
import qs.services as Services
import qs.utils as Utils

PopoutColumn {
    id: root

    RowLayout {
        spacing: Utils.Theme.spacingNormal

        Utils.MaterialIcon {
            text: Services.Brightness.icon
            fill: 1
            font.pixelSize: Utils.Theme.headerIconSize
            color: {
                const t = Math.min(1, Services.Brightness.percent / 100);
                if (t <= 0.5) {
                    const s = t / 0.5;
                    return Qt.tint(Utils.Theme.lavender, Qt.rgba(
                        Utils.Theme.accent.r, Utils.Theme.accent.g, Utils.Theme.accent.b, s));
                }
                const s = (t - 0.5) / 0.5;
                return Qt.tint(Utils.Theme.accent, Qt.rgba(
                    Utils.Theme.yellow.r, Utils.Theme.yellow.g, Utils.Theme.yellow.b, s));
            }
        }

        Text {
            text: Services.Brightness.percent + "%"
            font.family: Utils.Theme.fontFamily
            font.pixelSize: Utils.Theme.popoutTitleSize
            font.bold: true
            color: Utils.Theme.text
            Layout.fillWidth: true
        }
    }

    FlowSlider {
        Layout.fillWidth: true
        value: Services.Brightness.brightness
        flowColors: [Utils.Theme.accent, Utils.Theme.yellow, Utils.Theme.peach]

        onPressStarted: Services.Brightness.beginUserInput()
        onMoved: (newValue) => {
            const pct = Math.round(newValue * 100);
            Services.Brightness.percent = pct;
            Services.Brightness.setBrightness(pct);
        }
        onReleased: Services.Brightness.endUserInput()
    }

    // Hint
    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "scroll or drag to adjust"
        font.family: Utils.Theme.fontFamily
        font.pixelSize: Utils.Theme.fontSizeSmall
        color: Utils.Theme.subtleText
    }
}
