pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Current weather and the next three days, from Open-Meteo, for the place
// picked in the weather popup or, until one is, where GeoJS places you by
// your IP. Refreshed every 20 minutes.
Singleton {
  id: root

  // { name, latitude, longitude, imperial }: the place picked in the popup
  // (null while following the IP) and the one GeoJS found.
  readonly property var chosen: BarState.weatherLocation
  property var located: null
  // GeoJS answered, but only roughly (the country, or wider than a city):
  // rather than show the weather somewhere else, the popup asks for a place.
  property bool imprecise: false
  readonly property bool needsPlace: automatic && imprecise
  readonly property var location: chosen || located
  readonly property bool automatic: !chosen
  readonly property string place: location ? location.name : ""
  readonly property bool imperial: location ? location.imperial : false
  // What the forecast is fetched for: the place and its units.
  readonly property string key: location
    ? location.latitude + "," + location.longitude + (imperial ? ",imperial" : "") : ""
  // { temp, feels, wind, humidity, code, day }
  property var current: null
  // [{ date, code, max, min }]
  property var days: []
  property real updatedAt: 0

  readonly property bool ready: current !== null
  readonly property string icon: ready ? Icons.weather(current.code, !current.day) : ""
  readonly property string unit: imperial ? "°F" : "°C"
  readonly property string windUnit: imperial ? "mph" : "km/h"

  // A place from the popup's search, or null to follow the IP again (looked
  // up afresh, in case you've moved since).
  function setLocation(place) {
    if (!place) located = null
    BarState.weatherLocation = place
  }

  // Countries that use Fahrenheit and mph.
  function imperialIn(countryCode) {
    return ["US", "LR", "MM"].includes(countryCode)
  }

  // Another place (picked, loaded from the settings, or found after moving):
  // drop the old one's forecast and fetch its own.
  onKeyChanged: {
    current = null
    days = []
    updatedAt = 0
    refresh()
  }

  function refresh() {
    if (!location) {
      if (!locate.running) locate.running = true
      return
    }
    // If the place changes meanwhile, the running request asks again on exit.
    if (forecast.running) return
    forecast.target = key
    forecast.command = ["curl", "-fsS", "--max-time", "10",
      "https://api.open-meteo.com/v1/forecast?latitude=" + location.latitude + "&longitude=" + location.longitude
      + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
      + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=4"
      + (imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "")]
    forecast.running = true
  }

  function refreshIfStale() {
    if (Date.now() - updatedAt > 10 * 60 * 1000) refresh()
  }

  Process {
    id: locate
    command: ["curl", "-fsS", "--max-time", "10", "https://get.geojs.io/v1/ip/geo.json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const geo = JSON.parse(text)
          // accuracy: the radius, in km, the IP is likely within.
          root.imprecise = !geo.city || !(geo.accuracy <= 50)
          root.located = root.imprecise ? null : {
            name: geo.city,
            latitude: Number(geo.latitude),
            longitude: Number(geo.longitude),
            imperial: root.imperialIn(geo.country_code)
          }
        } catch (e) {
          retry.start()
        }
      }
    }
  }

  Process {
    id: forecast
    // The key of the place this request is for.
    property string target: ""
    stdout: StdioCollector {
      onStreamFinished: {
        // For a place since replaced: dropped, and asked again on exit.
        if (forecast.target !== root.key) return
        try {
          const json = JSON.parse(text)
          const c = json.current
          root.current = {
            temp: c.temperature_2m, feels: c.apparent_temperature, wind: c.wind_speed_10m,
            humidity: c.relative_humidity_2m, code: c.weather_code, day: c.is_day === 1
          }
          const d = json.daily
          root.days = d.time.slice(1, 4).map((date, i) => ({
            date: date, code: d.weather_code[i + 1], max: d.temperature_2m_max[i + 1], min: d.temperature_2m_min[i + 1]
          }))
          root.updatedAt = Date.now()
        } catch (e) {
          retry.start()
        }
      }
    }
    onExited: if (forecast.target !== root.key) root.refresh()
  }

  // Offline or a failed request: try again in a minute.
  Timer {
    id: retry
    interval: 60 * 1000
    onTriggered: root.refresh()
  }

  Timer {
    interval: 20 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // Look up the IP location again every few hours, in case you've moved.
  Timer {
    interval: 3 * 60 * 60 * 1000
    running: root.automatic
    repeat: true
    onTriggered: if (!locate.running) locate.running = true
  }
}
