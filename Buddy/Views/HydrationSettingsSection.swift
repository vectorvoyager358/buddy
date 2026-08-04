import SwiftUI

struct HydrationSettingsSection: View {
    @Binding var hydration: HydrationSettings

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Toggle(
                "Enable water reminders",
                isOn: $hydration.isEnabled
            )
            .toggleStyle(.switch)

            Group {
                Divider()

                intervalRow

                Divider()

                WorkingHoursSection(
                    hydration: $hydration
                )

                Divider()

                WeekdaySelector(
                    selectedWeekdays:
                        $hydration.weekdays
                )
            }
            .disabled(!hydration.isEnabled)
            .opacity(
                hydration.isEnabled
                    ? 1
                    : 0.45
            )
        }
    }

    private var intervalRow: some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("Reminder interval")

                Text(
                    "How often Buddy should "
                    + "suggest a water break."
                )
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
                .frame(
                    minWidth: 95,
                    alignment: .trailing
                )
            }
        }
    }
}
