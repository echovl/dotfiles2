import QtQuick
import Quickshell.Services.UPower
import qs.Common
import qs.Ui

Column {
  id: root

  width: parent ? parent.width : Theme.popupWidth
  spacing: 14

  readonly property var device: Devices.battery
  readonly property var profiles: PowerProfiles.hasPerformanceProfile
    ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
    : [PowerProfile.PowerSaver, PowerProfile.Balanced]

  function duration(seconds) {
    if (!(seconds > 0)) return "—"
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.round((seconds % 3600) / 60)
    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`
  }

  function profileGlyph(profile) {
    if (profile === PowerProfile.PowerSaver) return Icons.powerSaver
    if (profile === PowerProfile.Performance) return Icons.performance
    return Icons.balanced
  }

  function profileName(profile) {
    if (profile === PowerProfile.PowerSaver) return "Power-saver"
    if (profile === PowerProfile.Performance) return "Performance"
    return "Balanced"
  }

  Component.onCompleted: Devices.refreshBattery()

  Hero {
    icon: Devices.batteryIcon
    title: "Battery"
    subtitle: Devices.fullyCharged ? "Fully charged" : (Devices.discharging ? "On battery" : "Charging")
    phrases: Devices.fullyCharged ? [] : (Devices.charging
      ? ["Pumping power", "Injecting electrons", "Pouring juice", "Amassing watts", "Hoarding joules",
        "Sucking volts", "Topping reserves", "Soaking amps", "Inhaling kilowatts"]
      : (Devices.discharging
        ? ["Slurping power", "Spending joules", "Draining watts", "Burning electrons", "Sipping juice",
          "Spending coulombs", "Bleeding amps", "Guzzling volts", "Munching reserves"]
        : []))
    labelGap: 10

    Text {
      textFormat: Text.PlainText
      text: Math.round(Devices.batteryFraction * 100) + "%"
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.displayLarge
      font.bold: true
    }
  }

  Item {
    width: parent.width
    height: 8

    Rectangle {
      id: track
      anchors.fill: parent
      radius: height / 2
      color: Theme.divider
    }

    Rectangle {
      height: parent.height
      radius: track.radius
      width: Math.max(height, parent.width * Devices.batteryFraction)
      color: Theme.foreground

      Behavior on width {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
      }

      // Breathes while charging.
      SequentialAnimation on opacity {
        running: Devices.charging
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation { from: 1; to: 0.55; duration: 950; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.55; to: 1; duration: 950; easing.type: Easing.InOutSine }
      }
    }
  }

  Row {
    width: parent.width
    spacing: 20

    Column {
      width: (parent.width - parent.spacing) / 2
      spacing: 4

      InfoPair {
        label: "Battery size"
        value: root.device && root.device.energyCapacity > 0 ? Math.round(root.device.energyCapacity) + "Wh" : "—"
      }

      InfoPair {
        label: "Charge cycles"
        value: Devices.batteryCycles >= 0 ? String(Devices.batteryCycles) : "—"
      }
    }

    Column {
      width: (parent.width - parent.spacing) / 2
      spacing: 4

      InfoPair {
        label: Devices.discharging ? "Time left" : "Time to full"
        value: Devices.fullyCharged ? "-" : root.duration(Devices.discharging ? root.device.timeToEmpty : root.device.timeToFull)
      }

      InfoPair {
        label: Devices.discharging ? "Discharging" : "Charging"
        value: Devices.fullyCharged || !root.device ? "-" : Math.abs(root.device.changeRate).toFixed(1) + "W"
      }
    }
  }

  Separator {}

  Column {
    width: parent.width
    spacing: 10

    SectionTitle {
      text: "POWER PROFILE"
    }

    Row {
      id: profileRow
      width: parent.width
      spacing: 6

      Repeater {
        model: root.profiles

        PillButton {
          required property int modelData

          width: (profileRow.width - profileRow.spacing * (root.profiles.length - 1)) / root.profiles.length
          glyph: root.profileGlyph(modelData)
          text: root.profileName(modelData)
          active: PowerProfiles.profile === modelData
          onClicked: PowerProfiles.profile = modelData
        }
      }
    }
  }
}
