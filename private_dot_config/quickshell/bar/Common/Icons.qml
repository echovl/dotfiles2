pragma Singleton
import Quickshell

// The Nerd Font glyphs Omarchy's shell draws.
Singleton {
  function g(codePoint) {
    return String.fromCodePoint(codePoint)
  }

  readonly property string speakerMuted: g(0xEEE8)
  readonly property string speakerLow: g(0xF026)
  readonly property string speakerMid: g(0xF027)
  readonly property string speakerHigh: g(0xF028)
  readonly property string headphones: g(0xF02CB)
  readonly property string speaker: g(0xF04C3)
  readonly property string mic: g(0xF036C)
  readonly property string micMuted: g(0xF036D)
  readonly property string webcam: g(0xF0100)

  readonly property string bluetooth: g(0xF00AF)
  readonly property string bluetoothConnected: g(0xF00B1)
  readonly property string bluetoothOff: g(0xF00B2)
  readonly property string forget: g(0xF0159)

  readonly property var wifi: [g(0xF092F), g(0xF091F), g(0xF0922), g(0xF0925), g(0xF0928)]
  readonly property string wifiLimited: g(0xF0929)
  readonly property string wifiOff: g(0xF092E)
  readonly property string ethernet: g(0xF0200)
  readonly property string lock: g(0xF033E)

  readonly property string monitor: g(0xF0379)

  readonly property var battery: [0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079].map(g)
  readonly property var batteryCharging: [0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D, 0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085].map(g)
  readonly property string batteryFull: g(0xF0085)
  readonly property string powerSaver: g(0xF032A)
  readonly property string balanced: g(0xF029A)
  readonly property string performance: g(0xF04C5)

  readonly property string calendar: g(0xF00ED)
  readonly property string previous: g(0xF0141)
  readonly property string next: g(0xF0142)

  readonly property string trayExpand: g(0xF053)
  readonly property string check: g(0xF00C)

  readonly property string bell: g(0xF009A)
  readonly property string bellOff: g(0xF009B)
  readonly property string chip: g(0xF035B)
  readonly property string pin: g(0xF041)
  readonly property string updates: g(0xF021)

  readonly property string play: g(0xF040A)
  readonly property string pause: g(0xF03E4)
  readonly property string skipNext: g(0xF04AD)
  readonly property string skipPrevious: g(0xF04AE)
  readonly property string music: g(0xF075A)

  // Open-Meteo weather codes to Weather Icons glyphs, as Omarchy maps them.
  function weather(code, night) {
    if (code === 0) return night ? g(0xE32B) : g(0xE30D)
    if (code === 1 || code === 2) return night ? g(0xE32E) : g(0xE302)
    if (code === 45 || code === 48) return night ? g(0xE346) : g(0xE313)
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].includes(code)) return g(0xE318)
    if ([71, 73, 75, 77, 85, 86].includes(code)) return g(0xE31A)
    if ([95, 96, 99].includes(code)) return g(0xE31D)
    return g(0xE33D)
  }
}
