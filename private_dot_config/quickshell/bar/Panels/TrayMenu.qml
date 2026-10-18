import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Common

// A tray app's menu, drawn like Omarchy's rather than as a system menu.
// Submenus open in place, with a row to go back.
Column {
  id: root

  property var item: null

  width: parent ? parent.width : 216

  // One opener per open submenu, innermost last. Each level keeps its own:
  // a submenu's entry belongs to its parent's model.
  property var openers: []
  property var titles: []
  readonly property var opener: openers.length > 0 ? openers[openers.length - 1] : rootOpener
  // The live model, not a snapshot of its values: entries arrive after the
  // menu opens.
  readonly property var entries: opener.children

  function openSubmenu(entry) {
    openers = openers.concat([openerComponent.createObject(root, { menu: entry })])
    titles = titles.concat([entry.text])
  }

  function back() {
    const last = openers[openers.length - 1]
    openers = openers.slice(0, -1)
    titles = titles.slice(0, -1)
    last.destroy()
  }

  Component.onDestruction: {
    for (let i = openers.length - 1; i >= 0; i--) openers[i].destroy()
  }

  QsMenuOpener {
    id: rootOpener
    menu: root.item ? root.item.menu : null
  }

  Component {
    id: openerComponent
    QsMenuOpener {}
  }

  Column {
    width: parent.width
    visible: root.openers.length > 0

    Rectangle {
      width: parent.width
      height: 30
      radius: Theme.radius
      color: backMouse.containsMouse ? Theme.hoverFill : "transparent"

      Text {
        width: 22
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.PlainText
        text: "‹"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.bodySmall
      }

      Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 28
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.titles.length > 0 ? root.titles[root.titles.length - 1] : ""
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.bodySmall
        font.bold: true
        elide: Text.ElideRight
      }

      MouseArea {
        id: backMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.back()
      }
    }

    MenuSeparator {}
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, 420 - (root.openers.length > 0 ? 41 : 0))
    contentHeight: rows.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: rows
      width: parent.width

      Repeater {
        model: root.entries

        Item {
          id: entry

          required property var modelData
          required property int index
          // Apps often start their menu with a separator; drop it.
          readonly property bool hidden: modelData.isSeparator && index === 0

          width: rows.width
          height: hidden ? 0 : (modelData.isSeparator ? 11 : 30)
          visible: !hidden
          opacity: modelData.enabled ? 1 : 0.45

          MenuSeparator {
            visible: entry.modelData.isSeparator
          }

          Rectangle {
            anchors.fill: parent
            visible: !entry.modelData.isSeparator
            radius: Theme.radius
            color: mouse.containsMouse && entry.modelData.enabled ? Theme.hoverFill : "transparent"

            Text {
              width: 22
              anchors.verticalCenter: parent.verticalCenter
              horizontalAlignment: Text.AlignHCenter
              visible: entry.modelData.buttonType !== QsMenuButtonType.None
              textFormat: Text.PlainText
              text: entry.modelData.checkState === Qt.Checked ? Icons.check : ""
              color: Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.bodySmall
            }

            IconImage {
              id: icon
              x: 24
              anchors.verticalCenter: parent.verticalCenter
              implicitSize: 16
              visible: String(entry.modelData.icon || "") !== ""
              source: entry.modelData.icon
            }

            Text {
              anchors.left: parent.left
              anchors.right: submenuGlyph.left
              anchors.leftMargin: icon.visible ? 46 : 28
              anchors.rightMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: entry.modelData.text.replace(/_(?=[^_])/g, "")
              color: Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.bodySmall
              elide: Text.ElideRight
            }

            Text {
              id: submenuGlyph
              anchors.right: parent.right
              anchors.rightMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              visible: entry.modelData.hasChildren
              textFormat: Text.PlainText
              text: "›"
              color: Theme.foreground
              font.family: Theme.fontFamily
              font.pixelSize: Theme.bodySmall
            }

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              enabled: entry.modelData.enabled
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (entry.modelData.hasChildren) {
                  root.openSubmenu(entry.modelData)
                } else {
                  entry.modelData.triggered()
                  BarState.close()
                }
              }
            }
          }
        }
      }
    }
  }

  component MenuSeparator: Item {
    width: parent ? parent.width : 0
    height: 11

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      height: 1
      color: Theme.accent
      opacity: 0.45
    }
  }
}
