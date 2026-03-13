import Foundation

enum MessageProvider: Codable {
	case slack(SlackConfig)
	case discord(DiscordConfig)

	struct SlackConfig: Codable {
		var webhook: String
	}

	struct DiscordConfig: Codable {
		var webhook: String
	}

	var providerName: String {
		switch self {
		case .slack: return "Slack"
		case .discord: return "Discord"
		}
	}

	// Custom Codable: key is the discriminator
	private enum CodingKeys: String, CodingKey {
		case slack, discord
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		if let config = try container.decodeIfPresent(SlackConfig.self, forKey: .slack) {
			self = .slack(config)
		} else if let config = try container.decodeIfPresent(DiscordConfig.self, forKey: .discord) {
			self = .discord(config)
		} else {
			throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unknown message provider"))
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .slack(let config): try container.encode(config, forKey: .slack)
		case .discord(let config): try container.encode(config, forKey: .discord)
		}
	}

	func send(_ message: String) async throws {
		switch self {
		case .slack(let config):
			try await postWebhook(url: config.webhook, message: message, bodyKey: "text")
		case .discord(let config):
			try await postWebhook(url: config.webhook, message: message, bodyKey: "content")
		}
	}

	private func postWebhook(url: String, message: String, bodyKey: String) async throws {
		guard let webhookURL = URL(string: url) else { throw CLIError.invalidWebhookURL }
		let body = [bodyKey: message]
		let bodyData = try JSONEncoder().encode(body)
		var request = URLRequest(url: webhookURL)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = bodyData
		let (_, response) = try await URLSession.shared.data(for: request)
		guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
			throw CLIError.messageSendFailed
		}
	}
}
