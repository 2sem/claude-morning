import ArgumentParser

@main
struct Morning: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "claude-morning",
		abstract: "Morning briefing tool — resumes Claude Code and posts to Slack",
		subcommands: [InitCommand.self, RunCommand.self, UninstallCommand.self]
	)
}
