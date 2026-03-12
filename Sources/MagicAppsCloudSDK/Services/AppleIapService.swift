import Foundation

// MARK: - Entitlement Types

/// Status of an entitlement.
public enum EntitlementStatus: String, Decodable {
    case active
    case expired
    case pending
    case revoked
    case gracePeriod = "grace_period"
}

/// A typed entitlement object indicating subscription/purchase status.
public struct Entitlement: Decodable {
    /// The product ID this entitlement is for.
    public let productId: String
    /// Current status of the entitlement.
    public let status: EntitlementStatus
    /// When the entitlement was originally purchased.
    public let purchaseDate: String?
    /// When the entitlement expires (for subscriptions).
    public let expiresDate: String?
    /// The transaction ID that granted this entitlement.
    public let transactionId: String?
    /// Whether this is a trial period.
    public let isTrial: Bool?
    /// Whether auto-renew is enabled (subscriptions).
    public let autoRenewing: Bool?
    /// The renewal product ID if upgrading/downgrading.
    public let renewalProductId: String?
}

// MARK: - IAP Request/Response Types

public struct IapVerifyRequest: Encodable {
    /// The StoreKit 2 transaction ID or original transaction ID.
    public let transactionId: String
    /// Base64-encoded receipt data (StoreKit 1 compatibility).
    public let receiptData: String?
    /// The product ID being verified.
    public let productId: String?

    public init(transactionId: String, receiptData: String? = nil, productId: String? = nil) {
        self.transactionId = transactionId
        self.receiptData = receiptData
        self.productId = productId
    }
}

public struct IapVerifyResponse: Decodable {
    /// Whether the transaction is valid.
    public let valid: Bool
    /// The verified product ID.
    public let productId: String?
    /// When the entitlement expires.
    public let expiresDate: String?
    /// The verified transaction ID.
    public let transactionId: String?
    /// Typed entitlement with status.
    public let entitlement: Entitlement?
}

public struct IapRestoreRequest: Encodable {
    /// Array of local transaction IDs to reconcile.
    public let transactionIds: [String]?

    public init(transactionIds: [String]? = nil) {
        self.transactionIds = transactionIds
    }
}

public struct IapRestoreResponse: Decodable {
    public struct RestoredTransaction: Decodable {
        public let transactionId: String
        public let productId: String
        public let expiresDate: String?
        public let status: EntitlementStatus
    }
    /// Restored transactions with entitlement status.
    public let restoredTransactions: [RestoredTransaction]
    /// All current entitlements after restore.
    public let entitlements: [Entitlement]
}

/// Client commerce configuration from the platform backend.
public struct ClientCommerceConfig: Decodable {
    /// The app ID this config belongs to.
    public let appId: String?
    /// Available purchase modes.
    public let purchaseModes: [String]?
    /// UX copy for payment screens.
    public let uxCopy: UxCopy?
    /// Product catalog from the backend.
    public let products: [Product]?
    /// Feature flags for commerce features.
    public let features: [String: Bool]?

    public struct UxCopy: Decodable {
        public let purchaseButtonText: String?
        public let restoreButtonText: String?
        public let subscriptionTerms: String?
        public let trialDescription: String?
    }

    public struct Product: Decodable {
        public let productId: String
        public let name: String
        public let description: String?
        public let type: String
    }
}

// MARK: - Apple IAP Service

/// Apple IAP service module.
/// Only available on iOS.
///
/// Provides transaction verification, purchase restoration/sync,
/// entitlement checking, and client commerce config access.
public class AppleIapService: ServiceModule {
    public let name = "apple-iap"
    public let platforms: [SdkPlatform] = [.ios]

    private let http: SdkHttpClient

    init(http: SdkHttpClient) {
        self.http = http
    }

    /// Verify an Apple App Store transaction.
    /// Accepts a transaction receipt and returns entitlement status.
    ///
    /// Error cases:
    /// - Invalid receipt → SdkError with details
    /// - Expired entitlement → returns valid:true with entitlement.status = .expired
    /// - Network failure → retryable SdkError.networkError
    public func verifyTransaction(_ request: IapVerifyRequest) async throws -> IapVerifyResponse {
        return try await http.post("/iap/transactions/verify", body: request)
    }

    /// Convenience: verify a transaction by ID only.
    public func verifyTransaction(transactionId: String, receiptData: String? = nil, productId: String? = nil) async throws -> IapVerifyResponse {
        let request = IapVerifyRequest(transactionId: transactionId, receiptData: receiptData, productId: productId)
        return try await verifyTransaction(request)
    }

    /// Restore and sync previously purchased transactions with the platform backend.
    /// Reconciles local IAP transactions with server-side records.
    ///
    /// Returns all restored transactions with their current entitlement status,
    /// plus a full list of active entitlements.
    public func restorePurchases(transactionIds: [String]? = nil) async throws -> IapRestoreResponse {
        let request = IapRestoreRequest(transactionIds: transactionIds)
        return try await http.post("/iap/restore/sync", body: request)
    }

    /// Fetch the current client commerce configuration.
    /// Includes purchase modes, UX copy, and product information.
    public func getClientConfig() async throws -> ClientCommerceConfig {
        return try await http.get("/client-config", authMode: .none)
    }

    /// Check the current entitlement status for a specific product.
    /// Convenience method that verifies a transaction and returns the entitlement.
    ///
    /// Returns nil if the transaction is invalid.
    public func checkEntitlement(transactionId: String, productId: String? = nil) async throws -> Entitlement? {
        let response = try await verifyTransaction(transactionId: transactionId, productId: productId)

        if !response.valid { return nil }

        if let entitlement = response.entitlement {
            return entitlement
        }

        // Construct entitlement from response fields
        let status: EntitlementStatus
        if let expiresDate = response.expiresDate {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: expiresDate), date < Date() {
                status = .expired
            } else {
                status = .active
            }
        } else {
            status = .active
        }

        return Entitlement(
            productId: response.productId ?? "",
            status: status,
            purchaseDate: nil,
            expiresDate: response.expiresDate,
            transactionId: response.transactionId,
            isTrial: nil,
            autoRenewing: nil,
            renewalProductId: nil
        )
    }
}
