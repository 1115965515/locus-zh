import CoreLocation
import Foundation

/// China map offset: MapKit in mainland China uses GCJ-02 (火星坐标),
/// while `locationd` / developer location simulation expects WGS-84.
/// Injecting map-picked GCJ-02 as-is shifts the spoofed fix in China.
enum ChinaCoordinate {
    /// Rough mainland China bounds (excludes roughly TW / HK / MO).
    static func isMainlandChina(_ c: CLLocationCoordinate2D) -> Bool {
        let lat = c.latitude
        let lon = c.longitude
        // Outside broad China rectangle
        if lon < 72.004 || lon > 137.8347 || lat < 0.8293 || lat > 55.8271 {
            return false
        }
        // Taiwan
        if lat >= 21.5 && lat <= 25.5 && lon >= 119.3 && lon <= 122.5 {
            return false
        }
        // Hong Kong
        if lat >= 22.15 && lat <= 22.6 && lon >= 113.8 && lon <= 114.5 {
            return false
        }
        // Macau
        if lat >= 22.0 && lat <= 22.3 && lon >= 113.4 && lon <= 113.7 {
            return false
        }
        return true
    }

    /// Convert MapKit (GCJ-02 in mainland) → WGS-84 for locationd injection.
    static func gcj02ToWgs84(_ c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isMainlandChina(c) else { return c }
        let g = delta(lat: c.latitude, lon: c.longitude)
        return CLLocationCoordinate2D(
            latitude: c.latitude - g.lat,
            longitude: c.longitude - g.lon
        )
    }

    /// Convert WGS-84 → GCJ-02 (for display if ever needed).
    static func wgs84ToGcj02(_ c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isMainlandChina(c) else { return c }
        let g = delta(lat: c.latitude, lon: c.longitude)
        return CLLocationCoordinate2D(
            latitude: c.latitude + g.lat,
            longitude: c.longitude + g.lon
        )
    }

    /// More accurate iterative GCJ-02 → WGS-84 (preferred for injection).
    static func gcj02ToWgs84Exact(_ c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard isMainlandChina(c) else { return c }
        let threshold = 1e-7
        var wgs = gcj02ToWgs84(c)
        for _ in 0..<8 {
            let again = wgs84ToGcj02(wgs)
            let dLat = again.latitude - c.latitude
            let dLon = again.longitude - c.longitude
            if abs(dLat) < threshold && abs(dLon) < threshold { break }
            wgs = CLLocationCoordinate2D(
                latitude: wgs.latitude - dLat,
                longitude: wgs.longitude - dLon
            )
        }
        return wgs
    }

    // MARK: - Eviltransform math

    private static let a = 6378245.0
    private static let ee = 0.00669342162296594323

    private static func delta(lat: Double, lon: Double) -> (lat: Double, lon: Double) {
        var dLat = transformLat(lon - 105.0, lat - 35.0)
        var dLon = transformLon(lon - 105.0, lat - 35.0)
        let radLat = lat / 180.0 * .pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * .pi)
        dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)
        return (dLat, dLon)
    }

    private static func transformLat(_ x: Double, _ y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * .pi) + 320.0 * sin(y * .pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    private static func transformLon(_ x: Double, _ y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
        return ret
    }
}
