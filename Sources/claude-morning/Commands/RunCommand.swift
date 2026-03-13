import ArgumentParser
@preconcurrency import Foundation

struct RunCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "run",
		abstract: "Run the morning briefing and send to Slack"
	)

	func run() async throws {
		let config: Config
		do {
			config = try Config.load()
		} catch {
			throw CLIError.configNotFound
		}

		print("Running Claude…")
		let output = try await runClaude(config: config)

		print("Sending to Slack…")
		try await postToSlack(webhook: config.slackWebhook, output: output)

		print("Sent to Slack ✓")
	}

	private func runClaude(config: Config) async throws -> String {
		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
		process.arguments = ["claude", "-c", "-p", config.prompt]
		process.currentDirectoryURL = URL(fileURLWithPath: config.projectPath)

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

	private func postToSlack(webhook: String, output: String) async throws {
		guard let url = URL(string: webhook) else {
			throw CLIError.invalidWebhookURL
		}

		let body = ["text": "🌅 *Morning Briefing*\n\n\(output)"]
		let bodyData = try JSONEncoder().encode(body)

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = bodyData

		let (_, response) = try await URLSession.shared.data(for: request)

		guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
			throw CLIError.slackPostFailed
		}
	}
}

enum CLIError: Error, CustomStringConvertible {
	case claudeFailed(status: Int32)
	case invalidWebhookURL
	case slackPostFailed
	case configNotFound

	var description: String {
		switch self {
		case .claudeFailed(let status): "claude exited with status \(status)"
		case .invalidWebhookURL: "Invalid Slack webhook URL"
		case .slackPostFailed: "Failed to post to Slack"
		case .configNotFound: "Config not found — run `claude-morning init` first"
		}
	}
}
