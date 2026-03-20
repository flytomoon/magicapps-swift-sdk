import Foundation

// MARK: - Common Auth Types

public struct TokenRefreshRequest: Encodable {
    public let refresh_token: String
}

public struct TokenRefreshResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int?
}

public struct LinkProviderRequest: Encodable {
    public let provider: String
    public let token: String
}

public struct LinkProviderResponse: Decodable {
    public let success: Bool
    public let linkedProviders: [String]
}

// MARK: - Passkey Types

public struct PasskeyRegisterOptionsResponse: Decodable {
    public let challenge: String
    public let rp: RelyingParty
    public let user: PasskeyUser
    public let timeout: Int?

    public struct RelyingParty: Decodable {
        public let id: String
        public let name: String
    }

    public struct PasskeyUser: Decodable {
        public let id: String
        public let name: String
        public let displayName: String
    }
}

public struct PasskeyRegisterVerifyRequest: Encodable {
    public let id: String
    public let rawId: String
    public let type: String
    public let response: AttestationResponse

    public struct AttestationResponse: Encodable {
        public let attestationObject: String
        public let clientDataJSON: String
    }
}

public struct PasskeyRegisterVerifyResponse: Decodable {
    public let success: Bool
    public let credentialId: String
}

public struct PasskeyAuthOptionsResponse: Decodable {
    public let challenge: String
    public let timeout: Int?
    public let rpId: String?
    public let userVerification: String?
}

public struct PasskeyAuthVerifyRequest: Encodable {
    public let id: String
    public let rawId: String
    public let type: String
    public let response: AssertionResponse

    public struct AssertionResponse: Encodable {
        public let authenticatorData: String
        public let clientDataJSON: String
        public let signature: String
        public let userHandle: String?
    }
}

public struct PasskeyAuthVerifyResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String?
}

// MARK: - Apple Sign-In Types

public struct AppleExchangeRequest: Encodable {
    public let identityToken: String
    public let authorizationCode: String?
    public let user: AppleUser?

    public struct AppleUser: Encodable {
        public let email: String?
        public let name: AppleName?

        public struct AppleName: Encodable {
            public let firstName: String?
            public let lastName: String?
        }
    }
}

public struct AppleExchangeResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String?
    public let isNewUser: Bool?
}

struct EmptyResponse: Decodable {}
struct EmptyBody: Encodable {}

// MARK: - Auth Service (All Platforms)

/// Core authentication service module.
/// Provides passkey auth, token refresh, and identity linking.
/// Available on all platforms.
public class AuthService: ServiceModule {
    public let name = "auth"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    // MARK: - Token Refresh

    /// Refresh access token using stored refresh token.
    public func refreshToken(_ refreshToken: String) async throws -> TokenRefreshResponse {
        let body = TokenRefreshRequest(refresh_token: refreshToken)
        let response: TokenRefreshResponse = try await http.post("/auth/client/refresh", body: body, authMode: .none)
        await http.tokenManager.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }

    // MARK: - Identity Linking

    /// Link an additional auth provider to the current account.
    public func linkProvider(provider: String, token: String) async throws -> LinkProviderResponse {
        let body = LinkProviderRequest(provider: provider, token: token)
        return try await http.post("/auth/client/link", body: body, authMode: .bearer)
    }

    // MARK: - Passkey Registration

    /// Get passkey registration options (challenge) from the server.
    public func getPasskeyRegisterOptions() async throws -> PasskeyRegisterOptionsResponse {
        return try await http.post("/auth/client/passkey/register/options", body: EmptyBody(), authMode: .bearer)
    }

    /// Complete passkey registration by verifying the credential.
    public func verifyPasskeyRegistration(_ credential: PasskeyRegisterVerifyRequest) async throws -> PasskeyRegisterVerifyResponse {
        return try await http.post("/auth/client/passkey/register/verify", body: credential, authMode: .bearer)
    }

    // MARK: - Passkey Authentication

    /// Get passkey authentication options (challenge) from the server.
    public func getPasskeyAuthOptions() async throws -> PasskeyAuthOptionsResponse {
        return try await http.post("/auth/client/passkey/authenticate/options", body: EmptyBody(), authMode: .none)
    }

    /// Complete passkey authentication by verifying the assertion.
    public func verifyPasskeyAuth(_ assertion: PasskeyAuthVerifyRequest) async throws -> PasskeyAuthVerifyResponse {
        let response: PasskeyAuthVerifyResponse = try await http.post("/auth/client/passkey/authenticate/verify", body: assertion, authMode: .none)
        await http.tokenManager.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }

}

// MARK: - Apple Sign-In Service (iOS Only)

/// Apple Sign-In authentication module.
/// Only available on iOS.
public class AppleAuthService: ServiceModule {
    public let name = "apple-auth"
    public let platforms: [SdkPlatform] = [.ios]

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Exchange an Apple identity token for MagicApps access + refresh tokens.
    public func exchangeToken(_ request: AppleExchangeRequest) async throws -> AppleExchangeResponse {
        let response: AppleExchangeResponse = try await http.post("/auth/client/apple/exchange", body: request, authMode: .none)
        await http.tokenManager.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }
}
