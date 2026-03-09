import Foundation

/// Manages JWT access tokens and owner tokens for the SDK.
/// Handles automatic token refresh when a refresh token is available.
public actor TokenManager {
    private var accessToken: String?
    private var refreshToken: String?
    private var ownerToken: String?
    private var refreshTask: Task<String?, Error>?
    private let baseUrl: URL
    private let session: URLSession
    private let onTokenRefresh: ((TokenPair) -> Void)?

    init(config: SdkConfig) {
        self.accessToken = config.accessToken
        self.refreshToken = config.refreshToken
        self.ownerToken = config.ownerToken
        self.baseUrl = config.baseUrl
        self.session = config.session
        self.onTokenRefresh = config.onTokenRefresh
    }

    /// Get the current access token, refreshing if expired.
    func getAccessToken() async throws -> String? {
        if let token = accessToken, !isTokenExpired(token) {
            return token
        }
        if refreshToken != nil {
            return try await refreshAccessToken()
        }
        return accessToken
    }

    /// Get the owner token.
    func getOwnerToken() -> String? {
        return ownerToken
    }

    /// Get the authorization header value for a given auth mode.
    func getAuthHeader(mode: AuthMode) async throws -> String? {
        switch mode {
        case .bearer:
            guard let token = try await getAccessToken() else { return nil }
            return "Bearer \(token)"
        case .owner:
            guard let token = getOwnerToken() else { return nil }
            return "Bearer \(token)"
        case .none:
            return nil
        }
    }

    /// Update stored tokens.
    func setTokens(accessToken: String? = nil, refreshToken: String? = nil, ownerToken: String? = nil) {
        if let accessToken { self.accessToken = accessToken }
        if let refreshToken { self.refreshToken = refreshToken }
        if let ownerToken { self.ownerToken = ownerToken }
    }

    /// Clear all stored tokens.
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        ownerToken = nil
    }

    private func isTokenExpired(_ token: String) -> Bool {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return true }

        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padLength = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: padLength)

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return true
        }

        // 30-second buffer
        return Date().timeIntervalSince1970 > (exp - 30)
    }

    private func refreshAccessToken() async throws -> String? {
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task<String?, Error> {
            guard let rt = refreshToken else { return nil }

            let url = baseUrl.appendingPathComponent("/auth/refresh")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["refresh_token": rt])

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                accessToken = nil
                refreshToken = nil
                return nil
            }

            struct RefreshResponse: Decodable {
                let accessToken: String
                let refreshToken: String?
            }

            let tokens = try JSONDecoder().decode(RefreshResponse.self, from: data)
            accessToken = tokens.accessToken
            if let newRefresh = tokens.refreshToken {
                refreshToken = newRefresh
            }

            onTokenRefresh?(TokenPair(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken))
            return tokens.accessToken
        }

        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}
