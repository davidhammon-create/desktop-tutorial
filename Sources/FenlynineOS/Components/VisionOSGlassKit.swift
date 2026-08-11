import SwiftUI

// MARK: - visionOS Glas-Panels (Referenz: Apple Vision Pro UI)

struct VisionOSGlassPanel<Content: View>: View {
var cornerRadius: CGFloat = AppleUIKitTokens.radiusCard
var padding: CGFloat = 16
var elevated: Bool = true
@ViewBuilder let content: () -> Content

var body: some View {
  content()
    .padding(padding)
    .background { glasHintergrund }
    .shadow(
      color: .black.opacity(elevated ? 0.45 : 0.22),
      radius: elevated ? 28 : 12,
      y: elevated ? 14 : 6
    )
}

@ViewBuilder
private var glasHintergrund: some View {
  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    .fill(.regularMaterial)
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.14),
              Color.white.opacity(0.04),
              Color.black.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
    )
    .overlay(visionOSRimLight(cornerRadius: cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(Color.white.opacity(0.06), lineWidth: 1)
        .blur(radius: 0.5)
    )
}
}

struct VisionOSMilchglasPanel<Content: View>: View {
var cornerRadius: CGFloat = AppleUIKitTokens.radiusCard
var padding: CGFloat = 16
var basisFarbe: Color = FenlynineOSTheme.surface
@ViewBuilder let content: () -> Content

var body: some View {
  content()
    .padding(padding)
    .background {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(basisFarbe.opacity(0.55))
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.thinMaterial.opacity(0.72))
        )
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppleUIKitTokens.rauchglasTint)
        )
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
              LinearGradient(
                colors: [.white.opacity(0.28), .white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 0.8
            )
        )
    }
    .shadow(color: AppleUIKitTokens.shadowSoft, radius: 14, y: 6)
}
}

struct VisionOSPrimaerButton: View {
let titel: String
var symbol: String? = nil
var groesse: ButtonGroesse = .normal
let action: () -> Void
enum ButtonGroesse { case compact, normal, gross }

var body: some View {
  VisionOSGlasButton(titel: titel, symbol: symbol, stil: .primaerBlau, action: action)
}
}

struct VisionOSSekundaerButton: View {
let titel: String
var symbol: String? = nil
let action: () -> Void

var body: some View {
 VisionOSGlasButton(titel: titel, symbol: symbol, stil: .sekundaer, action: action)
}
}

struct VisionOSFloatingRail<Content: View>: View {
@ViewBuilder let content: () -> Content

var body: some View {
 VStack(spacing: 8) {
   content()
 }
 .padding(.vertical, 12)
 .padding(.horizontal, 8)
 .background {
   Capsule()
     .fill(.regularMaterial)
     .overlay(Capsule().fill(Color.white.opacity(0.08)))
     .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.6))
     .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
 }
}
}

typealias FenlynineOSVisionOSAccentProgressBar = VisionOSLeavesProgressBar

// MARK: - Leaves-Fortschritt (PDF: schraffierter Rest)

struct VisionOSLeavesProgressBar: View {
let wert: Double
var hoehe: CGFloat = 8
var farbe: Color = AppleUIKitTokens.systemBlue

var body: some View {
 GeometryReader { geo in
   let anteil = CGFloat(min(max(wert, 0), 100) / 100)
   let fuell = geo.size.width * anteil
   ZStack(alignment: .leading) {
     Capsule()
       .fill(Color.white.opacity(0.06))
     Capsule()
       .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
     SchraffurCapsule()
       .clipShape(Capsule())
     Capsule()
       .fill(
         LinearGradient(
           colors: [farbe, farbe.opacity(0.75)],
           startPoint: .leading,
           endPoint: .trailing
         )
       )
       .frame(width: max(4, fuell))
   }
 }
 .frame(height: hoehe)
}
}

private struct SchraffurCapsule: View {
var body: some View {
 Canvas { context, size in
   let spacing: CGFloat = 5
   var path = Path()
   var x: CGFloat = -size.height
   while x < size.width + size.height {
     path.move(to: CGPoint(x: x, y: size.height))
     path.addLine(to: CGPoint(x: x + size.height, y: 0))
     x += spacing
   }
   context.stroke(path, with: .color(.white.opacity(0.07)), lineWidth: 0.8)
 }
}
}

struct VisionOSAccentProgressBar: View {
let wert: Double
var hoehe: CGFloat = 6

var body: some View {
 GeometryReader { geo in
   ZStack(alignment: .leading) {
     Capsule().fill(Color.white.opacity(0.08))
     Capsule()
       .fill(
         LinearGradient(
           colors: [AppleUIKitTokens.systemBlue, AppleUIKitTokens.systemBlue.opacity(0.7)],
           startPoint: .leading,
           endPoint: .trailing
         )
       )
       .frame(width: geo.size.width * CGFloat(min(max(wert, 0), 100) / 100))
   }
 }
 .frame(height: hoehe)
}
}

