import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.Common
import qs.Ui

// App tray icons in a drawer behind a chevron, sliding open while the pointer
// is over it (or one of its menus is open), as Omarchy's does. Hidden when no
// app has an icon in the tray.
Item {
  id: root

  property color color: Theme.foreground
  property bool holdOpen: false
  signal menuRequested(var item, Item anchor)

  readonly property var items: SystemTray.items.values.filter(item => item.status !== Status.Passive)
  readonly property real drawerWidth: items.length * Theme.iconSlot
  property real reveal: hover.hovered || holdOpen ? 1 : 0

  Behavior on reveal {
    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
  }

  visible: items.length > 0
  implicitWidth: visible ? Theme.iconSlot + drawerWidth * reveal : 0
  implicitHeight: Theme.barHeight

  HoverHandler {
    id: hover
  }

  BarButton {
    id: chevron
    glyph: Icons.trayExpand
    color: root.color
  }

  Item {
    x: chevron.width
    width: root.drawerWidth * root.reveal
    height: parent.height
    clip: true

    Row {
      Repeater {
        model: root.items

        Item {
          id: entry

          required property var modelData

          width: Theme.iconSlot
          height: Theme.barHeight

          IconImage {
            anchors.centerIn: parent
            implicitSize: Theme.iconSize
            source: entry.modelData.icon
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (mouse.button === Qt.MiddleButton) entry.modelData.secondaryActivate()
              else if (mouse.button === Qt.RightButton || entry.modelData.onlyMenu) {
                if (entry.modelData.hasMenu) root.menuRequested(entry.modelData, entry)
              } else entry.modelData.activate()
            }
            onWheel: wheel => entry.modelData.scroll(wheel.angleDelta.y, false)
          }
        }
      }
    }
  }
}
