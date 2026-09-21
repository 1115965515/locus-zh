import Foundation

enum TunnelConfig {
    /// LocalDevVPN peer address (device iface is often 10.7.1.1; peer stays 10.7.0.1).
    static let defaultIP = "10.7.0.1"
    static let defaultsKey = "locus.targetDeviceIP"

    static var targetIP: String {
        let stored = UserDefaults.standard.string(forKey: defaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let stored, !stored.isEmpty else { return defaultIP }
        return stored
    }

    static func setTargetIP(_ value: String) {
        UserDefaults.standard.set(value, forKey: defaultsKey)
    }
}
