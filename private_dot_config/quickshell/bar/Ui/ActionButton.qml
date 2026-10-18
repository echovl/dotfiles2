import QtQuick
import qs.Common

// A small square icon button (month arrows, forget a device).
Rectangle {
  id: root

  property string glyph: ""
  property color foreground: Theme.foreground
  property color hoverColor: foreground
  property real fontSize: Theme.title

  signal clicked()

  implicitWidth: 23
  implicitHeight: 23
  radius: Theme.radius
  color: mouse.containsMouse ? Theme.alpha(hoverColor, 0.08) : "transparent"

  Behavior on color { ColorAnimation { duration: 60 } }

  Text {
    x: Math.round((root.width - width) / 2)
    y: Math.round((root.height - height) / 2)
    textFormat: Text.PlainText
    text: root.glyph
    color: !root.enabled ? Theme.fade(root.foreground, 2) : (mouse.containsMouse ? root.hoverColor : root.foreground)
    font.family: Theme.fontFamily
    font.pixelSize: root.fontSize
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
