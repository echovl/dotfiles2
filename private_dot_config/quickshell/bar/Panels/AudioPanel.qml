import QtQuick
import Quickshell.Services.Pipewire
import qs.Common
import qs.Ui

Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  readonly property bool outputMuted: Devices.muted
  readonly property bool inputMuted: Devices.sourceReady && Devices.source.audio.muted
  readonly property real inputVolume: Devices.sourceReady ? Devices.source.audio.volume : 0
  readonly property bool anyAudible: (Devices.sinkReady && !outputMuted) || (Devices.sourceReady && !inputMuted)
  readonly property var sinks: Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)
  readonly property var sources: Pipewire.nodes.values.filter(node => node.audio && !node.isSink && !node.isStream)

  PwObjectTracker {
    objects: root.sinks.concat(root.sources)
  }

  PwNodePeakMonitor {
    id: inputPeak
    node: Devices.source
    enabled: Devices.sourceReady
  }

  function levelName(volume, muted) {
    if (muted) return "Muted"
    const p = Math.round(volume * 100)
    if (p === 0) return "Silenced"
    if (p >= 100) return "Concert hall"
    if (p >= 85) return "Party mode"
    if (p >= 70) return "Cranked up"
    if (p >= 50) return "Steady groove"
    if (p >= 30) return "Easy listening"
    if (p >= 15) return "Murmur"
    return "Whisper"
  }

  function setAllMuted(muted) {
    if (Devices.sinkReady) Devices.sink.audio.muted = muted
    if (Devices.sourceReady) Devices.source.audio.muted = muted
  }

  function label(node) {
    return node.nickname || node.description || node.name || "Unknown"
  }

  function sinkGlyph(node) {
    if (Devices.isHeadphones(node)) return Icons.headphones
    const blob = Devices.nodeBlob(node)
    if (blob.includes("bluetooth")) return Icons.bluetooth
    if (blob.includes("hdmi") || blob.includes("display")) return Icons.monitor
    return Icons.speaker
  }

  function sourceGlyph(node) {
    const blob = Devices.nodeBlob(node)
    if (blob.includes("headset")) return Icons.headphones
    if (blob.includes("bluetooth")) return Icons.bluetooth
    if (blob.includes("webcam") || blob.includes("camera")) return Icons.webcam
    return Icons.mic
  }

  Hero {
    icon: Devices.audioIcon
    iconOpacity: root.outputMuted ? 0.5 : 1
    title: "Audio"
    subtitle: root.levelName(outputSlider.dragging ? outputSlider.liveValue : Devices.volume, root.outputMuted)

    Switch {
      checked: root.anyAudible
      onToggled: root.setAllMuted(root.anyAudible)
    }
  }

  Separator {}

  Column {
    width: parent.width
    spacing: 6

    SectionTitle {
      text: "OUTPUT"
      value: Math.round((outputSlider.dragging ? outputSlider.liveValue : Devices.volume) * 100) + "%"
      valueOpacity: root.outputMuted ? 0.5 : 1
    }

    RowSurface {
      width: parent.width
      height: outputSlider.implicitHeight + 8

      Slider {
        id: outputSlider
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        enabled: Devices.sinkReady
        opacity: root.outputMuted ? 0.5 : 1
        value: Devices.volume
        onMoved: value => Devices.sink.audio.volume = value
        onRightClicked: Devices.sink.audio.muted = !Devices.sink.audio.muted
      }
    }

    Repeater {
      model: root.sinks

      DeviceRow {
        current: !!Devices.sink && modelData.id === Devices.sink.id
        glyph: root.sinkGlyph(modelData)
        onClicked: Pipewire.preferredDefaultAudioSink = modelData
      }
    }
  }

  Separator {
    visible: root.sources.length > 0
  }

  Column {
    width: parent.width
    spacing: 6
    visible: root.sources.length > 0

    SectionTitle {
      text: "INPUT"
      value: Devices.sourceReady ? Math.round((inputSlider.dragging ? inputSlider.liveValue : root.inputVolume) * 100) + "%" : "–"
      valueOpacity: root.inputMuted ? 0.5 : 1
    }

    RowSurface {
      width: parent.width
      height: inputControls.implicitHeight + 8
      visible: Devices.sourceReady

      Column {
        id: inputControls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 5

        Slider {
          id: inputSlider
          width: parent.width
          opacity: root.inputMuted ? 0.5 : 1
          value: root.inputVolume
          onMoved: value => Devices.source.audio.volume = value
          onRightClicked: Devices.source.audio.muted = !Devices.source.audio.muted
        }

        // Live microphone level.
        Rectangle {
          width: parent.width
          height: 5
          color: Theme.alpha(Theme.foreground, 0.18)
          opacity: root.inputMuted ? 0.35 : 1

          Rectangle {
            height: parent.height
            width: parent.width * Math.max(0, Math.min(1, inputPeak.peak))
            color: Theme.foreground

            Behavior on width {
              NumberAnimation { duration: 70 }
            }
          }
        }
      }
    }

    Repeater {
      model: root.sources

      DeviceRow {
        current: !!Devices.source && modelData.id === Devices.source.id
        glyph: root.sourceGlyph(modelData)
        onClicked: Pipewire.preferredDefaultAudioSource = modelData
      }
    }
  }

  component DeviceRow: RowSurface {
    id: row

    required property var modelData
    property string glyph: ""
    signal clicked()

    width: root.width
    height: inner.implicitHeight + 12

    Row {
      id: inner
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 10

      Text {
        width: 22
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: row.glyph
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.title
      }

      Text {
        width: parent.width - 32
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.label(row.modelData)
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.body
        font.bold: row.current
        elide: Text.ElideRight
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: row.clicked()
    }
  }
}
