import ArgumentParser
@preconcurrency import Foundation

struct RunCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "run",
		abstract: "Run morning briefing for all projects"
	)

	@Flag(name: .long, help: "Skip scheduling checks and run immediately")
	var force = false

	func run() async throws {
		let config: Config
		do {
			config = try Config.load()
		} catch {
			throw CLIError.configNotFound
		}

		if !force {
			if alreadyRanToday() {
				print("Already ran today, skipping. Use --force to override.")
				return
			}
			if beforeScheduledTime(config.scheduledTime) {
				print("Before scheduled time (\(config.scheduledTime)), skipping.")
				return
			}
		}

		for project in config.projects {
			print("[\(project.name)] Running Claude…")
			do {
				let output = try await runClaude(project: project)
				print("[\(project.name)] Sending message…")
				let message = "🌅 *Morning Briefing — \(project.name)*\n\n\(output)"
				try await project.messageProvider.send(message)
				print("[\(project.name)] Sent ✓")
			} catch {
				print("[\(project.name)] Error: \(error)")
			}
		}

		saveLastRun()
	}

	private func alreadyRanToday() -> Bool {
		guard let data = try? Data(contentsOf: Config.lastRunURL),
			  let dateStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
		else { return false }
		return dateStr == todayString()
	}

	private func beforeScheduledTime(_ scheduledTime: String) -> Bool {
		let parts = scheduledTime.split(separator: ":").compactMap { Int($0) }
		guard parts.count == 2 else { return false }
		let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
		let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
		let scheduledMinutes = parts[0] * 60 + parts[1]
		return nowMinutes < scheduledMinutes
	}

	private func saveLastRun() {
		try? todayString().data(using: .utf8)?.write(to: Config.lastRunURL, options: .atomic)
	}

	private func todayString() -> String {
		let fmt = DateFormatter()
		fmt.dateFormat = "yyyy-MM-dd"
		return fmt.string(from: Date())
	}

	private func runClaude(project: Project) async throws -> String {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
		process.arguments = ["claude", "-c", "-p", project.prompt]
		process.currentDirectoryURL = URL(fileURLWithPath: project.path)
		let pipe = Pipe()
		process.standardOutput = pipe
		process.standardError = Pipe()
		try process.run()
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		process.waitUntilExit()
		guard process.terminationStatus == 0 else {
			throw CLIError.claudeFailed(status: process.terminationStatus)
		}
		return String(data: data, encoding: .utf8) ?? ""
	}
}
