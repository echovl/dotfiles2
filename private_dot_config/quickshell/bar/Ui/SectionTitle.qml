import QtQuick
import qs.Common

// The small bold label that opens a popup section ("OUTPUT", "PAIRED"), with
// an optional reading on the right ("50%").
Item {
  id: root

  property string text: ""
  property string value: ""
  property real valueOpacity: 1

  width: parent ? parent.width : implicitWidth
  implicitWidth: header.implicitWidth
  implicitHeight: Math.max(header.implicitHeight, valueText.implicitHeight)

  Text {
    id: header
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    textFormat: Text.PlainText
    text: root.text
    color: Theme.dim
    font.family: Theme.fontFamily
    font.pixelSize: Theme.caption
    font.bold: true
    // Nerd Font outlines reach past the ascent; keep their tops unclipped.
    topPadding: Math.ceil(Theme.caption * 0.15)
  }

  Text {
    id: valueText
    anchors.right: parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    visible: root.value !== ""
    textFormat: Text.PlainText
    text: root.value
    color: Theme.dim
    opacity: root.valueOpacity
    font.family: Theme.fontFamily
    font.pixelSize: Theme.caption
    font.bold: true
  }
}
