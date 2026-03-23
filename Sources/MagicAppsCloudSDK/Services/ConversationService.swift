import Foundation

// MARK: - Conversation Types

/// Request body for creating a new AI conversation.
public struct CreateConversationRequest: Encodable {
    public let title: String?
    public let systemPrompt: String?
    public let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case title
        case systemPrompt = "system_prompt"
        case metadata
    }

    public init(
        title: String? = nil,
        systemPrompt: String? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.title = title
        self.systemPrompt = systemPrompt
        self.metadata = metadata
    }
}

/// Response from listing conversations.
public struct ListConversationsResponse: Decodable {
    public let conversations: [AIConversation]?
    public let items: [AIConversation]?
    public let nextToken: String?

    enum CodingKeys: String, CodingKey {
        case conversations
        case items
        case nextToken = "next_token"
    }

    /// Convenience accessor that returns conversations from whichever field the API uses.
    public var allConversations: [AIConversation] {
        return conversations ?? items ?? []
    }
}

/// Request body for sending a message to a conversation.
public struct SendMessageRequest: Encodable {
    public let content: String
    public let stream: Bool?
    public let model: String?

    public init(content: String, stream: Bool? = nil, model: String? = nil) {
        self.content = content
        self.stream = stream
        self.model = model
    }
}

/// A message in an AI conversation.
public struct ConversationMessage: Decodable {
    public let messageId: String?
    public let conversationId: String?
    public let role: String?
    public let content: String?
    public let model: String?
    public let createdAt: Int?

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case conversationId = "conversation_id"
        case role
        case content
        case model
        case createdAt = "created_at"
    }
}

/// Response from sending a message.
public struct SendMessageResponse: Decodable {
    public let message: ConversationMessage?
    public let userMessage: ConversationMessage?
    public let assistantMessage: ConversationMessage?

    enum CodingKeys: String, CodingKey {
        case message
        case userMessage = "user_message"
        case assistantMessage = "assistant_message"
    }
}

/// Response from deleting a conversation.
public struct DeleteConversationResponse: Decodable {
    public let success: Bool?
    public let message: String?
}

// AIConversation and AIConversationDetail are defined in GeneratedTypes.swift

// MARK: - Conversation Service (All Platforms)

/// AI conversation service module.
/// Provides conversation management for multi-turn AI interactions.
/// Conversations are persistent and can be listed, retrieved, and deleted.
/// Available on all platforms.
public class ConversationService: ServiceModule {
    public let name = "conversations"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Create a new AI conversation.
    ///
    /// - Parameters:
    ///   - title: Optional title for the conversation.
    ///   - systemPrompt: Optional system prompt to set the AI's behavior.
    ///   - metadata: Optional metadata key-value pairs.
    /// - Returns: The created conversation details.
    public func createConversation(
        title: String? = nil,
        systemPrompt: String? = nil,
        metadata: [String: AnyCodable]? = nil
    ) async throws -> AIConversationDetail {
        let body = CreateConversationRequest(
            title: title,
            systemPrompt: systemPrompt,
            metadata: metadata
        )
        return try await http.post("/apps/\(http.appId)/ai/conversations", body: body)
    }

    /// List conversations for the authenticated user.
    ///
    /// - Parameter nextToken: Pagination token from a previous response.
    /// - Returns: A paginated list of conversations.
    public func listConversations(nextToken: String? = nil) async throws -> ListConversationsResponse {
        var query: [String: String]? = nil
        if let nextToken {
            query = ["next_token": nextToken]
        }
        return try await http.get("/apps/\(http.appId)/ai/conversations", query: query)
    }

    /// Get a specific conversation by ID, including message history.
    ///
    /// - Parameter id: The conversation ID.
    /// - Returns: The conversation details with messages.
    public func getConversation(id: String) async throws -> AIConversationDetail {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return try await http.get("/apps/\(http.appId)/ai/conversations/\(encoded)")
    }

    /// Send a message to an existing conversation and get the AI response.
    ///
    /// - Parameters:
    ///   - conversationId: The ID of the conversation to send the message to.
    ///   - content: The message content.
    ///   - stream: Whether to stream the response (default: false).
    ///   - model: Optional model override for this message.
    /// - Returns: The response containing the AI's reply.
    public func sendMessage(
        conversationId: String,
        content: String,
        stream: Bool? = nil,
        model: String? = nil
    ) async throws -> SendMessageResponse {
        let encoded = conversationId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? conversationId
        let body = SendMessageRequest(content: content, stream: stream, model: model)
        return try await http.post("/apps/\(http.appId)/ai/conversations/\(encoded)/messages", body: body)
    }

    /// Delete a conversation and all its messages.
    ///
    /// - Parameter id: The conversation ID to delete.
    /// - Returns: A response indicating whether the deletion was successful.
    public func deleteConversation(id: String) async throws -> DeleteConversationResponse {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return try await http.delete("/apps/\(http.appId)/ai/conversations/\(encoded)")
    }
}
