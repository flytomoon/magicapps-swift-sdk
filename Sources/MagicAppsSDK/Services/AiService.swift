import Foundation

// MARK: - AI Chat Types

/// A message in a chat completion request.
public struct ChatMessage: Codable {
    /// The role of the message author (system, user, assistant).
    public let role: String
    /// The content of the message.
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

/// Request body for chat completions (OpenAI-compatible format).
public struct ChatCompletionRequest: Encodable {
    /// The model to use for completion.
    public let model: String?
    /// The messages to generate a completion for.
    public let messages: [ChatMessage]
    /// Sampling temperature (0-2).
    public let temperature: Double?
    /// Maximum number of tokens to generate.
    public let maxTokens: Int?
    /// Top-p sampling parameter.
    public let topP: Double?
    /// Stop sequences.
    public let stop: [String]?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case stop
    }

    public init(
        messages: [ChatMessage],
        model: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        topP: Double? = nil,
        stop: [String]? = nil
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.stop = stop
    }
}

/// A choice in a chat completion response.
public struct ChatCompletionChoice: Decodable {
    public let index: Int
    public let message: ChatMessage
    public let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

/// Token usage information.
public struct TokenUsage: Decodable {
    public let promptTokens: Int?
    public let completionTokens: Int?
    public let totalTokens: Int?

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

/// Response from a chat completion request.
public struct ChatCompletionResponse: Decodable {
    public let id: String?
    public let object: String?
    public let created: Int?
    public let model: String?
    public let choices: [ChatCompletionChoice]
    public let usage: TokenUsage?
}

// MARK: - Embeddings Types

/// Request body for generating embeddings.
public struct EmbeddingRequest: Encodable {
    /// The input text to embed.
    public let input: String
    /// The model to use for embedding.
    public let model: String?

    public init(input: String, model: String? = nil) {
        self.input = input
        self.model = model
    }
}

/// A single embedding result.
public struct EmbeddingData: Decodable {
    public let object: String?
    public let embedding: [Double]
    public let index: Int
}

/// Response from an embedding request.
public struct EmbeddingResponse: Decodable {
    public let object: String?
    public let data: [EmbeddingData]
    public let model: String?
    public let usage: TokenUsage?
}

// MARK: - Image Generation Types

/// Request body for image generation.
public struct ImageGenerationRequest: Encodable {
    /// The prompt to generate images from.
    public let prompt: String
    /// Number of images to generate.
    public let n: Int?
    /// Size of the generated images (e.g., "1024x1024").
    public let size: String?
    /// The model to use.
    public let model: String?

    public init(prompt: String, n: Int? = nil, size: String? = nil, model: String? = nil) {
        self.prompt = prompt
        self.n = n
        self.size = size
        self.model = model
    }
}

/// A generated image.
public struct GeneratedImage: Decodable {
    public let url: String?
    public let b64Json: String?
    public let revisedPrompt: String?

    enum CodingKeys: String, CodingKey {
        case url
        case b64Json = "b64_json"
        case revisedPrompt = "revised_prompt"
    }
}

/// Response from an image generation request.
public struct ImageGenerationResponse: Decodable {
    public let created: Int?
    public let data: [GeneratedImage]
}

// MARK: - Content Moderation Types

/// Request body for content moderation.
public struct ModerationRequest: Encodable {
    /// The text to moderate.
    public let input: String
    /// The model to use.
    public let model: String?

    public init(input: String, model: String? = nil) {
        self.input = input
        self.model = model
    }
}

/// Category scores for content moderation.
public struct ModerationCategoryScores: Decodable {
    public let hate: Double?
    public let sexual: Double?
    public let violence: Double?
    public let selfHarm: Double?
    public let harassment: Double?

    enum CodingKeys: String, CodingKey {
        case hate, sexual, violence
        case selfHarm = "self-harm"
        case harassment
    }
}

/// Category flags for content moderation.
public struct ModerationCategories: Decodable {
    public let hate: Bool?
    public let sexual: Bool?
    public let violence: Bool?
    public let selfHarm: Bool?
    public let harassment: Bool?

    enum CodingKeys: String, CodingKey {
        case hate, sexual, violence
        case selfHarm = "self-harm"
        case harassment
    }
}

/// A moderation result.
public struct ModerationResult: Decodable {
    public let flagged: Bool
    public let categories: ModerationCategories?
    public let categoryScores: ModerationCategoryScores?

