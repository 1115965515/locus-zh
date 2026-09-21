import CoreLocation
import Foundation
import MapKit

enum PlaceGeocoder {
    /// Prefer a readable Chinese street address; fall back to coordinates.
    static func address(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let marks = try await CLGeocoder().reverseGeocodeLocation(location)
            guard let mark = marks.first else { return nil }
            let text = format(mark)
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }

    private static func format(_ mark: CLPlacemark) -> String {
        var parts: [String] = []
        if let area = mark.administrativeArea, !area.isEmpty { parts.append(area) }
        if let city = mark.locality, !city.isEmpty, city != mark.administrativeArea {
            parts.append(city)
        }
        if let sub = mark.subLocality, !sub.isEmpty { parts.append(sub) }
        if let street = mark.thoroughfare, !street.isEmpty { parts.append(street) }
        if let number = mark.subThoroughfare, !number.isEmpty { parts.append(number) }

        let joined = parts.joined()
        if !joined.isEmpty { return joined }

        if let name = mark.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return ""
    }
}
