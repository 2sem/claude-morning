import Foundation

enum CLIError: Error, CustomStringConvertible {
	case claudeFailed(status: Int32)
	case invalidWebhookURL
	case messageSendFailed
	case configNotFound

	var description: String {
		switch self {
		case .claudeFailed(let status): return "claude exited with status \(status)"
		case .invalidWebhookURL: return "Invalid webhook URL"
		case .messageSendFailed: return "Failed to send message"
		case .configNotFound: return "Config not found — run `claude-morning setup` in a project directory"
		}
	}
}
