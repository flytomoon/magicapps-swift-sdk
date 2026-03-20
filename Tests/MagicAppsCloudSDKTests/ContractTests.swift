import Testing
import Foundation
@testable import MagicAppsCloudSDK

// MARK: - Mock URLProtocol for intercepting requests

/// Records every outgoing request and returns a configurable JSON response.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    /// Store captured requests for assertions.
    nonisolated(unsafe) static var capturedRequests: [URLRequest] = []
    /// The JSON data to return for every request.
    nonisolated(unsafe) static var responseData: Data = "{}".data(using: .utf8)!
    /// HTTP status code to return.
    nonisolated(unsafe) static var responseStatus: Int = 200

    static func reset() {
        capturedRequests = []
        responseData = "{}".data(using: .utf8)!
        responseStatus = 200
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        MockURLProtocol.capturedRequests.append(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: MockURLProtocol.responseStatus,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: MockURLProtocol.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Helpers

func makeClient() -> MagicAppsClient {
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: sessionConfig)

    let config = SdkConfig(
        baseUrl: URL(string: "https://api.example.com")!,
        appId: "test-app",
        accessToken: "test-token",
        ownerToken: "owner-token",
        retries: 0,
        session: session,
        tokenStorage: InMemoryTokenStorage()
    )
    return MagicAppsClient(config: config)
}

/// The canonical list of API Gateway routes from apigateway_http.tf.
/// Used for phantom method detection — each SDK method path must match
/// at least one route here.
let API_ROUTES: [(method: String, path: String)] = [
    ("GET", "/ping"),
    ("GET", "/apps/{app_id}"),
    ("GET", "/apps/{app_id}/templates/{template_id}"),
    ("GET", "/apps/{app_id}/catalog"),
    ("GET", "/apps/{app_id}/devices"),
    ("POST", "/apps/{app_id}/endpoints"),
    ("POST", "/apps/{app_id}/endpoints/revoke"),
    ("POST", "/apps/{app_id}/endpoints/revoke_and_replace"),
    ("ANY", "/events/{slug}"),
    ("GET", "/lookup-tables"),
    ("GET", "/lookup-tables/{lookup_table_id}"),
    ("GET", "/lookup-tables/{lookup_table_id}/chunks/{chunk_index}"),
    ("POST", "/apps/{app_id}/ai/chat/completions"),
    ("POST", "/apps/{app_id}/ai/embeddings"),
    ("POST", "/apps/{app_id}/ai/images/generations"),
    ("POST", "/apps/{app_id}/ai/moderations"),
    ("GET", "/apps/{app_id}/ai/usage"),
    ("GET", "/apps/{app_id}/ai/usage/summary"),
    ("POST", "/auth/client/apple/exchange"),
    ("POST", "/auth/client/refresh"),
    ("POST", "/auth/client/link"),
    ("POST", "/auth/client/passkey/register/options"),
    ("POST", "/auth/client/passkey/register/verify"),
    ("POST", "/auth/client/passkey/authenticate/options"),
    ("POST", "/auth/client/passkey/authenticate/verify"),
    ("POST", "/iap/transactions/verify"),
    ("POST", "/iap/restore/sync"),
    ("GET", "/apps/{app_id}/client-config"),
    ("POST", "/owner/register"),
    ("POST", "/owner/migrate"),
    ("GET", "/apps/{app_id}/settings"),
    ("PUT", "/apps/{app_id}/settings"),
    ("GET", "/apps/{app_id}/config"),
    ("PUT", "/apps/{app_id}/config"),
    ("GET", "/apps/{app_id}/integrations/{integration_id}/secret"),
    ("POST", "/apps/{app_id}/integrations/{integration_id}/secret"),
]

/// Check whether a concrete path + method matches any API Gateway route.
func routeExists(method: String, path: String) -> Bool {
    let appId = "test-app"
    return API_ROUTES.contains { route in
        let resolved = route.path
            .replacingOccurrences(of: "{app_id}", with: appId)
            .replacingOccurrences(of: "{template_id}", with: "tmpl-1")
            .replacingOccurrences(of: "{slug}", with: "my-slug")
            .replacingOccurrences(of: "{lookup_table_id}", with: "lt-1")
            .replacingOccurrences(of: "{chunk_index}", with: "0")
            .replacingOccurrences(of: "{integration_id}", with: "intg-1")
        let methodMatch = route.method == "ANY" || route.method == method
        return methodMatch && resolved == path
    }
}

func lastCapturedRequest() -> URLRequest? {
    MockURLProtocol.capturedRequests.last
}

func lastCapturedPath() -> String? {
    guard let url = lastCapturedRequest()?.url else { return nil }
    return url.path
}

func lastCapturedMethod() -> String? {
    lastCapturedRequest()?.httpMethod
}

func lastCapturedBody() -> [String: Any]? {
    guard let request = lastCapturedRequest() else { return nil }
    // httpBody may be nil when URLSession streams it; try httpBodyStream as fallback
    if let data = request.httpBody {
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    if let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: 4096)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else {
                break
            }
        }
        if !data.isEmpty {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
    }
    return nil
}

