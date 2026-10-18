import QtQuick
import qs.Common
import qs.Ui

// Omarchy's media popup: art, track, transport buttons and, with several
// players open, a list to pick one. Adds a seekable progress bar.
Column {
  id: root

  width: parent ? parent.width : 288
  spacing: 10

  readonly property var player: Media.player
  readonly property bool hasLength: !!player && player.lengthSupported && player.length > 0

  function time(seconds) {
    const s = Math.max(0, Math.floor(seconds))
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
  }

  // Players don't report position continuously; ask while playing.
  Timer {
    interval: 1000
    running: !!root.player && root.player.isPlaying
    repeat: true
    triggeredOnStart: true
    onTriggered: root.player.positionChanged()
  }

  Row {
    width: parent.width
    spacing: 10

    Rectangle {
      width: 64
      height: 64
      radius: 4
      color: Theme.normalFill
      border.width: 1
      border.color: Theme.normalBorder
      clip: true

      Image {
        id: art
        anchors.fill: parent
        anchors.margins: 2
        source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
        sourceSize: Qt.size(128, 128)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
      }

      Text {
        anchors.centerIn: parent
        visible: !art.visible
        textFormat: Text.PlainText
        text: Icons.music
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.displayLarge
      }
    }

    Column {
      width: parent.width - 74
      spacing: 4

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: Media.title || "Nothing playing"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.subtitle
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: text !== ""
        textFormat: Text.PlainText
        text: Media.artist
        color: Theme.fade(Theme.foreground, 1.3)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.bodySmall
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: text !== ""
        textFormat: Text.PlainText
        text: root.player && root.player.trackAlbum ? root.player.trackAlbum : ""
        color: Theme.fade(Theme.foreground, 1.6)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.caption
        elide: Text.ElideRight
      }
    }
  }

  Column {
    width: parent.width
    visible: root.hasLength
    spacing: 0

    Slider {
      id: progress
      width: parent.width
      minimum: 0
      maximum: root.hasLength ? root.player.length : 1
      step: 5
      enabled: !!root.player && root.player.canSeek
      value: root.player ? root.player.position : 0
      onReleased: value => root.player.seek(value - root.player.position)
    }

    Item {
      width: parent.width
      height: elapsed.implicitHeight

      Text {
        id: elapsed
        textFormat: Text.PlainText
        text: root.time(progress.dragging ? progress.liveValue : progress.value)
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.caption
      }

      Text {
        anchors.right: parent.right
        textFormat: Text.PlainText
        text: root.hasLength ? root.time(root.player.length) : ""
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.caption
      }
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 6

    PillButton {
      bordered: false
      verticalPadding: 6
      glyph: Icons.skipPrevious
      enabled: !!root.player && root.player.canGoPrevious
      opacity: enabled ? 1 : 0.4
      onClicked: Media.previous()
    }

    PillButton {
      bordered: false
      horizontalPadding: 14
      verticalPadding: 6
      glyphSize: 18
      glyph: root.player && root.player.isPlaying ? Icons.pause : Icons.play
      enabled: !!root.player && root.player.canTogglePlaying
      opacity: enabled ? 1 : 0.4
      onClicked: Media.playPause()
    }

    PillButton {
      bordered: false
      verticalPadding: 6
      glyph: Icons.skipNext
      enabled: !!root.player && root.player.canGoNext
      opacity: enabled ? 1 : 0.4
      onClicked: Media.next()
    }
  }

  Separator {
    visible: Media.players.length > 1
  }

  Column {
    width: parent.width
    visible: Media.players.length > 1
    spacing: 4

    Repeater {
      model: Media.players

      RowSurface {
        id: source

        required property var modelData

        width: parent.width
        height: sourceRow.implicitHeight + 10
        current: modelData === root.player

        Row {
          id: sourceRow
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Text {
            width: 18
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: source.modelData.isPlaying ? Icons.pause : Icons.play
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.body
          }

          Column {
            width: parent.width - 26
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: source.modelData.trackTitle || source.modelData.identity
              color: Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.bodySmall
              font.bold: source.current
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: source.modelData.trackArtist || source.modelData.identity
              color: Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.caption
              elide: Text.ElideRight
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Media.choose(source.modelData)
        }
      }
    }
  }
}
