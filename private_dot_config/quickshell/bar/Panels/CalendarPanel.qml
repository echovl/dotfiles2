import QtQuick
import Quickshell
import qs.Common
import qs.Ui

// Arrow keys or the wheel move through months (up/down for years), t returns
// to today.
Column {
  id: root

  width: parent ? parent.width : 348
  spacing: 8
  focus: true

  property date today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()

  readonly property var locale: Qt.locale()
  readonly property bool viewingToday: viewYear === today.getFullYear() && viewMonth === today.getMonth()
  readonly property var weekdays: [0, 1, 2, 3, 4, 5, 6].map(i => (locale.firstDayOfWeek + i) % 7)
  readonly property var weeks: monthGrid(viewYear, viewMonth)
  readonly property real yearDone: {
    const start = new Date(today.getFullYear(), 0, 1)
    const end = new Date(today.getFullYear() + 1, 0, 1)
    const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    return Math.max(0, Math.min(1, (startOfToday - start) / (end - start)))
  }

  readonly property int cellWidth: 38
  readonly property int cellHeight: 28
  readonly property int cellSpacing: 2
  readonly property int weekColumnWidth: 26
  readonly property int gutterWidth: 10

  function isoWeek(year, month, day) {
    const d = new Date(Date.UTC(year, month, day))
    d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7))
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
  }

  // Six weeks starting on the locale's first weekday, each numbered by the ISO
  // week that owns its Thursday.
  function monthGrid(year, month) {
    const leading = (new Date(year, month, 1).getDay() - locale.firstDayOfWeek + 7) % 7
    const cursor = new Date(year, month, 1 - leading)
    const weeks = []
    for (let w = 0; w < 6; w++) {
      const days = []
      let thursday = null
      for (let d = 0; d < 7; d++) {
        const weekday = cursor.getDay()
        if (weekday === 4) thursday = new Date(cursor)
        days.push({
          day: cursor.getDate(),
          inMonth: cursor.getMonth() === month,
          weekend: weekday === 0 || weekday === 6,
          today: cursor.toDateString() === today.toDateString()
        })
        cursor.setDate(cursor.getDate() + 1)
      }
      weeks.push({ week: isoWeek(thursday.getFullYear(), thursday.getMonth(), thursday.getDate()), days: days })
    }
    return weeks
  }

  function moveMonth(delta) {
    const next = new Date(viewYear, viewMonth + delta, 1)
    viewYear = next.getFullYear()
    viewMonth = next.getMonth()
  }

  function goToToday() {
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
  }

  Keys.onLeftPressed: moveMonth(-1)
  Keys.onRightPressed: moveMonth(1)
  Keys.onUpPressed: moveMonth(-12)
  Keys.onDownPressed: moveMonth(12)
  Keys.onPressed: event => {
    if (event.text === "t" || event.text === "T") goToToday()
  }

  SystemClock {
    precision: SystemClock.Minutes
    onDateChanged: {
      if (date.toDateString() === root.today.toDateString()) return
      const follow = root.viewingToday
      root.today = date
      if (follow) root.goToToday()
    }
  }

  // Today's date; click it to come back from another month.
  Item {
    width: parent.width
    height: heroRow.height

    Row {
      id: heroRow
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 14

      Text {
        anchors.baseline: heroDate.baseline
        textFormat: Text.PlainText
        text: Icons.calendar
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 26
      }

      Text {
        id: heroDate
        textFormat: Text.PlainText
        text: root.today.toLocaleDateString(root.locale, "MMMM d")
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 28
        font.bold: true
      }
    }

    MouseArea {
      x: heroRow.x
      width: heroRow.width
      height: heroRow.height
      enabled: !root.viewingToday
      cursorShape: Qt.PointingHandCursor
      onClicked: root.goToToday()
    }
  }

  // How much of the year has gone.
  Item {
    width: parent.width
    height: yearBlock.y + yearBlock.height

    Item {
      id: yearBlock
      y: 6
      anchors.horizontalCenter: parent.horizontalCenter
      width: grid.width
      height: Math.max(yearLabel.implicitHeight, 10)

      Text {
        id: yearLabel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.today.getFullYear()
        color: Theme.faint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.bodySmall
        font.letterSpacing: 1
      }

      Text {
        id: yearPercent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: Math.round(root.yearDone * 100) + "%"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.bodySmall
      }

      Rectangle {
        anchors.left: yearLabel.right
        anchors.right: yearPercent.left
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: Theme.radius > 0 ? height / 2 : 0
        color: Theme.divider

        Rectangle {
          width: Math.round(parent.width * root.yearDone)
          height: parent.height
          radius: parent.radius
          color: Theme.foreground
        }
      }
    }
  }

  Item {
    width: parent.width
    height: grid.y + grid.height

    WheelHandler {
      onWheel: event => {
        if (event.angleDelta.y !== 0) root.moveMonth(event.angleDelta.y > 0 ? -1 : 1)
      }
    }

    Column {
      id: grid
      y: 12
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 3

      Row {
        id: headerRow
        spacing: root.cellSpacing

        Text {
          width: root.weekColumnWidth
          height: 16
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          textFormat: Text.PlainText
          text: "W"
          color: Theme.fade(Theme.foreground, 1.9)
          font.family: Theme.fontFamily
          font.pixelSize: Theme.caption
          font.letterSpacing: 1
          font.bold: true
        }

        Item {
          width: root.gutterWidth
          height: 16
        }

        Repeater {
          model: root.weekdays

          Text {
            required property int modelData
            width: root.cellWidth
            height: 16
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            text: root.locale.dayName(modelData, Locale.ShortFormat).toUpperCase()
            color: Theme.faint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.caption
            font.letterSpacing: 1
            font.bold: true
          }
        }
      }

      Repeater {
        model: root.weeks

        Row {
          id: week
          required property var modelData
          spacing: root.cellSpacing

          Text {
            width: root.weekColumnWidth
            height: root.cellHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            text: week.modelData.week
            color: Theme.fade(Theme.foreground, 1.9)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.caption
          }

          Item {
            width: root.gutterWidth
            height: root.cellHeight
          }

          Repeater {
            model: week.modelData.days

            Rectangle {
              required property var modelData
              width: root.cellWidth
              height: root.cellHeight
              radius: Theme.radius
              color: "transparent"
              border.width: modelData.today ? 1 : 0
              border.color: Theme.normalBorder

              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: modelData.day
                color: !modelData.inMonth ? Theme.fade(Theme.foreground, 2.2)
                  : (modelData.weekend ? Theme.fade(Theme.foreground, 1.45) : Theme.foreground)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.body
                font.bold: modelData.today
              }
            }
          }
        }
      }
    }

    // Rule between the week numbers and the days.
    Rectangle {
      x: grid.x + root.weekColumnWidth + root.cellSpacing + Math.round((root.gutterWidth - width) / 2)
      y: grid.y + headerRow.height + grid.spacing
      width: 1
      height: grid.height - headerRow.height - grid.spacing
      color: Theme.foreground
      opacity: 0.1
    }
  }

  Item {
    width: parent.width
    height: monthNav.height

    Item {
      id: monthNav
      anchors.horizontalCenter: parent.horizontalCenter
      width: grid.width
      height: monthLabel.implicitHeight + 10

      Text {
        id: monthLabel
        anchors.centerIn: parent
        width: 130
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: (root.locale.standaloneMonthName(root.viewMonth, Locale.LongFormat) + " " + root.viewYear).toUpperCase()
        color: Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.body
        font.letterSpacing: 1
      }

      ActionButton {
        anchors.left: parent.left
        anchors.leftMargin: -8
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.previous
        onClicked: root.moveMonth(-1)
      }

      ActionButton {
        anchors.right: parent.right
        anchors.rightMargin: -8
        anchors.verticalCenter: parent.verticalCenter
        glyph: Icons.next
        onClicked: root.moveMonth(1)
      }
    }
  }
}
