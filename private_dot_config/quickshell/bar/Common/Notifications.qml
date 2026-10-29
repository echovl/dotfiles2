pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// The notification daemon, in place of dunst: the bar owns
// org.freedesktop.Notifications on the session bus. A notification stays
// (in the panel, with its actions) until it is dismissed or its sender closes
// it; a card on screen is only the first few seconds of it. One the user
// acted on (clicked, ran an action of, replied to) stays in the panel after
// it closes, as history, until it is dismissed there.
Singleton {
  id: root

  // Newest first, with ones whose card is still fading out after they closed.
  property var entries: []
  // The cards on screen and on their way off it, newest first.
  readonly property var toasts: entries.filter(e => e.toast)
  // What the panel lists: the open notifications and the history.
  readonly property var open: entries.filter(e => !e.gone)
  // Held back by Do Not Disturb since the panel was last opened.
  readonly property int unseen: entries.filter(e => e.unseen && !e.gone).length

  readonly property bool dnd: BarState.dnd
  function setDnd(on) {
    BarState.dnd = on
  }

  // The pointer is on the cards, or a reply is being written: their time
  // stands still and new cards wait, so nothing moves under the pointer.
  property bool hovered: false
  property bool replying: false
  readonly property bool held: hovered || replying
  onHeldChanged: if (!held) releaseWaiting()

  // Cards appear on the screen that was focused when the first one came, and
  // stay there until they are all gone rather than jumping between screens.
  property string screenName: ""
  onToastsChanged: {
    if (toasts.length === 0) screenName = ""
    else if (screenName === "" || !Quickshell.screens.some(s => s.name === screenName))
      screenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
  }

  // More cards than this and the oldest go to the panel.
  readonly property int maxToasts: 8
  // More notifications than this and the oldest are closed.
  readonly property int maxEntries: 50

  NotificationServer {
    keepOnReload: true
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    actionsSupported: true
    imageSupported: true
    inlineReplySupported: true
    // dunst's stacking hints, which volume and brightness scripts use to
    // update one notification instead of piling up new ones.
    extraHints: ["x-dunst-stack-tag", "x-canonical-private-synchronous"]
    onNotification: notification => root.admit(notification)
  }

  // Arrival times by notification id, and the history, kept across a config
  // reload (the server hands its open notifications to the new config then).
  // As JSON: a JS object doesn't survive into the new config's engine.
  PersistentProperties {
    id: kept
    reloadableId: "notifications"
    property string times: "{}"
    property string history: "[]"
    // Entry keys stay unique across a reload, history included.
    property int serial: 0
    // Before the server hands back its notifications.
    onLoaded: root.restoreHistory()
  }

  function savedTimes() {
    try {
      return JSON.parse(kept.times) || {}
    } catch (e) {
      return {}
    }
  }

  Component {
    id: entryComponent
    NotificationEntry {}
  }

  function admit(notification) {
    notification.tracked = true
    const restored = notification.lastGeneration
    const hints = notification.hints || {}
    const tag = String(hints["x-dunst-stack-tag"] || hints["x-canonical-private-synchronous"] || "")

    // A stack tag takes over the card with the same tag and app, in place.
    const twin = tag === "" || restored ? null
      : entries.find(e => !e.gone && e.stackTag === tag && e.app === notification.appName)
    if (twin) {
      const old = twin.notification
      twin.notification = notification
      twin.refresh()
      remember(notification.id, Date.now())
      if (old) {
        forget(old.id)
        old.expire()
      }
      present(twin)
      return
    }

    kept.serial += 1
    const entry = entryComponent.createObject(root, {
      key: "n" + kept.serial,
      notification: notification,
      time: savedTimes()[notification.id] || Date.now()
    })
    entry.refresh()
    entry.updated.connect(() => root.present(entry))
    entry.closed.connect(() => root.close(entry))
    remember(notification.id, entry.time)
    // One handed back after a reload goes back among the history in its place.
    entries = restored ? entries.concat(entry).sort((a, b) => b.time - a.time) : [entry].concat(entries)
    if (!restored) present(entry)
    trim()
  }

  function remember(id, time) {
    const times = savedTimes()
    times[id] = time
    kept.times = JSON.stringify(times)
  }

  function forget(id) {
    const times = savedTimes()
    delete times[id]
    kept.times = JSON.stringify(times)
  }

  // A new or updated notification: a card on screen, unless Do Not Disturb
  // holds it back (critical ones get through). An update restarts the
  // card's time, or brings the card back if it had gone.
  function present(entry) {
    if (entry.gone) return
    entry.time = Date.now()
    remember(entry.notification.id, entry.time)
    entry.remaining = entry.timeout
    if (entry.toast) {
      entry.leaving = false
      return
    }
    if (dnd && !entry.critical) {
      // Nobody looks back at a transient one; the rest wait in the panel.
      if (entry.ephemeral) entry.notification.expire()
      else entry.unseen = true
      return
    }
    if (entries[0] !== entry) entries = [entry].concat(entries.filter(e => e !== entry))
    if (held) entry.waiting = true
    else show(entry)
  }

  function show(entry) {
    entry.waiting = false
    entry.leaving = false
    entry.remaining = entry.timeout
    entry.toast = true
    const shown = toasts.filter(e => !e.leaving)
    for (let i = shown.length - 1; i >= maxToasts; i--) hide(shown[i])
  }

  function releaseWaiting() {
    for (let i = entries.length - 1; i >= 0; i--)
      if (entries[i].waiting && !entries[i].gone) show(entries[i])
  }

  // Cards don't wait for the pointer forever.
  Timer {
    interval: 30000
    running: root.held && root.entries.some(e => e.waiting)
    onTriggered: root.releaseWaiting()
  }

  // Takes a card off screen; the notification stays in the panel.
  function hide(entry) {
    if (!entry.toast || entry.leaving) return
    entry.leaving = true
    entry.leftAt = Date.now()
  }

  // Counts the cards' time down and finishes the ones fading out.
  Timer {
    interval: 250
    repeat: true
    running: root.toasts.length > 0
    onTriggered: root.tick(interval)
  }

  function tick(elapsed) {
    const now = Date.now()
    for (const entry of toasts) {
      if (entry.leaving) {
        if (now - entry.leftAt >= 250) finishLeaving(entry)
      } else if (!held && entry.timeout > 0) {
        entry.remaining -= elapsed
        if (entry.remaining <= 0) expire(entry)
      }
    }
  }

  function expire(entry) {
    // Nobody looks back at a transient notification: close it, don't keep it.
    if (entry.ephemeral && entry.notification) entry.notification.expire()
    else hide(entry)
  }

  function finishLeaving(entry) {
    entry.toast = false
    entry.leaving = false
    if (entry.gone) drop(entry)
  }

  // The notification closed, whoever closed it. One the user acted on stays
  // in the panel as history, unless it was transient; a history entry
  // closed here is dismissed.
  function close(entry) {
    if (entry.gone) return
    const notification = entry.notification
    if (notification) forget(notification.id)
    if (notification && entry.acted && !entry.ephemeral) {
      entry.retire()
      entry.unseen = false
      entry.waiting = false
      hide(entry)
    } else {
      entry.gone = true
      entry.unseen = false
      entry.waiting = false
      if (entry.toast) hide(entry)
      else drop(entry)
    }
    saveHistory()
  }

  function drop(entry) {
    entries = entries.filter(e => e !== entry)
    entry.destroy()
  }

  // What a history entry keeps across a config reload.
  readonly property var historyFields: ["key", "time", "timeout", "app", "appIcon", "image", "source", "group",
    "iconNames", "summary", "body", "plainBody", "urgency", "progress", "codes", "senderPid"]

  function saveHistory() {
    kept.history = JSON.stringify(entries.filter(e => e.history && !e.gone).map(e => {
      const fields = {}
      for (const name of historyFields) fields[name] = e[name]
      return fields
    }))
  }

  function restoreHistory() {
    let saved = []
    try {
      saved = JSON.parse(kept.history) || []
    } catch (e) {}
    const restored = saved.map(fields => entryComponent.createObject(root, Object.assign({ acted: true, history: true }, fields)))
    entries = entries.concat(restored).sort((a, b) => b.time - a.time)
  }

  // More than maxEntries, history included: the oldest are closed for good.
  function trim() {
    const live = open
    for (let i = live.length - 1; i >= maxEntries; i--) {
      live[i].acted = false
      if (live[i].notification) live[i].notification.expire()
      else close(live[i])
    }
  }

  // Closed for good: nothing of it stays in the panel.
  function dismiss(entry) {
    entry.acted = false
    if (entry.notification) entry.notification.dismiss()
    else close(entry)
  }

  function dismissAll(list) {
    for (const entry of list.slice()) dismiss(entry)
  }

  // A click on a notification: the sender's window comes forward and gets
  // the default action; without one, the click just closes it. Either way
  // it stays in the panel as history.
  function activate(entry) {
    if (entry.gone) return
    focusSender(entry)
    const notification = entry.notification
    if (!notification) {
      hide(entry)
      return
    }
    entry.acted = true
    if (entry.hasDefault) invoke(entry, "default")
    else notification.dismiss()
  }

  function invoke(entry, id) {
    const notification = entry.notification
    if (!notification) return
    entry.acted = true
    for (let i = 0; i < notification.actions.length; i++) {
      if (notification.actions[i].identifier === id) {
        notification.actions[i].invoke()
        break
      }
    }
    // A resident notification stays open after an action; its card goes.
    if (!entry.gone) hide(entry)
  }

  function reply(entry, text) {
    const notification = entry.notification
    if (!notification || !entry.canReply || text === "") return
    entry.acted = true
    notification.sendInlineReply(text)
    if (!entry.gone) hide(entry)
  }

  // Kept out of clipboard history: these are mostly one-time codes.
  function copy(text) {
    Quickshell.execDetached(["wl-copy", "--sensitive", "--", text])
  }

  // Brings the newest notification that has no card back on screen.
  function restore() {
    const entry = open.find(e => !e.toast)
    if (!entry) return
    entry.unseen = false
    entries = [entry].concat(entries.filter(e => e !== entry))
    show(entry)
  }

  function markSeen() {
    for (const entry of entries) entry.unseen = false
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // "now", "5m", "2h", "3d".
  function ago(time) {
    const seconds = Math.max(0, (clock.date.getTime() - time) / 1000)
    if (seconds < 60) return "now"
    if (seconds < 3600) return Math.floor(seconds / 60) + "m"
    if (seconds < 86400) return Math.floor(seconds / 3600) + "h"
    return Math.floor(seconds / 86400) + "d"
  }

  // The sender's own window if it has one (by pid), else the most recently
  // used window whose class is one of the app's names.
  property var focusWanted: null

  function focusSender(entry) {
    if (windows.running) return
    focusWanted = { pid: entry.senderPid, names: entry.iconNames.map(name => name.toLowerCase()) }
    windows.running = true
  }

  function pickWindow(clients, wanted) {
    const valid = clients.filter(c => /^0x[0-9a-f]+$/i.test(String(c.address)))
    const own = wanted.pid > 0 ? valid.find(c => c.pid === wanted.pid) : null
    if (own) return own.address
    const named = valid.filter(c => wanted.names.includes(String(c.class).toLowerCase())
      || wanted.names.includes(String(c.initialClass).toLowerCase()))
    named.sort((a, b) => a.focusHistoryID - b.focusHistoryID)
    return named.length > 0 ? named[0].address : ""
  }

  Process {
    id: windows
    command: ["hyprctl", "-j", "clients"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const address = root.pickWindow(JSON.parse(text), root.focusWanted)
          if (address) Hyprland.dispatch('hl.dsp.focus({ window = "address:' + address + '" })')
        } catch (e) {}
      }
    }
  }

  // `qs -c bar ipc call notifications dismiss`, for keybindings and scripts.
  IpcHandler {
    target: "notifications"

    readonly property bool dnd: root.dnd
    readonly property int count: root.open.length

    function toggleDnd(): void {
      root.setDnd(!root.dnd)
    }

    function setDnd(on: bool): void {
      root.setDnd(on)
    }

    // The newest card on screen: dismiss it, or click it.
    function dismiss(): void {
      const entry = root.toasts.find(e => !e.leaving)
      if (entry) root.dismiss(entry)
    }

    function invoke(): void {
      const entry = root.toasts.find(e => !e.leaving)
      if (entry) root.activate(entry)
    }

    // Every card on screen; `clear` also empties the panel.
    function dismissAll(): void {
      root.dismissAll(root.toasts.filter(e => !e.leaving))
    }

    function clear(): void {
      root.dismissAll(root.open)
    }

    // The newest notification without a card gets one again.
    function restore(): void {
      root.restore()
    }
  }
}
