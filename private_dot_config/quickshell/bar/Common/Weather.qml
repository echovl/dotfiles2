pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Current weather and the next three days. wttr.in places you by your IP, as
// Omarchy does; Open-Meteo gives the forecast. Refreshed every 20 minutes.
Singleton {
  id: root

  property string place: ""
  property real latitude: NaN
  property real longitude: NaN
  property bool imperial: false
  // { temp, feels, wind, humidity, code, day }
  property var current: null
  // [{ date, code, max, min }]
  property var days: []
  property real updatedAt: 0

  readonly property bool ready: current !== null
  readonly property string icon: ready ? Icons.weather(current.code, !current.day) : ""
  readonly property string unit: imperial ? "°F" : "°C"
  readonly property string windUnit: imperial ? "mph" : "km/h"

  function refresh() {
    if (isNaN(latitude)) {
      if (!locate.running) locate.running = true
      return
    }
    if (forecast.running) return
    forecast.command = ["curl", "-fsS", "--max-time", "10",
      "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
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
    command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/?format=j1"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const area = JSON.parse(text).nearest_area[0]
          root.place = area.areaName[0].value
          root.latitude = Number(area.latitude)
          root.longitude = Number(area.longitude)
          root.imperial = ["United States of America", "Liberia", "Myanmar"].includes(area.country[0].value)
          root.refresh()
        } catch (e) {
          retry.start()
        }
      }
    }
  }

  Process {
    id: forecast
    stdout: StdioCollector {
      onStreamFinished: {
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

  // Look up the location again every few hours, in case you've moved.
  Timer {
    interval: 3 * 60 * 60 * 1000
    running: true
    repeat: true
    onTriggered: {
      root.latitude = NaN
      root.refresh()
    }
  }
}