// MARK: - Golden Fixtures (sourced from real Lambda handler return statements)

// Each fixture mirrors the exact JSON shape returned by the corresponding Lambda handler.
// Source comments reference the file, function, and approximate line number.

/// Source: lambda/templates/index.js ok() helper (~line 1028)
/// Used by handleGet (~line 880) - returns single template item
let FIXTURE_TEMPLATE = """
{"template_id":"tmpl-1","app_id":"test-app","name":"Test Template","slug":"test-template","description":"A test template","content":{},"created_at":"2025-01-01T00:00:00Z","updated_at":"2025-01-01T00:00:00Z"}
"""

/// Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
/// All AI responses are normalized to { id, provider, model, choices, usage }
let FIXTURE_CHAT_COMPLETION = """
{"id":"ai_resp_abc123","provider":"openai","model":"gpt-4","choices":[{"index":0,"message":{"role":"assistant","content":"Hello!"},"finish_reason":"stop"}],"usage":{"input_tokens":10,"output_tokens":5,"total_tokens":15,"estimated_cost_usd":0.001}}
"""

/// Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
/// Embedding responses also go through normalization.
let FIXTURE_EMBEDDING = """
{"id":"ai_resp_emb123","provider":"openai","model":"text-embedding-3-small","choices":[],"usage":{"input_tokens":8,"output_tokens":0,"total_tokens":8,"estimated_cost_usd":0.0001},"data":[{"embedding":[0.1,0.2,0.3],"index":0}]}
"""

/// Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
/// Image generation responses also go through normalization.
let FIXTURE_IMAGE_GENERATION = """
{"id":"ai_resp_img123","provider":"openai","model":"dall-e-3","choices":[],"usage":{"input_tokens":0,"output_tokens":0,"total_tokens":0,"estimated_cost_usd":0.04},"data":[{"url":"https://example.com/generated.png","revised_prompt":"A friendly cat"}]}
"""

/// Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
/// Moderation responses also go through normalization.
let FIXTURE_MODERATION = """
{"id":"ai_resp_mod123","provider":"openai","model":"text-moderation-latest","choices":[],"usage":{"input_tokens":5,"output_tokens":0,"total_tokens":5,"estimated_cost_usd":0.0},"results":[{"flagged":false,"categories":{"hate":false,"sexual":false,"violence":false},"category_scores":{"hate":0.001,"sexual":0.0002,"violence":0.0001}}]}
"""

/// Source: lambda/ai_proxy/index.js handleGetUsageSummary (~line 457-474)
/// Returns { summaries: AiUsageSummaryRecord[] }
let FIXTURE_AI_USAGE_SUMMARY = """
{"summaries":[{"app_id":"test-app","period":"MONTHLY#2026-03","total_requests":150,"total_input_tokens":50000,"total_output_tokens":25000,"total_estimated_cost_usd":1.25,"updated_at":1741900000}]}
"""

/// Source: lambda/ai_proxy/index.js handleGetUsage (~line 436-454)
/// Returns { usage: AiUsageRecord[], count: N }
let FIXTURE_AI_USAGE = """
{"usage":[{"usage_id":"usage-001","app_id":"test-app","provider_id":"openai","model_id":"gpt-4","request_type":"chat","input_tokens":10,"output_tokens":5,"total_tokens":15,"latency_ms":250,"status":"success","created_at":1741900000,"expires_at":1749676000}],"count":1}
"""

/// Source: lambda/devices/index.js (~line 22-26)
/// Returns { items: Device[] }
let FIXTURE_DEVICES = """
{"items":[{"device_name":"Test Device","device_id":"dev-1","device_type":"phone","tags":["ios"],"os":"iOS","manufacturer":"Apple"}]}
"""

/// Source: lambda/endpoints/index.js handleCreate (~line 221-232)
/// Returns { slug, status, expires_at, endpoint_path, hmac_secret?, hmac_required? }
let FIXTURE_ENDPOINT_CREATED = """
{"slug":"abc123","status":"active","expires_at":1749676000,"endpoint_path":"/events/abc123","hmac_secret":"hmac-secret-value","hmac_required":true}
"""

