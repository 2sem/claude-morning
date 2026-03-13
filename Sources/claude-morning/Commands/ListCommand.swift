import ArgumentParser
@preconcurrency import Foundation

struct ListCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "list",
		abstract: "List all configured projects"
	)

	func run() async throws {
		let config: Config
		do {
			config = try Config.load()
		} catch {
			throw CLIError.configNotFound
		}

		if config.projects.isEmpty {
			print("No projects configured. Run `claude-morning setup` in a project directory.")
			return
		}
		print("Scheduled: \(config.scheduledTime) daily\n")
		for (i, project) in config.projects.enumerated() {
			print("\(i + 1). \(project.name)")
			print("   Path:     \(project.path)")
			print("   Prompt:   \(project.prompt)")
			print("   Provider: \(project.messageProvider.providerName)")
		}
	}
}
