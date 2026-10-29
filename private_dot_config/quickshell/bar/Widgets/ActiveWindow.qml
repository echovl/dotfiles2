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
  // The width the title needs. The item eases to it when focus moves to another
  // window; a window retitling itself (fish names each command it runs) takes
  // its new width at once, so the bar isn't redrawn for every animation frame.
  readonly property real targetWidth: visible ? Math.min(maxWidth, Math.ceil(metrics.advanceWidth)) + 20 : 0
  // The window the current width belongs to. Set after a focus change has been
  // handled, so the width change that focus change brings still sees the old one.
  property var widthOwner: null

  visible: title !== ""
  implicitHeight: Theme.barHeight

  onTargetWidthChanged: {
    if (toplevel !== widthOwner) {
      widthEase.to = targetWidth
      widthEase.restart()
    } else {
      widthEase.stop()
      implicitWidth = targetWidth
    }
  }
  onToplevelChanged: Qt.callLater(() => { widthOwner = toplevel })
  Component.onCompleted: {
    implicitWidth = targetWidth
    widthOwner = toplevel
  }

  // Measured apart from the label, whose width follows this item's.
  TextMetrics {
    id: metrics
    font: label.font
    text: root.title
  }

  NumberAnimation {
    id: widthEase
    target: root
    property: "implicitWidth"
    duration: 180
    easing.type: Easing.OutCubic
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: 8
    anchors.rightMargin: 8
    clip: true

    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: (labelMetrics.descent - labelMetrics.ascent + labelMetrics.tightBoundingRect("0").height) / 2
      width: parent.width
      textFormat: Text.PlainText
      text: root.title
      color: root.color
      opacity: 0.85
      font.family: Theme.fontFamily
      font.pixelSize: Theme.body
      elide: Text.ElideRight
      renderType: Text.NativeRendering
    }

    // Centred on the digits' ink, like BarLabel, so the title sits on the
    // same line as the clock.
    FontMetrics {
      id: labelMetrics
      font: label.font
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
