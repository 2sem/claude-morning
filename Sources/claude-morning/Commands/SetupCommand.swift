import ArgumentParser
@preconcurrency import Foundation

struct SetupCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "setup",
		abstract: "Add the current directory as a project"
	)

	func run() async throws {
		let currentPath = FileManager.default.currentDirectoryPath
		let defaultName = URL(fileURLWithPath: currentPath).lastPathComponent

		print("\nAdding project at: \(currentPath)\n")

		let name = ask("Project name [\(defaultName)]: ", default: defaultName)
		let prompt = ask("Prompt [what's next?]: ", default: "what's next?")

		// Load existing config or create new one
		var config: Config
		let isFirstProject: Bool
		if let existing = try? Config.load() {
			config = existing
			isFirstProject = false
		} else {
			config = Config(scheduledTime: "09:00", projects: [])
			isFirstProject = true
		}

		// Message provider
		let provider: MessageProvider
		if !config.projects.isEmpty, let lastProvider = config.projects.last?.messageProvider {
			let reuse = ask("Reuse message provider from \(config.projects.last!.name)? [Y/n]: ", default: "Y")
			if reuse.uppercased() == "Y" {
				provider = lastProvider
			} else {
				provider = try askProvider()
			}
		} else {
			provider = try askProvider()
		}

		let project = Project(name: name, path: currentPath, prompt: prompt, messageProvider: provider)
		config.projects.append(project)

		// If first project, ask for scheduled time
		if isFirstProject {
			let timeStr = ask("Briefing time [09:00]: ", default: "09:00")
			config.scheduledTime = timeStr
		}

		try config.save()
		print("\n✓ Project '\(name)' added to \(Config.configURL.path)")

		if isFirstProject {
			try installLaunchAgent(scheduledTime: config.scheduledTime)
			print("""

			Setup complete!
			  Config:      \(Config.configURL.path)
			  LaunchAgent: ~/Library/LaunchAgents/com.leesam.claude-morning.plist
			  Scheduled:   \(config.scheduledTime) daily (and on boot if after \(config.scheduledTime))

			To test now: claude-morning run --force
			""")
		}
	}

	private func ask(_ prompt: String, default defaultValue: String) -> String {
		print(prompt, terminator: "")
		let input = readLine(strippingNewline: true) ?? ""
		return input.isEmpty ? defaultValue : input
	}

	private func askProvider() throws -> MessageProvider {
		print("Message provider (slack / discord) [slack]: ", terminator: "")
		let type_ = readLine(strippingNewline: true)?.lowercased() ?? "slack"
		print("Webhook URL: ", terminator: "")
		let webhook = readLine(strippingNewline: true) ?? ""
		switch type_ {
		case "discord": return .discord(.init(webhook: webhook))
		default: return .slack(.init(webhook: webhook))
		}
	}

	private func installLaunchAgent(scheduledTime: String) throws {
		let parts = scheduledTime.split(separator: ":").compactMap { Int($0) }
		let hour = parts.count > 0 ? parts[0] : 9
		let minute = parts.count > 1 ? parts[1] : 0

		let executablePath = CommandLine.arguments[0]
		let launchAgentsURL = FileManager.default.homeDirectoryForCurrentUser
			.appendingPathComponent("Library/LaunchAgents")
		try FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)

		let plistURL = launchAgentsURL.appendingPathComponent("com.leesam.claude-morning.plist")
		try plistContent(executablePath: executablePath, hour: hour, minute: minute)
			.write(to: plistURL, atomically: true, encoding: .utf8)

		let load = Process()
		load.executableURL = URL(fileURLWithPath: "/bin/launchctl")
		load.arguments = ["load", plistURL.path]
		try load.run()
		load.waitUntilExit()

		print("✓ LaunchAgent installed")
	}

	private func plistContent(executablePath: String, hour: Int, minute: Int) -> String {
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
		    <key>StartCalendarInterval</key>
		    <dict>
		        <key>Hour</key>
		        <integer>\(hour)</integer>
		        <key>Minute</key>
		        <integer>\(minute)</integer>
		    </dict>
		    <key>StandardOutPath</key>
		    <string>/tmp/claude-morning.log</string>
		    <key>StandardErrorPath</key>
		    <string>/tmp/claude-morning-error.log</string>
		</dict>
		</plist>
		"""
	}
}
