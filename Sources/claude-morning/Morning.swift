import ArgumentParser

@main
struct Morning: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "claude-morning",
		abstract: "Morning briefing tool — resumes Claude Code sessions and reports to messaging platforms",
		subcommands: [SetupCommand.self, RunCommand.self, ListCommand.self, RemoveCommand.self, UninstallCommand.self]
	)
}
