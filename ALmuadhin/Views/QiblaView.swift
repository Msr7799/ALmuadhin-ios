import SwiftUI
import CoreLocation
import CoreMotion

// MARK: - Qibla View
struct QiblaView: View {
    @StateObject private var qiblaManager = QiblaManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.warmBeige, Color.warmCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("اتجاه القبلة")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.islamicGoldDark)
                    
                    // Compass
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 300, height: 300)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                        
                        // Compass rose
                        CompassRose()
                            .rotationEffect(.degrees(-qiblaManager.heading))
                        
                        // Qibla arrow
                        QiblaArrow()
                            .rotationEffect(.degrees(qiblaManager.qiblaDirection - qiblaManager.heading))
                        
                        // Center circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.islamicGold, .islamicGoldDark],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "safari")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    // Qibla degree
                    if qiblaManager.hasLocation {
                        VStack(spacing: 8) {
                            Text("\(Int(qiblaManager.qiblaDirection))°")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.islamicGoldDark)
                            
                            Text("اتجاه القبلة من موقعك")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.islamicGold.opacity(0.1))
                        )
                    } else {
                        HStack {
                            Image(systemName: "location.slash")
                                .foregroundColor(.red)
                            Text("يرجى تفعيل الموقع لتحديد اتجاه القبلة")
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    
                    // Accuracy indicator
                    HStack {
                        Circle()
                            .fill(qiblaManager.accuracy)
                            .frame(width: 10, height: 10)
                        Text("دقة الحساس: \(qiblaManager.accuracyText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Calibration hint
                    Text("💡 لمعايرة البوصلة، حرّك هاتفك على شكل رقم 8")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.warmBeige)
                        )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("القبلة")
        }
        .onAppear {
            qiblaManager.start()
        }
        .onDisappear {
            qiblaManager.stop()
        }
    }
}

// MARK: - Compass Rose
struct CompassRose: View {
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.islamicGold, lineWidth: 2)
                .frame(width: 280, height: 280)
            
            // Inner circle
            Circle()
                .stroke(Color.islamicGold.opacity(0.3), lineWidth: 1)
                .frame(width: 240, height: 240)
            
            // Direction markers
            ForEach(0..<8) { i in
                let isMain = i % 2 == 0
                Rectangle()
                    .fill(Color.islamicGold.opacity(isMain ? 1 : 0.5))
                    .frame(width: isMain ? 3 : 2, height: isMain ? 20 : 12)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            // North arrow
            Triangle()
                .fill(Color.red)
                .frame(width: 20, height: 30)
                .offset(y: -105)
            
            // Cardinal directions
            Text("ش")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.islamicGoldDark)
                .offset(y: -80)
            
            Text("ج")
                .font(.caption)
                .foregroundColor(.islamicGoldDark)
                .offset(y: 80)
            
            Text("غ")
                .font(.caption)
                .foregroundColor(.islamicGoldDark)
                .offset(x: -80)
            
            Text("ش")
                .font(.caption)
                .foregroundColor(.islamicGoldDark)
                .offset(x: 80)
        }
    }
}

// MARK: - Qibla Arrow
struct QiblaArrow: View {
    var body: some View {
        VStack(spacing: 0) {
            // Kaaba image
            Image("alkaba")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            
            // Arrow body
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.islamicGold, .islamicGoldDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6, height: 50)
            
            // Arrow head
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [.islamicGold, .islamicGoldDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 35, height: 45)
                .rotationEffect(.degrees(180))
        }
        .offset(y: -55)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Qibla Manager
class QiblaManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    @Published var qiblaDirection: Double = 0
    @Published var hasLocation = false
    @Published var accuracy: Color = .green
    @Published var accuracyText = "جيدة"
    
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    
    // Kaaba coordinates
    private let kaabaLat = 21.4225
    private let kaabaLng = 39.8262
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        hasLocation = true
        qiblaDirection = calculateQiblaDirection(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.trueHeading
        
        // Update accuracy
        switch newHeading.headingAccuracy {
        case ..<10:
            accuracy = .green
            accuracyText = "ممتازة"
        case 10..<25:
            accuracy = .yellow
            accuracyText = "جيدة"
        case 25..<45:
            accuracy = .orange
            accuracyText = "متوسطة"
        default:
            accuracy = .red
            accuracyText = "ضعيفة - قم بمعايرة البوصلة"
        }
    }
    
    private func calculateQiblaDirection(lat: Double, lng: Double) -> Double {
        let latRad = lat * .pi / 180
        let lngRad = lng * .pi / 180
        let kaabaLatRad = kaabaLat * .pi / 180
        let kaabaLngRad = kaabaLng * .pi / 180
        
        let dLng = kaabaLngRad - lngRad
        
        let x = sin(dLng) * cos(kaabaLatRad)
        let y = cos(latRad) * sin(kaabaLatRad) - sin(latRad) * cos(kaabaLatRad) * cos(dLng)
        
        var bearing = atan2(x, y) * 180 / .pi
        if bearing < 0 {
            bearing += 360
        }
        
        return bearing
    }
}

#Preview {
    QiblaView()
}
