import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.Common
import qs.Ui

// Scans for Wi-Fi networks and samples the connection while open.
Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  readonly property var wifi: Devices.wifiDevice
  readonly property string iface: Devices.networkInterface
  readonly property var networks: Devices.wifiNetworks.filter(network => network.name !== "")
  readonly property var known: networks.filter(network => network.known).sort(bySignal)
  readonly property var others: networks.filter(network => !network.known).sort(bySignal)

  // The network asking for a passphrase, and the last one that failed.
  property string passwordFor: ""
  property string failedName: ""
  property string failReason: ""

  function bySignal(a, b) {
    return (b.connected - a.connected) || (b.signalStrength - a.signalStrength)
  }

  function secured(network) {
    return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe
      && network.security !== WifiSecurityType.Unknown
  }

  Component.onCompleted: if (wifi) wifi.scannerEnabled = true
  Component.onDestruction: if (wifi) wifi.scannerEnabled = false

  // ---------------------------------------------------------------- stats

  property real rxBytes: -1
  property real txBytes: -1
  property real rxRate: 0
  property real txRate: 0
  property real sampledAt: 0
  property string address: ""
  property string gateway: ""
  property var pings: []

  readonly property var answered: pings.filter(ms => ms >= 0)
  readonly property int packetLoss: pings.length > 0 ? Math.round((pings.length - answered.length) * 100 / pings.length) : 0
  readonly property string pingText: {
    if (pings.length === 0) return "--"
    const last = pings[pings.length - 1]
    if (last < 0) return "Timeout"
    const average = answered.reduce((sum, ms) => sum + ms, 0) / answered.length
    return average.toFixed(average > 0 && average < 10 ? 1 : 0) + " ms"
  }

  function bytes(n) {
    if (n < 0) return "--"
    if (n < 1024) return Math.round(n) + " B"
    if (n < 1024 * 1024) return (n / 1024).toFixed(1) + " KB"
    if (n < 1024 * 1024 * 1024) return (n / (1024 * 1024)).toFixed(1) + " MB"
    return (n / (1024 * 1024 * 1024)).toFixed(2) + " GB"
  }

  function sample() {
    if (iface === "") return
    if (!statsProc.running) {
      statsProc.command = [Quickshell.shellPath("scripts/net-stats.sh"), iface]
      statsProc.running = true
    }
    if (!pingProc.running) pingProc.running = true
  }

  onIfaceChanged: {
    rxBytes = -1
    txBytes = -1
    pings = []
    sample()
  }

  Timer {
    interval: 1500
    running: root.iface !== ""
    repeat: true
    triggeredOnStart: true
    onTriggered: root.sample()
  }

  // A second sample soon after opening, so the rates show without waiting.
  Timer {
    interval: 500
    running: root.iface !== ""
    onTriggered: root.sample()
  }

  Process {
    id: statsProc
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(" ")
        if (parts.length !== 4) return
        const now = Date.now()
        const rx = Number(parts[0])
        const tx = Number(parts[1])
        if (root.rxBytes >= 0 && now > root.sampledAt) {
          const seconds = (now - root.sampledAt) / 1000
          root.rxRate = Math.max(0, (rx - root.rxBytes) / seconds)
          root.txRate = Math.max(0, (tx - root.txBytes) / seconds)
        }
        root.rxBytes = rx
        root.txBytes = tx
        root.sampledAt = now
        root.address = parts[2] === "-" ? "" : parts[2]
        root.gateway = parts[3] === "-" ? "" : parts[3]
      }
    }
  }

  // One probe to 1.1.1.1 per sample, kept over the last five, as Omarchy does.
  Process {
    id: pingProc
    command: ["ping", "-n", "-c", "1", "-W", "1", "1.1.1.1"]
    environment: ({ LC_ALL: "C" })
    stdout: StdioCollector {
      onStreamFinished: {
        const match = text.match(/time[=<]([\d.]+)/)
        root.pings = root.pings.concat([match ? Number(match[1]) : -1]).slice(-5)
      }
    }
  }

  // ----------------------------------------------------------------- view

  Hero {
    icon: Devices.networkIcon
    title: Devices.networkKind === "wifi" ? Devices.wifiNetwork.name : (Devices.networkKind === "ethernet" ? "Ethernet" : "Disconnected")
    subtitle: "Not connected"
    phrases: Devices.networkKind !== "disconnected" ? ["Wiring bits", "Handling packets", "Sorting frames", "Hauling bytes",
      "Routing crumbs", "Counting collisions", "Bending light"] : []

    Switch {
      visible: !!root.wifi
      checked: Networking.wifiEnabled
      onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
    }
  }

  GridLayout {
    width: parent.width
    visible: root.iface !== ""
    columns: 4
    columnSpacing: 20
    rowSpacing: 4

    InfoLabel { text: "Ping" }
    InfoValue { text: root.pingText; color: root.packetLoss > 0 ? Theme.urgent : Theme.foreground }
    InfoLabel { text: "Packet Loss" }
    InfoValue { text: root.pings.length > 0 ? root.packetLoss + "%" : "--"; color: root.packetLoss > 0 ? Theme.urgent : Theme.foreground }
    InfoLabel { text: "Receiving" }
    InfoValue { text: root.rxBytes >= 0 ? root.bytes(root.rxRate) + "/s" : "--" }
    InfoLabel { text: "Sending" }
    InfoValue { text: root.txBytes >= 0 ? root.bytes(root.txRate) + "/s" : "--" }
    InfoLabel { text: "Downloaded" }
    InfoValue { text: root.bytes(root.rxBytes) }
    InfoLabel { text: "Uploaded" }
    InfoValue { text: root.bytes(root.txBytes) }
    InfoLabel { text: "IP Address" }
    InfoValue { text: root.address || "--" }
    InfoLabel { text: "Gateway" }
    InfoValue { text: root.gateway || "--" }
  }

  Separator {
    visible: !!root.wifi && Networking.wifiEnabled
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, 400)
    visible: root.networks.length > 0 && Networking.wifiEnabled
    contentHeight: lists.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: lists
      width: parent.width
      spacing: 10

      SectionTitle {
        visible: root.known.length > 0
        text: "KNOWN NETWORKS"
      }

      Repeater {
        model: root.known
        NetworkRow {}
      }

      SectionTitle {
        visible: root.others.length > 0
        text: "OTHER NETWORKS"
      }

      Repeater {
        model: root.others
        NetworkRow {}
      }
    }
  }

  Text {
    width: parent.width
    visible: !!root.wifi && Networking.wifiEnabled && root.networks.length === 0
    textFormat: Text.PlainText
    text: "SCANNING WI-FI…"
    color: Theme.dim
    font.family: Theme.fontFamily
    font.pixelSize: Theme.caption
    font.bold: true
  }

  component InfoLabel: Text {
    textFormat: Text.PlainText
    color: Theme.foreground
    opacity: 0.6
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
  }

  component InfoValue: Text {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignRight
    textFormat: Text.PlainText
    color: Theme.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
  }

  component NetworkRow: RowSurface {
    id: row

    required property var modelData
    readonly property var network: modelData
    readonly property bool needsPassword: root.secured(network)
    readonly property bool passwordOpen: root.passwordFor === network.name
    readonly property bool failed: root.failedName === network.name
    readonly property bool forgetShown: network.known && (!needsPassword || lockHover.hovered)
    readonly property string status: {
      if (passwordOpen) return ""
      if (network.stateChanging) return network.connected ? "Disconnecting…" : "Connecting…"
      if (failed) return root.failReason
      if (network.connected) return "Connected"
      return ""
    }
    readonly property color statusColor: failed ? Theme.urgent
      : (network.connected || network.stateChanging ? Theme.foreground : Theme.faint)

    function join(passphrase) {
      root.failedName = ""
      root.passwordFor = ""
      if (passphrase !== undefined) network.connectWithPsk(passphrase)
      else network.connect()
    }

    current: network.connected
    width: parent ? parent.width : root.width
    height: body.height + (passwordOpen ? passwordRow.height + 6 : 0)

    Connections {
      target: row.network
      function onConnectionFailed(reason) {
        root.failedName = row.network.name
        root.failReason = reason === ConnectionFailReason.NoSecrets ? "Wrong password"
          : (reason === ConnectionFailReason.WifiAuthTimeout ? "Timed out connecting" : "Connection failed")
        if (reason === ConnectionFailReason.NoSecrets && row.needsPassword) root.passwordFor = row.network.name
      }
    }

    MouseArea {
      width: parent.width
      height: body.height
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (row.network.connected) row.network.disconnect()
        else if (row.needsPassword && !row.network.known) root.passwordFor = row.passwordOpen ? "" : row.network.name
        else row.join()
      }
    }

    Item {
      id: body
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      height: Math.max(icon.implicitHeight, info.implicitHeight, lockSpot.height) + 12

      Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: Devices.wifiIcon(row.network.signalStrength * 100)
        color: row.statusColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.title
      }

      Column {
        id: info
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: lockSpot.visible ? lockSpot.left : parent.right
        anchors.rightMargin: lockSpot.visible ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: row.network.name
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.body
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: row.status !== ""
          textFormat: Text.PlainText
          text: row.status
          color: row.statusColor
          font.family: Theme.fontFamily
          font.pixelSize: Theme.caption
          elide: Text.ElideRight
        }
      }

      // A lock on secured networks; on known ones it turns into "forget"
      // under the pointer.
      Item {
        id: lockSpot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: lockGlyph.implicitHeight
        visible: row.needsPassword || row.network.known

        HoverHandler {
          id: lockHover
        }

        Text {
          id: lockGlyph
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          textFormat: Text.PlainText
          text: row.forgetShown ? Icons.forget : Icons.lock
          color: row.forgetShown ? Theme.urgent : Theme.dim
          font.family: Theme.fontFamily
          font.pixelSize: Theme.subtitle
        }

        MouseArea {
          anchors.fill: parent
          enabled: row.network.known
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: row.network.forget()
        }
      }
    }

    Row {
      id: passwordRow
      visible: row.passwordOpen
      anchors.top: body.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      spacing: 6
      height: field.implicitHeight + 8

      Field {
        id: field
        width: parent.width - connectButton.width - parent.spacing
        password: true
        placeholderText: "Passphrase"
        onAccepted: if (text.length > 0) row.join(text)
        Keys.onEscapePressed: root.passwordFor = ""
        onVisibleChanged: if (visible) {
          text = ""
          forceActiveFocus()
        }
      }

      PillButton {
        id: connectButton
        height: field.height
        verticalPadding: 6
        fontSize: Theme.body
        text: "Connect"
        onClicked: if (field.text.length > 0) row.join(field.text)
      }
    }
  }
}
