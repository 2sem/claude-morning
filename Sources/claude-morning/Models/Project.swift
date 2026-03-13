import Foundation

struct Project: Codable {
	var name: String
	var path: String
	var prompt: String
	var messageProvider: MessageProvider
}
