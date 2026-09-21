import Darwin
import Foundation
import UIKit

enum LocalDevVPN {
    static let appStoreURL = URL(string: "https://apps.apple.com/us/app/localdevvpn/id6755608044")!
    static let detectURL = URL(string: "localdevvpn://")!

    /// Starts the tunnel, then returns to Locus via `locus://`.
    static let enableURL = URL(string: "localdevvpn://enable?scheme=locus")!

    static var isInstalled: Bool {
        UIApplication.shared.canOpenURL(detectURL)
    }

    /// LocalDevVPN assigns a local iface IP and a peer IP (what Locus dials).
    /// Current App Store defaults: iface `10.7.1.1`, peer `10.7.0.1`.
    /// Older builds used iface `10.7.0.0` (same /24 as the peer).
    static var isConnected: Bool {
        let interfaces = ipv4Interfaces()
        let ips = interfaces.map(\.ip)
        let target = TunnelConfig.targetIP

        if ips.contains(target) { return true }

        // Same /24 as configured peer (legacy LocalDevVPN / custom subnet).
        if let prefix = slash24Prefix(target), ips.contains(where: { $0.hasPrefix(prefix) }) {
            return true
        }

        // Current LocalDevVPN default iface is 10.7.1.1 while peer stays 10.7.0.1.
        if ips.contains(where: { $0 == "10.7.1.1" || $0.hasPrefix("10.7.1.") }) {
            return true
        }

        // Any utun holding a 10.7.x address (covers custom mid-range LocalDevVPN setups).
        if interfaces.contains(where: { $0.name.hasPrefix("utun") && $0.ip.hasPrefix("10.7.") }) {
            return true
        }

        return false
    }

    static func openInstalled() {
        UIApplication.shared.open(enableURL)
    }

    static func openAppStore() {
        UIApplication.shared.open(appStoreURL)
    }

    /// Open LocalDevVPN to connect if installed; otherwise App Store.
    static func openOrInstall() {
        if isInstalled {
            openInstalled()
        } else {
            openAppStore()
        }
    }

    private static func slash24Prefix(_ ip: String) -> String? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return nil }
        return parts.dropLast().joined(separator: ".") + "."
    }

    private struct IPv4Interface {
        let name: String
        let ip: String
    }

    private static func ipv4Interfaces() -> [IPv4Interface] {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        var results: [IPv4Interface] = []
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            defer { ptr = current.pointee.ifa_next }
            let interface = current.pointee
            guard let addr = interface.ifa_addr else { continue }
            guard addr.pointee.sa_family == sa_family_t(AF_INET) else { continue }
            // Skip interfaces that are down.
            if (interface.ifa_flags & UInt32(IFF_UP)) == 0 { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let nameLen = socklen_t(addr.pointee.sa_len)
            guard getnameinfo(
                addr,
                nameLen > 0 ? nameLen : socklen_t(MemoryLayout<sockaddr_in>.size),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            ) == 0 else { continue }

            let name = String(cString: interface.ifa_name)
            let ip = String(cString: host)
            results.append(IPv4Interface(name: name, ip: ip))
        }
        return results
    }
}
