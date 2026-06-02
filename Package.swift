// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AgentSupervisor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AgentSupervisor", targets: ["AgentSupervisor"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "AgentSupervisor",
            dependencies: ["SwiftTerm"],
            path: "Sources/AgentSupervisor"
        )
    ]
)
