// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "claude-morning",
	platforms: [.macOS(.v13)],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
	],
	targets: [
		.executableTarget(
			name: "claude-morning",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			],
			path: "Sources/claude-morning"
		),
	]
)
