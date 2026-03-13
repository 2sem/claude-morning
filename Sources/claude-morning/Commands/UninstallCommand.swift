import ArgumentParser
@preconcurrency import Foundation

struct UninstallCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "uninstall",
		abstract: "Remove the LaunchAgent and all config files"
	)

	func run() async throws {
		let plistURL = FileManager.default.homeDirectoryForCurrentUser
			.appendingPathComponent("Library/LaunchAgents/com.leesam.claude-morning.plist")

		if FileManager.default.fileExists(atPath: plistURL.path) {
			let unload = Process()
			unload.executableURL = URL(fileURLWithPath: "/bin/launchctl")
			unload.arguments = ["unload", plistURL.path]
			try unload.run()
			unload.waitUntilExit()

			try FileManager.default.removeItem(at: plistURL)
			print("✓ LaunchAgent removed")
		} else {
			print("LaunchAgent not installed, skipping")
		}

		if FileManager.default.fileExists(atPath: Config.configDir.path) {
			try FileManager.default.removeItem(at: Config.configDir)
			print("✓ Config directory removed (\(Config.configDir.path))")
		} else {
			print("Config directory not found, skipping")
		}

		print("\nUninstalled successfully.")
	}
}
