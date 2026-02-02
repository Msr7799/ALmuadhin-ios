import SwiftUI

// MARK: - Tasbeeh View (Digital Prayer Beads)
struct TasbeehView: View {
    @StateObject private var counter = TasbeehCounter()
    @State private var selectedDhikr: TasbeehDhikr = .subhanAllah
    @State private var showDhikrPicker = false
    @State private var animatePress = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.warmBeige, Color.warmCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Total counter
                    totalCounterSection
                    
                    // Current dhikr display
                    dhikrDisplaySection
                    
                    Spacer()
                    
                    // Main counter circle
                    mainCounterCircle
                    
                    Spacer()
                    
                    // Controls
                    controlsSection
                    
                    // Target presets
                    targetPresetsSection
                }
                .padding()
            }
            .navigationTitle("المسبحة")
            .sheet(isPresented: $showDhikrPicker) {
                DhikrPickerSheet(selected: $selectedDhikr, counter: counter)
            }
        }
    }
    
    // MARK: - Total Counter Section
    private var totalCounterSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("إجمالي التسبيحات")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(counter.totalCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.islamicGold)
            }
            
            Spacer()
            
            Button(action: {
                counter.resetTotal()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("مسح الإجمالي")
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
        )
    }
    
    // MARK: - Dhikr Display Section
    private var dhikrDisplaySection: some View {
        Button(action: { showDhikrPicker = true }) {
            VStack(spacing: 8) {
                Text(selectedDhikr.arabic)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.islamicGoldDark)
                
                Text(selectedDhikr.transliteration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.caption)
                    Text("اضغط للتغيير")
                        .font(.caption)
                }
                .foregroundColor(.islamicGold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.95))
                    .shadow(color: .islamicGold.opacity(0.1), radius: 5)
            )
        }
    }
    
    // MARK: - Main Counter Circle
    private var mainCounterCircle: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.islamicGold.opacity(0.2), lineWidth: 20)
                .frame(width: 250, height: 250)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(counter.progress))
                .stroke(
                    LinearGradient(
                        colors: counter.isComplete ? [.green, .green.opacity(0.7)] : [.islamicGold, .islamicGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 250, height: 250)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: counter.currentCount)
            
            // Inner touch area
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, .warmCream],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .scaleEffect(animatePress ? 0.95 : 1.0)
            
            // Counter display
            VStack(spacing: 4) {
                Text("\(counter.currentCount)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(counter.isComplete ? .green : .islamicGoldDark)
                
                Text("/ \(counter.targetCount)")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                animatePress = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    animatePress = false
                }
            }
            
            counter.increment()
        }
        .overlay(
            // Completion checkmark
            Group {
                if counter.isComplete {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                                .background(Circle().fill(.white))
                                .offset(x: 20, y: 20)
                        }
                    }
                }
            }
        )
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 32) {
            // Reset button
            Button(action: { counter.reset() }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                    Text("إعادة")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .padding()
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 70, height: 70)
                )
            }
            
            // Minus button
            Button(action: {
                if counter.currentCount > 0 {
                    counter.currentCount -= 1
                }
            }) {
                Image(systemName: "minus")
                    .font(.title)
                    .foregroundColor(.islamicGold)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.islamicGold.opacity(0.1))
                    )
            }
            
            // Plus button
            Button(action: { counter.increment() }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.islamicGold)
                    )
            }
        }
    }
    
    // MARK: - Target Presets Section
    private var targetPresetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("الهدف")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach([33, 99, 100, 1000], id: \.self) { target in
                    Button(action: {
                        counter.setTarget(target)
                    }) {
                        Text("\(target)")
                            .font(.subheadline)
                            .fontWeight(counter.targetCount == target ? .bold : .regular)
                            .foregroundColor(counter.targetCount == target ? .white : .islamicGold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(counter.targetCount == target ? Color.islamicGold : Color.islamicGold.opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.9))
        )
    }
}

// MARK: - Tasbeeh Dhikr Enum
enum TasbeehDhikr: String, CaseIterable, Identifiable {
    case subhanAllah = "subhan_allah"
    case alhamdulillah = "alhamdulillah"
    case allahuAkbar = "allahu_akbar"
    case laIlahaIllallah = "la_ilaha_illallah"
    case subhanAllahWaBihamdihi = "subhanallah_wabihamdihi"
    case astaghfirullah = "astaghfirullah"
    case salawat = "salawat"
    
    var id: String { rawValue }
    
    var arabic: String {
        switch self {
        case .subhanAllah: return "سُبْحَانَ اللَّهِ"
        case .alhamdulillah: return "الْحَمْدُ لِلَّهِ"
        case .allahuAkbar: return "اللَّهُ أَكْبَرُ"
        case .laIlahaIllallah: return "لَا إِلَٰهَ إِلَّا اللَّهُ"
        case .subhanAllahWaBihamdihi: return "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ"
        case .astaghfirullah: return "أَسْتَغْفِرُ اللَّهَ"
        case .salawat: return "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ"
        }
    }
    
    var transliteration: String {
        switch self {
        case .subhanAllah: return "Subhan Allah"
        case .alhamdulillah: return "Alhamdulillah"
        case .allahuAkbar: return "Allahu Akbar"
        case .laIlahaIllallah: return "La ilaha illallah"
        case .subhanAllahWaBihamdihi: return "Subhan Allah wa bihamdihi"
        case .astaghfirullah: return "Astaghfirullah"
        case .salawat: return "Salawat"
        }
    }
    
    var reward: String {
        switch self {
        case .subhanAllah: return "من قالها ٣٣ مرة بعد كل صلاة غُفرت ذنوبه"
        case .alhamdulillah: return "تملأ الميزان"
        case .allahuAkbar: return "أحب الكلام إلى الله"
        case .laIlahaIllallah: return "أفضل ما قلته أنا والنبيون من قبلي"
        case .subhanAllahWaBihamdihi: return "حُطّت خطاياه وإن كانت مثل زبد البحر"
        case .astaghfirullah: return "من لزم الاستغفار جعل الله له من كل ضيق مخرجاً"
        case .salawat: return "من صلى عليّ صلاة صلى الله عليه بها عشراً"
        }
    }
}

// MARK: - Dhikr Picker Sheet
struct DhikrPickerSheet: View {
    @Binding var selected: TasbeehDhikr
    @ObservedObject var counter: TasbeehCounter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(TasbeehDhikr.allCases) { dhikr in
                    Button(action: {
                        selected = dhikr
                        counter.reset()
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dhikr.arabic)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(dhikr.transliteration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(dhikr.reward)
                                    .font(.caption2)
                                    .foregroundColor(.islamicGold)
                            }
                            
                            Spacer()
                            
                            if selected == dhikr {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.islamicGold)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("اختر الذكر")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إغلاق") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TasbeehView()
}
