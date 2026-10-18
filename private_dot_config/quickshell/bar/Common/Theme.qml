pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Colors from the applied tinty scheme, and the sizes Omarchy's shell uses at
// the default 12px font, so the bar and popups line up with Omarchy's.
Singleton {
  id: root

  // base16 roles from the scheme scripts/tinty-hook.sh writes on `tinty apply`;
  // Omarchy's Tokyo Night until one has been applied.
  readonly property color background: scheme.base00 || "#1a1b26"
  readonly property color foreground: scheme.base05 || "#a9b1d6"
  readonly property color accent: scheme.base0D || "#7aa2f7"
  readonly property color urgent: scheme.base08 || "#f7768e"

  // Faded text moves toward the background: darker on dark schemes, lighter
  // on light ones.
  readonly property bool dark: scheme.variant !== "light"
  function fade(c, factor) {
    return dark ? Qt.darker(c, factor) : Qt.lighter(c, factor)
  }

  // Subtitles and section headers, then inactive rows and hints.
  readonly property color dim: fade(foreground, 1.4)
  readonly property color faint: fade(foreground, 1.5)

  FileView {
    id: schemeFile
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/bar/colors.json"
    watchChanges: true
    onFileChanged: reload()
    // A file that doesn't exist yet can't be watched: look again until
    // tinty has written it.
    onLoadFailed: schemeRetry.start()

    JsonAdapter {
      id: scheme
      property string variant: "dark"
      property string base00: ""
      property string base05: ""
      property string base08: ""
      property string base0D: ""
    }
  }

  Timer {
    id: schemeRetry
    interval: 5000
    onTriggered: schemeFile.reload()
  }

  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  // Control states from Omarchy's shell.toml [controls].
  readonly property color normalFill: alpha(foreground, 0.04)
  readonly property color hoverFill: alpha(foreground, 0.08)
  readonly property color selectedFill: alpha(foreground, 0.18)
  readonly property color pressedFill: alpha(foreground, 0.22)
  readonly property color normalBorder: alpha(foreground, 0.4)
  readonly property color hoverBorder: alpha(foreground, 0.25)
  readonly property color divider: alpha(foreground, 0.12)

  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int caption: 10
  readonly property int bodySmall: 11
  readonly property int body: 12
  readonly property int subtitle: 13
  readonly property int title: 14
  readonly property int heading: 16
  readonly property int display: 24
  readonly property int displayLarge: 28

  readonly property int barHeight: 26
  readonly property int iconSlot: 27
  readonly property int iconFont: 13
  // Bar glyphs are scaled so their ink is this many px on the long side.
  readonly property int iconSize: 12
  readonly property int iconCanvas: 16

  readonly property int popupWidth: 380
  readonly property int popupPadding: 14
  readonly property int popupBorder: 2
  readonly property int controlHeight: 28

  // Corners and the bar-to-popup gap follow Hyprland, as Omarchy's do:
  // decoration:rounding, and half of general:gaps_out.
  property int radius: 0
  property int gap: 5

  function refresh() {
    roundingProc.running = true
    gapsProc.running = true
  }

  Process {
    id: roundingProc
    command: ["hyprctl", "-j", "getoption", "decoration:rounding"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const n = Number(JSON.parse(text).int)
          if (n >= 0) root.radius = n
        } catch (e) {}
      }
    }
  }

  Process {
    id: gapsProc
    command: ["hyprctl", "-j", "getoption", "general:gaps_out"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const json = JSON.parse(text)
          const parts = String(json.css || "").match(/\d+(\.\d+)?/g) || []
          const n = parts.length > 0 ? Number(parts[0]) : Number(json.int)
          if (n >= 0) root.gap = Math.round(n / 2)
        } catch (e) {}
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "configreloaded") root.refresh()
    }
  }

  Component.onCompleted: refresh()
}
