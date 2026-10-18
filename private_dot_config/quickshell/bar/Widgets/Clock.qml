import QtQuick
import Quickshell
import qs.Common
import qs.Ui

// The date and time. Click for the calendar; right-click steps through
// Omarchy's formats, and the choice is remembered.
Item {
  id: root

  property color color: Theme.foreground
  property bool open: false
  signal toggled()

  readonly property var formats: [
    "dddd HH:mm", "dddd h:mm AP", "dddd HH:mm:ss", "dddd h:mm:ss AP", "HH:mm", "h:mm AP",
    "ddd d MMM HH:mm", "ddd d MMM h:mm AP", "d MMMM 'W'ww yyyy", "yyyy-MM-dd HH:mm"
  ]
  readonly property string format: BarState.clockFormat

  function isoWeek(date) {
    const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7))
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
  }

  function formatted(date) {
    const week = String(isoWeek(date)).padStart(2, "0")
    return date.toLocaleString(Qt.locale(), format.replace(/ww/g, week))
  }

  function cycleFormat() {
    const index = formats.indexOf(format)
    BarState.clockFormat = formats[(index + 1) % formats.length]
  }

  implicitWidth: label.implicitWidth
  implicitHeight: Theme.barHeight

  SystemClock {
    id: clock
    precision: root.format.includes("s") ? SystemClock.Seconds : SystemClock.Minutes
  }

  BarLabel {
    id: label
    anchors.centerIn: parent
    text: root.formatted(clock.date)
    color: root.color
  }

  OpenMark {
    open: root.open
    width: Math.round(label.textWidth)
    x: Math.floor((root.width - width) / 2)
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => mouse.button === Qt.RightButton ? root.cycleFormat() : root.toggled()
  }
}
