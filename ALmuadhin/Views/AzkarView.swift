import SwiftUI

// MARK: - Azkar View with Pager
struct AzkarView: View {
    @StateObject private var azkarService = AzkarService.shared
    @State private var selectedTab: AzkarType = .morning
    @State private var currentIndex = 0
    @State private var counts: [String: Int] = [:]
    @State private var showCopyAlert = false
    
    var currentAzkar: [ZikrItem] {
        azkarService.getAzkar(for: selectedTab)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.warmBeige, Color.warmCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if azkarService.isLoading {
                    ProgressView("جاري التحميل...")
                        .tint(.islamicGold)
                } else if currentAzkar.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 16) {
                        // Tab selector
                        tabSelector
                        
                        // Progress indicator
                        progressSection
                        
                        // Dhikr Pager
                        dhikrPager
                        
                        // Counter
                        counterSection
                        
                        // Action buttons
                        actionButtons
                        
                        // Navigation buttons
                        navigationButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("الأذكار")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: TasbeehView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.grid.3x3.fill")
                            Text("المسبحة")
                        }
                        .font(.caption)
                        .foregroundColor(.islamicGold)
                    }
                }
            }
            .alert("تم النسخ", isPresented: $showCopyAlert) {
                Button("موافق", role: .cancel) {}
            } message: {
                Text("تم نسخ الذكر إلى الحافظة")
            }
        }
        .onAppear {
            selectCurrentTimePeriod()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(.islamicGold.opacity(0.5))
            
            Text("لا توجد أذكار")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button("إعادة التحميل") {
                azkarService.loadAzkar()
            }
            .foregroundColor(.islamicGold)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AzkarType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = type
                        currentIndex = 0
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.caption)
                        Text(type.displayName)
                            .font(.subheadline)
                            .fontWeight(selectedTab == type ? .bold : .regular)
                    }
                    .foregroundColor(selectedTab == type ? .white : .islamicGoldDark)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == type ? Color.islamicGold : Color.clear)
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("التقدم")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                
                Text("\(completedCount) / \(currentAzkar.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.islamicGold)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.islamicGold.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.islamicGold, .islamicGoldDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(completedCount) / max(CGFloat(currentAzkar.count), 1))
                        .animation(.easeInOut(duration: 0.3), value: completedCount)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Dhikr Pager
    private var dhikrPager: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(currentAzkar.enumerated()), id: \.element.id) { index, zikr in
                DhikrCard(
                    zikr: zikr,
                    index: index + 1,
                    total: currentAzkar.count
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 280)
    }
    
    // MARK: - Counter Section
    private var counterSection: some View {
        let zikr = currentAzkar[safe: currentIndex]
        let currentCount = counts[zikr?.id ?? ""] ?? 0
        let targetCount = zikr?.repeat ?? 1
        let isComplete = currentCount >= targetCount
        
        return VStack(spacing: 12) {
            // Circular counter
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.islamicGold.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: min(CGFloat(currentCount) / CGFloat(targetCount), 1.0))
                    .stroke(
                        isComplete ? Color.green : Color.islamicGold,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: currentCount)
                
                // Counter text
                VStack(spacing: 2) {
                    Text("\(currentCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(isComplete ? .green : .islamicGoldDark)
                    
                    Text("/ \(targetCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Circle())
            .onTapGesture {
                incrementCounter()
            }
            
            // Complete indicator
            if isComplete {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("تم إكمال هذا الذكر")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Tap hint
            if !isComplete {
                Text("اضغط للعد")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Copy button
            Button(action: copyCurrentZikr) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                    Text("نسخ")
                }
                .font(.caption)
                .foregroundColor(.islamicGold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.islamicGold.opacity(0.1))
                )
            }
            
            // Share button
            Button(action: shareCurrentZikr) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("مشاركة")
                }
                .font(.caption)
                .foregroundColor(.islamicGold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.islamicGold.opacity(0.1))
                )
            }
            
            // Reset button
            Button(action: resetCurrentCount) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("إعادة")
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous
            Button(action: {
                withAnimation {
                    if currentIndex > 0 {
                        currentIndex -= 1
                    }
                }
            }) {
                HStack {
                    Image(systemName: "chevron.right")
                    Text("السابق")
                }
                .font(.subheadline)
                .foregroundColor(currentIndex > 0 ? .islamicGoldDark : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.05), radius: 3)
                )
            }
            .disabled(currentIndex == 0)
            
            Spacer()
            
            // Page indicator
            Text("\(currentIndex + 1)")
                .font(.headline)
                .foregroundColor(.islamicGold)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.white))
            
            Spacer()
            
            // Next
            Button(action: {
                withAnimation {
                    if currentIndex < currentAzkar.count - 1 {
                        currentIndex += 1
                    }
                }
            }) {
                HStack {
                    Text("التالي")
                    Image(systemName: "chevron.left")
                }
                .font(.subheadline)
                .foregroundColor(currentIndex < currentAzkar.count - 1 ? .white : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentIndex < currentAzkar.count - 1 ? Color.islamicGold : Color.gray.opacity(0.3))
                        .shadow(color: currentIndex < currentAzkar.count - 1 ? .islamicGold.opacity(0.3) : .clear, radius: 5)
                )
            }
            .disabled(currentIndex >= currentAzkar.count - 1)
        }
    }
    
    // MARK: - Helper Properties & Methods
    private var completedCount: Int {
        var count = 0
        for zikr in currentAzkar {
            let currentCount = counts[zikr.id] ?? 0
            if currentCount >= zikr.repeat {
                count += 1
            }
        }
        return count
    }
    
    private func selectCurrentTimePeriod() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 4 && hour < 12 {
            selectedTab = .morning
        } else {
            selectedTab = .evening
        }
    }
    
    private func incrementCounter() {
        guard let zikr = currentAzkar[safe: currentIndex] else { return }
        let currentCount = counts[zikr.id] ?? 0
        
        if currentCount < zikr.repeat {
            counts[zikr.id] = currentCount + 1
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Auto advance when complete
            if currentCount + 1 >= zikr.repeat && currentIndex < currentAzkar.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        currentIndex += 1
                    }
                }
            }
        } else {
            // Already complete, show feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    private func resetCurrentCount() {
        guard let zikr = currentAzkar[safe: currentIndex] else { return }
        counts[zikr.id] = 0
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func copyCurrentZikr() {
        guard let zikr = currentAzkar[safe: currentIndex] else { return }
        UIPasteboard.general.string = zikr.text
        showCopyAlert = true
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func shareCurrentZikr() {
        guard let zikr = currentAzkar[safe: currentIndex] else { return }
        let textToShare = "\(zikr.title)\n\n\(zikr.text)\n\nالتكرار: \(zikr.repeat) مرات"
        
        let activityVC = UIActivityViewController(
            activityItems: [textToShare],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Dhikr Card
struct DhikrCard: View {
    let zikr: ZikrItem
    let index: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Title with index
            HStack {
                Text(zikr.title)
                    .font(.headline)
                    .foregroundColor(.islamicGold)
                
                Spacer()
                
                Text("\(index)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.islamicGold.opacity(0.1))
                    )
            }
            
            Divider()
            
            // Zikr text
            ScrollView {
                Text(zikr.text)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.islamicGoldDark)
                    .lineSpacing(8)
            }
            
            Divider()
            
            // Benefit
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.islamicGold)
                    .font(.caption)
                
                Text(zikr.benefit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.98))
                .shadow(color: .islamicGold.opacity(0.15), radius: 10, y: 5)
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Array Safe Access Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    AzkarView()
}
