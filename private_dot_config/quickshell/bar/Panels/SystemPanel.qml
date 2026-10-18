import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Ui

// CPU, memory and disk use, sampled while the popup is open.
Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  property real cpu: -1
  property real lastTotal: 0
  property real lastIdle: 0
  property real memTotal: 0
  property real memUsed: 0
  property real diskTotal: 0
  property real diskUsed: 0
  property real temperature: -1
  property real load: 0
  property real uptime: 0

  function gigabytes(bytes) {
    return (bytes / (1024 * 1024 * 1024)).toFixed(1)
  }

  function duration(seconds) {
    const days = Math.floor(seconds / 86400)
    const hours = Math.floor(seconds % 86400 / 3600)
    const minutes = Math.floor(seconds % 3600 / 60)
    if (days > 0) return `${days}d ${hours}h`
    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`
  }

  Timer {
    interval: 1500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!sampler.running) sampler.running = true
  }

  // A second sample soon after opening, so CPU use shows without waiting.
  Timer {
    interval: 400
    running: true
    onTriggered: if (!sampler.running) sampler.running = true
  }

  Process {
    id: sampler
    command: [Quickshell.shellPath("scripts/stats.sh")]
    stdout: StdioCollector {
      onStreamFinished: {
        const v = text.trim().split(" ").map(Number)
        if (v.length !== 9) return
        if (root.lastTotal > 0 && v[0] > root.lastTotal)
          root.cpu = 100 * (1 - (v[1] - root.lastIdle) / (v[0] - root.lastTotal))
        root.lastTotal = v[0]
        root.lastIdle = v[1]
        root.memTotal = v[2] * 1024
        root.memUsed = (v[2] - v[3]) * 1024
        root.diskUsed = v[4]
        root.diskTotal = v[5]
        root.temperature = v[6] >= 0 ? v[6] / 1000 : -1
        root.load = v[7]
        root.uptime = v[8]
      }
    }
  }

  Hero {
    icon: Icons.chip
    title: "System"
    subtitle: root.uptime > 0 ? "Up " + root.duration(root.uptime) : ""
    labelGap: 10

    Text {
      textFormat: Text.PlainText
      text: root.cpu >= 0 ? Math.round(root.cpu) + "%" : "—"
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.displayLarge
      font.bold: true
    }
  }

  Usage {
    title: "CPU"
    value: root.cpu >= 0 ? Math.round(root.cpu) + "%" : ""
    fraction: Math.max(0, root.cpu) / 100
  }

  Row {
    width: parent.width
    spacing: 20

    InfoPair {
      width: (parent.width - parent.spacing) / 2
      label: "Temperature"
      value: root.temperature >= 0 ? Math.round(root.temperature) + "°C" : "—"
    }

    InfoPair {
      width: (parent.width - parent.spacing) / 2
      label: Devices.discharging ? "Power draw" : "Load"
      value: Devices.discharging && Devices.battery
        ? Math.abs(Devices.battery.changeRate).toFixed(1) + "W"
        : root.load.toFixed(2)
    }
  }

  Separator {}

  Usage {
    title: "MEMORY"
    value: root.memTotal > 0 ? root.gigabytes(root.memUsed) + " / " + root.gigabytes(root.memTotal) + " GB" : ""
    fraction: root.memTotal > 0 ? root.memUsed / root.memTotal : 0
  }

  Usage {
    title: "DISK"
    value: root.diskTotal > 0 ? root.gigabytes(root.diskUsed) + " / " + root.gigabytes(root.diskTotal) + " GB" : ""
    fraction: root.diskTotal > 0 ? root.diskUsed / root.diskTotal : 0
  }

  // A section title with its reading, over a bar like the battery's.
  component Usage: Column {
    property string title: ""
    property string value: ""
    property real fraction: 0

    width: parent.width
    spacing: 8

    SectionTitle {
      text: parent.title
      value: parent.value
    }

    Item {
      width: parent.width
      height: 8

      Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.divider
      }

      Rectangle {
        height: parent.height
        radius: height / 2
        width: Math.max(height, parent.width * Math.min(1, parent.parent.fraction))
        color: Theme.foreground

        Behavior on width {
          NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }
      }
    }
  }
}
