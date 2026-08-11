// swift-tools-version: 5.9
import PackageDescription

let package = Package(
name: "FenlynineOS",
platforms: [
  .macOS(.v14)
],
products: [
  .executable(name: "FenlynineOS", targets: ["FenlynineOS"])
],
dependencies: [],
targets: [
  .executableTarget(
    name: "FenlynineOS",
    path: "Sources/FenlynineOS",
    resources: [
      .process("Resources")
    ],
    swiftSettings: [
      .unsafeFlags(["-parse-as-library"])
    ]
  )
]
)

