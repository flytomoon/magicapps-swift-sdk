import Foundation

/// Apple IAP service module. Only available on iOS.
public class AppleIapService: ServiceModule {
    public let name = "apple-iap"
    public let platforms: [SdkPlatform] = [.ios]

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Verify an Apple App Store transaction.
    public func verifyTransaction(transactionId: String, receiptData: String? = nil) async throws -> IapVerifyResponse {
        let body = IapVerifyRequest(transactionId: transactionId, receiptData: receiptData)
        return try await http.post("/iap/transactions/verify", body: body)
    }

    /// Restore previously purchased transactions.
    public func restorePurchases() async throws -> IapRestoreResponse {
        return try await http.post("/iap/restore/sync", body: [String: String]())
    }
}

public struct IapVerifyRequest: Encodable {
    public let transactionId: String
    public let receiptData: String?
}

public struct IapVerifyResponse: Decodable {
    public let valid: Bool
    public let productId: String?
    public let expiresDate: String?
    public let transactionId: String?
}

public struct IapRestoreResponse: Decodable {
    public struct RestoredTransaction: Decodable {
        public let transactionId: String
        public let productId: String
        public let expiresDate: String?
    }
    public let restoredTransactions: [RestoredTransaction]
}
