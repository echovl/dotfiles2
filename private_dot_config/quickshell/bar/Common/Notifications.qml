pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// dunst's Do Not Disturb state and notification history, through dunstctl.
Singleton {
  id: root

  property bool paused: false
  // Arrived while paused, shown when notifications resume.
  property int waiting: 0
  property int historyCount: 0
  // Newest first: [{ id, app, summary, body, age }], age in seconds.
  property var history: []

  function refresh() {
    if (!state.running) state.running = true
  }

  function refreshHistory() {
    if (!historyProc.running) historyProc.running = true
  }

  function run(args) {
    if (action.running) return
    action.command = ["dunstctl"].concat(args)
    action.running = true
  }

  function setPaused(value) { run(["set-paused", value ? "true" : "false"]) }
  function remove(id) { run(["history-rm", String(id)]) }
  function clear() { run(["history-clear"]) }

  Process {
    id: state
    command: ["sh", "-c", "dunstctl is-paused; dunstctl count waiting; dunstctl count history"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n")
        if (lines.length < 3) return
        root.paused = lines[0] === "true"
        root.waiting = parseInt(lines[1]) || 0
        const count = parseInt(lines[2]) || 0
        if (count !== root.historyCount) root.refreshHistory()
        root.historyCount = count
      }
    }
  }

  // dunst stamps notifications with the time since boot, in microseconds.
  Process {
    id: historyProc
    command: ["sh", "-c", "cut -d' ' -f1 /proc/uptime; dunstctl history"]
    stdout: StdioCollector {
      onStreamFinished: {
        const split = text.indexOf("\n")
        if (split < 0) return
        try {
          const uptime = Number(text.slice(0, split))
          const entries = JSON.parse(text.slice(split + 1)).data[0] || []
          root.history = entries.map(n => ({
            id: n.id.data,
            app: n.appname.data,
            summary: n.summary.data,
            body: String(n.body.data).replace(/<[^>]*>/g, ""),
            age: Math.max(0, uptime - n.timestamp.data / 1000000)
          }))
        } catch (e) {}
      }
    }
  }

  Process {
    id: action
    onExited: {
      root.refresh()
      root.refreshHistory()
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
