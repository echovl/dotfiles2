pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // The open popup ("" when none), the screen whose bar opened it, the x of
  // the widget it hangs from in that bar, and anything it needs (a tray item).
  property string popup: ""
  property var screen: null
  property real anchorX: 0
  property var payload: null

  function toggle(name, screen, anchorX, payload) {
    const nextPayload = payload === undefined ? null : payload
    if (popup === name && root.screen === screen && root.payload === nextPayload) {
      close()
      return
    }
    root.screen = screen
    root.anchorX = anchorX
    root.payload = nextPayload
    root.popup = name
  }

  function close() {
    popup = ""
  }

  function isOpen(name, screen) {
    return popup === name && root.screen === screen
  }

  // Double-clicking the bar steps its background the way Omarchy's does:
  // opaque, then clear, then glassy, then opaque again.
  readonly property string background: settings.background
  function cycleBackground() {
    settings.background = background === "none" ? "glassy" : (background === "glassy" ? "opaque" : "none")
  }

  property alias clockFormat: settings.clockFormat
  // Right-clicking the battery icon shows its percentage beside it.
  property alias batteryPercent: settings.batteryPercent
  // The place the weather is for, picked in its popup; null follows the IP.
  property alias weatherLocation: settings.weatherLocation
  // Do Not Disturb: notifications go to the panel without a card, except
  // critical ones. Kept across restarts, unlike caffeine.
  property alias dnd: settings.dnd

  // While on, the bar holds an idle inhibitor, so hypridle doesn't dim, lock
  // or turn off the screen. Like GNOME's Caffeine, it's off after a restart.
  property bool caffeine: false

  // The on-screen display Omarchy shows for volume and brightness changes.
  property string osdIcon: ""
  property int osdPercent: 0
  property bool osdShown: false

  function showOsd(icon, percent) {
    osdIcon = icon
    osdPercent = Math.max(0, Math.min(100, percent))
    osdShown = true
    osdTimer.restart()
  }

  Timer {
    id: osdTimer
    interval: 1200
    onTriggered: root.osdShown = false
  }

  FileView {
    path: Quickshell.statePath("settings.json")
    blockLoading: true
    onAdapterUpdated: writeAdapter()
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) writeAdapter()
    }

    JsonAdapter {
      id: settings
      property string background: "opaque"
      property string clockFormat: "dddd HH:mm"
      property bool batteryPercent: false
      // { name, latitude, longitude, imperial } or null
      property var weatherLocation: null
      property bool dnd: false
    }
  }
}
