import ArgumentParser
@preconcurrency import Foundation

struct RemoveCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "remove",
		abstract: "Remove a project by name"
	)

	@Argument(help: "Project name to remove")
	var name: String

	func run() async throws {
		var config: Config
		do {
			config = try Config.load()
		} catch {
			throw CLIError.configNotFound
		}

		let before = config.projects.count
		config.projects.removeAll { $0.name == name }
		guard config.projects.count < before else {
			print("Project '\(name)' not found.")
			return
		}
		try config.save()
		print("✓ Project '\(name)' removed.")
	}
}