    enum CodingKeys: String, CodingKey {
        case flagged, categories
        case categoryScores = "category_scores"
    }
}

/// Response from a moderation request.
public struct ModerationResponse: Decodable {
    public let id: String?
    public let model: String?
    public let results: [ModerationResult]
}

// MARK: - AI Usage Types

/// AI usage summary response.
public struct AiUsageSummary: Decodable {
    public let totalRequests: Int?
    public let totalTokens: Int?
    public let totalCost: Double?
    public let period: String?
    public let breakdown: [AiUsageBreakdown]?

    enum CodingKeys: String, CodingKey {
        case totalRequests = "total_requests"
        case totalTokens = "total_tokens"
        case totalCost = "total_cost"
        case period, breakdown
    }
}

/// Breakdown of AI usage by model/endpoint.
public struct AiUsageBreakdown: Decodable {
    public let endpoint: String?
    public let model: String?
    public let requests: Int?
    public let tokens: Int?
    public let cost: Double?
}

// MARK: - AI Service (All Platforms)

/// AI proxy service module.
/// Provides access to chat completions, embeddings, image generation,
/// and content moderation via the platform's AI proxy.
/// The proxy routes requests through the tenant's configured providers
/// (OpenAI, Anthropic, Google) so developers don't manage API keys on the client.
/// Available on all platforms.
public class AiService: ServiceModule {
    public let name = "ai"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    // MARK: - Chat Completions

    /// Create a chat completion via the AI proxy.
    /// Uses an OpenAI-compatible request format routed through the tenant's configured provider.
    ///
    /// - Parameter request: The chat completion request with messages and optional parameters.
    /// - Returns: A chat completion response with generated choices and usage info.
    public func createChatCompletion(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        return try await http.post("/apps/\(http.appId)/ai/chat/completions", body: request)
    }

    /// Convenience: create a simple chat completion with a single user message.
    public func chat(message: String, model: String? = nil) async throws -> ChatCompletionResponse {
        let request = ChatCompletionRequest(
            messages: [ChatMessage(role: "user", content: message)],
            model: model
        )
        return try await createChatCompletion(request)
    }

    // MARK: - Embeddings

    /// Generate embeddings for the given input text.
    ///
    /// - Parameter request: The embedding request with input text and optional model.
    /// - Returns: An embedding response with vector data.
    public func createEmbedding(_ request: EmbeddingRequest) async throws -> EmbeddingResponse {
        return try await http.post("/apps/\(http.appId)/ai/embeddings", body: request)
    }

    /// Convenience: generate embeddings for a text string.
    public func embed(text: String, model: String? = nil) async throws -> EmbeddingResponse {
        let request = EmbeddingRequest(input: text, model: model)
        return try await createEmbedding(request)
    }

    // MARK: - Image Generation

    /// Generate images from a text prompt.
    ///
    /// - Parameter request: The image generation request with prompt and optional parameters.
    /// - Returns: An image generation response with image URLs or base64 data.
    public func createImage(_ request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        return try await http.post("/apps/\(http.appId)/ai/images/generations", body: request)
    }

    /// Convenience: generate an image from a text prompt.
    public func generateImage(prompt: String, size: String? = nil) async throws -> ImageGenerationResponse {
        let request = ImageGenerationRequest(prompt: prompt, size: size)
        return try await createImage(request)
    }

    // MARK: - Content Moderation

    /// Check content for policy violations.
    ///
    /// - Parameter request: The moderation request with input text.
    /// - Returns: A moderation response with flagged categories and scores.
    public func createModeration(_ request: ModerationRequest) async throws -> ModerationResponse {
        return try await http.post("/apps/\(http.appId)/ai/moderations", body: request)
    }

    /// Convenience: moderate a text string.
    public func moderate(text: String) async throws -> ModerationResponse {
        let request = ModerationRequest(input: text)
        return try await createModeration(request)
    }

    // MARK: - Usage

    /// Get AI usage summary for the current app.
    ///
    /// - Returns: Usage summary with request counts, token usage, and cost breakdown.
    public func getUsageSummary() async throws -> AiUsageSummary {
        return try await http.get("/apps/\(http.appId)/ai/usage/summary")
    }
}
