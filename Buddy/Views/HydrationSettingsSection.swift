import SwiftUI

struct HydrationSettingsSection: View {
    @Binding var hydration: HydrationSettings

    var body: some View {
        Section {
            Toggle(
                "Enable water reminders",
                isOn: $hydration.isEnabled
            )
            .toggleStyle(.switch)

            Group {
                intervalRow

                WorkingHoursSection(
                    hydration: $hydration
                )

                WeekdaySelector(
                    selectedWeekdays: $hydration.weekdays
                )
            }
            .disabled(!hydration.isEnabled)
            .opacity(hydration.isEnabled ? 1 : 0.55)
        } header: {
            Label(
                "Hydration",
                systemImage: "drop.fill"
            )
            .font(.headline)
        } footer: {
            Text(scheduleSummary)
                .foregroundStyle(.secondary)
        }
    }
    
    private var intervalRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Reminder interval")

                Text("How often Buddy should remind you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Stepper(
                value: $hydration.intervalMinutes,
                in: 15...240,
                step: 15
            ) {
                Text(
                    "\(hydration.intervalMinutes) minutes"
                )
                .monospacedDigit()
                .frame(minWidth: 90, alignment: .trailing)
            }
        }
    }

    private var scheduleSummary: String {
        let days = Weekday.allCases
            .filter {
                hydration.weekdays.contains($0)
            }
            .map(\.shortName)
            .joined(separator: ", ")

        return """
        Buddy will remind you every \
        \(hydration.intervalMinutes) minutes on \
        \(days.isEmpty ? "no selected days" : days).
        """
    }
}

#Preview {
    HydrationSettingsSection(
        hydration: .constant(.default)
    )
    .padding()
    .frame(width: 520)
}
