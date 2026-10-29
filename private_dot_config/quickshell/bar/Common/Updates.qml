pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Pending package updates: repositories through checkupdates (pacman-contrib),
// AUR through paru when it's installed. Checked every two hours and after
// every pacman transaction, however it was run.
Singleton {
  id: root

  // [{ name, from, to }]
  property var repo: []
  property var aur: []
  property bool checking: false
  property bool updating: false
  // A check was asked for while one was running; run another once it ends.
  property bool recheck: false

  readonly property int count: repo.length + aur.length

  function parse(text) {
    return text.trim().split("\n").filter(line => line.includes("->")).map(line => {
      const parts = line.trim().split(/\s+/)
      return { name: parts[0], from: parts[1], to: parts[3] }
    })
  }

  function check() {
    if (updating) return
    if (checking) {
      recheck = true
      return
    }
    checking = true
    repoProc.running = true
  }

  // Runs the update in a terminal; the list refreshes when it closes.
  function update() {
    if (updating) return
    updating = true
    updateProc.running = true
  }

  Process {
    id: repoProc
    command: ["checkupdates"]
    stdout: StdioCollector {
      onStreamFinished: root.repo = root.parse(text)
    }
    onExited: aurProc.running = true
  }

  Process {
    id: aurProc
    command: ["sh", "-c", "command -v paru >/dev/null && paru -Qua 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: root.aur = root.parse(text)
    }
    onExited: {
      root.checking = false
      if (root.recheck) {
        root.recheck = false
        root.check()
      }
    }
  }

  Process {
    id: updateProc
    command: ["alacritty", "-e", "bash", "-c",
      "if command -v paru >/dev/null; then paru -Syu; else sudo pacman -Syu; fi; echo; read -rsn1 -p 'Done. Press any key to close.'"]
    onExited: {
      root.updating = false
      root.check()
    }
  }

  // pacman writes its log on every install, upgrade and removal, so upgrades
  // made in a terminal or by another helper clear the list too. Only the
  // change notifications are needed, not the text.
  FileView {
    path: "/var/log/pacman.log"
    preload: false
    watchChanges: true
    onFileChanged: settle.restart()
  }

  // Waits for the log to go quiet, so a transaction isn't checked halfway.
  Timer {
    id: settle
    interval: 5000
    onTriggered: root.check()
  }

  Timer {
    interval: 2 * 60 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.check()
  }
}
