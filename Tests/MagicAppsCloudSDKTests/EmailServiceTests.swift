import Testing
import Foundation
@testable import MagicAppsCloudSDK

// MARK: - Email Service Type Decoding Tests
//
// These tests verify response type decoding in isolation (no network mock).
// Contract tests (path, method, auth, body assertions) live in ContractTests.swift
// within the serialized ContractTests suite to avoid MockURLProtocol race conditions.

@Suite
struct EmailServiceTests {

    // MARK: - CreateImageTokenResponse

    @Test func createImageTokenResponseDecodes() throws {
        let json = """
        {"token":"img-tok-abc123","image_url":"https://cdn.example.com/email-images/img-tok-abc123.jpg","expires_at":1749676000}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CreateImageTokenResponse.self, from: json)
        #expect(response.token == "img-tok-abc123")
        #expect(response.imageUrl == "https://cdn.example.com/email-images/img-tok-abc123.jpg")
        #expect(response.expiresAt == 1749676000)
    }

    @Test func createImageTokenResponseSnakeCaseMapping() throws {
        // Verify CodingKeys: image_url -> imageUrl, expires_at -> expiresAt
        let json = """
        {"token":"t","image_url":"https://x.com/t.jpg","expires_at":999}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CreateImageTokenResponse.self, from: json)
        #expect(response.imageUrl == "https://x.com/t.jpg")
        #expect(response.expiresAt == 999)
    }

    // MARK: - CreateTextTokenResponse

    @Test func createTextTokenResponseDecodes() throws {
        let json = """
        {"token":"txt-tok-xyz789","text_url":"https://cdn.example.com/email-text/txt-tok-xyz789","expires_at":1749676000}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CreateTextTokenResponse.self, from: json)
        #expect(response.token == "txt-tok-xyz789")
        #expect(response.textUrl == "https://cdn.example.com/email-text/txt-tok-xyz789")
        #expect(response.expiresAt == 1749676000)
    }

    @Test func createTextTokenResponseSnakeCaseMapping() throws {
        // Verify CodingKeys: text_url -> textUrl, expires_at -> expiresAt
        let json = """
        {"token":"t","text_url":"https://x.com/t","expires_at":999}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CreateTextTokenResponse.self, from: json)
        #expect(response.textUrl == "https://x.com/t")
        #expect(response.expiresAt == 999)
    }

    // MARK: - EmailTokenStatus

    @Test func emailTokenStatusDecodesReadyState() throws {
        let json = """
        {"token":"img-tok-abc123","type":"image","state":"ready","ready_at":1741900000,"consumed_at":null,"expires_at":1749676000,"updated_at":1741900000}
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(EmailTokenStatus.self, from: json)
        #expect(status.token == "img-tok-abc123")
        #expect(status.type == "image")
        #expect(status.state == "ready")
        #expect(status.readyAt == 1741900000)
        #expect(status.consumedAt == nil)
        #expect(status.expiresAt == 1749676000)
        #expect(status.updatedAt == 1741900000)
    }

    @Test func emailTokenStatusDecodesConsumedState() throws {
        let json = """
        {"token":"txt-tok-xyz789","type":"text","state":"consumed","ready_at":1741900000,"consumed_at":1741901000,"expires_at":1749676000,"updated_at":1741901000}
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(EmailTokenStatus.self, from: json)
        #expect(status.token == "txt-tok-xyz789")
        #expect(status.type == "text")
        #expect(status.state == "consumed")
        #expect(status.readyAt == 1741900000)
        #expect(status.consumedAt == 1741901000)
        #expect(status.expiresAt == 1749676000)
        #expect(status.updatedAt == 1741901000)
    }

    @Test func emailTokenStatusDecodesPendingState() throws {
        // Pending state has no ready_at or consumed_at
        let json = """
        {"token":"tok-pending","type":"image","state":"pending","expires_at":1749676000,"updated_at":1741800000}
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(EmailTokenStatus.self, from: json)
        #expect(status.token == "tok-pending")
        #expect(status.state == "pending")
        #expect(status.readyAt == nil)
        #expect(status.consumedAt == nil)
        #expect(status.expiresAt == 1749676000)
        #expect(status.updatedAt == 1741800000)
    }

    @Test func emailTokenStatusDecodesExpiredState() throws {
        let json = """
        {"token":"tok-expired","type":"text","state":"expired","ready_at":1741900000,"consumed_at":null,"expires_at":1741900100,"updated_at":1741900100}
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(EmailTokenStatus.self, from: json)
        #expect(status.token == "tok-expired")
        #expect(status.state == "expired")
        #expect(status.readyAt == 1741900000)
        #expect(status.consumedAt == nil)
    }

    @Test func emailTokenStatusSnakeCaseMapping() throws {
        // Verify all CodingKeys map correctly
        let json = """
        {"token":"t","type":"image","state":"ready","ready_at":1,"consumed_at":2,"expires_at":3,"updated_at":4}
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(EmailTokenStatus.self, from: json)
        #expect(status.readyAt == 1)
        #expect(status.consumedAt == 2)
        #expect(status.expiresAt == 3)
        #expect(status.updatedAt == 4)
    }
}
