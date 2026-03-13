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

// MARK: - Contract Tests

final class ContractTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    // MARK: - MagicAppsClient root methods

    func testPing() async throws {
        MockURLProtocol.responseData = """
        {"message":"pong","requestId":"r1"}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.ping()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/ping"))
        XCTAssertTrue(routeExists(method: "GET", path: "/ping"))
    }

    func testGetAppInfo() async throws {
        MockURLProtocol.responseData = """
        {"app_id":"test-app","name":"Test","slug":"test","created_at":"2025-01-01","updated_at":"2025-01-01"}
        """.data(using: .utf8)!

        let client = makeClient()
        let info = try await client.getAppInfo()
        XCTAssertEqual(info.appId, "test-app")
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app"))
    }

    // MARK: - Templates Service

    func testTemplatesList() async throws {
        MockURLProtocol.responseData = """
        {"templates":[],"count":0}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.templates.list()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/templates"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/templates"))
    }

    func testTemplatesGet() async throws {
        MockURLProtocol.responseData = """
        {"template_id":"tmpl-1","name":"T1","created_at":"2025-01-01","updated_at":"2025-01-01"}
        """.data(using: .utf8)!

        let client = makeClient()
        let tmpl = try await client.templates.get(templateId: "tmpl-1")
        XCTAssertEqual(tmpl.templateId, "tmpl-1")
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/templates/tmpl-1"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/templates/tmpl-1"))
    }

    func testTemplatesCreate() async throws {
        MockURLProtocol.responseData = """
        {"template_id":"tmpl-new","name":"New","created_at":"2025-01-01","updated_at":"2025-01-01"}
        """.data(using: .utf8)!

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
        MockURLProtocol.responseData = """
        {"template_id":"tmpl-1","name":"Updated","created_at":"2025-01-01","updated_at":"2025-01-01"}
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
        MockURLProtocol.responseData = """
        {"apps":[]}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.templates.browseRegistry()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/registry/apps"))
        XCTAssertTrue(routeExists(method: "GET", path: "/registry/apps"))
    }

    // MARK: - AI Service

    func testCreateChatCompletion() async throws {
        MockURLProtocol.responseData = """
        {"choices":[{"index":0,"message":{"role":"assistant","content":"hi"},"finish_reason":"stop"}]}
        """.data(using: .utf8)!

        let client = makeClient()
        let req = ChatCompletionRequest(messages: [ChatMessage(role: "user", content: "hello")])
        _ = try await client.ai.createChatCompletion(req)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/chat/completions"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/chat/completions"))

        let body = lastCapturedBody()
        XCTAssertNotNil(body?["messages"])
    }

    func testCreateEmbedding() async throws {
        MockURLProtocol.responseData = """
        {"data":[{"embedding":[0.1,0.2],"index":0}]}
        """.data(using: .utf8)!

        let client = makeClient()
        let req = EmbeddingRequest(input: "test")
        _ = try await client.ai.createEmbedding(req)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/embeddings"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/embeddings"))

        let body = lastCapturedBody()
        XCTAssertEqual(body?["input"] as? String, "test")
    }

    func testCreateImage() async throws {
        MockURLProtocol.responseData = """
        {"data":[{"url":"https://example.com/img.png"}]}
        """.data(using: .utf8)!

        let client = makeClient()
        let req = ImageGenerationRequest(prompt: "a cat")
        _ = try await client.ai.createImage(req)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/images/generations"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/images/generations"))

        let body = lastCapturedBody()
        XCTAssertEqual(body?["prompt"] as? String, "a cat")
    }

    func testCreateModeration() async throws {
        MockURLProtocol.responseData = """
        {"results":[{"flagged":false}]}
        """.data(using: .utf8)!

        let client = makeClient()
        let req = ModerationRequest(input: "hello world")
        _ = try await client.ai.createModeration(req)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/moderations"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/ai/moderations"))
    }

    func testGetUsageSummary() async throws {
        MockURLProtocol.responseData = """
        {"total_requests":10,"total_tokens":500}
        """.data(using: .utf8)!

        let client = makeClient()
        let summary = try await client.ai.getUsageSummary()
        XCTAssertEqual(summary.totalRequests, 10)
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/ai/usage/summary"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/ai/usage/summary"))
    }

    // MARK: - Devices Service

    func testDevicesList() async throws {
        MockURLProtocol.responseData = """
        {"devices":[{"device_name":"Device A"}],"count":1}
        """.data(using: .utf8)!

        let client = makeClient()
        let catalog = try await client.devices.list()
        XCTAssertEqual(catalog.allDevices.count, 1)
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/devices"))
        XCTAssertTrue(routeExists(method: "GET", path: "/apps/test-app/devices"))
    }

    func testDevicesGetAll() async throws {
        MockURLProtocol.responseData = """
        {"devices":[{"device_name":"A"},{"device_name":"B"}],"count":2}
        """.data(using: .utf8)!

        let client = makeClient()
        let devices = try await client.devices.getAll()
        XCTAssertEqual(devices.count, 2)
        XCTAssertEqual(devices[0].deviceName, "A")
    }

    // MARK: - Endpoints Service

    func testEndpointsCreate() async throws {
        MockURLProtocol.responseData = """
        {"slug":"abc","status":"active","expires_at":9999999,"endpoint_path":"/events/abc"}
        """.data(using: .utf8)!

        let client = makeClient()
        let ep = try await client.endpoints.create()
        XCTAssertEqual(ep.slug, "abc")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/endpoints"))
    }

    func testEndpointsRevokeAndReplace() async throws {
        MockURLProtocol.responseData = """
        {"old_slug":"old","new_slug":"new","new_endpoint_path":"/events/new","revoked_expires_at":100,"new_expires_at":9999}
        """.data(using: .utf8)!

        let client = makeClient()
        let result = try await client.endpoints.revokeAndReplace(oldSlug: "old")
        XCTAssertEqual(result.oldSlug, "old")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints/revoke_and_replace"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/endpoints/revoke_and_replace"))
    }

    func testEndpointsRevoke() async throws {
        MockURLProtocol.responseData = """
        {"slug":"my-slug","revoked":true}
        """.data(using: .utf8)!

        let client = makeClient()
        let result = try await client.endpoints.revoke(slug: "my-slug")
        XCTAssertTrue(result.revoked)
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/apps/test-app/endpoints/revoke"))
        XCTAssertTrue(routeExists(method: "POST", path: "/apps/test-app/endpoints/revoke"))
    }

    func testPostEvent() async throws {
        MockURLProtocol.responseData = """
        {"slug":"my-slug","timestamp":12345,"expires_at":99999}
        """.data(using: .utf8)!

        let client = makeClient()
        let payload: [String: AnyCodable] = ["text": AnyCodable("hello")]
        let result = try await client.endpoints.postEvent(slug: "my-slug", payload: payload)
        XCTAssertEqual(result.slug, "my-slug")
        XCTAssertEqual(lastCapturedMethod(), "POST")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/events/my-slug"))
        XCTAssertTrue(routeExists(method: "POST", path: "/events/my-slug"))
    }

    func testConsumeEvent() async throws {
        MockURLProtocol.responseData = """
        {"slug":"my-slug","empty":true}
        """.data(using: .utf8)!

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
        MockURLProtocol.responseData = """
        {"items":[]}
        """.data(using: .utf8)!

        let client = makeClient()
        _ = try await client.lookupTables.list()
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/lookup-tables"))
        XCTAssertTrue(routeExists(method: "GET", path: "/lookup-tables"))
    }

    func testLookupTablesGet() async throws {
        MockURLProtocol.responseData = """
        {
            "lookup_table_id":"lt-1","name":"Colors","schema_keys":["hex"],
            "schema_key_count":1,"schema_keys_truncated":false,"version":1,
            "payload_hash":"abc","storage_mode":"chunked","chunk_count":1,
            "updated_at":1000,"chunk_encoding":"json","manifest_hash":"xyz",
            "chunks":[{"index":0,"path":"c0.json","sha256":"h","byte_length":10}]
        }
        """.data(using: .utf8)!

        let client = makeClient()
        let detail = try await client.lookupTables.get(lookupTableId: "lt-1")
        XCTAssertEqual(detail.lookupTableId, "lt-1")
        XCTAssertEqual(detail.name, "Colors")
        XCTAssertEqual(lastCapturedMethod(), "GET")
        XCTAssertTrue(lastCapturedPath()!.hasSuffix("/lookup-tables/lt-1"))
        XCTAssertTrue(routeExists(method: "GET", path: "/lookup-tables/lt-1"))
    }

    func testLookupTablesGetChunk() async throws {
        MockURLProtocol.responseData = """
        {"key":"value"}
        """.data(using: .utf8)!

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

    // MARK: - Response Decoding Validation

    func testAppInfoDecodesFromRealShape() throws {
        let json = """
        {"app_id":"myapp","name":"My App","slug":"myapp","description":"desc","created_at":"2025-01-01T00:00:00Z","updated_at":"2025-01-01T00:00:00Z"}
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(AppInfo.self, from: json)
        XCTAssertEqual(info.appId, "myapp")
        XCTAssertEqual(info.slug, "myapp")
    }

    func testDeviceCatalogDecodesFromRealShape() throws {
        let json = """
        {"devices":[{"device_name":"iPhone","device_id":"d1","device_type":"phone","tags":["ios"]}],"count":1}
        """.data(using: .utf8)!
        let catalog = try JSONDecoder().decode(DeviceCatalogResponse.self, from: json)
        XCTAssertEqual(catalog.allDevices.count, 1)
        XCTAssertEqual(catalog.allDevices[0].deviceName, "iPhone")
    }

    func testLookupTableSummaryDecodesFromRealShape() throws {
        let json = """
        {"lookup_table_id":"lt-1","name":"Colors","description":null,"schema_keys":["hex","name"],"schema_key_count":2,"schema_keys_truncated":false,"version":3,"payload_hash":"abc","storage_mode":"chunked","chunk_count":2,"updated_at":1700000000}
        """.data(using: .utf8)!
        let summary = try JSONDecoder().decode(LookupTableSummary.self, from: json)
        XCTAssertEqual(summary.lookupTableId, "lt-1")
        XCTAssertEqual(summary.schemaKeys.count, 2)
    }

    func testChatCompletionResponseDecodesFromRealShape() throws {
        let json = """
        {"id":"chatcmpl-1","object":"chat.completion","created":1700000000,"model":"gpt-4","choices":[{"index":0,"message":{"role":"assistant","content":"Hello!"},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.content, "Hello!")
        XCTAssertEqual(response.usage?.totalTokens, 15)
    }

    func testCreateEndpointResponseDecodesFromRealShape() throws {
        let json = """
        {"slug":"abc123","status":"active","expires_at":1700000000,"endpoint_path":"/events/abc123","hmac_secret":"secret","hmac_required":true}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(CreateEndpointResponse.self, from: json)
        XCTAssertEqual(response.slug, "abc123")
        XCTAssertEqual(response.hmacSecret, "secret")
        XCTAssertEqual(response.hmacRequired, true)
    }

    func testConsumedEventDecodesFromRealShape() throws {
        let json = """
        {"slug":"my-slug","timestamp":12345,"created_at":12300,"expires_at":99999,"text":"hello","keywords":["greeting"],"raw_text":"hello world","empty":false}
        """.data(using: .utf8)!
        let event = try JSONDecoder().decode(ConsumedEvent.self, from: json)
        XCTAssertEqual(event.slug, "my-slug")
        XCTAssertEqual(event.text, "hello")
        XCTAssertEqual(event.keywords, ["greeting"])
        XCTAssertEqual(event.empty, false)
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
        let ts = 1700000000

        let headers = generateHmacSignature(slug: slug, body: body, secret: secret, timestampSec: ts)

        // Should verify with matching timestamp within skew
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
