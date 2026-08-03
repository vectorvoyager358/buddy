import SwiftUI

struct WeekdaySelector: View {
    @Binding var selectedWeekdays: Set<Weekday>

    private let orderedWeekdays: [Weekday] = [
        .monday,
        .tuesday,
        .wednesday,
        .thursday,
        .friday,
        .saturday,
        .sunday
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active days")

            HStack(spacing: 8) {
                ForEach(
                    orderedWeekdays,
                    id: \.self
                ) { weekday in
                    weekdayButton(weekday)
                }
            }

            if selectedWeekdays.isEmpty {
                Label(
                    "Select at least one day.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func weekdayButton(
        _ weekday: Weekday
    ) -> some View {
        let isSelected =
            selectedWeekdays.contains(weekday)

        return Button {
            toggle(weekday)
        } label: {
            Text(weekday.shortName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    isSelected ? Color.white : Color.primary
                )
                .frame(
                    minWidth: 34,
                    minHeight: 28
                )
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            isSelected
                                ? Color.accentColor
                                : Color.secondary.opacity(0.12)
                        )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(
                            isSelected
                                ? Color.clear
                                : Color.secondary.opacity(0.25)
                        )
                }
        }
        .buttonStyle(.plain)
        .help(
            isSelected
                ? "Remove \(weekday.shortName)"
                : "Add \(weekday.shortName)"
        )
    }
    
    private func toggle(
        _ weekday: Weekday
    ) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }
}

#Preview {
    WeekdaySelector(
        selectedWeekdays: .constant([
            .monday,
            .tuesday,
            .wednesday,
            .thursday,
            .friday
        ])
    )
    .padding()
    .frame(width: 500)
}
