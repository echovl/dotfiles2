import QtQuick
import Quickshell.Wayland
import qs.Common

// The focused window's title, as Omarchy shows it. Click to focus the
// window, middle-click to close it.
Item {
  id: root

  property color color: Theme.foreground

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string title: toplevel ? (toplevel.title || toplevel.appId || "") : ""
  readonly property int maxWidth: 280

  visible: title !== ""
  implicitWidth: visible ? Math.min(maxWidth, Math.ceil(metrics.advanceWidth)) + 20 : 0
  implicitHeight: Theme.barHeight

  // Measured apart from the label, whose width follows this item's.
  TextMetrics {
    id: metrics
    font: label.font
    text: root.title
  }

  Behavior on implicitWidth {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    clip: true

    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      textFormat: Text.PlainText
      text: root.title
      color: root.color
      opacity: 0.85
      font.family: Theme.fontFamily
      font.pixelSize: Theme.body
      elide: Text.ElideRight
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (!root.toplevel) return
      if (mouse.button === Qt.MiddleButton) root.toplevel.close()
      else root.toplevel.activate()
    }
  }
}
