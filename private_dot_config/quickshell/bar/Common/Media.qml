pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player the bar follows: the one playing, or else the last one
// that played, or else any that has a track.
Singleton {
  id: root

  readonly property var players: Mpris.players.values.filter(p => p.trackTitle || p.trackArtist)
  property var chosen: null
  property var lastPlaying: null

  readonly property var player: {
    if (chosen && players.includes(chosen)) return chosen
    const playing = players.find(p => p.isPlaying)
    if (playing) return playing
    if (lastPlaying && players.includes(lastPlaying)) return lastPlaying
    return players.length > 0 ? players[0] : null
  }

  readonly property bool active: player !== null
  readonly property string title: player ? (player.trackTitle || "") : ""
  readonly property string artist: player ? (player.trackArtist || "") : ""

  onPlayerChanged: if (player && player.isPlaying) lastPlaying = player

  // Picking a player in the popup sticks until it goes away.
  function choose(p) {
    chosen = p
  }

  function playPause() {
    if (player && player.canTogglePlaying) player.togglePlaying()
  }

  function next() {
    if (player && player.canGoNext) player.next()
  }

  function previous() {
    if (player && player.canGoPrevious) player.previous()
  }
}
