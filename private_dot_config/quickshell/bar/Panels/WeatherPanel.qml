import QtQuick
import Quickshell.Io
import qs.Common
import qs.Ui

// Omarchy's weather popup: now, with feels-like, wind and humidity, and the
// next three days. Clicking the place searches for another.
Column {
  id: root

  width: parent ? parent.width : 348
  spacing: 14

  property bool editing: false
  // [{ name, detail, latitude, longitude, imperial }]
  property var results: []
  property bool searchFailed: false
  readonly property string query: searchField.text.trim()
  // Open to pick a place, or because the IP didn't give one.
  readonly property bool searchShown: editing || Weather.needsPlace
  // Place names in the system's language.
  readonly property string language: {
    const code = Qt.locale().name.split("_")[0]
    return /^[a-z]{2,3}$/.test(code) ? code : "en"
  }
  readonly property string status: {
    if (query.length < 2) return ""
    if (searchDelay.running || geocode.running) return "Searching…"
    if (searchFailed) return "Couldn't reach the place search"
    if (results.length === 0) return "No places found"
    return ""
  }

  function degrees(value) {
    return Math.round(value) + "°"
  }

  function dayName(date) {
    return new Date(date + "T12:00:00").toLocaleDateString(Qt.locale(), "dddd").toUpperCase()
  }

  function search() {
    if (query.length < 2) {
      results = []
      searchFailed = false
      return
    }
    // If the query changes meanwhile, the running search asks again on exit.
    if (geocode.running) return
    geocode.target = query
    geocode.command = ["curl", "-fsS", "--max-time", "10",
      "https://geocoding-api.open-meteo.com/v1/search?count=6&format=json&language=" + language
      + "&name=" + encodeURIComponent(query)]
    geocode.running = true
  }

  function choose(place) {
    Weather.setLocation({ name: place.name, latitude: place.latitude, longitude: place.longitude, imperial: place.imperial })
    editing = false
  }

  Component.onCompleted: Weather.refreshIfStale()

  Timer {
    id: searchDelay
    interval: 300
    onTriggered: root.search()
  }

  Process {
    id: geocode
    // The query this search is for.
    property string target: ""
    stdout: StdioCollector {
      onStreamFinished: {
        // For a query since changed: dropped, and asked again on exit.
        if (geocode.target !== root.query) return
        try {
          root.results = (JSON.parse(text).results || []).map(r => ({
            name: r.name,
            detail: [r.admin1, r.country].filter(part => part && part !== r.name).join(", "),
            latitude: r.latitude,
            longitude: r.longitude,
            imperial: Weather.imperialIn(r.country_code)
          }))
          root.searchFailed = false
        } catch (e) {
          root.results = []
          root.searchFailed = true
        }
      }
    }
    onExited: if (geocode.target !== root.query) root.search()
  }

  Text {
    visible: !Weather.ready
    width: parent.width
    wrapMode: Text.Wrap
    textFormat: Text.PlainText
    text: Weather.needsPlace ? "Your IP address doesn't show your city." : "Fetching forecast…"
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

      // The place, which opens the search for another.
      Rectangle {
        id: placeButton

        readonly property bool hot: placeMouse.containsMouse || root.editing

        // Outset by its padding, so the pin lines up with the readings below.
        x: -6
        width: placeRow.implicitWidth + 12
        height: placeRow.implicitHeight + 6
        visible: Weather.place !== ""
        radius: Theme.radius
        color: hot ? Theme.hoverFill : "transparent"

        Behavior on color { ColorAnimation { duration: 60 } }

        Row {
          id: placeRow
          anchors.centerIn: parent
          spacing: 8

          Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: Icons.pin
            color: placeButton.hot ? Theme.foreground : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySmall
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: Weather.place
            color: placeButton.hot ? Theme.foreground : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySmall
            font.letterSpacing: 1
          }
        }

        MouseArea {
          id: placeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.editing = !root.editing
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

  Separator {
    visible: root.searchShown && Weather.ready
  }

  // Open-Meteo's place search, and the way back to following the IP.
  Column {
    visible: root.searchShown
    width: parent.width
    spacing: 8

    Field {
      id: searchField
      width: parent.width
      placeholderText: "Search for a city"
      onTextChanged: searchDelay.restart()
      onAccepted: if (root.results.length > 0) root.choose(root.results[0])
      // Closes the search; the popup when the search can't be closed.
      Keys.onEscapePressed: event => {
        if (root.editing) root.editing = false
        else event.accepted = false
      }
      // The popup opened on the search (the IP didn't give a place).
      Component.onCompleted: if (root.searchShown) forceActiveFocus()
      onVisibleChanged: if (visible) {
        text = ""
        forceActiveFocus()
      }
    }

    Text {
      visible: text !== ""
      textFormat: Text.PlainText
      text: root.status
      color: root.searchFailed ? Theme.urgent : Theme.faint
      font.family: Theme.fontFamily
      font.pixelSize: Theme.bodySmall
    }

    Column {
      width: parent.width
      spacing: 2

      PlaceRow {
        visible: !Weather.automatic
        glyph: Icons.myLocation
        title: "Use my location"
        detail: "Found by your IP address"
        onPicked: {
          Weather.setLocation(null)
          root.editing = false
        }
      }

      Repeater {
        model: root.results

        PlaceRow {
          required property var modelData

          title: modelData.name
          detail: modelData.detail
          onPicked: root.choose(modelData)
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

  // A place found by the search, or the way back to the IP's.
  component PlaceRow: RowSurface {
    id: row

    property string glyph: Icons.pin
    property string title: ""
    property string detail: ""

    signal picked()

    width: parent ? parent.width : root.width
    height: info.implicitHeight + 12

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: row.picked()
    }

    Text {
      id: icon
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      width: 16
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: row.glyph
      color: Theme.dim
      font.family: Theme.fontFamily
      font.pixelSize: Theme.title
    }

    Column {
      id: info
      anchors.left: icon.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: row.title
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.body
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: row.detail !== ""
        textFormat: Text.PlainText
        text: row.detail
        color: Theme.faint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.caption
        elide: Text.ElideRight
      }
    }
  }
}