/// Source: lambda/endpoints/index.js handleRevokeAndReplace (~line 402-414)
let FIXTURE_ENDPOINT_REVOKE_AND_REPLACE = """
{"old_slug":"old-slug","new_slug":"new-slug","new_endpoint_path":"/events/new-slug","revoked_expires_at":1741900000,"new_expires_at":1749676000,"hmac_secret":"new-hmac-secret","hmac_required":true}
"""

/// Source: lambda/endpoints/index.js handleRevoke (~line 521-524)
let FIXTURE_ENDPOINT_REVOKE = """
{"slug":"my-slug","revoked":true}
"""

/// Source: lambda/events/index.js POST handler (~line 238-246)
let FIXTURE_POST_EVENT = """
{"slug":"my-slug","timestamp":1741900000,"expires_at":1749676000}
"""

/// Source: lambda/events/index.js GET handler empty slot (~line 262-267)
/// Returns { empty: true, slug, text: "George Lucas" }
let FIXTURE_CONSUME_EVENT_EMPTY = """
{"slug":"my-slug","empty":true,"text":"George Lucas"}
"""

/// Source: lambda/events/index.js GET handler with data (~line 250-260)
let FIXTURE_CONSUME_EVENT = """
{"slug":"my-slug","timestamp":1741900000,"created_at":1741899000,"expires_at":1749676000,"text":"hello","keywords":["greeting"],"raw_text":"hello world","empty":false}
"""

/// Source: lambda/lookup_tables/index.js toSummary (~line 867-880)
/// list handler returns { items: LookupTableSummary[] }
let FIXTURE_LOOKUP_TABLES_LIST = """
{"items":[{"lookup_table_id":"lt-1","name":"Colors","description":null,"schema_keys":["hex","name"],"schema_key_count":2,"schema_keys_truncated":false,"version":3,"payload_hash":"abc123","storage_mode":"chunked","chunk_count":2,"updated_at":1741900000}]}
"""

/// Source: lambda/lookup_tables/index.js toClientDetail (~line 903-920)
let FIXTURE_LOOKUP_TABLE_DETAIL = """
{"lookup_table_id":"lt-1","name":"Colors","description":null,"schema_keys":["hex","name"],"schema_key_count":2,"schema_keys_truncated":false,"version":3,"payload_hash":"abc123","storage_mode":"chunked","chunk_count":1,"updated_at":1741900000,"prompt":"Find colors","default_success_sentence":"Found it","default_fail_sentence":"Not found","chunk_encoding":"json","manifest_hash":"mhash","chunks":[{"index":0,"path":"c0.json","sha256":"chunksha","byte_length":1024}]}
"""

/// Source: lambda/lookup_tables/index.js handleClientChunk (~line 134-138)
/// Returns raw JSON object (the chunk data itself)
let FIXTURE_LOOKUP_TABLE_CHUNK = """
{"red":"#ff0000","blue":"#0000ff"}
"""

/// Source: lambda/templates/index.js ok() helper (~line 1028)
/// Ping returns { message, requestId }
let FIXTURE_PING = """
{"message":"pong","requestId":"req-abc123"}
"""

/// Source: lambda/templates/index.js ok() helper (~line 1028) via handleGetAppInfo
/// Returns app info fields
let FIXTURE_APP_INFO = """
{"app_id":"test-app","name":"Test App","slug":"test-app","description":"A test application","created_at":"2025-01-01T00:00:00Z","updated_at":"2025-06-01T00:00:00Z"}
"""

// MARK: - Contract Tests

@Suite(.serialized)
struct ContractTests {

    init() {
        MockURLProtocol.reset()
    }

    // MARK: - MagicAppsClient root methods

    @Test func ping() async throws {
        // Source: lambda/templates/index.js ok() (~line 1028) - { message, requestId }
        MockURLProtocol.responseData = FIXTURE_PING.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.ping()
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/ping"))
        #expect(routeExists(method: "GET", path: "/ping"))
    }

    @Test func getAppInfo() async throws {
        // Source: lambda/templates/index.js handleGetAppInfo via ok() (~line 1028)
        MockURLProtocol.responseData = FIXTURE_APP_INFO.data(using: .utf8)!

        let client = makeClient()
        let info = try await client.getAppInfo()
        #expect(info.appId == "test-app")
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app"))
        #expect(routeExists(method: "GET", path: "/apps/test-app"))
    }

    // MARK: - Templates Service

