pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower

// Readings the bar icons and their popups share.
Singleton {
  id: root

  // ---------------------------------------------------------------- audio

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property bool sinkReady: !!(sink && sink.audio)
  readonly property bool sourceReady: !!(source && source.audio)
  readonly property real volume: sinkReady ? sink.audio.volume : 0
  readonly property bool muted: sinkReady && sink.audio.muted

  PwObjectTracker {
    objects: [root.sink, root.source].filter(node => !!node)
  }

  function nodeBlob(node) {
    const p = node.properties || {}
    return [node.name, node.description, node.nickname, p["device.icon-name"], p["device.product.name"],
      p["node.description"], p["node.nick"]].join(" ").toLowerCase()
  }

  function isHeadphones(node) {
    if (!node) return false
    const blob = nodeBlob(node)
    return ["headphone", "headset", "earbud", "earphone", "airpod"].some(word => blob.includes(word))
  }

  // Volume changes show the on-screen display, except from the sound popup
  // and right after the output device changes (a new device reports its
  // volume, which isn't a change).
  property real sinkSince: 0
  onSinkChanged: sinkSince = Date.now()
  Component.onCompleted: sinkSince = Date.now()

  Connections {
    target: root.sinkReady ? root.sink.audio : null
    function onVolumeChanged() { root.announceVolume() }
    function onMutedChanged() { root.announceVolume() }
  }

  function announceVolume() {
    if (Date.now() - sinkSince < 1000 || BarState.popup === "audio") return
    // Read the node itself: the bindings above may not have caught up yet.
    const audio = sink.audio
    BarState.showOsd(audio.muted || audio.volume <= 0 ? Icons.speakerMuted : Icons.speakerHigh, Math.round(audio.volume * 100))
  }

  readonly property string audioIcon: {
    if (!sinkReady) return Icons.speakerMuted
    if (isHeadphones(sink)) return Icons.headphones
    if (muted || volume <= 0) return Icons.speakerMuted
    if (volume >= 0.67) return Icons.speakerHigh
    if (volume >= 0.34) return Icons.speakerMid
    return Icons.speakerLow
  }

  // ------------------------------------------------------------ bluetooth

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var bluetoothDevices: adapter ? adapter.devices.values : []
  readonly property var bluetoothConnected: bluetoothDevices.filter(device => device.connected)
  readonly property string bluetoothIcon: !adapter || !adapter.enabled
    ? Icons.bluetoothOff
    : (bluetoothConnected.length > 0 ? Icons.bluetoothConnected : Icons.bluetooth)

  // -------------------------------------------------------------- network

  readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
  readonly property var wifiDevice: networkDevices.find(device => device.type === DeviceType.Wifi) || null
  readonly property var wiredDevice: networkDevices.find(device => device.type === DeviceType.Wired && device.connected) || null
  readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values : []
  readonly property var wifiNetwork: wifiNetworks.find(network => network.connected) || null
  readonly property string networkKind: wiredDevice ? "ethernet" : (wifiNetwork ? "wifi" : "disconnected")
  readonly property string networkInterface: wiredDevice ? wiredDevice.name : (wifiNetwork ? wifiDevice.name : "")
  readonly property int wifiSignal: wifiNetwork ? Math.round(wifiNetwork.signalStrength * 100) : 0
  readonly property bool networkLimited: Networking.connectivity === NetworkConnectivity.Portal
    || Networking.connectivity === NetworkConnectivity.Limited

  function wifiIcon(strength) {
    return Icons.wifi[Math.max(0, Math.min(4, Math.ceil(strength / 20) - 1))]
  }

  readonly property string networkIcon: {
    if (networkKind === "ethernet") return Icons.ethernet
    if (networkKind === "wifi") return networkLimited ? Icons.wifiLimited : wifiIcon(wifiSignal)
    return Icons.wifiOff
  }

  // -------------------------------------------------------------- battery

  readonly property var battery: UPower.displayDevice
  readonly property bool batteryPresent: !!(battery && battery.isPresent)
  readonly property real batteryFraction: batteryPresent ? Math.max(0, Math.min(1, battery.percentage)) : 0
  // The battery's own state, rather than UPower.onBattery, which can be stale
  // after a config reload.
  readonly property bool discharging: batteryPresent
    ? [UPowerDeviceState.Discharging, UPowerDeviceState.PendingDischarge, UPowerDeviceState.Empty].includes(battery.state)
    : UPower.onBattery
  readonly property bool fullyCharged: batteryPresent && battery.state === UPowerDeviceState.FullyCharged
  readonly property bool charging: batteryPresent && !discharging && !fullyCharged && batteryFraction < 1

  readonly property string batteryIcon: {
    if (!batteryPresent) return ""
    const step = Math.max(0, Math.min(9, Math.floor(batteryFraction * 10)))
    if (fullyCharged) return Icons.batteryFull
    return discharging ? Icons.battery[step] : Icons.batteryCharging[step]
  }

  readonly property var laptopBattery: UPower.devices.values.find(device => device.isLaptopBattery) || null
  property int batteryCycles: -1

  function refreshBattery() {
    if (cyclesFile.path !== "") cyclesFile.reload()
  }

  FileView {
    id: cyclesFile
    path: root.laptopBattery && root.laptopBattery.nativePath
      ? "/sys/class/power_supply/" + root.laptopBattery.nativePath + "/cycle_count" : ""
    onLoaded: root.batteryCycles = parseInt(text()) || -1
  }

  // ----------------------------------------------------------- brightness
  // Read from sysfs and set through logind, as brightnessctl does, so it
  // needs neither root nor an extra package.

  property string backlight: ""
  property int brightnessMax: 0
  property int brightnessRaw: 0
  property int pendingBrightness: -1
  readonly property bool brightnessAvailable: backlight !== "" && brightnessMax > 0
  readonly property real brightnessPercent: brightnessAvailable ? brightnessRaw * 100 / brightnessMax : 0

  function refreshBrightness() {
    if (brightnessAvailable && !brightnessSetter.running && pendingBrightness < 0) brightnessFile.reload()
  }

  function setBrightness(percent) {
    if (!brightnessAvailable) return
    const clamped = Math.max(1, Math.min(100, percent))
    pendingBrightness = Math.max(1, Math.round(brightnessMax * clamped / 100))
    if (!brightnessSetter.running) applyBrightness()
  }

  function applyBrightness() {
    if (pendingBrightness < 0) return
    brightnessSetter.command = ["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto",
      "org.freedesktop.login1.Session", "SetBrightness", "ssu", "backlight", backlight, String(pendingBrightness)]
    pendingBrightness = -1
    brightnessSetter.running = true
  }

  Process {
    id: brightnessSetter
    onExited: root.applyBrightness()
  }

  Process {
    running: true
    command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -r \"$d/max_brightness\" ] && echo \"${d##*/} $(cat \"$d/max_brightness\")\"; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = (text.trim().split("\n")[0] || "").split(" ")
        if (parts.length === 2 && Number(parts[1]) > 0) {
          root.brightnessMax = Number(parts[1])
          root.backlight = parts[0]
        }
      }
    }
  }

  // Writes to the brightness file (the keys' `light`, logind) notify watchers,
  // so changes made anywhere show up here and on the on-screen display.
  FileView {
    id: brightnessFile
    path: root.backlight !== "" ? "/sys/class/backlight/" + root.backlight + "/brightness" : ""
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const raw = parseInt(text()) || 0
      const first = !root.brightnessLoaded
      root.brightnessLoaded = true
      if (raw === root.brightnessRaw && !first) return
      root.brightnessRaw = raw
      if (!first && BarState.popup !== "brightness") BarState.showOsd(Icons.monitor, Math.round(root.brightnessPercent))
    }
  }

  property bool brightnessLoaded: false
}
