import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Panels

// The open popup's window. It covers the screen below the bars (it stays out
// of their exclusive zones), so a click anywhere outside the card closes the
// popup while clicks on a bar still reach the bar.
PanelWindow {
  id: popups

  required property var modelData
  screen: modelData

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0
  color: "transparent"
  WlrLayershell.namespace: "qs-popup"
  WlrLayershell.layer: WlrLayer.Overlay
  // Take the keyboard for a moment when a popup opens so Esc works right
  // away, then only when clicked into (Omarchy does the same).
  WlrLayershell.keyboardFocus: !shown ? WlrKeyboardFocus.None
    : (focusPrime.running ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)

  readonly property bool shown: BarState.popup !== "" && BarState.screen === modelData
  // What the card shows, kept through the fade-out after the popup closes.
  property string current: ""
  property var currentPayload: null

  readonly property int padding: current === "tray" ? 8 : Theme.popupPadding
  readonly property int inset: Theme.popupBorder + padding
  readonly property int cardWidth: current === "tray" ? 232 : (current === "media" ? 320 : Theme.popupWidth)

  function sync() {
    if (!shown) return
    current = BarState.popup
    currentPayload = BarState.payload
    focusPrime.restart()
  }

  onShownChanged: sync()

  Connections {
    target: BarState
    function onPopupChanged() { popups.sync() }
    function onPayloadChanged() { popups.sync() }
  }

  Timer {
    id: focusPrime
    interval: 200
  }

  visible: shown || card.opacity > 0

  MouseArea {
    anchors.fill: parent
    onPressed: BarState.close()
  }

  Rectangle {
    id: card

    width: popups.cardWidth
    height: Math.min(content.implicitHeight + popups.inset * 2, popups.height - Theme.gap * 2)
    x: popups.current === "calendar"
      ? Math.round((popups.width - width) / 2)
      : Math.round(Math.max(Theme.gap, Math.min(popups.width - width - Theme.gap, BarState.anchorX - width / 2)))
    y: Theme.gap
    radius: Theme.radius
    color: Theme.background
    border.width: Theme.popupBorder
    border.color: popups.current === "tray" ? Theme.alpha(Theme.foreground, 0.45) : Theme.accent
    opacity: popups.shown ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    // Clicks on the card's empty space must not fall through and close it.
    MouseArea {
      anchors.fill: parent
    }

    FocusScope {
      id: content
      anchors.fill: parent
      anchors.margins: popups.inset
      implicitHeight: loader.item ? loader.item.implicitHeight : 0
      clip: true
      focus: true
      Keys.onEscapePressed: BarState.close()

      Loader {
        id: loader
        width: parent.width
        focus: true
        sourceComponent: {
          switch (popups.current) {
            case "audio": return audioPanel
            case "bluetooth": return bluetoothPanel
            case "network": return networkPanel
            case "brightness": return brightnessPanel
            case "battery": return batteryPanel
            case "calendar": return calendarPanel
            case "tray": return trayMenu
            case "weather": return weatherPanel
            case "notifications": return notificationsPanel
            case "system": return systemPanel
            case "media": return mediaPanel
            case "updates": return updatesPanel
            default: return null
          }
        }
      }
    }
  }

  Component { id: audioPanel; AudioPanel {} }
  Component { id: bluetoothPanel; BluetoothPanel {} }
  Component { id: networkPanel; NetworkPanel {} }
  Component { id: brightnessPanel; BrightnessPanel {} }
  Component { id: batteryPanel; BatteryPanel {} }
  Component { id: calendarPanel; CalendarPanel {} }
  Component { id: trayMenu; TrayMenu { item: popups.currentPayload } }
  Component { id: weatherPanel; WeatherPanel {} }
  Component { id: notificationsPanel; NotificationsPanel {} }
  Component { id: systemPanel; SystemPanel {} }
  Component { id: mediaPanel; MediaPanel {} }
  Component { id: updatesPanel; UpdatesPanel {} }
}
