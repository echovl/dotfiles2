import QtQuick
import qs.Common
import qs.Ui

// Pending updates, repositories and AUR, and a button that runs them in a
// terminal.
Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  Hero {
    icon: Icons.updates
    title: "Updates"
    subtitle: Updates.updating ? "Updating…" : (Updates.checking ? "Checking…"
      : (Updates.count > 0 ? Updates.count + " pending" : "Up to date"))

    PillButton {
      visible: Updates.count > 0 && !Updates.updating
      text: "Update"
      fontSize: Theme.body
      verticalPadding: 6
      onClicked: {
        Updates.update()
        BarState.close()
      }
    }
  }

  Separator {
    visible: Updates.count > 0
  }

  Flickable {
    width: parent.width
    height: Math.min(contentHeight, 400)
    visible: Updates.count > 0
    contentHeight: lists.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: lists
      width: parent.width
      spacing: 8

      SectionTitle {
        visible: Updates.repo.length > 0
        text: "REPOSITORIES"
        value: String(Updates.repo.length)
      }

      Repeater {
        model: Updates.repo
        PackageRow {}
      }

      Separator {
        visible: Updates.repo.length > 0 && Updates.aur.length > 0
      }

      SectionTitle {
        visible: Updates.aur.length > 0
        text: "AUR"
        value: String(Updates.aur.length)
      }

      Repeater {
        model: Updates.aur
        PackageRow {}
      }
    }
  }

  component PackageRow: Item {
    required property var modelData

    width: parent ? parent.width : 0
    height: Math.max(name.implicitHeight, version.implicitHeight)

    Text {
      id: name
      anchors.left: parent.left
      anchors.right: version.left
      anchors.rightMargin: 12
      textFormat: Text.PlainText
      text: modelData.name
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.body
      elide: Text.ElideRight
    }

    Text {
      id: version
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.baseline: name.baseline
      width: Math.min(implicitWidth, parent.width * 0.5)
      horizontalAlignment: Text.AlignRight
      textFormat: Text.PlainText
      text: modelData.to
      color: Theme.dim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.bodySmall
      elide: Text.ElideLeft
    }
  }
}
