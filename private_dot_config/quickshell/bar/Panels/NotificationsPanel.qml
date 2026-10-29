import QtQuick
import Quickshell
import qs.Common
import qs.Ui

// Every notification still open, and the ones acted on that have closed
// since, newest first, with their actions; Do Not Disturb is the switch.
// Click one to open it, right-click to dismiss it.
Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  readonly property int count: Notifications.open.length
  // The row whose reply is being written.
  property string replyKey: ""

  Component.onCompleted: Notifications.markSeen()

  Hero {
    icon: Notifications.dnd ? Icons.bellOff : Icons.bell
    title: "Notifications"
    subtitle: Notifications.dnd ? "Do not disturb"
      : (root.count > 0 ? root.count + (root.count === 1 ? " notification" : " notifications") : "All caught up")

    Switch {
      checked: !Notifications.dnd
      onToggled: Notifications.setDnd(!Notifications.dnd)
    }
  }

  Separator {}

  Item {
    width: parent.width
    height: recentTitle.height
    visible: root.count > 0

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
        onClicked: Notifications.dismissAll(Notifications.open)
      }
    }
  }

  Text {
    visible: root.count === 0
    textFormat: Text.PlainText
    text: "No notifications"
    color: Theme.faint
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, 460)
    visible: root.count > 0
    contentHeight: list.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: list
      width: parent.width
      spacing: 6

      Repeater {
        model: ScriptModel { values: Notifications.open }

        RowSurface {
          id: row

          required property var modelData

          width: list.width
          height: content.implicitHeight + strip.implicitHeight
          clip: true
          // A faint tile at rest, so a row's buttons read as part of it
          // and not as the start of the next one.
          color: hovered ? Theme.hoverFill : Theme.normalFill

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (mouse.button === Qt.LeftButton) {
                Notifications.activate(row.modelData)
                BarState.close()
              } else {
                Notifications.dismiss(row.modelData)
              }
            }
          }

          NotificationContent {
            id: content
            width: parent.width
            entry: row.modelData
            showApp: true
            hovered: row.hovered
            iconSize: 32
            padding: 10
            replying: root.replyKey === row.modelData.key
            onReplySent: text => {
              root.replyKey = ""
              Notifications.reply(row.modelData, text)
            }
            onReplyCancelled: root.replyKey = ""
          }

          NotificationActions {
            id: strip
            y: content.height
            width: parent.width
            height: implicitHeight
            entry: row.modelData
            replying: root.replyKey === row.modelData.key
            onReplyRequested: root.replyKey = row.modelData.key
          }
        }
      }
    }
  }
}
