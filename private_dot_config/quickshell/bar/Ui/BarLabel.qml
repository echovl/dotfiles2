import QtQuick
import qs.Common

// Text on the bar, centered on its digits' ink rather than the font box so
// numbers sit in the middle of the bar.
Item {
  id: root

  property string text: ""
  property color color: Theme.foreground
  property real margin: 8.5
  readonly property real textWidth: label.implicitWidth

  implicitWidth: Math.max(12, label.implicitWidth + margin * 2)
  implicitHeight: Theme.barHeight

  Text {
    id: label
    anchors.centerIn: parent
    anchors.verticalCenterOffset: (metrics.descent - metrics.ascent + metrics.tightBoundingRect("0").height) / 2
    textFormat: Text.PlainText
    text: root.text
    color: root.color
    font.family: Theme.fontFamily
    font.pixelSize: Theme.body
    renderType: Text.NativeRendering
  }

  FontMetrics {
    id: metrics
    font: label.font
  }
}
