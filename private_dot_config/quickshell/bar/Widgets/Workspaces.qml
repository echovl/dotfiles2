import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Ui

// Workspaces that have windows, plus the focused one even when it's empty so
// you can see where you are. The focused one's number sits in a filled block.
Row {
  id: root

  property color color: Theme.foreground
  // The number inside the focused block: whichever theme color the bar text isn't.
  readonly property color inverse: Qt.colorEqual(color, Theme.foreground) ? Theme.background : Theme.foreground
  property real wheelRemainder: 0

  spacing: 1
  rightPadding: 1.5

  readonly property var ids: {
    const focused = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    return Hyprland.workspaces.values
      .filter(ws => ws.id > 0 && (ws.toplevels.values.length > 0 || ws.id === focused))
      .map(ws => ws.id)
      .sort((a, b) => a - b)
  }

  // Not named `focus`: that is every Item's focus property. Sent over
  // Hyprland's socket, so a click or a scroll step starts no process.
  function goTo(id) {
    Hyprland.dispatch('hl.dsp.focus({ workspace = "' + id + '" })')
  }

  function scroll(delta) {
    const total = wheelRemainder + delta / 120
    const steps = total > 0 ? Math.floor(total) : Math.ceil(total)
    wheelRemainder = total - steps
    if (steps === 0 || !Hyprland.focusedWorkspace) return
    const index = ids.indexOf(Hyprland.focusedWorkspace.id)
    if (index === -1) return
    const target = ids[Math.max(0, Math.min(ids.length - 1, index - steps))]
    if (target !== ids[index]) goTo(target)
  }

  Repeater {
    // Diffed, so a workspace appearing or going away adds or removes its own
    // slot instead of rebuilding them all.
    model: ScriptModel { values: root.ids }

    Item {
      id: slot

      required property int modelData
      readonly property bool focused: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
      readonly property string label: String(modelData)

      width: Math.max(20, block.width + 4)
      height: Theme.barHeight

      BarLabel {
        anchors.centerIn: parent
        visible: !slot.focused
        margin: 6
        text: slot.label
        color: root.color
      }

      // The focused workspace: its number cut out of a filled block, where
      // Omarchy draws a plain square.
      Rectangle {
        id: block
        anchors.centerIn: parent
        visible: slot.focused
        width: Math.max(16, number.textWidth + 6)
        height: 16
        radius: 3
        color: root.color

        BarLabel {
          id: number
          anchors.centerIn: parent
          margin: 0
          text: slot.label
          color: root.inverse
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!slot.focused) root.goTo(slot.modelData)
        onWheel: wheel => root.scroll(wheel.angleDelta.y)
      }
    }
  }
}
