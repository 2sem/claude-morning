import Foundation

struct Config: Codable {
	var slackWebhook: String
	var projectPath: String
	var prompt: String

	static let defaultPrompt = "Generate today's morning briefing as mobile team manager. Check open GitHub issues, recent commits on main, and pending PRs. Summarize what the team should focus on today."

	static var configURL: URL {
		FileManager.default.homeDirectoryForCurrentUser
			.appendingPathComponent(".claude-morning.json")
	}

	static func load() throws -> Config {
		let data = try Data(contentsOf: configURL)
		return try JSONDecoder().decode(Config.self, from: data)
	}

	func save() throws {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		let data = try encoder.encode(self)
		try data.write(to: Config.configURL, options: .atomic)
	}
}