    @Test func templatesGet() async throws {
        // Source: lambda/templates/index.js handleGet (~line 880) - returns single template
        MockURLProtocol.responseData = FIXTURE_TEMPLATE.data(using: .utf8)!

        let client = makeClient()
        let tmpl = try await client.templates.get(templateId: "tmpl-1")
        #expect(tmpl.templateId == "tmpl-1")
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/templates/tmpl-1"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/templates/tmpl-1"))
    }

    @Test func getCatalog() async throws {
        MockURLProtocol.responseData = """
        {"items":[{"app_id":"app-1","name":"Test App"}]}
        """.data(using: .utf8)!

        let client = makeClient()
        let catalog = try await client.templates.getCatalog()
        #expect(catalog.allApps.count == 1)
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/catalog"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/catalog"))
    }

    // MARK: - AI Service

    @Test func createChatCompletion() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        // All AI responses normalized to { id, provider, model, choices, usage }
        MockURLProtocol.responseData = FIXTURE_CHAT_COMPLETION.data(using: .utf8)!

        let client = makeClient()
        let req = ChatCompletionRequest(messages: [ChatMessage(role: "user", content: "hello")])
        let response = try await client.ai.createChatCompletion(req)
        #expect(response.choices.count == 1)
        #expect(response.choices[0].message.content == "Hello!")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/chat/completions"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/ai/chat/completions"))

        let body = lastCapturedBody()
        #expect(body?["messages"] != nil)
    }

    @Test func createEmbedding() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        MockURLProtocol.responseData = FIXTURE_EMBEDDING.data(using: .utf8)!

        let client = makeClient()
        let req = EmbeddingRequest(input: "test")
        let response = try await client.ai.createEmbedding(req)
        #expect(response.data.count == 1)
        #expect(response.data[0].embedding == [0.1, 0.2, 0.3])
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/embeddings"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/ai/embeddings"))

        let body = lastCapturedBody()
        #expect(body?["input"] as? String == "test")
    }

    @Test func createImage() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        MockURLProtocol.responseData = FIXTURE_IMAGE_GENERATION.data(using: .utf8)!

        let client = makeClient()
        let req = ImageGenerationRequest(prompt: "a cat")
        let response = try await client.ai.createImage(req)
        #expect(response.data.count == 1)
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/images/generations"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/ai/images/generations"))

        let body = lastCapturedBody()
        #expect(body?["prompt"] as? String == "a cat")
    }

    @Test func createModeration() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        MockURLProtocol.responseData = FIXTURE_MODERATION.data(using: .utf8)!

        let client = makeClient()
        let req = ModerationRequest(input: "hello world")
        let response = try await client.ai.createModeration(req)
        #expect(response.results.count == 1)
        #expect(response.results[0].flagged == false)
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/moderations"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/ai/moderations"))
    }

    @Test func getUsageSummary() async throws {
        // Source: lambda/ai_proxy/index.js handleGetUsageSummary (~line 457-474)
        // Returns { summaries: AiUsageSummaryRecord[] }
        MockURLProtocol.responseData = FIXTURE_AI_USAGE_SUMMARY.data(using: .utf8)!

        let client = makeClient()
        let summary = try await client.ai.getUsageSummary()
        #expect(summary.summaries?.count == 1)
        #expect(summary.summaries?[0].totalRequests == 150)
        #expect(summary.totalRequests == 150)
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/usage/summary"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/ai/usage/summary"))
    }

    @Test func getUsage() async throws {
        // Source: lambda/ai_proxy/index.js handleGetUsage (~line 436-454)
        // Returns { usage: AiUsageRecord[], count: N }
        MockURLProtocol.responseData = FIXTURE_AI_USAGE.data(using: .utf8)!

        let client = makeClient()
        let response = try await client.ai.getUsage()
        #expect(response.usage.count == 1)
        #expect(response.usage[0].usageId == "usage-001")
        #expect(response.count == 1)
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/usage"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/ai/usage"))
    }

    // MARK: - Devices Service

    @Test func devicesList() async throws {
        // Source: lambda/devices/index.js (~line 22-26) - returns { items: Device[] }
        MockURLProtocol.responseData = FIXTURE_DEVICES.data(using: .utf8)!

        let client = makeClient()
        let catalog = try await client.devices.list()
        #expect(catalog.allDevices.count == 1)
        #expect(catalog.allDevices[0].deviceName == "Test Device")
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/devices"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/devices"))
    }

    @Test func devicesGetAll() async throws {
        // Source: lambda/devices/index.js (~line 22-26) - returns { items: Device[] }
        MockURLProtocol.responseData = FIXTURE_DEVICES.data(using: .utf8)!

        let client = makeClient()
        let devices = try await client.devices.getAll()
        #expect(devices.count == 1)
        #expect(devices[0].deviceName == "Test Device")
    }

    // MARK: - Endpoints Service

    @Test func endpointsCreate() async throws {
        // Source: lambda/endpoints/index.js handleCreate (~line 221-232)
        MockURLProtocol.responseData = FIXTURE_ENDPOINT_CREATED.data(using: .utf8)!

        let client = makeClient()
        let ep = try await client.endpoints.create()
        #expect(ep.slug == "abc123")
        #expect(ep.status == "active")
        #expect(ep.hmacSecret == "hmac-secret-value")
        #expect(ep.hmacRequired == true)
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/endpoints"))
    }

    @Test func endpointsRevokeAndReplace() async throws {
        // Source: lambda/endpoints/index.js handleRevokeAndReplace (~line 402-414)
        MockURLProtocol.responseData = FIXTURE_ENDPOINT_REVOKE_AND_REPLACE.data(using: .utf8)!

        let client = makeClient()
        let result = try await client.endpoints.revokeAndReplace(oldSlug: "old-slug")
        #expect(result.oldSlug == "old-slug")
        #expect(result.newSlug == "new-slug")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints/revoke_and_replace"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/endpoints/revoke_and_replace"))
    }

    @Test func endpointsRevoke() async throws {
        // Source: lambda/endpoints/index.js handleRevoke (~line 521-524)
        MockURLProtocol.responseData = FIXTURE_ENDPOINT_REVOKE.data(using: .utf8)!

        let client = makeClient()
        let result = try await client.endpoints.revoke(slug: "my-slug")
        #expect(result.revoked)
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints/revoke"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/endpoints/revoke"))
    }

    @Test func postEvent() async throws {
        // Source: lambda/events/index.js POST handler (~line 238-246)
        MockURLProtocol.responseData = FIXTURE_POST_EVENT.data(using: .utf8)!

        let client = makeClient()
        let payload: [String: AnyCodable] = ["text": AnyCodable("hello")]
        let result = try await client.endpoints.postEvent(slug: "my-slug", payload: payload)
        #expect(result.slug == "my-slug")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/events/my-slug"))
        #expect(routeExists(method: "POST", path: "/events/my-slug"))
    }

    @Test func consumeEvent() async throws {
        // Source: lambda/events/index.js GET handler empty slot (~line 262-267)
        MockURLProtocol.responseData = FIXTURE_CONSUME_EVENT_EMPTY.data(using: .utf8)!

        let client = makeClient()
        let event = try await client.endpoints.consumeEvent(slug: "my-slug")
        #expect(event.slug == "my-slug")
        #expect(event.empty == true)
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/events/my-slug"))
        #expect(routeExists(method: "GET", path: "/events/my-slug"))
    }

    // MARK: - Lookup Tables Service

    @Test func lookupTablesList() async throws {
        // Source: lambda/lookup_tables/index.js list handler with toSummary (~line 867-880)
        MockURLProtocol.responseData = FIXTURE_LOOKUP_TABLES_LIST.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.lookupTables.list()
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/lookup-tables"))
        #expect(routeExists(method: "GET", path: "/lookup-tables"))
    }

    @Test func lookupTablesGet() async throws {
        // Source: lambda/lookup_tables/index.js toClientDetail (~line 903-920)
        MockURLProtocol.responseData = FIXTURE_LOOKUP_TABLE_DETAIL.data(using: .utf8)!

        let client = makeClient()
        let detail = try await client.lookupTables.get(lookupTableId: "lt-1")
        #expect(detail.lookupTableId == "lt-1")
        #expect(detail.name == "Colors")
        #expect((detail.chunks?.count ?? 0) == 1)
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/lookup-tables/lt-1"))
        #expect(routeExists(method: "GET", path: "/lookup-tables/lt-1"))
    }

    @Test func lookupTablesGetChunk() async throws {
        // Source: lambda/lookup_tables/index.js handleClientChunk (~line 134-138)
        MockURLProtocol.responseData = FIXTURE_LOOKUP_TABLE_CHUNK.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.lookupTables.getChunk(lookupTableId: "lt-1", chunkIndex: 0)
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/lookup-tables/lt-1/chunks/0"))
        #expect(routeExists(method: "GET", path: "/lookup-tables/lt-1/chunks/0"))
    }

    // MARK: - Auth Service

    @Test func refreshToken() async throws {
        MockURLProtocol.responseData = """
        {"accessToken":"new-token","expiresIn":3600}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.refreshToken("old-refresh")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/auth/client/refresh"))
        #expect(routeExists(method: "POST", path: "/auth/client/refresh"))
    }

    @Test func linkProvider() async throws {
        MockURLProtocol.responseData = """
        {"success":true,"linkedProviders":["apple","google"]}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.linkProvider(provider: "google", token: "gtoken")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/auth/client/link"))
        #expect(routeExists(method: "POST", path: "/auth/client/link"))
    }

    @Test func passkeyRegisterOptions() async throws {
        MockURLProtocol.responseData = """
        {"challenge":"abc","rp":{"id":"example.com","name":"Example"},"user":{"id":"u1","name":"user","displayName":"User"}}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.getPasskeyRegisterOptions()
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/auth/client/passkey/register/options"))
        #expect(routeExists(method: "POST", path: "/auth/client/passkey/register/options"))
    }

    @Test func passkeyAuthOptions() async throws {
        MockURLProtocol.responseData = """
        {"challenge":"xyz","rpId":"example.com"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.getPasskeyAuthOptions()
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/auth/client/passkey/authenticate/options"))
        #expect(routeExists(method: "POST", path: "/auth/client/passkey/authenticate/options"))
    }

    // MARK: - Apple Auth Service

    @Test func appleExchange() async throws {
        MockURLProtocol.responseData = """
        {"accessToken":"tok","refreshToken":"ref","isNewUser":true}
        """.data(using: .utf8)!

        let client = makeClient()
        let req = AppleExchangeRequest(identityToken: "apple-id-token", authorizationCode: nil, user: nil)
        _ = try await client.appleAuth.exchangeToken(req)
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/auth/client/apple/exchange"))
        #expect(routeExists(method: "POST", path: "/auth/client/apple/exchange"))
    }

    // MARK: - Apple IAP Service

    @Test func iapVerifyTransaction() async throws {
        MockURLProtocol.responseData = """
        {"valid":true,"productId":"com.app.premium","transactionId":"tx-1"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.appleIap.verifyTransaction(transactionId: "tx-1")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/iap/transactions/verify"))
        #expect(routeExists(method: "POST", path: "/iap/transactions/verify"))

        let body = lastCapturedBody()
        #expect(body?["transactionId"] as? String == "tx-1")
    }

    @Test func iapRestorePurchases() async throws {
        MockURLProtocol.responseData = """
        {"restoredTransactions":[],"entitlements":[]}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.appleIap.restorePurchases()
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/iap/restore/sync"))
        #expect(routeExists(method: "POST", path: "/iap/restore/sync"))
    }

    @Test func iapGetClientConfig() async throws {
        MockURLProtocol.responseData = """
        {"appId":"test-app","purchaseModes":["apple_iap"]}
        """.data(using: .utf8)!

        let client = makeClient()
        let config = try await client.appleIap.getClientConfig()
        #expect(config.appId == "test-app")
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/client-config"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/client-config"))
    }

    // MARK: - Owner Service

    @Test func ownerRegister() async throws {
        MockURLProtocol.responseData = """
        {"owner_token":"tok-abc123"}
        """.data(using: .utf8)!

        let client = makeClient()
        let response = try await client.owner.registerOwner(deviceOwnerId: "device-1", appId: "test-app")
        #expect(response.ownerToken == "tok-abc123")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/owner/register"))
        #expect(routeExists(method: "POST", path: "/owner/register"))

        let body = lastCapturedBody()
        #expect(body?["device_owner_id"] as? String == "device-1")
        #expect(body?["app_id"] as? String == "test-app")
    }

    @Test func ownerRegisterWithHcaptcha() async throws {
        MockURLProtocol.responseData = """
        {"owner_token":"tok-abc123"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.owner.registerOwner(deviceOwnerId: "device-1", appId: "test-app", hcaptchaToken: "captcha-tok")

        let body = lastCapturedBody()
        #expect(body?["hcaptcha_token"] as? String == "captcha-tok")
    }

    @Test func ownerMigrate() async throws {
        MockURLProtocol.responseData = """
        {"success":true,"message":"Migrated successfully"}
        """.data(using: .utf8)!

        let client = makeClient()
        let response = try await client.owner.migrateOwnerToUser(deviceOwnerId: "device-1", appId: "test-app")
        #expect(response.success)
        #expect(response.message == "Migrated successfully")
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/owner/migrate"))
        #expect(routeExists(method: "POST", path: "/owner/migrate"))

        let body = lastCapturedBody()
        #expect(body?["device_owner_id"] as? String == "device-1")
        #expect(body?["app_id"] as? String == "test-app")
    }

    // MARK: - Settings Service

    @Test func getSettings() async throws {
        MockURLProtocol.responseData = """
        {"app_id":"test-app","settings":{"theme":"dark"}}
        """.data(using: .utf8)!

        let client = makeClient()
        let response = try await client.settings.getSettings()
        #expect(response.appId == "test-app")
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/settings"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/settings"))
    }

    @Test func updateSettings() async throws {
        MockURLProtocol.responseData = """
        {"app_id":"test-app","settings":{"theme":"light"}}
        """.data(using: .utf8)!

        let client = makeClient()
        let body: [String: AnyCodable] = ["theme": AnyCodable("light")]
        _ = try await client.settings.updateSettings(body)
        #expect(lastCapturedMethod() == "PUT")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/settings"))
        #expect(routeExists(method: "PUT", path: "/apps/test-app/settings"))
    }

    @Test func getConfig() async throws {
        MockURLProtocol.responseData = """
        {"app_id":"test-app","config":{"feature_flags":{}}}
        """.data(using: .utf8)!

        let client = makeClient()
        let response = try await client.settings.getConfig()
        #expect(response.appId == "test-app")
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/config"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/config"))
    }

    @Test func updateConfig() async throws {
        MockURLProtocol.responseData = """
        {"app_id":"test-app","config":{"feature_flags":{"new_ui":true}}}
        """.data(using: .utf8)!

        let client = makeClient()
        let body: [String: AnyCodable] = ["feature_flags": AnyCodable(["new_ui": AnyCodable(true)])]
        _ = try await client.settings.updateConfig(body)
        #expect(lastCapturedMethod() == "PUT")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/config"))
        #expect(routeExists(method: "PUT", path: "/apps/test-app/config"))
    }

    @Test func getIntegrationSecret() async throws {
        MockURLProtocol.responseData = """
        {"integration_id":"intg-1","secret":{"api_key":"***"},"success":true}
        """.data(using: .utf8)!

        let client = makeClient()
        let response = try await client.settings.getIntegrationSecret(integrationId: "intg-1")
        #expect(response.integrationId == "intg-1")
        #expect(response.success == true)
        #expect(lastCapturedMethod() == "GET")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/integrations/intg-1/secret"))
        #expect(routeExists(method: "GET", path: "/apps/test-app/integrations/intg-1/secret"))
    }

    @Test func uploadIntegrationSecret() async throws {
        MockURLProtocol.responseData = """
        {"integration_id":"intg-1","success":true}
        """.data(using: .utf8)!

        let client = makeClient()
        let body: [String: AnyCodable] = ["api_key": AnyCodable("sk-test-123")]
        _ = try await client.settings.uploadIntegrationSecret(integrationId: "intg-1", body: body)
        #expect(lastCapturedMethod() == "POST")
        #expect(lastCapturedPath()!.hasSuffix("/apps/test-app/integrations/intg-1/secret"))
        #expect(routeExists(method: "POST", path: "/apps/test-app/integrations/intg-1/secret"))
    }

    // MARK: - Response Decoding Validation (Golden fixture shape tests)

    @Test func appInfoDecodesFromRealShape() throws {
        // Source: lambda/templates/index.js handleGetAppInfo via ok() (~line 1028)
        let json = FIXTURE_APP_INFO.data(using: .utf8)!
        let info = try JSONDecoder().decode(AppInfo.self, from: json)
        #expect(info.appId == "test-app")
        #expect(info.slug == "test-app")
        #expect(info.name == "Test App")
    }

    @Test func deviceCatalogDecodesFromRealShape() throws {
        // Source: lambda/devices/index.js (~line 22-26) - returns { items: Device[] }
        let json = FIXTURE_DEVICES.data(using: .utf8)!
        let catalog = try JSONDecoder().decode(DeviceCatalogResponse.self, from: json)
        #expect(catalog.allDevices.count == 1)
        #expect(catalog.allDevices[0].deviceName == "Test Device")
    }

    @Test func lookupTableSummaryDecodesFromRealShape() throws {
        // Source: lambda/lookup_tables/index.js toSummary (~line 867-880)
        let json = """
        {"lookup_table_id":"lt-1","name":"Colors","description":null,"schema_keys":["hex","name"],"schema_key_count":2,"schema_keys_truncated":false,"version":3,"payload_hash":"abc","storage_mode":"chunked","chunk_count":2,"updated_at":1700000000}
        """.data(using: .utf8)!
        let summary = try JSONDecoder().decode(LookupTableSummary.self, from: json)
        #expect(summary.lookupTableId == "lt-1")
        #expect(summary.schemaKeys?.count == 2)
    }

    @Test func chatCompletionResponseDecodesFromRealShape() throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        // Real Lambda returns normalized format, not raw OpenAI format
        let json = FIXTURE_CHAT_COMPLETION.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)
        #expect(response.choices.count == 1)
        #expect(response.choices[0].message.content == "Hello!")
    }

    @Test func createEndpointResponseDecodesFromRealShape() throws {
        // Source: lambda/endpoints/index.js handleCreate (~line 221-232)
        let json = FIXTURE_ENDPOINT_CREATED.data(using: .utf8)!
        let response = try JSONDecoder().decode(CreateEndpointResponse.self, from: json)
        #expect(response.slug == "abc123")
        #expect(response.hmacSecret == "hmac-secret-value")
        #expect(response.hmacRequired == true)
    }

    @Test func consumedEventDecodesFromRealShape() throws {
        // Source: lambda/events/index.js GET handler with data (~line 250-260)
        let json = FIXTURE_CONSUME_EVENT.data(using: .utf8)!
        let event = try JSONDecoder().decode(ConsumedEvent.self, from: json)
        #expect(event.slug == "my-slug")
        #expect(event.text == "hello")
        #expect(event.keywords == ["greeting"])
        #expect(event.empty == false)
    }

    @Test func aiUsageSummaryDecodesFromRealShape() throws {
        // Source: lambda/ai_proxy/index.js handleGetUsageSummary (~line 457-474)
        let json = FIXTURE_AI_USAGE_SUMMARY.data(using: .utf8)!
        let summary = try JSONDecoder().decode(AiUsageSummary.self, from: json)
        #expect(summary.summaries?.count == 1)
        #expect(summary.summaries?[0].period == "MONTHLY#2026-03")
        #expect(summary.summaries?[0].totalRequests == 150)
        #expect(summary.totalRequests == 150)
    }

    @Test func aiUsageDecodesFromRealShape() throws {
        // Source: lambda/ai_proxy/index.js handleGetUsage (~line 436-454)
        let json = FIXTURE_AI_USAGE.data(using: .utf8)!
        let response = try JSONDecoder().decode(AiUsageResponse.self, from: json)
        #expect(response.usage.count == 1)
        #expect(response.usage[0].usageId == "usage-001")
        #expect(response.usage[0].providerId == "openai")
        #expect(response.count == 1)
    }

    // MARK: - HMAC Helpers

    @Test func generateHmacSignatureWorks() {
        let headers = generateHmacSignature(slug: "my-slug", body: "{}", secret: "test-secret", timestampSec: 1700000000)
        #expect(headers.timestamp == "1700000000")
        // Signature should be 64 hex chars (SHA-256 = 32 bytes = 64 hex)
        #expect(headers.signature.count == 64)
        #expect(headers.signature.allSatisfy { "0123456789abcdef".contains($0) })
    }

    @Test func verifyHmacSignatureWorks() {
        let slug = "my-slug"
        let body = "{\"key\":\"val\"}"
        let secret = "test-secret"

        // Note: verifyHmacSignature checks clock skew against "now", so for unit testing
        // we use the current time
        let nowTs = Int(Date().timeIntervalSince1970)
        let nowHeaders = generateHmacSignature(slug: slug, body: body, secret: secret, timestampSec: nowTs)
        let valid = verifyHmacSignature(slug: slug, body: body, signature: nowHeaders.signature, timestamp: nowHeaders.timestamp, secret: secret)
        #expect(valid)
    }

    @Test func verifyHmacSignatureRejectsWrongSecret() {
        let slug = "my-slug"
        let body = "{}"
        let nowTs = Int(Date().timeIntervalSince1970)

        let headers = generateHmacSignature(slug: slug, body: body, secret: "correct-secret", timestampSec: nowTs)
        let valid = verifyHmacSignature(slug: slug, body: body, signature: headers.signature, timestamp: headers.timestamp, secret: "wrong-secret")
        #expect(!valid)
    }

    @Test func verifyHmacSignatureRejectsExpiredTimestamp() {
        let slug = "my-slug"
        let body = "{}"
        let oldTs = Int(Date().timeIntervalSince1970) - 400 // 400 seconds ago

        let headers = generateHmacSignature(slug: slug, body: body, secret: "secret", timestampSec: oldTs)
        let valid = verifyHmacSignature(slug: slug, body: body, signature: headers.signature, timestamp: headers.timestamp, secret: "secret")
        #expect(!valid)
    }

    @Test func hmacDeterministic() {
        let h1 = generateHmacSignature(slug: "s", body: "b", secret: "k", timestampSec: 100)
        let h2 = generateHmacSignature(slug: "s", body: "b", secret: "k", timestampSec: 100)
        #expect(h1.signature == h2.signature)
    }
}
