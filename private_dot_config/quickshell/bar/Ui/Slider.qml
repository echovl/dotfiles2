import QtQuick
import qs.Common

// Omarchy's panel slider: thin rounded track, filled to the value, and a knob
// that grows a little under the pointer.
Item {
  id: root

  property real value: 0
  property real minimum: 0
  property real maximum: 1
  property real step: 0.05
  property bool integer: false
  property bool dragging: false
  property real liveValue: value

  signal moved(real value)
  signal released(real value)
  signal rightClicked()

  onValueChanged: if (!dragging) liveValue = value

  readonly property real trackHeight: 4
  readonly property real knobSize: 14
  readonly property real progress: Math.max(0, Math.min(1, (liveValue - minimum) / Math.max(0.0001, maximum - minimum)))
  readonly property bool hot: mouse.containsMouse || dragging

  implicitWidth: 200
  implicitHeight: Math.max(22, knobSize + 6)

  Rectangle {
    id: track
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: root.trackHeight
    radius: height / 2
    color: Theme.selectedFill
  }

  Rectangle {
    anchors.left: track.left
    anchors.verticalCenter: track.verticalCenter
    height: track.height
    radius: track.radius
    width: track.width * root.progress
    color: Theme.foreground

    Behavior on width {
      enabled: !root.dragging
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
  }

  Rectangle {
    width: root.knobSize
    height: root.knobSize
    radius: width / 2
    anchors.verticalCenter: track.verticalCenter
    x: Math.max(0, Math.min(track.width - width, track.width * root.progress - width / 2))
    color: Theme.foreground
    border.width: 2
    border.color: Theme.background
    scale: root.hot ? 1.15 : 1

    Behavior on x {
      enabled: !root.dragging
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
      NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    function valueAt(x) {
      const fraction = Math.max(0, Math.min(1, x / track.width))
      const raw = root.minimum + fraction * (root.maximum - root.minimum)
      return root.integer ? Math.round(raw) : raw
    }

    onPressed: mouse => {
      if (mouse.button !== Qt.LeftButton) return
      root.dragging = true
      root.liveValue = valueAt(mouse.x)
      root.moved(root.liveValue)
    }
    onPositionChanged: mouse => {
      if (!root.dragging) return
      root.liveValue = valueAt(mouse.x)
      root.moved(root.liveValue)
    }
    onReleased: mouse => {
      if (mouse.button !== Qt.LeftButton) return
      root.dragging = false
      root.released(root.liveValue)
      root.liveValue = root.value
    }
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) root.rightClicked()
    }
    onWheel: wheel => {
      const delta = wheel.angleDelta.y > 0 ? root.step : -root.step
      let next = Math.max(root.minimum, Math.min(root.maximum, root.liveValue + delta))
      if (root.integer) next = Math.round(next)
      root.liveValue = next
      root.moved(next)
      root.released(next)
    }
  }
}
