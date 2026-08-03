import SwiftUI

struct WorkingHoursSection: View {
    @Binding var hydration: HydrationSettings

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active hours")
                .font(.body)

            HStack(spacing: 16) {
                timePicker(
                    title: "Start",
                    selection: startTimeBinding
                )

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                timePicker(
                    title: "End",
                    selection: endTimeBinding
                )

                Spacer()
            }

            if !hasValidTimeRange {
                Label(
                    "End time must be later than start time.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func timePicker(
        title: String,
        selection: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            DatePicker(
                title,
                selection: selection,
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
        }
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: {
                makeDate(
                    hour: hydration.startHour,
                    minute: hydration.startMinute
                )
            },
            set: { newValue in
                let components = calendar.dateComponents(
                    [.hour, .minute],
                    from: newValue
                )

                hydration.startHour =
                    components.hour ?? hydration.startHour

                hydration.startMinute =
                    components.minute ?? hydration.startMinute
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: {
                makeDate(
                    hour: hydration.endHour,
                    minute: hydration.endMinute
                )
            },
            set: { newValue in
                let components = calendar.dateComponents(
                    [.hour, .minute],
                    from: newValue
                )

                hydration.endHour =
                    components.hour ?? hydration.endHour

                hydration.endMinute =
                    components.minute ?? hydration.endMinute
            }
        )
    }

    private func makeDate(
        hour: Int,
        minute: Int
    ) -> Date {
        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: Date()
        )

        components.hour = hour
        components.minute = minute
        components.second = 0

        return calendar.date(
            from: components
        ) ?? Date()
    }

    private var hasValidTimeRange: Bool {
        let startMinutes =
            hydration.startHour * 60
            + hydration.startMinute

        let endMinutes =
            hydration.endHour * 60
            + hydration.endMinute

        return endMinutes > startMinutes
    }
}

#Preview {
    WorkingHoursSection(
        hydration: .constant(.default)
    )
    .padding()
    .frame(width: 500)
}
