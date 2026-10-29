// Notification icons come from Papirus, as they did in dunst, instead of the
// GTK theme (Adwaita has few app icons). Read once at startup: restart the
// bar after changing it.
//@ pragma IconTheme Papirus-Dark
// A minimal bar in the style of Omarchy's: workspaces, the date with a
// calendar, and tray, Bluetooth, network, sound, brightness and battery icons
// that each open a popup, plus the volume/brightness overlay and the
// notification daemon's cards. Run with `qs -c bar`.
import QtQuick
import Quickshell

ShellRoot {
  Variants {
    model: Quickshell.screens

    Scope {
      id: screenScope

      required property var modelData

      Bar {
        modelData: screenScope.modelData
      }

      PopupLayer {
        modelData: screenScope.modelData
      }

      Osd {
        modelData: screenScope.modelData
      }

      Toasts {
        modelData: screenScope.modelData
      }
    }
  }
}
