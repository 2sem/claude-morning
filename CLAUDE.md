# claude-morning

A macOS CLI tool that resumes the most recent Claude Code session, generates a mobile team manager briefing, and sends it to Slack. Runs automatically on MacBook boot via a macOS LaunchAgent.

## Project Goal

Every morning when the user boots their MacBook:
1. A LaunchAgent triggers `claude-morning run`
2. The tool runs `claude -c -p "<prompt>"` in the configured project directory
3. Claude resumes the last session and generates a briefing as a mobile team manager
4. The output is POSTed to a Slack channel via webhook
5. The user receives the briefing in Slack and opens Claude Code to act on it

## Tech Stack

- **Language**: Swift 6.0
- **Build**: Swift Package Manager only (no Tuist, no Xcode project)
- **Dependencies**: `swift-argument-parser` (Apple, via SPM) — no other third-party deps
- **Platform**: macOS 13.0+
- **Slack**: Incoming Webhook only (no Bot token, no OAuth)

## Commands

### `claude-morning init`
Interactive setup wizard:
1. Asks for Slack webhook URL
2. Asks for project path (the Claude Code project directory to run `claude` in)
3. Asks for briefing prompt (has a sensible default)
4. Saves config to `~/.claude-morning.json`
5. Installs LaunchAgent at `~/Library/LaunchAgents/com.leesam.claude-morning.plist`
6. Prints success summary

### `claude-morning run`
1. Loads `~/.claude-morning.json`
2. Runs `claude -c -p "<prompt>"` as a subprocess (`Process`) in the configured project path
3. Captures stdout
4. POSTs to Slack webhook:
   ```json
   { "text": "🌅 *Morning Briefing*\n\n<output>" }
   ```
5. Prints `Sent to Slack ✓` or error

### `claude-morning uninstall`
- Unloads and removes the LaunchAgent plist
- Removes `~/.claude-morning.json`

## Config File (`~/.claude-morning.json`)

```json
{
  "slackWebhook": "https://hooks.slack.com/...",
  "projectPath": "/Users/LYJ/Projects/leesam/talktrans/src/talktrans",
  "prompt": "Generate today's morning briefing as mobile team manager. Check open GitHub issues, recent commits on main, and pending PRs. Summarize what the team should focus on today."
}
```

## LaunchAgent Plist Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.leesam.claude-morning</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/claude-morning</string>
        <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/claude-morning.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/claude-morning-error.log</string>
</dict>
</plist>
```

## Recommended File Structure

```
claude-morning/
├── Package.swift
├── README.md
├── CLAUDE.md                          # this file
├── Sources/
│   └── claude-morning/
│       ├── Morning.swift              # @main, root ArgumentParser command
│       ├── Commands/
│       │   ├── InitCommand.swift
│       │   ├── RunCommand.swift
│       │   └── UninstallCommand.swift
│       └── Models/
│           └── Config.swift           # Codable config + load/save helpers
```

## Code Style

- Tabs for indentation
- Swift 6 concurrency (async/await, `@MainActor` where needed)
- No force unwraps
- `private` by default for internal properties/methods
- `URLSession` for Slack webhook POST
- `Process` for running `claude` subprocess

## What To Do Next (Start Here)

1. Initialize git repo: `git init`
2. Create `Package.swift` with `swift-argument-parser` dependency
3. Implement `Config.swift` (Codable struct, load/save to `~/.claude-morning.json`)
4. Implement `RunCommand.swift` (core logic: subprocess + Slack POST)
5. Implement `InitCommand.swift` (setup wizard + LaunchAgent install)
6. Implement `UninstallCommand.swift`
7. Wire up `Morning.swift` as the root command
8. Write `README.md`
9. Test locally with `swift run claude-morning init`
10. Create GitHub repo at `github.com/2sem/claude-morning` and push

## Open Source Notes

- This project is owned by leesam (github: 2sem)
- MIT License
- Keep it simple — Slack only for now, other outputs (Discord, email) can be added later by contributors
