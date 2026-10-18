import QtQuick
import qs.Common

// Omarchy's toggle switch. Rounded only when Hyprland rounds windows.
Item {
  id: root

  property bool checked: false
  signal toggled()

  readonly property int trackHeight: 22
  readonly property int trackWidth: 42
  readonly property int knobSize: 16
  readonly property int knobInset: 3
  readonly property int pad: 6
  readonly property bool rounded: Theme.radius > 0

  implicitWidth: trackWidth + pad * 2
  implicitHeight: trackHeight + pad * 2

  Rectangle {
    anchors.fill: parent
    visible: mouse.containsMouse
    color: "transparent"
    radius: Theme.radius
    border.width: 1
    border.color: Theme.hoverBorder
  }

  Rectangle {
    id: track
    anchors.centerIn: parent
    width: root.trackWidth
    height: root.trackHeight
    radius: root.rounded ? height / 2 : 0
    color: root.checked ? Theme.selectedFill : Theme.normalFill
    border.width: root.checked ? 0 : 1
    border.color: Theme.normalBorder

    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
      width: root.knobSize
      height: root.knobSize
      radius: root.rounded ? height / 2 : 0
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? track.width - width - root.knobInset : root.knobInset
      color: root.checked ? Theme.foreground : Theme.fade(Theme.foreground, 1.25)

      Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 120 } }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
