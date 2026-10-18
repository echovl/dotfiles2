import QtQuick
import qs.Common

// One icon on the bar, in a 27px slot, with an optional label before it (the
// battery percentage), which doubles the slot as Omarchy's does.
Item {
  id: root

  property string glyph: ""
  property string label: ""
  property color color: Theme.foreground
  property bool open: false
  // Omarchy's status widgets, like the weather, sit in a narrower slot.
  property real slot: Theme.iconSlot

  signal clicked(int button)
  signal wheel(int delta)

  implicitWidth: label !== "" ? slot * 2 : slot
  implicitHeight: Theme.barHeight

  Row {
    id: content
    anchors.centerIn: parent
    spacing: 4

    Text {
      id: labelText
      anchors.verticalCenter: parent.verticalCenter
      // Center the digits' ink, not the font box.
      anchors.verticalCenterOffset: (metrics.descent - metrics.ascent + metrics.tightBoundingRect("0").height) / 2
      visible: root.label !== ""
      textFormat: Text.PlainText
      text: root.label
      color: root.color
      font.family: Theme.fontFamily
      font.pixelSize: Theme.iconFont
      renderType: Text.NativeRendering
    }

    Glyph {
      id: glyph
      width: Theme.iconCanvas
      height: Theme.iconCanvas
      anchors.verticalCenter: parent.verticalCenter
      text: root.glyph
      color: root.color
    }
  }

  FontMetrics {
    id: metrics
    font: labelText.font
  }

  // Under the icon, not the label.
  OpenMark {
    open: root.open
    width: Math.max(10, Math.round(root.slot * 0.55))
    x: Math.floor(content.x + glyph.x + glyph.width / 2 - width / 2)
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => root.clicked(mouse.button)
    onWheel: wheel => root.wheel(wheel.angleDelta.y)
  }
}
