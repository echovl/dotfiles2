import QtQuick
import qs.Common

// "Battery size      57Wh": a faded label with its value at the far end.
Item {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Theme.foreground

  width: parent ? parent.width : implicitWidth
  implicitWidth: labelText.implicitWidth + 8 + valueText.implicitWidth
  implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

  Text {
    id: labelText
    textFormat: Text.PlainText
    text: root.label
    color: Theme.foreground
    opacity: 0.6
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
  }

  Text {
    id: valueText
    anchors.right: parent.right
    textFormat: Text.PlainText
    text: root.value
    color: root.valueColor
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
  }
}
