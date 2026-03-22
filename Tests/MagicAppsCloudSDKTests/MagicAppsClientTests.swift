import Testing
import Foundation
@testable import MagicAppsCloudSDK

@Suite
struct MagicAppsClientTests {

    @Test func sdkConfigInitialization() {
        let config = SdkConfig(
            baseUrl: URL(string: "https://api.example.com")!,
            appId: "test-app"
        )
        #expect(config.appId == "test-app")
        #expect(config.baseUrl.absoluteString == "https://api.example.com")
        #expect(config.accessToken == nil)
        #expect(config.retries == 2)
    }

    @Test func sdkConfigWithTokens() {
        let config = SdkConfig(
            baseUrl: URL(string: "https://api.example.com")!,
            appId: "test-app",
            accessToken: "my-token",
            refreshToken: "my-refresh",
            retries: 5,
            retryDelay: 1.0
        )
        #expect(config.accessToken == "my-token")
        #expect(config.refreshToken == "my-refresh")
        #expect(config.retries == 5)
        #expect(config.retryDelay == 1.0)
    }

    @Test func clientInitialization() {
        let config = SdkConfig(
            baseUrl: URL(string: "https://api.example.com")!,
            appId: "test-app"
        )
        let client = MagicAppsClient(config: config)
        #expect(client != nil)
    }

    @Test func appInfoDecoding() throws {
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
        #expect(appInfo.appId == "test-app")
        #expect(appInfo.name == "Test App")
        #expect(appInfo.slug == "test-app")
        #expect(appInfo.description == "A test application")
    }

    @Test func templateDecoding() throws {
        // Source: openapi.yaml Template schema — created_at/updated_at are type: number (epoch)
        let json = """
        {
            "template_id": "tmpl-1",
            "app_id": "test-app",
            "template_name": "Test Template",
            "description": null,
            "created_at": 1735689600,
            "updated_at": 1735689600
        }
        """.data(using: .utf8)!

        let template = try JSONDecoder().decode(Template.self, from: json)
        #expect(template.templateId == "tmpl-1")
        #expect(template.appId == "test-app")
        #expect(template.templateName == "Test Template")
        #expect(template.description == nil)
    }

    @Test func sdkErrorDescriptions() {
        let configError = SdkError.configError("missing appId")
        #expect(configError.description.contains("Config Error"))

        let apiError = SdkError.apiError(404, "Not Found", nil)
        #expect(apiError.description.contains("404"))

        let networkError = SdkError.networkError("timeout", nil)
        #expect(networkError.description.contains("Network Error"))
    }

    @Test func sdkErrorFromStatus() {
        let error401 = SdkError.from(status: 401, payload: nil)
        if case .unauthorized = error401 {
            // Expected
        } else {
            Issue.record("Expected unauthorized error for 401")
        }

        let error404 = SdkError.from(status: 404, payload: nil)
        if case .notFound = error404 {
            // Expected
        } else {
            Issue.record("Expected notFound error for 404")
        }

        let error500 = SdkError.from(status: 500, payload: nil)
        if case .serverError = error500 {
            // Expected
        } else {
            Issue.record("Expected serverError for 500")
        }
    }

}
