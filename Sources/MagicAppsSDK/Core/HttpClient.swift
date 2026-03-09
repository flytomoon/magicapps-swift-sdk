import Foundation

/// Internal HTTP client for the MagicApps SDK.
/// Wraps URLSession with app_id scoping, authentication, retries, and typed errors.
public class SdkHttpClient {
    let tokenManager: TokenManager
    private let baseUrl: URL
    private let appId: String
    private let session: URLSession
    private let defaultRetries: Int
    private let retryDelay: TimeInterval

    init(config: SdkConfig) {
        self.baseUrl = config.baseUrl
        self.appId = config.appId
        self.session = config.session
        self.defaultRetries = config.retries
        self.retryDelay = config.retryDelay
        self.tokenManager = TokenManager(config: config)
    }

    /// Make a GET request.
    public func get<T: Decodable>(
        _ path: String,
        query: [String: String]? = nil,
        authMode: AuthMode = .bearer
    ) async throws -> T {
        return try await request(method: "GET", path: path, body: nil as String?, query: query, authMode: authMode)
    }

    /// Make a POST request.
    public func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B? = nil as String?,
        authMode: AuthMode = .bearer
    ) async throws -> T {
        return try await request(method: "POST", path: path, body: body, authMode: authMode)
    }

    /// Make a PUT request.
    public func put<T: Decodable, B: Encodable>(
        _ path: String,
        body: B? = nil as String?,
        authMode: AuthMode = .bearer
    ) async throws -> T {
        return try await request(method: "PUT", path: path, body: body, authMode: authMode)
    }

    /// Make a DELETE request.
    public func delete<T: Decodable>(
        _ path: String,
        authMode: AuthMode = .bearer
    ) async throws -> T {
        return try await request(method: "DELETE", path: path, body: nil as String?, authMode: authMode)
    }

    private func request<T: Decodable, B: Encodable>(
        method: String,
        path: String,
        body: B?,
        query: [String: String]? = nil,
        authMode: AuthMode = .bearer,
        retries: Int? = nil
    ) async throws -> T {
        let maxRetries = retries ?? defaultRetries
        let url = buildUrl(path: path, query: query)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(appId, forHTTPHeaderField: "X-App-Id")

        if let authHeader = try await tokenManager.getAuthHeader(mode: authMode) {
            urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }

        if let body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }

        var attempt = 0
        while true {
            do {
                let (data, response) = try await session.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SdkError.networkError("Invalid response", nil)
                }

                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    if httpResponse.statusCode == 204 || data.isEmpty {
                        // For 204 or empty responses, return empty JSON object
                        let emptyData = "{}".data(using: .utf8)!
                        return try JSONDecoder().decode(T.self, from: emptyData)
                    }
                    return try JSONDecoder().decode(T.self, from: data)
                }

                let payload = try? JSONDecoder().decode(ApiErrorPayload.self, from: data)
                let error = SdkError.from(status: httpResponse.statusCode, payload: payload)

                let isIdempotent = method == "GET"
                let isRetryable = httpResponse.statusCode >= 500 || httpResponse.statusCode == 429

                if attempt < maxRetries && isIdempotent && isRetryable {
                    let backoff = retryDelay * pow(2.0, Double(attempt))
                    attempt += 1
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                }

                throw error

            } catch let error as SdkError {
                throw error
            } catch {
                let isIdempotent = method == "GET"
                if attempt < maxRetries && isIdempotent {
                    let backoff = retryDelay * pow(2.0, Double(attempt))
                    attempt += 1
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                }
                throw SdkError.networkError("Network request failed", error)
            }
        }
    }

    private func buildUrl(path: String, query: [String: String]? = nil) -> URL {
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        var components = URLComponents(url: baseUrl.appendingPathComponent(normalizedPath), resolvingAgainstBaseURL: true)!

        if let query, !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        return components.url!
    }
}
