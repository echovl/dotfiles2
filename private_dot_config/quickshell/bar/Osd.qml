import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common

// Omarchy's volume and brightness overlay: icon, accent bar and percentage,
// low and centered on the focused screen. Clicks pass through it.
PanelWindow {
  id: osd

  required property var modelData
  screen: modelData

  readonly property bool focusedScreen: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === modelData.name
  readonly property bool shown: BarState.osdShown && focusedScreen

  anchors.bottom: true
  margins.bottom: 67
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: card.width
  implicitHeight: card.height
  color: "transparent"
  mask: Region {}
  WlrLayershell.namespace: "qs-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  visible: shown || card.opacity > 0

  readonly property int pad: 16
  readonly property int gap: 16
  readonly property int barWidth: 142
  // Columns sized for the widest icon and "100%", so nothing shifts.
  readonly property int iconWidth: Math.ceil(widestIcon.tightBoundingRect.width)
  readonly property int valueWidth: Math.ceil(widestValue.advanceWidth)

  TextMetrics {
    id: widestIcon
    font.family: Theme.fontFamily
    font.pixelSize: Theme.displayLarge
    text: Icons.speakerHigh
  }

  TextMetrics {
    id: iconInk
    font: widestIcon.font
    text: BarState.osdIcon
  }

  TextMetrics {
    id: widestValue
    font.family: Theme.fontFamily
    font.pixelSize: Theme.title
    font.bold: true
    text: "100%"
  }

  Rectangle {
    id: card

    width: Theme.popupBorder * 2 + osd.pad * 2 + osd.iconWidth + osd.gap + osd.barWidth + osd.gap + osd.valueWidth
    height: Theme.popupBorder * 2 + osd.pad * 2 + Theme.displayLarge
    radius: Theme.radius
    color: Theme.alpha(Theme.background, 0.97)
    border.width: Theme.popupBorder
    border.color: Theme.accent
    opacity: osd.shown ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Row {
      anchors.fill: parent
      anchors.margins: Theme.popupBorder + osd.pad
      spacing: osd.gap

      Item {
        width: osd.iconWidth
        height: parent.height

        Text {
          x: Math.round((osd.iconWidth - iconInk.tightBoundingRect.width) / 2 - iconInk.tightBoundingRect.x)
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: BarState.osdIcon
          font: widestIcon.font
          color: Theme.foreground
        }
      }

      Rectangle {
        width: osd.barWidth
        height: 6
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.alpha(Theme.foreground, 0.45)

        Rectangle {
          height: parent.height
          width: parent.width * BarState.osdPercent / 100
          color: Theme.accent

          Behavior on width {
            enabled: osd.shown
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
          }
        }
      }

      Text {
        width: osd.valueWidth
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        textFormat: Text.PlainText
        text: BarState.osdPercent + "%"
        font: widestValue.font
        color: Theme.foreground
      }
    }
  }
}
