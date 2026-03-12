import Foundation
import CommonCrypto

/// Configuration for certificate pinning.
///
/// Certificate pinning protects against man-in-the-middle attacks by validating
/// that the server's TLS certificate matches a known set of public key hashes.
///
/// Pins are SHA-256 hashes of the Subject Public Key Info (SPKI), encoded as
/// base64 strings (the standard format used by HTTP Public Key Pinning).
///
/// ```swift
/// let pinning = CertificatePinningConfig(
///     pins: ["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="],
///     includeBuiltInPins: true
/// )
/// let config = SdkConfig(
///     baseUrl: URL(string: "https://api.magicapps.dev")!,
///     appId: "my-app",
///     certificatePinning: pinning
/// )
/// ```
public struct CertificatePinningConfig {
    /// SHA-256 SPKI pin hashes (base64 encoded).
    /// At least one pin must match the server certificate chain for the connection to succeed.
    public let pins: [String]

    /// Whether certificate pinning is enabled. Set to `false` for development/testing.
    /// Default: `true`.
    public var enabled: Bool

    /// Whether to include the built-in pins for the Magic Apps Cloud API domain.
    /// When `true`, the SDK's bundled pins for `api.magicapps.dev` are appended
    /// to the custom `pins` array. Default: `true`.
    public var includeBuiltInPins: Bool

    public init(
        pins: [String] = [],
        enabled: Bool = true,
        includeBuiltInPins: Bool = true
    ) {
        self.pins = pins
        self.enabled = enabled
        self.includeBuiltInPins = includeBuiltInPins
    }

    /// All effective pins (custom + built-in if enabled).
    internal var effectivePins: [String] {
        var allPins = pins
        if includeBuiltInPins {
            allPins.append(contentsOf: CertificatePinningConfig.builtInPins)
        }
        return allPins
    }

    /// Built-in pins for the Magic Apps Cloud API domain (api.magicapps.dev).
    /// These correspond to the current and backup certificate public key hashes.
    /// Update these when rotating certificates.
    internal static let builtInPins: [String] = [
        // Primary: Let's Encrypt ISRG Root X1 (intermediate CA)
        "sha256/C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=",
        // Backup: Let's Encrypt E5 intermediate
        "sha256/J2/oqMTsdhFWW/n85tys6b4yDBtb6idZayIEBx7QTxA="
    ]
}

/// URLSession delegate that performs certificate pinning validation.
///
/// This delegate intercepts TLS authentication challenges and verifies that
/// the server's certificate chain contains at least one public key whose
/// SHA-256 hash matches the configured pin set. If no pin matches, the
/// connection is cancelled with a clear error — there is no silent fallback.
internal class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    private let pins: [Data] // Decoded pin hashes
    private let enabled: Bool

    init(config: CertificatePinningConfig) {
        self.enabled = config.enabled
        self.pins = config.effectivePins.compactMap { pin in
            // Strip "sha256/" prefix if present
            let base64 = pin.hasPrefix("sha256/") ? String(pin.dropFirst(7)) : pin
            return Data(base64Encoded: base64)
        }
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard enabled else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Evaluate the server trust to ensure the chain is valid first
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)

        guard isValid else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check each certificate in the chain for a matching pin
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        for index in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) {
                let publicKeyHash = hashPublicKey(of: certificate)
                if pins.contains(publicKeyHash) {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }

        // No pin matched — cancel the connection
        completionHandler(.cancelAuthenticationChallenge, nil)
    }

    /// Compute SHA-256 hash of a certificate's Subject Public Key Info (SPKI).
    private func hashPublicKey(of certificate: SecCertificate) -> Data {
        let publicKeyData = extractPublicKeyData(from: certificate)
        return sha256(data: publicKeyData)
    }

    /// Extract raw public key data from a certificate.
    private func extractPublicKeyData(from certificate: SecCertificate) -> Data {
        // Create a trust from the certificate
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        SecTrustCreateWithCertificates(certificate, policy, &trust)

        guard let trust = trust else {
            return Data()
        }

        // Get the public key
        guard let publicKey = SecTrustCopyPublicKey(trust) else {
            return Data()
        }

        // Export the public key as data
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return Data()
        }

        return publicKeyData
    }

    /// SHA-256 hash.
    private func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}
