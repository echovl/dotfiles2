import QtQuick
import qs.Common
import qs.Ui

Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  readonly property real shownPercent: slider.dragging ? slider.liveValue : Devices.brightnessPercent

  function levelName(percent) {
    const p = Math.round(percent)
    if (p >= 95) return "Sun blast"
    if (p >= 80) return "Solar flare"
    if (p >= 65) return "Golden hour"
    if (p >= 45) return "Even day"
    if (p >= 30) return "Soft glow"
    if (p >= 20) return "Lamp light"
    if (p >= 10) return "Candlelit"
    return "Night owl"
  }

  // Follow changes made elsewhere, such as the brightness keys.
  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: Devices.refreshBrightness()
  }

  Hero {
    icon: Icons.monitor
    title: "Display"
    subtitle: Devices.brightnessAvailable ? root.levelName(root.shownPercent) : "Fixed brightness"
  }

  Separator {
    visible: Devices.brightnessAvailable
  }

  Column {
    width: parent.width
    spacing: 6
    visible: Devices.brightnessAvailable

    SectionTitle {
      text: "BRIGHTNESS"
      value: Math.round(root.shownPercent) + "%"
    }

    RowSurface {
      width: parent.width
      height: slider.implicitHeight + 8

      Slider {
        id: slider
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        minimum: 1
        maximum: 100
        step: 1
        integer: true
        value: Devices.brightnessPercent
        onMoved: value => Devices.setBrightness(value)
      }
    }
  }
}
