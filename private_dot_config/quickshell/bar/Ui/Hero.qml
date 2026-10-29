import QtQuick
import qs.Common

// A popup's header: big icon, bold title and a spaced-out uppercase subtitle,
// which can rotate through Omarchy's playful phrases. Children go on the right.
Item {
  id: root

  property string icon: ""
  property real iconOpacity: 1
  property string title: ""
  property string subtitle: ""
  property var phrases: []
  property real labelGap: 12
  default property alias trailing: trailingSlot.data

  property int phraseIndex: 0
  readonly property bool rotating: phrases.length > 0
  readonly property string shownSubtitle: rotating ? phrases[phraseIndex % phrases.length] : subtitle

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(iconSlot.implicitHeight, labels.implicitHeight, trailingSlot.height)

  // A fixed-width slot, so titles start at the same x in every card, with the
  // glyph scaled to one ink size whatever its natural width.
  Item {
    id: iconSlot
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 28
    implicitHeight: 28

    Glyph {
      anchors.centerIn: parent
      width: 28
      height: 28
      text: root.icon
      color: Theme.foreground
      opacity: root.iconOpacity
      fontSize: Theme.display
      size: 22
    }
  }

  Column {
    id: labels
    anchors.left: iconSlot.right
    anchors.leftMargin: 14
    anchors.right: trailingSlot.left
    anchors.rightMargin: trailingSlot.width > 0 ? root.labelGap : 0
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Text {
      width: parent.width
      textFormat: Text.PlainText
      text: root.title
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.title
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      id: subtitleText
      width: parent.width
      visible: text !== ""
      textFormat: Text.PlainText
      text: root.shownSubtitle.toUpperCase()
      color: Theme.dim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.caption
      font.bold: true
      font.letterSpacing: 1.2
      elide: Text.ElideRight
    }
  }

  Item {
    id: trailingSlot
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: childrenRect.width
    height: childrenRect.height
  }

  Timer {
    interval: 2800
    repeat: true
    running: root.rotating && root.visible
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap
    NumberAnimation { target: subtitleText; property: "opacity"; to: 0; duration: 180; easing.type: Easing.OutQuad }
    ScriptAction { script: root.phraseIndex = (root.phraseIndex + 1) % Math.max(1, root.phrases.length) }
    NumberAnimation { target: subtitleText; property: "opacity"; to: 1; duration: 260; easing.type: Easing.InQuad }
  }
}
