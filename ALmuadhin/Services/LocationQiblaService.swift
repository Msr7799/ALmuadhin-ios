import Foundation
import CoreLocation
import CoreMotion
import SwiftUI

// MARK: - Location & Qibla Service
class LocationQiblaService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationQiblaService()
    
    // Kaaba coordinates
    static let kaabaLatitude = 21.4225
    static let kaabaLongitude = 39.8262
    
    // Location Manager
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    
    // Published properties
    @Published var userLocation: CLLocation?
    @Published var heading: Double = 0
    @Published var qiblaDirection: Double = 0
    @Published var locationError: String?
    @Published var hasLocationPermission = false
    @Published var isCalibrationNeeded = false
    @Published var headingAccuracy: CLLocationDirection = 0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
    }
    
    // MARK: - Permission & Location
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            hasLocationPermission = true
            startUpdatingLocation()
        case .denied, .restricted:
            hasLocationPermission = false
            locationError = "يرجى تفعيل خدمة الموقع من الإعدادات"
        @unknown default:
            break
        }
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        calculateQiblaDirection()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingAccuracy = newHeading.headingAccuracy
        isCalibrationNeeded = newHeading.headingAccuracy < 0 || newHeading.headingAccuracy > 25
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "خطأ في تحديد الموقع: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            hasLocationPermission = true
            startUpdatingLocation()
        case .denied, .restricted:
            hasLocationPermission = false
            locationError = "يرجى تفعيل خدمة الموقع"
        default:
            break
        }
    }
    
    // MARK: - Qibla Calculation
    func calculateQiblaDirection() {
        guard let location = userLocation else { return }
        
        let userLat = location.coordinate.latitude.toRadians
        let userLng = location.coordinate.longitude.toRadians
        let kaabaLat = Self.kaabaLatitude.toRadians
        let kaabaLng = Self.kaabaLongitude.toRadians
        
        let dLng = kaabaLng - userLng
        
        let y = sin(dLng) * cos(kaabaLat)
        let x = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(dLng)
        
        var bearing = atan2(y, x).toDegrees
        if bearing < 0 {
            bearing += 360
        }
        
        qiblaDirection = bearing
    }
    
    // MARK: - Compass Rotation
    var compassRotation: Double {
        let rotation = qiblaDirection - heading
        return rotation
    }
    
    // MARK: - Distance to Kaaba
    var distanceToKaaba: Double? {
        guard let location = userLocation else { return nil }
        let kaabaLocation = CLLocation(latitude: Self.kaabaLatitude, longitude: Self.kaabaLongitude)
        return location.distance(from: kaabaLocation) / 1000 // Convert to km
    }
    
    // MARK: - Accuracy Description
    var accuracyDescription: String {
        if headingAccuracy < 0 {
            return "غير متاح"
        } else if headingAccuracy <= 5 {
            return "ممتازة"
        } else if headingAccuracy <= 15 {
            return "جيدة"
        } else if headingAccuracy <= 25 {
            return "متوسطة"
        } else {
            return "ضعيفة - يرجى المعايرة"
        }
    }
}

// MARK: - Extensions
extension Double {
    var toRadians: Double {
        return self * .pi / 180
    }
    
    var toDegrees: Double {
        return self * 180 / .pi
    }
}
