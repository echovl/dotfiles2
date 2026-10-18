import QtQuick
import qs.Common
import qs.Ui

// Now playing, as Omarchy shows it: play state and "title · artist", cut off
// with an ellipsis when it doesn't fit. (It used to scroll, but a looping
// animation redraws the bar every frame and costs battery.) Click to play or
// pause, right-click for the popup, middle-click for the next track, scroll to skip.
Item {
  id: root

  property color color: Theme.foreground
  property bool open: false
  signal popupRequested()

  readonly property int maxLabelWidth: 180
  readonly property bool playing: !!Media.player && Media.player.isPlaying

  visible: Media.active
  implicitWidth: visible ? row.implicitWidth + 14 : 0
  implicitHeight: Theme.barHeight

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Text {
      id: glyph
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: root.playing ? Icons.pause : Icons.play
      color: root.playing ? root.color : Theme.fade(root.color, 1.5)
      font.family: Theme.fontFamily
      font.pixelSize: Theme.body

      Behavior on color { ColorAnimation { duration: 160 } }
    }

    Item {
      id: clipper
      anchors.verticalCenter: parent.verticalCenter
      width: Math.min(root.maxLabelWidth, label.implicitWidth)
      height: glyph.height

      Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        width: clipper.width
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
        color: root.color
        font.family: Theme.fontFamily
        font.pixelSize: Theme.body
      }
    }
  }

  OpenMark {
    open: root.open
    width: Math.max(10, Math.round(clipper.width * 0.55))
    x: Math.floor(row.x + clipper.x + (clipper.width - width) / 2)
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) root.popupRequested()
      else if (mouse.button === Qt.MiddleButton) Media.next()
      else Media.playPause()
    }
    onWheel: wheel => wheel.angleDelta.y > 0 ? Media.previous() : Media.next()
  }
}
