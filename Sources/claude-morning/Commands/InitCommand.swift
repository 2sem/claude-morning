import ArgumentParser
@preconcurrency import Foundation

struct InitCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "init",
		abstract: "Interactive setup wizard"
	)

	func run() async throws {
		print("Welcome to claude-morning setup!\n")

		let webhook = ask("Slack webhook URL: ")
		let projectPath = ask("Project path (Claude Code project directory): ")

		print("Briefing prompt (press Enter to use default):")
		print("  \(Config.defaultPrompt)")
		let userPrompt = readLine(strippingNewline: true) ?? ""
		let briefingPrompt = userPrompt.isEmpty ? Config.defaultPrompt : userPrompt

		let config = Config(slackWebhook: webhook, projectPath: projectPath, prompt: briefingPrompt)
		try config.save()
		print("\n✓ Config saved to \(Config.configURL.path)")

		try installLaunchAgent()

		print("""

		Setup complete!
		  Config:      \(Config.configURL.path)
		  LaunchAgent: ~/Library/LaunchAgents/com.leesam.claude-morning.plist

		claude-morning will run automatically on next MacBook boot.
		To test now, run: claude-morning run
		""")
	}

	private func ask(_ prompt: String) -> String {
		print(prompt, terminator: "")
		return readLine(strippingNewline: true) ?? ""
	}

	private func installLaunchAgent() throws {
		let executablePath = CommandLine.arguments[0]

		let launchAgentsURL = FileManager.default.homeDirectoryForCurrentUser
			.appendingPathComponent("Library/LaunchAgents")
		try FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)

		let plistURL = launchAgentsURL.appendingPathComponent("com.leesam.claude-morning.plist")
		try plistContent(executablePath: executablePath)
			.write(to: plistURL, atomically: true, encoding: .utf8)

		let load = Process()
		load.executableURL = URL(fileURLWithPath: "/bin/launchctl")
		load.arguments = ["load", plistURL.path]
		try load.run()
		load.waitUntilExit()

		print("✓ LaunchAgent installed")
	}

	private func plistContent(executablePath: String) -> String {
		"""
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
		    <key>Label</key>
		    <string>com.leesam.claude-morning</string>
		    <key>ProgramArguments</key>
		    <array>
		        <string>\(executablePath)</string>
		        <string>run</string>
		    </array>
		    <key>RunAtLoad</key>
		    <true/>
		    <key>StandardOutPath</key>
		    <string>/tmp/claude-morning.log</string>
		    <key>StandardErrorPath</key>
		    <string>/tmp/claude-morning-error.log</string>
		</dict>
		</plist>
		"""
	}
}
