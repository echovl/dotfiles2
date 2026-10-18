import QtQuick
import qs.Common

// Omarchy's button: bordered by default, filled when it is the active choice.
Rectangle {
  id: root

  property string text: ""
  property string glyph: ""
  property bool active: false
  property bool bordered: true
  property real fontSize: Theme.bodySmall
  property real glyphSize: Theme.title
  property real horizontalPadding: 10
  property real verticalPadding: 8

  signal clicked()

  readonly property bool hot: mouse.containsMouse

  // From the content's natural sizes, not the row's: the label's width
  // depends on the button's, and the row's would make that a loop.
  readonly property real glyphRoom: glyph !== "" ? glyphText.implicitWidth + (text !== "" ? row.spacing : 0) : 0
  implicitWidth: glyphRoom + (text !== "" ? labelText.implicitWidth : 0) + horizontalPadding * 2 + 2
  implicitHeight: row.implicitHeight + verticalPadding * 2 + 2
  radius: Theme.radius
  color: mouse.pressed ? Theme.pressedFill : (hot ? Theme.hoverFill : (active ? Theme.selectedFill : "transparent"))
  border.width: hot || bordered ? 1 : 0
  border.color: hot ? Theme.hoverBorder : Theme.normalBorder

  Behavior on color { ColorAnimation { duration: 120 } }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 8

    Text {
      id: glyphText
      anchors.verticalCenter: parent.verticalCenter
      visible: root.glyph !== ""
      textFormat: Text.PlainText
      text: root.glyph
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: root.glyphSize
    }

    Text {
      id: labelText
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      // Elides when the button is narrower than its label.
      width: Math.min(implicitWidth, root.width - root.horizontalPadding * 2 - 2 - root.glyphRoom)
      textFormat: Text.PlainText
      text: root.text
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: root.fontSize
      elide: Text.ElideRight
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
