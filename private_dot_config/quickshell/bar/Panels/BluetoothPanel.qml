import QtQuick
import Quickshell.Bluetooth
import qs.Common
import qs.Ui

// Scans for devices while open.
Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  readonly property var adapter: Devices.adapter
  readonly property bool powered: !!adapter && adapter.enabled
  readonly property var devices: Devices.bluetoothDevices
  readonly property var connected: devices.filter(device => device.connected)
  readonly property var paired: devices.filter(device => !device.connected && known(device))
  readonly property var available: powered && adapter.discovering
    ? devices.filter(device => !device.connected && !known(device) && named(device)) : []

  function known(device) {
    return device.paired || device.bonded || device.trusted
  }

  function label(device) {
    return device.name || device.deviceName || device.address
  }

  // Unnamed devices report their address as their name.
  function named(device) {
    const name = device.name || device.deviceName || ""
    return name !== "" && name.replace(/[-:]/g, "") !== device.address.replace(/:/g, "")
  }

  // Keep scanning while open, even if something else stops the scan. Devices
  // stops the scans started here once the popup closes.
  Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: root.powered && !root.adapter.discovering
    onTriggered: {
      Devices.owesDiscoveryStop = true
      root.adapter.discovering = true
    }
  }

  Component.onCompleted: Devices.bluetoothPopups++
  Component.onDestruction: Devices.bluetoothPopups--

  Hero {
    icon: Devices.bluetoothIcon
    title: "Bluetooth"
    subtitle: root.adapter ? "Turned off" : "No adapter"
    phrases: root.powered ? ["Untangling wires", "Streaming vikings", "Pairing mysteries", "Herding headsets",
      "Taming radios", "Summoning speakers", "Wrangling codecs", "Polishing packets"] : []

    Switch {
      visible: !!root.adapter
      checked: root.powered
      onToggled: root.adapter.enabled = !root.adapter.enabled
    }
  }

  Separator {}

  Column {
    width: parent.width
    spacing: 10
    visible: root.connected.length > 0

    SectionTitle {
      text: "CONNECTED"
    }

    Repeater {
      model: root.connected
      DeviceRow {
        section: "connected"
      }
    }
  }

  Separator {
    visible: root.connected.length > 0 && root.paired.length + root.available.length > 0
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, 400)
    visible: root.paired.length + root.available.length > 0
    contentHeight: lists.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: lists
      width: parent.width
      spacing: 10

      SectionTitle {
        visible: root.paired.length > 0
        text: "PAIRED"
      }

      Repeater {
        model: root.paired
        DeviceRow {
          section: "paired"
        }
      }

      Separator {
        visible: root.paired.length > 0 && root.available.length > 0
      }

      SectionTitle {
        visible: root.available.length > 0
        text: "AVAILABLE"
      }

      Repeater {
        model: root.available
        DeviceRow {
          section: "available"
        }
      }
    }
  }

  Text {
    width: parent.width
    visible: root.connected.length + root.paired.length + root.available.length === 0
    textFormat: Text.PlainText
    text: !root.adapter ? "No Bluetooth adapter" : (!root.powered ? "Turn Bluetooth on to scan" : "Scanning for devices…")
    color: Theme.faint
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
    wrapMode: Text.WordWrap
  }

  component DeviceRow: RowSurface {
    id: row

    required property var modelData
    property string section: ""
    property bool pairRequested: false

    readonly property var device: modelData
    readonly property bool connecting: device.state === BluetoothDeviceState.Connecting || device.pairing || pairRequested
    readonly property bool disconnecting: device.state === BluetoothDeviceState.Disconnecting
    readonly property string status: {
      if (disconnecting) return "Disconnecting…"
      if (device.connected) {
        if (device.batteryAvailable) return Math.round(device.battery * 100) + "%"
        return section === "connected" ? "" : "Connected"
      }
      if (connecting) return "Connecting…"
      return ""
    }
    readonly property color statusColor: device.connected || connecting || disconnecting ? Theme.foreground : Theme.faint

    function activate() {
      if (device.connected) device.disconnect()
      else if (root.known(device)) device.connect()
      else {
        pairRequested = true
        device.pair()
      }
    }

    current: device.connected
    width: parent ? parent.width : root.width
    height: content.implicitHeight + 12

    // A device paired from here is trusted and connected, as bluetoothctl's
    // "pair, trust, connect" would do.
    Connections {
      target: row.device
      function onPairedChanged() {
        if (!row.pairRequested || !row.device.paired) return
        row.pairRequested = false
        row.device.trusted = true
        row.device.connect()
      }
      function onPairingChanged() {
        if (!row.device.pairing && !row.device.paired) row.pairRequested = false
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
          if (row.device.connected) row.device.disconnect()
          else if (row.section === "paired") row.device.forget()
        } else row.activate()
      }
    }

    Item {
      id: content
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      implicitHeight: Math.max(icon.implicitHeight, info.implicitHeight, forget.implicitHeight)

      Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: row.device.connected ? Icons.bluetoothConnected : Icons.bluetooth
        color: row.statusColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.title
      }

      Column {
        id: info
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: forget.visible ? forget.left : parent.right
        anchors.rightMargin: forget.visible ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.label(row.device)
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

      ActionButton {
        id: forget
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: row.section !== "available" && row.hovered
        glyph: Icons.forget
        onClicked: row.device.forget()
      }
    }
  }
}
