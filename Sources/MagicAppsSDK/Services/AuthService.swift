import Foundation

/// Authentication service module. Available on all platforms.
public class AuthService: ServiceModule {
    public let name = "auth"
    public let platforms: [SdkPlatform] = [] // all platforms

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Register a new user account.
    public func register(email: String, password: String, name: String? = nil) async throws -> RegisterResponse {
        let body = RegisterRequest(email: email, password: password, name: name)
        return try await http.post("/auth/register", body: body, authMode: .none)
    }

    /// Authenticate with email and password.
    public func login(email: String, password: String) async throws -> LoginResponse {
        let body = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await http.post("/auth/login", body: body, authMode: .none)
        await http.tokenManager.setTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        return response
    }

    /// Log out and clear stored tokens.
    public func logout() async throws {
        let _: EmptyResponse = try await http.post("/auth/logout", authMode: .bearer)
        await http.tokenManager.clearTokens()
    }
}

public struct LoginRequest: Encodable {
    public let email: String
    public let password: String
}

public struct LoginResponse: Decodable {
    public let accessToken: String
    public let refreshToken: String?
    public let idToken: String?
    public let expiresIn: Int?
}

public struct RegisterRequest: Encodable {
    public let email: String
    public let password: String
    public let name: String?
}

public struct RegisterResponse: Decodable {
    public let userId: String
    public let email: String
    public let confirmed: Bool
}

struct EmptyResponse: Decodable {}
