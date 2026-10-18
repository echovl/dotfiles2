import QtQuick
import QtQuick.Controls
import qs.Common

TextField {
  id: root

  property bool password: false
  readonly property bool hot: activeFocus || hovered

  echoMode: password ? TextInput.Password : TextInput.Normal
  font.family: Theme.fontFamily
  font.pixelSize: Theme.body
  color: Theme.foreground
  selectionColor: Theme.alpha(Theme.foreground, 0.35)
  selectedTextColor: Theme.foreground
  placeholderTextColor: Theme.fade(Theme.foreground, 1.6)
  leftPadding: 9
  rightPadding: 9
  topPadding: 7
  bottomPadding: 7

  background: Rectangle {
    radius: Theme.radius
    color: root.hot ? Theme.hoverFill : Theme.normalFill
    border.width: 1
    border.color: root.hot ? Theme.hoverBorder : Theme.normalBorder
  }
}
