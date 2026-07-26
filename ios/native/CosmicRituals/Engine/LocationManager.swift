import Combine
import CoreLocation
import UIKit

enum RitualLocationState: Equatable {
    case defaultCity
    case manual
    case savedCurrent
    case requesting
    case current
    case denied
    case restricted
    case failed(String)

    var description: String {
        switch self {
        case .defaultCity: return "Using the visible default city"
        case .manual: return "Using an offline city"
        case .savedCurrent: return "Using a saved GPS coordinate until location is refreshed"
        case .requesting: return "Updating current location…"
        case .current: return "Using current location"
        case .denied: return "Location permission denied; saved city remains active"
        case .restricted: return "Location access is restricted; saved city remains active"
        case .failed(let message): return "Location update failed: \(message)"
        }
    }
}

/// Accepts only a fresh, authorized and usable Core Location fix. Keeping this
/// policy separate makes the fail-closed boundary independently testable.
enum RitualGPSFixValidator {
    static let maximumAge: TimeInterval = 120
    static let maximumFutureClockSkew: TimeInterval = 10
    static let maximumHorizontalAccuracy: CLLocationAccuracy = 5_000

    static func rejectionReason(
        for location: CLLocation,
        authorizationStatus: CLAuthorizationStatus,
        now: Date = Date()
    ) -> String? {
        rejectionReason(
            authorizationStatus: authorizationStatus,
            coordinate: location.coordinate,
            timestamp: location.timestamp,
            horizontalAccuracy: location.horizontalAccuracy,
            now: now
        )
    }

    static func rejectionReason(
        authorizationStatus: CLAuthorizationStatus,
        coordinate: CLLocationCoordinate2D,
        timestamp: Date,
        horizontalAccuracy: CLLocationAccuracy,
        now: Date
    ) -> String? {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return "location access is no longer authorized"
        }
        guard coordinate.latitude.isFinite,
              coordinate.longitude.isFinite,
              CLLocationCoordinate2DIsValid(coordinate) else {
            return "the coordinate is invalid"
        }
        guard timestamp.timeIntervalSinceReferenceDate.isFinite else {
            return "the location timestamp is invalid"
        }

        let age = now.timeIntervalSince(timestamp)
        guard age >= -maximumFutureClockSkew else {
            return "the location timestamp is in the future"
        }
        guard age <= maximumAge else {
            return "the location fix is older than two minutes"
        }
        guard horizontalAccuracy.isFinite, horizontalAccuracy >= 0 else {
            return "the location accuracy is unavailable"
        }
        guard horizontalAccuracy <= maximumHorizontalAccuracy else {
            return "the location accuracy is worse than five kilometers"
        }
        return nil
    }
}

@MainActor
final class LocationManager: NSObject, @preconcurrency CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()

    @Published private(set) var activeLocation: RitualLocation
    @Published private(set) var state: RitualLocationState

    var latitude: Double { activeLocation.latitude }
    var longitude: Double { activeLocation.longitude }
    var timeZoneIdentifier: String { activeLocation.timeZoneIdentifier }
    var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    override init() {
        let persisted = RitualLocationStore.load()
        let initial: RitualLocation
        if let persisted, persisted.source == .current || persisted.source == .savedCurrent {
            initial = persisted.asSavedCurrent()
            RitualLocationStore.save(initial)
        } else {
            initial = persisted ?? WorldCityCatalog.newDelhi
        }
        activeLocation = initial
        switch initial.source {
        case .defaultCity: state = .defaultCity
        case .manual: state = .manual
        case .savedCurrent: state = .savedCurrent
        case .current: state = .current
        }

        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer

        if initial.source == .savedCurrent, isAuthorized {
            state = .requesting
            manager.requestLocation()
        }
    }

    func calculationContext(for localDay: Date) -> CalculationContext {
        CalculationContext(localDay: localDay, location: activeLocation)
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            state = .requesting
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            state = .requesting
            manager.requestLocation()
        case .denied:
            downgradeCurrentLocation()
            state = .denied
        case .restricted:
            downgradeCurrentLocation()
            state = .restricted
        @unknown default:
            state = .failed("Unknown authorization state")
        }
    }

    func select(_ city: RitualLocation) {
        let selected = city.withSource(.manual)
        activeLocation = selected
        state = .manual
        RitualLocationStore.save(selected)
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            state = .requesting
            manager.requestLocation()
        case .denied:
            downgradeCurrentLocation()
            state = .denied
        case .restricted:
            downgradeCurrentLocation()
            state = .restricted
        case .notDetermined:
            break
        @unknown default:
            state = .failed("Unknown authorization state")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            state = .failed("No coordinate was returned")
            return
        }
        if let rejection = RitualGPSFixValidator.rejectionReason(
            for: location,
            authorizationStatus: manager.authorizationStatus
        ) {
            downgradeCurrentLocation()
            state = .failed("Location update rejected: \(rejection)")
            return
        }

        let current = RitualLocation(
            name: "Current Location",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier,
            source: .current
        )
        activeLocation = current
        state = .current
        RitualLocationStore.save(current)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        downgradeCurrentLocation()
        if let locationError = error as? CLError, locationError.code == .denied {
            state = .denied
        } else {
            state = .failed(error.localizedDescription)
        }
    }

    private func downgradeCurrentLocation() {
        guard activeLocation.source == .current else { return }
        let saved = activeLocation.asSavedCurrent()
        activeLocation = saved
        RitualLocationStore.save(saved)
    }
}
