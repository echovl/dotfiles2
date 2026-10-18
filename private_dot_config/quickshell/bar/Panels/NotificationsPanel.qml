import QtQuick
import qs.Common
import qs.Ui

// dunst's recent notifications, with Do Not Disturb as the switch.
Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  function ago(seconds) {
    if (seconds < 60) return "now"
    if (seconds < 3600) return Math.floor(seconds / 60) + "m"
    if (seconds < 86400) return Math.floor(seconds / 3600) + "h"
    return Math.floor(seconds / 86400) + "d"
  }

  Component.onCompleted: Notifications.refreshHistory()

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: Notifications.refreshHistory()
  }

  Hero {
    icon: Notifications.paused ? Icons.bellOff : Icons.bell
    title: "Notifications"
    subtitle: Notifications.paused
      ? (Notifications.waiting > 0 ? Notifications.waiting + " waiting" : "Do not disturb")
      : (Notifications.history.length > 0 ? Notifications.history.length + " recent" : "All caught up")

    Switch {
      checked: !Notifications.paused
      onToggled: Notifications.setPaused(!Notifications.paused)
    }
  }

  Separator {}

  Item {
    width: parent.width
    height: recentTitle.height
    visible: Notifications.history.length > 0

    SectionTitle {
      id: recentTitle
      text: "RECENT"
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: "CLEAR"
      color: clearMouse.containsMouse ? Theme.foreground : Theme.dim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.caption
      font.bold: true

      MouseArea {
        id: clearMouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.clear()
      }
    }
  }

  Text {
    visible: Notifications.history.length === 0
    textFormat: Text.PlainText
    text: "No notifications"
    color: Theme.faint
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, 400)
    visible: Notifications.history.length > 0
    contentHeight: list.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: list
      width: parent.width
      spacing: 4

      Repeater {
        model: Notifications.history

        RowSurface {
          id: row

          required property var modelData

          width: list.width
          height: content.implicitHeight + 16

          Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Item {
              width: parent.width
              height: appName.implicitHeight

              Text {
                id: appName
                width: parent.width - when.width - 8
                textFormat: Text.PlainText
                text: row.modelData.app
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.caption
                font.bold: true
                font.letterSpacing: 1.2
                elide: Text.ElideRight
              }

              Text {
                id: when
                anchors.right: parent.right
                visible: !row.hovered
                textFormat: Text.PlainText
                text: root.ago(row.modelData.age)
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.caption
              }
            }

            Text {
              width: parent.width
              visible: text !== ""
              textFormat: Text.PlainText
              text: row.modelData.summary
              color: Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.body
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              visible: text !== "" && text !== row.modelData.summary
              textFormat: Text.PlainText
              text: row.modelData.body
              color: Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.bodySmall
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }
          }

          ActionButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            visible: row.hovered
            glyph: Icons.forget
            onClicked: Notifications.remove(row.modelData.id)
          }
        }
      }
    }
  }
}
