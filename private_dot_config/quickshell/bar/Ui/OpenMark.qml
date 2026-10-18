import QtQuick
import qs.Common

// The accent line under a bar widget while its popup is open.
Rectangle {
  property bool open: false

  height: 2
  radius: 1
  y: (parent ? parent.height : Theme.barHeight) - height - 2
  color: Theme.accent
  opacity: open ? 0.9 : 0
  visible: opacity > 0

  Behavior on opacity {
    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
  }
}
