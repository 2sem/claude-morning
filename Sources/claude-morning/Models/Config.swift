import Foundation

struct Config: Codable {
	var scheduledTime: String  // "HH:mm" format, e.g. "09:00"
	var projects: [Project]

	static var configDir: URL {
		FileManager.default.homeDirectoryForCurrentUser
			.appendingPathComponent(".config/claude-morning")
	}

	static var configURL: URL {
		configDir.appendingPathComponent("config.json")
	}

	static var lastRunURL: URL {
		configDir.appendingPathComponent("last-run")
	}

	static func load() throws -> Config {
		let data = try Data(contentsOf: configURL)
		return try JSONDecoder().decode(Config.self, from: data)
	}

	func save() throws {
		try FileManager.default.createDirectory(at: Config.configDir, withIntermediateDirectories: true)
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		let data = try encoder.encode(self)
		try data.write(to: Config.configURL, options: .atomic)
	}
}
