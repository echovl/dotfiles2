import QtQuick
import QtQuick.Shapes
import qs.Common
import qs.Ui

// Now playing: the round album cover in a ring that fills as the track plays,
// then "title · artist", or just the title when both don't fit in 180px, so it
// never ends in "· …". All of it fades while paused. Click for the popup
// card, right-click to play or pause, middle-click for the next track, scroll
// to skip.
Item {
  id: root

  property color color: Theme.foreground
  property bool open: false
  signal popupRequested()

  readonly property int maxLabelWidth: 180
  readonly property var player: Media.player
  readonly property bool playing: !!player && player.isPlaying
  readonly property string artUrl: player && player.trackArtUrl ? player.trackArtUrl : ""
  readonly property string fullText: Media.title + (Media.artist ? "  ·  " + Media.artist : "")

  visible: Media.active
  implicitWidth: visible ? row.implicitWidth + 14 : 0
  implicitHeight: Theme.barHeight

  // The ring moves in steps of one device pixel along its length, and the bar
  // is redrawn only when it takes one: about every 2s on a 4-minute track,
  // never more than once a second, and not at all while paused. Reading the
  // position is free (Quickshell extrapolates it from the player's last
  // report), and seeks and track changes arrive as signals.
  readonly property real ringRadius: 9.25
  readonly property bool timed: !!player && player.positionSupported && player.lengthSupported && player.length > 0
  readonly property int steps: Math.max(60, Math.round(2 * Math.PI * ringRadius * Screen.devicePixelRatio))
  property int step: 0

  function measure() {
    step = timed ? Math.round(Math.max(0, Math.min(1, player.position / player.length)) * steps) : 0
  }

  onPlayerChanged: measure()
  onTimedChanged: measure()

  Connections {
    target: root.player
    function onPositionChanged() { root.measure() }
    function onPostTrackChanged() { root.measure() }
  }

  Timer {
    running: root.visible && root.playing && root.timed
    repeat: true
    triggeredOnStart: true
    interval: root.timed ? Math.max(1000, root.player.length * 1000 / root.steps) : 1000
    onTriggered: root.measure()
  }

  // Centres the label on the digits' ink, like BarLabel, so it sits on the
  // same line as the clock.
  FontMetrics {
    id: labelMetrics
    font: label.font
  }

  TextMetrics {
    id: fullMetrics
    font: label.font
    text: root.fullText
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6
    opacity: root.playing ? 1 : 0.5

    Behavior on opacity { NumberAnimation { duration: 160 } }

    Item {
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20

      Cover {
        anchors.centerIn: parent
        width: 14
        height: 14
        radius: 7
        color: root.color
        source: root.artUrl
      }

      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
          strokeColor: Theme.alpha(root.color, 0.2)
          strokeWidth: 1.5
          fillColor: "transparent"
          PathAngleArc { centerX: 10; centerY: 10; radiusX: root.ringRadius; radiusY: root.ringRadius; sweepAngle: 360 }
        }

        ShapePath {
          strokeColor: root.step > 0 ? root.color : "transparent"
          strokeWidth: 1.5
          fillColor: "transparent"
          capStyle: ShapePath.RoundCap
          PathAngleArc { centerX: 10; centerY: 10; radiusX: root.ringRadius; radiusY: root.ringRadius; startAngle: -90; sweepAngle: 360 * root.step / root.steps }
        }
      }
    }

    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: (labelMetrics.descent - labelMetrics.ascent + labelMetrics.tightBoundingRect("0").height) / 2
      width: Math.min(root.maxLabelWidth, implicitWidth)
      elide: Text.ElideRight
      textFormat: Text.PlainText
      text: fullMetrics.width <= root.maxLabelWidth ? root.fullText : Media.title
      color: root.color
      font.family: Theme.fontFamily
      font.pixelSize: Theme.body
      renderType: Text.NativeRendering
    }
  }

  OpenMark {
    open: root.open
    width: Math.max(10, Math.round(label.width * 0.55))
    x: Math.floor(row.x + label.x + (label.width - width) / 2)
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) Media.playPause()
      else if (mouse.button === Qt.MiddleButton) Media.next()
      else root.popupRequested()
    }
    onWheel: wheel => wheel.angleDelta.y > 0 ? Media.previous() : Media.next()
  }
}
