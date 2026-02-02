import SwiftUI

// MARK: - Hijri Month Names
let hijriMonths = [
    "محرم", "صفر", "ربيع الأول", "ربيع الثاني",
    "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان",
    "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
]

let gregorianMonths = [
    "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
    "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
]

let arabicDays = ["أح", "اث", "ثل", "أر", "خم", "جم", "سب"]

// MARK: - Calendar View
struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.warmBeige, Color.warmCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Week quick view
                        weekQuickView
                        
                        // Month calendar
                        monthCalendarCard
                        
                        // Selected date info
                        selectedDateInfoCard
                        
                        // Ramadan countdown
                        ramadanCountdownCard
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("التقويم الهجري")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("التقويم الهجري")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.islamicGoldDark)
            
            let hijri = approximateHijriDate(from: Date())
            Text("\(hijri.day) \(hijriMonths[hijri.month - 1]) \(hijri.year)هـ")
                .font(.title3)
                .foregroundColor(.islamicGold)
        }
    }
    
    private var weekQuickView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("عرض سريع للأسبوع")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(-3..<4, id: \.self) { offset in
                    let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let hijri = approximateHijriDate(from: date)
                    let isToday = offset == 0
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    
                    VStack(spacing: 4) {
                        Text(arabicDays[calendar.component(.weekday, from: date) - 1])
                            .font(.caption2)
                        
                        Text("\(calendar.component(.day, from: date))")
                            .font(.headline)
                            .fontWeight(isToday ? .bold : .regular)
                        
                        Text("\(hijri.day)")
                            .font(.caption2)
                            .foregroundColor(isToday ? .white.opacity(0.8) : .islamicGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isToday ? Color.islamicGold : (isSelected ? Color.islamicGold.opacity(0.2) : Color.clear))
                    )
                    .foregroundColor(isToday ? .white : .primary)
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
        )
    }
    
    private var monthCalendarCard: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.islamicGold)
                }
                
                Spacer()
                
                VStack {
                    Text("\(gregorianMonths[calendar.component(.month, from: currentMonth) - 1]) \(calendar.component(.year, from: currentMonth))")
                        .font(.headline)
                        .foregroundColor(.islamicGoldDark)
                    
                    let hijri = approximateHijriDate(from: currentMonth)
                    Text("\(hijriMonths[hijri.month - 1]) \(hijri.year)هـ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.islamicGold)
                }
            }
            
            // Day headers
            HStack {
                ForEach(arabicDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.islamicGold)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            let days = generateMonthDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let hijri = approximateHijriDate(from: date)
                        let isToday = calendar.isDateInToday(date)
                        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        
                        VStack(spacing: 2) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.callout)
                                .fontWeight(isToday ? .bold : .regular)
                            
                            Text("\(hijri.day)")
                                .font(.system(size: 8))
                                .foregroundColor(isToday ? .white.opacity(0.8) : .islamicGold)
                        }
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            Circle()
                                .fill(isToday ? Color.islamicGold : (isSelected ? Color.islamicGold.opacity(0.2) : Color.clear))
                        )
                        .foregroundColor(isToday ? .white : (isCurrentMonth ? .primary : .secondary.opacity(0.5)))
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
        )
    }
    
    private var selectedDateInfoCard: some View {
        let hijri = approximateHijriDate(from: selectedDate)
        let isToday = calendar.isDateInToday(selectedDate)
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.islamicGold)
                
                Text(isToday ? "اليوم" : "التاريخ المحدد")
                    .font(.headline)
                    .foregroundColor(.islamicGoldDark)
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 32) {
                // Gregorian date
                VStack(spacing: 4) {
                    Text("الميلادي")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(calendar.component(.day, from: selectedDate))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.islamicGoldDark)
                    
                    Text("\(gregorianMonths[calendar.component(.month, from: selectedDate) - 1]) \(calendar.component(.year, from: selectedDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.islamicGold.opacity(0.1))
                )
                
                // Hijri date
                VStack(spacing: 4) {
                    Text("الهجري")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(hijri.day)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.islamicGold)
                    
                    Text("\(hijriMonths[hijri.month - 1]) \(hijri.year)هـ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.islamicGold.opacity(0.1))
                )
            }
            
            // Day of week
            let weekDay = calendar.component(.weekday, from: selectedDate)
            let weekDayNames = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
            
            Text("يوم \(weekDayNames[weekDay - 1])")
                .font(.subheadline)
                .foregroundColor(.islamicGold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.islamicGold.opacity(0.15))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
    }
    
    private var ramadanCountdownCard: some View {
        let hijri = approximateHijriDate(from: Date())
        let isRamadan = hijri.month == 9
        
        return VStack(spacing: 12) {
            if isRamadan {
                Text("🌙 رمضان كريم 🌙")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.islamicGoldDark)
                
                Text("اليوم \(hijri.day) من رمضان")
                    .foregroundColor(.secondary)
            } else {
                Text("🌙")
                    .font(.system(size: 40))
                
                Text("العد التنازلي لرمضان")
                    .font(.headline)
                    .foregroundColor(.islamicGoldDark)
                
                let daysToRamadan = estimateDaysToRamadan(from: hijri)
                
                HStack(spacing: 16) {
                    VStack {
                        Text("\(daysToRamadan)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.islamicGoldDark)
                        Text("يوم")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.islamicGold.opacity(0.15))
        )
    }
    
    private func generateMonthDays() -> [Date?] {
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        var days: [Date?] = []
        
        // Empty cells before first day
        for _ in 0..<(firstWeekday - 1) {
            days.append(nil)
        }
        
        // Days of month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining cells
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

// MARK: - Hijri Date Helpers
struct HijriDateComponents {
    let day: Int
    let month: Int
    let year: Int
}

func approximateHijriDate(from date: Date) -> HijriDateComponents {
    // Reference: 1 Muharram 1446 = July 7, 2024
    let referenceDate = Calendar.current.date(from: DateComponents(year: 2024, month: 7, day: 7))!
    let referenceHijri = HijriDateComponents(day: 1, month: 1, year: 1446)
    
    let daysDiff = Calendar.current.dateComponents([.day], from: referenceDate, to: date).day ?? 0
    
    let hijriMonthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29]
    
    var remainingDays = daysDiff
    var year = referenceHijri.year
    var month = referenceHijri.month
    var day = referenceHijri.day
    
    if remainingDays >= 0 {
        while remainingDays > 0 {
            let monthLength = hijriMonthLengths[(month - 1) % 12]
            let daysLeftInMonth = monthLength - day + 1
            
            if remainingDays >= daysLeftInMonth {
                remainingDays -= daysLeftInMonth
                day = 1
                month += 1
                if month > 12 {
                    month = 1
                    year += 1
                }
            } else {
                day += remainingDays
                remainingDays = 0
            }
        }
    } else {
        remainingDays = -remainingDays
        while remainingDays > 0 {
            if remainingDays >= day {
                remainingDays -= day
                month -= 1
                if month < 1 {
                    month = 12
                    year -= 1
                }
                day = hijriMonthLengths[(month - 1) % 12]
            } else {
                day -= remainingDays
                remainingDays = 0
            }
        }
    }
    
    return HijriDateComponents(day: day, month: month, year: year)
}

func estimateDaysToRamadan(from hijri: HijriDateComponents) -> Int {
    let hijriMonthLengths = [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29]
    
    var targetYear = hijri.year
    if hijri.month > 9 || (hijri.month == 9 && hijri.day >= 30) {
        targetYear += 1
    }
    
    var days = 0
    
    // Days left in current month
    let currentMonthLength = hijriMonthLengths[(hijri.month - 1) % 12]
    days += currentMonthLength - hijri.day
    
    // Full months between
    var m = hijri.month + 1
    var y = hijri.year
    while y < targetYear || (y == targetYear && m < 9) {
        if m > 12 {
            m = 1
            y += 1
        }
        days += hijriMonthLengths[(m - 1) % 12]
        m += 1
    }
    
    return days
}

#Preview {
    CalendarView()
}
