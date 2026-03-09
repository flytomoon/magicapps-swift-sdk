import XCTest
@testable import MagicAppsSDK

final class MagicAppsClientTests: XCTestCase {

    func testSdkConfigInitialization() {
        let config = SdkConfig(
            baseUrl: URL(string: "https://api.example.com")!,
            appId: "test-app"
        )
        XCTAssertEqual(config.appId, "test-app")
        XCTAssertEqual(config.baseUrl.absoluteString, "https://api.example.com")
        XCTAssertNil(config.accessToken)
        XCTAssertEqual(config.retries, 2)
    }

    func testSdkConfigWithTokens() {
        let config = SdkConfig(
            baseUrl: URL(string: "https://api.example.com")!,
            appId: "test-app",
            accessToken: "my-token",
            refreshToken: "my-refresh",
            retries: 5,
            retryDelay: 1.0
        )
        XCTAssertEqual(config.accessToken, "my-token")
        XCTAssertEqual(config.refreshToken, "my-refresh")
        XCTAssertEqual(config.retries, 5)
        XCTAssertEqual(config.retryDelay, 1.0)
    }

    func testClientInitialization() {
        let config = SdkConfig(
            baseUrl: URL(string: "https://api.example.com")!,
            appId: "test-app"
        )
        let client = MagicAppsClient(config: config)
        XCTAssertNotNil(client)
    }

    func testAppInfoDecoding() throws {
        let json = """
        {
            "app_id": "test-app",
            "name": "Test App",
            "slug": "test-app",
            "description": "A test application",
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let appInfo = try JSONDecoder().decode(AppInfo.self, from: json)
        XCTAssertEqual(appInfo.appId, "test-app")
        XCTAssertEqual(appInfo.name, "Test App")
        XCTAssertEqual(appInfo.slug, "test-app")
        XCTAssertEqual(appInfo.description, "A test application")
    }

    func testTemplateDecoding() throws {
        let json = """
        {
            "template_id": "tmpl-1",
            "app_id": "test-app",
            "name": "Test Template",
            "description": null,
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let template = try JSONDecoder().decode(Template.self, from: json)
        XCTAssertEqual(template.templateId, "tmpl-1")
        XCTAssertEqual(template.appId, "test-app")
        XCTAssertEqual(template.name, "Test Template")
        XCTAssertNil(template.description)
    }

    func testSdkErrorDescriptions() {
        let configError = SdkError.configError("missing appId")
        XCTAssertTrue(configError.description.contains("Config Error"))

        let apiError = SdkError.apiError(404, "Not Found", nil)
        XCTAssertTrue(apiError.description.contains("404"))

        let networkError = SdkError.networkError("timeout", nil)
        XCTAssertTrue(networkError.description.contains("Network Error"))
    }

    func testSdkErrorFromStatus() {
        let error401 = SdkError.from(status: 401, payload: nil)
        if case .unauthorized = error401 {
            // Expected
        } else {
            XCTFail("Expected unauthorized error for 401")
        }

        let error404 = SdkError.from(status: 404, payload: nil)
        if case .notFound = error404 {
            // Expected
        } else {
            XCTFail("Expected notFound error for 404")
        }

        let error500 = SdkError.from(status: 500, payload: nil)
        if case .serverError = error500 {
            // Expected
        } else {
            XCTFail("Expected serverError for 500")
        }
    }
}
