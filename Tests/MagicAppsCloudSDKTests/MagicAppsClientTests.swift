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

    @Test func aiUsageRecordDecoding() throws {
        let json = """
        {
            "usage_id": "u-abc-123",
            "app_id": "test-app",
            "provider_id": "openai",
            "model_id": "gpt-4o-mini",
            "request_type": "chat",
            "input_tokens": 100,
            "output_tokens": 50,
            "total_tokens": 150,
            "latency_ms": 420,
            "status": "success",
            "created_at": 1709251200000,
            "expires_at": 1717027200,
            "error_code": null,
            "user_id": "user-42"
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(AiUsageRecord.self, from: json)
        #expect(record.usageId == "u-abc-123")
        #expect(record.appId == "test-app")
        #expect(record.providerId == "openai")
        #expect(record.modelId == "gpt-4o-mini")
        #expect(record.requestType == "chat")
        #expect(record.inputTokens == 100)
        #expect(record.outputTokens == 50)
        #expect(record.totalTokens == 150)
        #expect(record.latencyMs == 420)
        #expect(record.status == "success")
        #expect(record.errorCode == nil)
        #expect(record.userId == "user-42")
    }

    @Test func aiUsageRecordDecodingWithError() throws {
        let json = """
        {
            "usage_id": "u-err-456",
            "app_id": "test-app",
            "provider_id": "anthropic",
            "model_id": "claude-sonnet-4-20250514",
            "request_type": "chat",
            "input_tokens": 0,
            "output_tokens": 0,
            "total_tokens": 0,
            "latency_ms": 120,
            "status": "error",
            "created_at": 1709251200000,
            "expires_at": 1717027200,
            "error_code": "rate_limited"
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(AiUsageRecord.self, from: json)
        #expect(record.status == "error")
        #expect(record.errorCode == "rate_limited")
        #expect(record.userId == nil)
    }

    @Test func aiUsageResponseDecoding() throws {
        let json = """
        {
            "usage": [
                {
                    "usage_id": "u-1",
                    "app_id": "test-app",
                    "provider_id": "openai",
                    "model_id": "gpt-4o-mini",
                    "request_type": "chat",
                    "input_tokens": 100,
                    "output_tokens": 50,
                    "total_tokens": 150,
                    "latency_ms": 420,
                    "status": "success",
                    "created_at": 1709251200000,
                    "expires_at": 1717027200
                }
            ],
            "count": 1
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AiUsageResponse.self, from: json)
        #expect(response.count == 1)
        #expect(response.usage.count == 1)
        #expect(response.usage[0].usageId == "u-1")
    }
}
