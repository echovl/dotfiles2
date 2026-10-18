import QtQuick
import qs.Common
import qs.Ui

// Omarchy's weather popup: now, with feels-like, wind and humidity, and the
// next three days.
Column {
  id: root

  width: parent ? parent.width : 348
  spacing: 14

  function degrees(value) {
    return Math.round(value) + "°"
  }

  function dayName(date) {
    return new Date(date + "T12:00:00").toLocaleDateString(Qt.locale(), "dddd").toUpperCase()
  }

  Component.onCompleted: Weather.refreshIfStale()

  Text {
    visible: !Weather.ready
    textFormat: Text.PlainText
    text: "Fetching forecast…"
    color: Theme.faint
    font.family: Theme.fontFamily
    font.pixelSize: Theme.bodySmall
  }

  Item {
    visible: Weather.ready
    width: parent.width
    height: Math.max(now.height, details.height)

    Row {
      id: now
      anchors.verticalCenter: parent.verticalCenter
      spacing: 10

      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: Weather.icon
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 44
      }

      // The unit tucked against the top of the number.
      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
          id: temperature
          textFormat: Text.PlainText
          text: Weather.ready ? Math.round(Weather.current.temp) : ""
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: 40
          font.bold: true
        }

        Text {
          y: 4
          textFormat: Text.PlainText
          text: Weather.unit
          color: Theme.foreground
          font.family: Theme.fontFamily
          font.pixelSize: Theme.heading
        }
      }
    }

    Column {
      id: details
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      Row {
        spacing: 8
        visible: Weather.place !== ""

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: Icons.pin
          color: Theme.dim
          font.family: Theme.fontFamily
          font.pixelSize: Theme.bodySmall
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: Weather.place
          color: Theme.dim
          font.family: Theme.fontFamily
          font.pixelSize: Theme.bodySmall
          font.letterSpacing: 1
        }
      }

      Row {
        spacing: 16

        Reading {
          label: "FEELS"
          value: Weather.ready ? root.degrees(Weather.current.feels) + Weather.unit.slice(1) : ""
        }

        Reading {
          label: "WIND"
          value: Weather.ready ? Math.round(Weather.current.wind) + " " + Weather.windUnit : ""
        }

        Reading {
          label: "HUMID"
          value: Weather.ready ? Math.round(Weather.current.humidity) + "%" : ""
        }
      }
    }
  }

  Separator {
    visible: Weather.days.length > 0
  }

  Row {
    id: forecast
    visible: Weather.days.length > 0
    width: parent.width

    Repeater {
      model: Weather.days

      Item {
        required property var modelData

        width: forecast.width / Math.max(1, Weather.days.length)
        height: dayRow.height

        Row {
          id: dayRow
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8

          Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: Icons.weather(modelData.code, false)
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 20
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              textFormat: Text.PlainText
              text: root.dayName(modelData.date)
              color: Theme.dim
              font.family: Theme.fontFamily
              font.pixelSize: Theme.caption
              font.bold: true
              font.letterSpacing: 1.2
            }

            Row {
              spacing: 6

              Text {
                textFormat: Text.PlainText
                text: root.degrees(modelData.max)
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.body
              }

              Text {
                textFormat: Text.PlainText
                text: root.degrees(modelData.min)
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.body
              }
            }
          }
        }
      }
    }
  }

  component Reading: Column {
    property string label: ""
    property string value: ""
    spacing: 4

    Text {
      textFormat: Text.PlainText
      text: parent.label
      color: Theme.dim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.caption
      font.bold: true
      font.letterSpacing: 1.2
    }

    Text {
      textFormat: Text.PlainText
      text: parent.value
      color: Theme.foreground
      font.family: Theme.fontFamily
      font.pixelSize: Theme.title
    }
  }
}
