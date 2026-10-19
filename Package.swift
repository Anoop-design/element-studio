// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ElementStudioAuthoring",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "ElementStudioAuthor", targets: ["ElementStudioAuthor"])],
    targets: [
        .executableTarget(name: "ElementStudioAuthor", path: "NativeAuthoring", exclude: ["README.md"], resources: [.process("Resources")]),
        .testTarget(name: "AuthoringTests", dependencies: ["ElementStudioAuthor"], path: "AuthoringTests")
    ],
    swiftLanguageModes: [.v5]
)
