import QtQuick
import qs.Common

// An icon glyph scaled so its ink is `size` px on its longer side and centered
// by its ink rather than its font box, so every bar icon reads the same size
// (Omarchy's OpticalGlyph).
Item {
  id: root

  property string text: ""
  property real fontSize: Theme.iconFont
  property real size: Theme.iconSize
  property color color: Theme.foreground

  readonly property real inkWidth: Math.max(1, metrics.tightBoundingRect.width)
  readonly property real inkHeight: Math.max(1, metrics.tightBoundingRect.height)
  readonly property real inkScale: Math.min(size, width, height) / Math.max(inkWidth, inkHeight)

  TextMetrics {
    id: metrics
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(root.fontSize)
    text: root.text
  }

  Text {
    textFormat: Text.PlainText
    text: root.text
    color: root.color
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(root.fontSize)
    renderType: Text.CurveRendering
    transformOrigin: Item.TopLeft
    scale: root.inkScale
    x: root.width / 2 - (metrics.tightBoundingRect.x + root.inkWidth / 2) * root.inkScale
    y: root.height / 2 - (baselineOffset + metrics.tightBoundingRect.y + root.inkHeight / 2) * root.inkScale
  }
}
