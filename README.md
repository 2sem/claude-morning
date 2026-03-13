# claude-morning

A macOS CLI tool that resumes the most recent Claude Code session each morning, generates a mobile team manager briefing, and sends it to Slack. Runs automatically on MacBook boot via a macOS LaunchAgent.

## What it does

1. A LaunchAgent triggers `claude-morning run` on boot
2. The tool runs `claude -c -p "<prompt>"` in your configured project directory
3. Claude resumes the last session and generates a briefing as mobile team manager
4. The output is POSTed to a Slack channel via webhook
5. You receive the briefing in Slack and open Claude Code to act on it

## Requirements

- macOS 13.0+
- [Claude Code CLI](https://claude.ai/code) installed and authenticated (`claude` must be on `$PATH`)
- A Slack Incoming Webhook URL

## Install

### Build from source

```bash
git clone https://github.com/2sem/claude-morning
cd claude-morning
swift build -c release
cp .build/release/claude-morning /usr/local/bin/claude-morning
```

## Usage

### Setup

Run the interactive setup wizard once:

```bash
claude-morning init
```

This will:
- Ask for your Slack webhook URL
- Ask for your project path (the Claude Code project directory)
- Ask for a briefing prompt (or use the built-in default)
- Save config to `~/.claude-morning.json`
- Install a LaunchAgent that runs automatically on boot

### Run manually

```bash
claude-morning run
```

### Uninstall

```bash
claude-morning uninstall
```

Removes the LaunchAgent and config file.

## Config file

Saved at `~/.claude-morning.json`:

```json
{
  "projectPath": "/Users/you/Projects/my-app",
  "prompt": "Generate today's morning briefing as mobile team manager. Check open GitHub issues, recent commits on main, and pending PRs. Summarize what the team should focus on today.",
  "slackWebhook": "https://hooks.slack.com/services/..."
}
```

You can edit this file directly to update settings without re-running `init`.

## Logs

When running via LaunchAgent:

- stdout: `/tmp/claude-morning.log`
- stderr: `/tmp/claude-morning-error.log`

## License

MIT
