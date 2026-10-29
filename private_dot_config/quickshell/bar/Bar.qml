import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Ui
import qs.Widgets

PanelWindow {
  id: bar

  required property var modelData
  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Theme.barHeight
  // Hyprland blurs this namespace where the bar is more than 30% opaque, so
  // only the glassy background (70%) shows blur.
  WlrLayershell.namespace: "qs-bar"
  WlrLayershell.layer: WlrLayer.Top

  readonly property string look: BarState.background
  color: look === "none" ? "transparent" : (look === "glassy" ? Theme.alpha(Theme.background, 0.7) : Theme.background)
  // A surface created opaque draws a clear or glassy bar as black.
  surfaceFormat.opaque: false

  // A clear bar uses whichever theme color stands out more on the wallpaper.
  property color clearForeground: Theme.foreground
  readonly property color foreground: look === "none" ? clearForeground : Theme.foreground

  function sampleWallpaper() {
    if (look !== "none" || textColor.running) return
    textColor.command = [Quickshell.shellPath("scripts/text-color.sh"), String(screen.width), String(screen.height),
      String(Theme.barHeight), String(Theme.foreground), String(Theme.background)]
    textColor.running = true
  }

  onLookChanged: sampleWallpaper()
  Component.onCompleted: sampleWallpaper()

  Process {
    id: textColor
    stdout: StdioCollector {
      onStreamFinished: {
        const value = text.trim()
        if (/^#[0-9a-fA-F]{6}$/.test(value)) bar.clearForeground = value
      }
    }
  }

  // Hyprland treats a mapped layer surface as visible, so this holds even
  // under a fullscreen window.
  IdleInhibitor {
    window: bar
    enabled: BarState.caffeine
  }

  function toggle(name, item, payload) {
    const point = item.mapToItem(null, item.width / 2, 0)
    BarState.toggle(name, modelData, point.x, payload)
  }

  function isOpen(name) {
    return BarState.isOpen(name, modelData)
  }

  // `qs -c bar ipc call bar toggle audio` opens a popup from a script or key.
  IpcHandler {
    target: "bar"
    enabled: Quickshell.screens.length > 0 && bar.modelData.name === Quickshell.screens[0].name

    function toggle(name: string): void {
      const items = {
        calendar: clock, weather: weatherButton, media: media, updates: updatesButton, system: systemButton, bluetooth: bluetoothButton,
        network: networkButton, audio: audioButton, brightness: brightnessButton, battery: batteryButton,
        notifications: notificationsButton
      }
      if (items[name]) bar.toggle(name, items[name])
    }

    // Same as double-clicking the bar.
    function cycleBackground(): void {
      BarState.cycleBackground()
    }

    // Same as clicking the cup; `qs -c bar ipc prop get bar caffeine` reads it.
    readonly property bool caffeine: BarState.caffeine
    function toggleCaffeine(): void {
      BarState.caffeine = !BarState.caffeine
    }
  }

  // Double-clicking an empty part of the bar changes its background.
  MouseArea {
    anchors.fill: parent
    onDoubleClicked: BarState.cycleBackground()
  }

  Row {
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter

    Workspaces {
      color: bar.foreground
    }

    ActiveWindow {
      color: bar.foreground
    }
  }

  Clock {
    id: clock
    anchors.centerIn: parent
    color: bar.foreground
    open: bar.isOpen("calendar")
    onToggled: bar.toggle("calendar", clock)
  }

  // Caffeine sits left of the clock, where Omarchy keeps its toggles, apart
  // from the status icons on the right. Dimmed while the screen may idle.
  BarButton {
    id: caffeineButton
    anchors.right: clock.left
    anchors.verticalCenter: parent.verticalCenter
    slot: 21
    glyph: Icons.stayAwake
    dimmed: !BarState.caffeine
    color: bar.foreground
    onClicked: BarState.caffeine = !BarState.caffeine
  }

  NowPlaying {
    id: media
    anchors.right: caffeineButton.left
    anchors.verticalCenter: parent.verticalCenter
    color: bar.foreground
    open: bar.isOpen("media")
    onPopupRequested: bar.toggle("media", media)
  }

  // Shown only when there are updates, after the weather as on Omarchy.
  BarButton {
    id: updatesButton
    anchors.left: weatherButton.visible ? weatherButton.right : clock.right
    anchors.verticalCenter: parent.verticalCenter
    visible: Updates.count > 0
    slot: 21
    glyph: Icons.updates
    color: bar.foreground
    open: bar.isOpen("updates")
    onClicked: bar.toggle("updates", updatesButton)
  }

  // Beside the clock, as on Omarchy; a pin while it needs a place picked.
  // Middle-click fetches it again.
  BarButton {
    id: weatherButton
    anchors.left: clock.right
    anchors.verticalCenter: parent.verticalCenter
    visible: Weather.ready || Weather.needsPlace
    slot: 21
    glyph: Weather.ready ? Weather.icon : Icons.pin
    color: bar.foreground
    open: bar.isOpen("weather")
    onClicked: button => {
      if (button === Qt.MiddleButton) Weather.refresh()
      else bar.toggle("weather", weatherButton)
    }
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter

    Tray {
      color: bar.foreground
      holdOpen: bar.isOpen("tray")
      onMenuRequested: (item, anchor) => bar.toggle("tray", anchor, item)
    }

    BarButton {
      id: systemButton
      glyph: Icons.chip
      color: bar.foreground
      open: bar.isOpen("system")
      onClicked: bar.toggle("system", systemButton)
    }

    BarButton {
      id: bluetoothButton
      visible: !!Devices.adapter
      glyph: Devices.bluetoothIcon
      color: bar.foreground
      dimmed: Devices.bluetoothOff
      open: bar.isOpen("bluetooth")
      onClicked: bar.toggle("bluetooth", bluetoothButton)
    }

    BarButton {
      id: networkButton
      glyph: Devices.networkIcon
      color: bar.foreground
      open: bar.isOpen("network")
      onClicked: bar.toggle("network", networkButton)
    }

    BarButton {
      id: audioButton
      glyph: Devices.audioIcon
      color: bar.foreground
      dimmed: Devices.soundOff
      open: bar.isOpen("audio")
      onClicked: button => {
        if (button === Qt.RightButton && Devices.sinkReady) Devices.sink.audio.muted = !Devices.sink.audio.muted
        else bar.toggle("audio", audioButton)
      }
      onWheel: delta => {
        if (Devices.sinkReady) Devices.sink.audio.volume = Math.max(0, Math.min(1, Devices.volume + (delta > 0 ? 0.05 : -0.05)))
      }
    }

    BarButton {
      id: brightnessButton
      glyph: Icons.monitor
      color: bar.foreground
      open: bar.isOpen("brightness")
      onClicked: bar.toggle("brightness", brightnessButton)
      onWheel: delta => Devices.setBrightness(Math.round(Devices.brightnessPercent) + (delta > 0 ? 5 : -5))
    }

    BarButton {
      id: batteryButton
      visible: Devices.batteryPresent
      glyph: Devices.batteryIcon
      label: BarState.batteryPercent ? Math.round(Devices.batteryFraction * 100) + "%" : ""
      color: bar.foreground
      open: bar.isOpen("battery")
      onClicked: button => {
        if (button === Qt.RightButton) BarState.batteryPercent = !BarState.batteryPercent
        else bar.toggle("battery", batteryButton)
      }
    }

    // Right-click toggles Do Not Disturb. A dot marks notifications it held
    // back that the panel hasn't shown yet.
    BarButton {
      id: notificationsButton
      glyph: Notifications.dnd ? Icons.bellOff : Icons.bell
      color: bar.foreground
      dimmed: Notifications.dnd
      open: bar.isOpen("notifications")
      onClicked: button => {
        if (button === Qt.RightButton) Notifications.setDnd(!Notifications.dnd)
        else bar.toggle("notifications", notificationsButton)
      }

      Rectangle {
        visible: Notifications.unseen > 0
        width: 5
        height: 5
        radius: 2.5
        x: parent.width / 2 + 3
        y: parent.height / 2 - 7
        color: Theme.accent
      }
    }
  }
}
