import XCTest
@testable import MagicAppsCloudSDK

// MARK: - Mock URLProtocol for intercepting requests

/// Records every outgoing request and returns a configurable JSON response.
final class MockURLProtocol: URLProtocol {
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
    ("GET", "/apps/{app_id}/templates"),
    ("GET", "/apps/{app_id}/templates/{template_id}"),
    ("POST", "/apps/{app_id}/templates"),
    ("PUT", "/apps/{app_id}/templates/{template_id}"),
    ("DELETE", "/apps/{app_id}/templates/{template_id}"),
    ("GET", "/registry/apps"),
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
    ("POST", "/auth/client/email/request"),
    ("POST", "/auth/client/email/verify"),
    ("POST", "/iap/transactions/verify"),
    ("POST", "/iap/restore/sync"),
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

/// Source: lambda/templates/index.js handleList (~line 860) - returns { items: Template[] }
let FIXTURE_TEMPLATES_LIST = """
{"items":[{"template_id":"tmpl-1","app_id":"test-app","name":"Test Template","slug":"test-template","created_at":"2025-01-01T00:00:00Z","updated_at":"2025-01-01T00:00:00Z"}]}
"""

/// Source: lambda/templates/index.js handleCreate (~line 963) - returns created item with pk/sk
let FIXTURE_TEMPLATE_CREATED = """
{"template_id":"tmpl-new","app_id":"test-app","name":"New","slug":"new","created_at":"2025-01-01T00:00:00Z","updated_at":"2025-01-01T00:00:00Z"}
"""

/// Source: lambda/templates/index.js handleRegistryApps (~line 515-518) via toCardApp (~line 571-591)
/// Returns { items: CardApp[] }
let FIXTURE_REGISTRY_APPS = """
{"items":[{"app_id":"registry-app-1","name":"Registry App","slug":"registry-app","icon_url":"https://example.com/icon.png","description":"A registry app"}]}
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

final class ContractTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    // MARK: - MagicAppsClient root methods

    func testPing() async throws {
        // Source: lambda/templates/index.js ok() (~line 1028) - { message, requestId }
        MockURLProtocol.responseData = FIXTURE_PING.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.ping()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/ping"))
        XCTAssertTrue(routeExists(method: "GET", path: "/ping"))
    }

    func testGetAppInfo() async throws {
        // Source: lambda/templates/index.js handleGetAppInfo via ok() (~line 1028)
        MockURLProtocol.responseData = FIXTURE_APP_INFO.data(using: .utf8)!

        let client = makeClient()
        let info = try await client.getAppInfo()
        XCTAssertEqual(info.appId, "test-app")
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app"))
    }

    // MARK: - Templates Service

    func testTemplatesList() async throws {
        // Source: lambda/templates/index.js handleList (~line 860) - returns { items: Template[] }
        MockURLProtocol.responseData = FIXTURE_TEMPLATES_LIST.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.templates.list()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/templates"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/templates"))
    }

    func testTemplatesGet() async throws {
        // Source: lambda/templates/index.js handleGet (~line 880) - returns single template
        MockURLProtocol.responseData = FIXTURE_TEMPLATE.data(using: .utf8)!

        let client = makeClient()
        let tmpl = try await client.templates.get(templateId: "tmpl-1")
        XCTAssertEqual(tmpl.templateId, "tmpl-1")
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/templates/tmpl-1"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/templates/tmpl-1"))
    }

    func testTemplatesCreate() async throws {
        // Source: lambda/templates/index.js handleCreate (~line 963)
        MockURLProtocol.responseData = FIXTURE_TEMPLATE_CREATED.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.templates.create(name: "New")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/templates"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/templates"))

        let body = lastCapturedBody()
        XCTAssertNotNil(body?["name"])
        XCTAssertEqual(body?["name"] as? String, "New")
    }

    func testTemplatesUpdate() async throws {
        // Source: lambda/templates/index.js handleUpdate - returns updated template
        MockURLProtocol.responseData = """
        {"template_id":"tmpl-1","app_id":"test-app","name":"Updated","slug":"updated","created_at":"2025-01-01T00:00:00Z","updated_at":"2025-06-01T00:00:00Z"}
        """.data(using: .utf8)!

        let client = makeClient()
        let req = UpdateTemplateRequest(name: "Updated")
        _ = try await client.templates.update(templateId: "tmpl-1", req)
        XCTAssertEqual(lastCapturedMethod(), "PUT")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/templates/tmpl-1"))
        XCTAssertTrue(routeExists(method: "PUT", path: "/apps/test-app/templates/tmpl-1"))
    }

    func testTemplatesDelete() async throws {
        let client = makeClient()
        try await client.templates.delete(templateId: "tmpl-1")
        XCTAssertEqual(lastCapturedMethod(), "DELETE")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/templates/tmpl-1"))
        XCTAssertTrue(routeExists(method: "DELETE", path: "/apps/test-app/templates/tmpl-1"))
    }

    func testBrowseRegistry() async throws {
        // Source: lambda/templates/index.js handleRegistryApps (~line 515-518)
        // Returns { items: CardApp[] } via toCardApp (~line 571-591)
        MockURLProtocol.responseData = FIXTURE_REGISTRY_APPS.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.templates.browseRegistry()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/registry/apps"))
        XCTAssertTrue(routeExists(method: "GET", path: "/registry/apps"))
    }

    // MARK: - AI Service

    func testCreateChatCompletion() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        // All AI responses normalized to { id, provider, model, choices, usage }
        MockURLProtocol.responseData = FIXTURE_CHAT_COMPLETION.data(using: .utf8)!

        let client = makeClient()
        let req = ChatCompletionRequest(messages: [ChatMessage(role: "user", content: "hello")])
        let response = try await client.ai.createChatCompletion(req)
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.content, "Hello!")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/chat/completions"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/chat/completions"))

        let body = lastCapturedBody()
        XCTAssertNotNil(body?["messages"])
    }

    func testCreateEmbedding() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        MockURLProtocol.responseData = FIXTURE_EMBEDDING.data(using: .utf8)!

        let client = makeClient()
        let req = EmbeddingRequest(input: "test")
        let response = try await client.ai.createEmbedding(req)
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].embedding, [0.1, 0.2, 0.3])
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/embeddings"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/embeddings"))

        let body = lastCapturedBody()
        XCTAssertEqual(body?["input"] as? String, "test")
    }

    func testCreateImage() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        MockURLProtocol.responseData = FIXTURE_IMAGE_GENERATION.data(using: .utf8)!

        let client = makeClient()
        let req = ImageGenerationRequest(prompt: "a cat")
        let response = try await client.ai.createImage(req)
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/images/generations"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/images/generations"))

        let body = lastCapturedBody()
        XCTAssertEqual(body?["prompt"] as? String, "a cat")
    }

    func testCreateModeration() async throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        MockURLProtocol.responseData = FIXTURE_MODERATION.data(using: .utf8)!

        let client = makeClient()
        let req = ModerationRequest(input: "hello world")
        let response = try await client.ai.createModeration(req)
        XCTAssertEqual(response.results.count, 1)
        XCTAssertEqual(response.results[0].flagged, false)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/moderations"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/moderations"))
    }

    func testGetUsageSummary() async throws {
        // Source: lambda/ai_proxy/index.js handleGetUsageSummary (~line 457-474)
        // Returns { summaries: AiUsageSummaryRecord[] }
        MockURLProtocol.responseData = FIXTURE_AI_USAGE_SUMMARY.data(using: .utf8)!

        let client = makeClient()
        let summary = try await client.ai.getUsageSummary()
        XCTAssertEqual(summary.summaries?.count, 1)
        XCTAssertEqual(summary.summaries?[0].totalRequests, 150)
        XCTAssertEqual(summary.totalRequests, 150)
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/usage/summary"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/ai/usage/summary"))
    }

    func testGetUsage() async throws {
        // Source: lambda/ai_proxy/index.js handleGetUsage (~line 436-454)
        // Returns { usage: AiUsageRecord[], count: N }
        MockURLProtocol.responseData = FIXTURE_AI_USAGE.data(using: .utf8)!

        let client = makeClient()
        let response = try await client.ai.getUsage()
        XCTAssertEqual(response.usage.count, 1)
        XCTAssertEqual(response.usage[0].usageId, "usage-001")
        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/usage"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/ai/usage"))
    }

    // MARK: - Devices Service

    func testDevicesList() async throws {
        // Source: lambda/devices/index.js (~line 22-26) - returns { items: Device[] }
        MockURLProtocol.responseData = FIXTURE_DEVICES.data(using: .utf8)!

        let client = makeClient()
        let catalog = try await client.devices.list()
        XCTAssertEqual(catalog.allDevices.count, 1)
        XCTAssertEqual(catalog.allDevices[0].deviceName, "Test Device")
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/devices"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/devices"))
    }

    func testDevicesGetAll() async throws {
        // Source: lambda/devices/index.js (~line 22-26) - returns { items: Device[] }
        MockURLProtocol.responseData = FIXTURE_DEVICES.data(using: .utf8)!

        let client = makeClient()
        let devices = try await client.devices.getAll()
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices[0].deviceName, "Test Device")
    }

    // MARK: - Endpoints Service

    func testEndpointsCreate() async throws {
        // Source: lambda/endpoints/index.js handleCreate (~line 221-232)
        MockURLProtocol.responseData = FIXTURE_ENDPOINT_CREATED.data(using: .utf8)!

        let client = makeClient()
        let ep = try await client.endpoints.create()
        XCTAssertEqual(ep.slug, "abc123")
        XCTAssertEqual(ep.status, "active")
        XCTAssertEqual(ep.hmacSecret, "hmac-secret-value")
        XCTAssertEqual(ep.hmacRequired, true)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/endpoints"))
    }

    func testEndpointsRevokeAndReplace() async throws {
        // Source: lambda/endpoints/index.js handleRevokeAndReplace (~line 402-414)
        MockURLProtocol.responseData = FIXTURE_ENDPOINT_REVOKE_AND_REPLACE.data(using: .utf8)!

        let client = makeClient()
        let result = try await client.endpoints.revokeAndReplace(oldSlug: "old-slug")
        XCTAssertEqual(result.oldSlug, "old-slug")
        XCTAssertEqual(result.newSlug, "new-slug")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints/revoke_and_replace"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/endpoints/revoke_and_replace"))
    }

    func testEndpointsRevoke() async throws {
        // Source: lambda/endpoints/index.js handleRevoke (~line 521-524)
        MockURLProtocol.responseData = FIXTURE_ENDPOINT_REVOKE.data(using: .utf8)!

        let client = makeClient()
        let result = try await client.endpoints.revoke(slug: "my-slug")
        XCTAssertTrue(result.revoked)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints/revoke"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/endpoints/revoke"))
    }

    func testPostEvent() async throws {
        // Source: lambda/events/index.js POST handler (~line 238-246)
        MockURLProtocol.responseData = FIXTURE_POST_EVENT.data(using: .utf8)!

        let client = makeClient()
        let payload: [String: AnyCodable] = ["text": AnyCodable("hello")]
        let result = try await client.endpoints.postEvent(slug: "my-slug", payload: payload)
        XCTAssertEqual(result.slug, "my-slug")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/events/my-slug"))
        XCTAssertTrue(routeExists(method: "POST", path: "/events/my-slug"))
    }

    func testConsumeEvent() async throws {
        // Source: lambda/events/index.js GET handler empty slot (~line 262-267)
        MockURLProtocol.responseData = FIXTURE_CONSUME_EVENT_EMPTY.data(using: .utf8)!

        let client = makeClient()
        let event = try await client.endpoints.consumeEvent(slug: "my-slug")
        XCTAssertEqual(event.slug, "my-slug")
        XCTAssertEqual(event.empty, true)
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/events/my-slug"))
        XCTAssertTrue(routeExists(method: "GET", path: "/events/my-slug"))
    }

    // MARK: - Lookup Tables Service

    func testLookupTablesList() async throws {
        // Source: lambda/lookup_tables/index.js list handler with toSummary (~line 867-880)
        MockURLProtocol.responseData = FIXTURE_LOOKUP_TABLES_LIST.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.lookupTables.list()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/lookup-tables"))
        XCTAssertTrue(routeExists(method: "GET", path: "/lookup-tables"))
    }

    func testLookupTablesGet() async throws {
        // Source: lambda/lookup_tables/index.js toClientDetail (~line 903-920)
        MockURLProtocol.responseData = FIXTURE_LOOKUP_TABLE_DETAIL.data(using: .utf8)!

        let client = makeClient()
        let detail = try await client.lookupTables.get(lookupTableId: "lt-1")
        XCTAssertEqual(detail.lookupTableId, "lt-1")
        XCTAssertEqual(detail.name, "Colors")
        XCTAssertEqual(detail.chunks.count, 1)
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/lookup-tables/lt-1"))
        XCTAssertTrue(routeExists(method: "GET", path: "/lookup-tables/lt-1"))
    }

    func testLookupTablesGetChunk() async throws {
        // Source: lambda/lookup_tables/index.js handleClientChunk (~line 134-138)
        MockURLProtocol.responseData = FIXTURE_LOOKUP_TABLE_CHUNK.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.lookupTables.getChunk(lookupTableId: "lt-1", chunkIndex: 0)
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/lookup-tables/lt-1/chunks/0"))
        XCTAssertTrue(routeExists(method: "GET", path: "/lookup-tables/lt-1/chunks/0"))
    }

    // MARK: - Auth Service

    func testRefreshToken() async throws {
        MockURLProtocol.responseData = """
        {"accessToken":"new-token","expiresIn":3600}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.refreshToken("old-refresh")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/auth/client/refresh"))
        XCTAssertTrue(routeExists(method: "POST", path: "/auth/client/refresh"))
    }

    func testLinkProvider() async throws {
        MockURLProtocol.responseData = """
        {"success":true,"linkedProviders":["apple","google"]}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.linkProvider(provider: "google", token: "gtoken")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/auth/client/link"))
        XCTAssertTrue(routeExists(method: "POST", path: "/auth/client/link"))
    }

    func testPasskeyRegisterOptions() async throws {
        MockURLProtocol.responseData = """
        {"challenge":"abc","rp":{"id":"example.com","name":"Example"},"user":{"id":"u1","name":"user","displayName":"User"}}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.getPasskeyRegisterOptions()
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/auth/client/passkey/register/options"))
        XCTAssertTrue(routeExists(method: "POST", path: "/auth/client/passkey/register/options"))
    }

    func testPasskeyAuthOptions() async throws {
        MockURLProtocol.responseData = """
        {"challenge":"xyz","rpId":"example.com"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.getPasskeyAuthOptions()
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/auth/client/passkey/authenticate/options"))
        XCTAssertTrue(routeExists(method: "POST", path: "/auth/client/passkey/authenticate/options"))
    }

    func testEmailMagicLinkRequest() async throws {
        MockURLProtocol.responseData = """
        {"success":true,"message":"Email sent"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.requestEmailMagicLink(email: "user@test.com")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/auth/client/email/request"))
        XCTAssertTrue(routeExists(method: "POST", path: "/auth/client/email/request"))

        let body = lastCapturedBody()
        XCTAssertEqual(body?["email"] as? String, "user@test.com")
    }

    func testEmailMagicLinkVerify() async throws {
        MockURLProtocol.responseData = """
        {"accessToken":"tok","refreshToken":"ref"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.auth.verifyEmailMagicLink(token: "magic-token")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/auth/client/email/verify"))
        XCTAssertTrue(routeExists(method: "POST", path: "/auth/client/email/verify"))
    }

    // MARK: - Apple Auth Service

    func testAppleExchange() async throws {
        MockURLProtocol.responseData = """
        {"accessToken":"tok","refreshToken":"ref","isNewUser":true}
        """.data(using: .utf8)!

        let client = makeClient()
        let req = AppleExchangeRequest(identityToken: "apple-id-token", authorizationCode: nil, user: nil)
        _ = try await client.appleAuth.exchangeToken(req)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/auth/client/apple/exchange"))
        XCTAssertTrue(routeExists(method: "POST", path: "/auth/client/apple/exchange"))
    }

    // MARK: - Apple IAP Service

    func testIapVerifyTransaction() async throws {
        MockURLProtocol.responseData = """
        {"valid":true,"productId":"com.app.premium","transactionId":"tx-1"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.appleIap.verifyTransaction(transactionId: "tx-1")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/iap/transactions/verify"))
        XCTAssertTrue(routeExists(method: "POST", path: "/iap/transactions/verify"))

        let body = lastCapturedBody()
        XCTAssertEqual(body?["transactionId"] as? String, "tx-1")
    }

    func testIapRestorePurchases() async throws {
        MockURLProtocol.responseData = """
        {"restoredTransactions":[],"entitlements":[]}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.appleIap.restorePurchases()
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/iap/restore/sync"))
        XCTAssertTrue(routeExists(method: "POST", path: "/iap/restore/sync"))
    }

    // MARK: - Response Decoding Validation (Golden fixture shape tests)

    func testAppInfoDecodesFromRealShape() throws {
        // Source: lambda/templates/index.js handleGetAppInfo via ok() (~line 1028)
        let json = FIXTURE_APP_INFO.data(using: .utf8)!
        let info = try JSONDecoder().decode(AppInfo.self, from: json)
        XCTAssertEqual(info.appId, "test-app")
        XCTAssertEqual(info.slug, "test-app")
        XCTAssertEqual(info.name, "Test App")
    }

    func testDeviceCatalogDecodesFromRealShape() throws {
        // Source: lambda/devices/index.js (~line 22-26) - returns { items: Device[] }
        let json = FIXTURE_DEVICES.data(using: .utf8)!
        let catalog = try JSONDecoder().decode(DeviceCatalogResponse.self, from: json)
        XCTAssertEqual(catalog.allDevices.count, 1)
        XCTAssertEqual(catalog.allDevices[0].deviceName, "Test Device")
    }

    func testLookupTableSummaryDecodesFromRealShape() throws {
        // Source: lambda/lookup_tables/index.js toSummary (~line 867-880)
        let json = """
        {"lookup_table_id":"lt-1","name":"Colors","description":null,"schema_keys":["hex","name"],"schema_key_count":2,"schema_keys_truncated":false,"version":3,"payload_hash":"abc","storage_mode":"chunked","chunk_count":2,"updated_at":1700000000}
        """.data(using: .utf8)!
        let summary = try JSONDecoder().decode(LookupTableSummary.self, from: json)
        XCTAssertEqual(summary.lookupTableId, "lt-1")
        XCTAssertEqual(summary.schemaKeys.count, 2)
    }

    func testChatCompletionResponseDecodesFromRealShape() throws {
        // Source: lambda/ai_proxy/index.js normalizeProviderResponse (~line 830-874)
        // Real Lambda returns normalized format, not raw OpenAI format
        let json = FIXTURE_CHAT_COMPLETION.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.content, "Hello!")
    }

    func testCreateEndpointResponseDecodesFromRealShape() throws {
        // Source: lambda/endpoints/index.js handleCreate (~line 221-232)
        let json = FIXTURE_ENDPOINT_CREATED.data(using: .utf8)!
        let response = try JSONDecoder().decode(CreateEndpointResponse.self, from: json)
        XCTAssertEqual(response.slug, "abc123")
        XCTAssertEqual(response.hmacSecret, "hmac-secret-value")
        XCTAssertEqual(response.hmacRequired, true)
    }

    func testConsumedEventDecodesFromRealShape() throws {
        // Source: lambda/events/index.js GET handler with data (~line 250-260)
        let json = FIXTURE_CONSUME_EVENT.data(using: .utf8)!
        let event = try JSONDecoder().decode(ConsumedEvent.self, from: json)
        XCTAssertEqual(event.slug, "my-slug")
        XCTAssertEqual(event.text, "hello")
        XCTAssertEqual(event.keywords, ["greeting"])
        XCTAssertEqual(event.empty, false)
    }

    func testAiUsageSummaryDecodesFromRealShape() throws {
        // Source: lambda/ai_proxy/index.js handleGetUsageSummary (~line 457-474)
        let json = FIXTURE_AI_USAGE_SUMMARY.data(using: .utf8)!
        let summary = try JSONDecoder().decode(AiUsageSummary.self, from: json)
        XCTAssertEqual(summary.summaries?.count, 1)
        XCTAssertEqual(summary.summaries?[0].period, "MONTHLY#2026-03")
        XCTAssertEqual(summary.summaries?[0].totalRequests, 150)
        XCTAssertEqual(summary.totalRequests, 150)
    }

    func testAiUsageDecodesFromRealShape() throws {
        // Source: lambda/ai_proxy/index.js handleGetUsage (~line 436-454)
        let json = FIXTURE_AI_USAGE.data(using: .utf8)!
        let response = try JSONDecoder().decode(AiUsageResponse.self, from: json)
        XCTAssertEqual(response.usage.count, 1)
        XCTAssertEqual(response.usage[0].usageId, "usage-001")
        XCTAssertEqual(response.usage[0].providerId, "openai")
        XCTAssertEqual(response.count, 1)
    }

    // MARK: - HMAC Helpers

    func testGenerateHmacSignature() {
        let headers = generateHmacSignature(slug: "my-slug", body: "{}", secret: "test-secret", timestampSec: 1700000000)
        XCTAssertEqual(headers.timestamp, "1700000000")
        // Signature should be 64 hex chars (SHA-256 = 32 bytes = 64 hex)
        XCTAssertEqual(headers.signature.count, 64)
        XCTAssertTrue(headers.signature.allSatisfy { "0123456789abcdef".contains($0) })
    }

    func testVerifyHmacSignature() {
        let slug = "my-slug"
        let body = "{\"key\":\"val\"}"
        let secret = "test-secret"

        // Note: verifyHmacSignature checks clock skew against "now", so for unit testing
        // we use the current time
        let nowTs = Int(Date().timeIntervalSince1970)
        let nowHeaders = generateHmacSignature(slug: slug, body: body, secret: secret, timestampSec: nowTs)
        let valid = verifyHmacSignature(slug: slug, body: body, signature: nowHeaders.signature, timestamp: nowHeaders.timestamp, secret: secret)
        XCTAssertTrue(valid)
    }

    func testVerifyHmacSignatureRejectsWrongSecret() {
        let slug = "my-slug"
        let body = "{}"
        let nowTs = Int(Date().timeIntervalSince1970)

        let headers = generateHmacSignature(slug: slug, body: body, secret: "correct-secret", timestampSec: nowTs)
        let valid = verifyHmacSignature(slug: slug, body: body, signature: headers.signature, timestamp: headers.timestamp, secret: "wrong-secret")
        XCTAssertFalse(valid)
    }

    func testVerifyHmacSignatureRejectsExpiredTimestamp() {
        let slug = "my-slug"
        let body = "{}"
        let oldTs = Int(Date().timeIntervalSince1970) - 400 // 400 seconds ago

        let headers = generateHmacSignature(slug: slug, body: body, secret: "secret", timestampSec: oldTs)
        let valid = verifyHmacSignature(slug: slug, body: body, signature: headers.signature, timestamp: headers.timestamp, secret: "secret")
        XCTAssertFalse(valid)
    }

    func testHmacDeterministic() {
        let h1 = generateHmacSignature(slug: "s", body: "b", secret: "k", timestampSec: 100)
        let h2 = generateHmacSignature(slug: "s", body: "b", secret: "k", timestampSec: 100)
        XCTAssertEqual(h1.signature, h2.signature)
    }
}
