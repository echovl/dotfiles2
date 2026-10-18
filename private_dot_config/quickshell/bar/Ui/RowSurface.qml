import QtQuick
import qs.Common

// Background for a popup row: filled and outlined under the pointer, filled
// when it is the current choice (the active output, the connected network).
Rectangle {
  id: root

  property bool current: false
  readonly property alias hovered: hover.hovered

  radius: Theme.radius
  color: hovered ? Theme.hoverFill : (current ? Theme.selectedFill : "transparent")
  border.width: hovered ? 1 : 0
  border.color: Theme.hoverBorder

  Behavior on color { ColorAnimation { duration: 60 } }

  HoverHandler {
    id: hover
  }
}
