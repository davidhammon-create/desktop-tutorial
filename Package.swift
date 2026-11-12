// swift-tools-version: 5.9
import PackageDescription

let package = Package(
name: "FenlynineOS",
platforms: [
  .macOS(.v14)
],
products: [
  .executable(name: "FenlynineOS", targets: ["FenlynineOS"]),
  // Die Rechenlogik ist als eigene Bibliothek nutzbar -- auch von Werkzeugen,
  // Skripten und Tests, die keine Oberfläche starten.
  .library(name: "FenlynineOSKern", targets: ["FenlynineOSKern"])
],
dependencies: [],
targets: [
  // Reine Fachlogik: Fristen, Gebühren, Prognose, Nachweis.
  // Bewusst ohne SwiftUI und AppKit -- dadurch testbar und plattformunabhängig.
  .target(
    name: "FenlynineOSKern",
    path: "Sources/FenlynineOSKern"
  ),

  .executableTarget(
    name: "FenlynineOS",
    dependencies: ["FenlynineOSKern"],
    path: "Sources/FenlynineOS",
    resources: [
      .process("Resources")
    ],
    swiftSettings: [
      .unsafeFlags(["-parse-as-library"])
    ]
  ),

  // Prüft die haftungskritischen Berechnungen: Fristen und Gebühren.
  .testTarget(
    name: "FenlynineOSKernTests",
    dependencies: ["FenlynineOSKern"],
    path: "Tests/FenlynineOSKernTests"
  )
]
)
