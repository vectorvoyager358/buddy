import SwiftUI

struct SupplementSettingsSection:
    View {

    @Binding var reminder:
        ReminderDefinition

    private let maximumDailyTimes = 8

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            enableToggle

            Divider()

            nameField

            Divider()

            activeDays

            Divider()

            dailyTimes
        }
    }

    private var enableToggle:
        some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(
                    "Enable supplement reminder"
                )

                Text(
                    "Buddy will keep reminding you until you mark it done."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle(
                "",
                isOn:
                    $reminder.isEnabled
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
    }

    private var nameField:
        some View {
        HStack(spacing: 16) {
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("Supplement name")

                Text(
                    "For example: Vitamin D, Magnesium, or Omega-3."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            TextField(
                "Supplement name",
                text: supplementNameBinding
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 210)
        }
    }

    private var activeDays:
        some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("Active days")

                Text(
                    "Choose the days Buddy should remind you."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            WeekdaySelector(
                selectedWeekdays:
                    $reminder.weekdays
            )
        }
    }

    private var dailyTimes:
        some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text("Daily reminder times")

                    Text(
                        "Each time is treated as a separate daily dose."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    addTime()
                } label: {
                    Label(
                        "Add Time",
                        systemImage: "plus"
                    )
                }
                .disabled(
                    times.count
                        >= maximumDailyTimes
                )
            }

            if times.isEmpty {
                emptyTimesView
            } else {
                VStack(spacing: 9) {
                    ForEach(
                        Array(
                            times.enumerated()
                        ),
                        id: \.element.id
                    ) {
                        index,
                        time in

                        timeRow(
                            time,
                            at: index
                        )
                    }
                }
            }
        }
    }

    private var emptyTimesView:
        some View {
        HStack(spacing: 10) {
            Image(
                systemName:
                    "clock.badge.exclamationmark"
            )
            .foregroundStyle(.orange)

            Text(
                "Add at least one reminder time."
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(
                Color.orange
                    .opacity(0.08)
            )
        )
    }

    private func timeRow(
        _ time: ReminderTime,
        at index: Int
    ) -> some View {
        HStack(spacing: 12) {
            Image(
                systemName:
                    "pill.fill"
            )
            .foregroundStyle(.purple)
            .frame(width: 18)

            Text(
                "Dose \(index + 1)"
            )
            .font(
                .system(
                    size: 13,
                    weight: .medium
                )
            )

            Spacer()

            DatePicker(
                "",
                selection:
                    timeBinding(
                        at: index
                    ),
                displayedComponents:
                    .hourAndMinute
            )
            .labelsHidden()

            Button {
                removeTime(
                    at: index
                )
            } label: {
                Image(
                    systemName:
                        "minus.circle.fill"
                )
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(
                "Remove this reminder time"
            )
        }
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            9
        )
        .background(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(
                Color.primary
                    .opacity(0.035)
            )
        )
    }

    private var supplementNameBinding:
        Binding<String> {
        Binding(
            get: {
                reminder.title
            },
            set: {
                newValue in

                reminder.title =
                    newValue

                let trimmedName =
                    newValue.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                reminder.message =
                    trimmedName.isEmpty
                    ? "It is time to take your supplement."
                    : "It is time to take \(trimmedName)."
            }
        )
    }

    private var times:
        [ReminderTime] {
        guard case .fixedTimes(
            let fixedSchedule
        ) = reminder.schedule else {
            return []
        }

        return fixedSchedule.times
    }

    private func timeBinding(
        at index: Int
    ) -> Binding<Date> {
        Binding(
            get: {
                date(
                    from: times[index]
                )
            },
            set: {
                newDate in

                var updatedTimes =
                    times

                let components =
                    Calendar.current
                        .dateComponents(
                            [
                                .hour,
                                .minute
                            ],
                            from: newDate
                        )

                updatedTimes[index] =
                    ReminderTime(
                        hour:
                            components.hour
                            ?? 9,
                        minute:
                            components.minute
                            ?? 0
                    )

                reminder.schedule =
                    .fixedTimes(
                        FixedTimeReminderSchedule(
                            times:
                                updatedTimes
                        )
                    )
            }
        )
    }

    private func addTime() {
        var updatedTimes =
            times

        let newTime: ReminderTime

        if let lastTime =
            updatedTimes.last {
            let totalMinutes =
                min(
                    lastTime.totalMinutes
                        + 60,
                    23 * 60 + 59
                )

            newTime =
                ReminderTime(
                    hour:
                        totalMinutes / 60,
                    minute:
                        totalMinutes % 60
                )
        } else {
            newTime =
                ReminderTime(
                    hour: 9,
                    minute: 0
                )
        }

        updatedTimes.append(
            newTime
        )

        reminder.schedule =
            .fixedTimes(
                FixedTimeReminderSchedule(
                    times:
                        updatedTimes
                )
            )
    }

    private func removeTime(
        at index: Int
    ) {
        var updatedTimes =
            times

        guard updatedTimes.indices
            .contains(index) else {
            return
        }

        updatedTimes.remove(
            at: index
        )

        reminder.schedule =
            .fixedTimes(
                FixedTimeReminderSchedule(
                    times:
                        updatedTimes
                )
            )
    }

    private func date(
        from time: ReminderTime
    ) -> Date {
        var components =
            Calendar.current
                .dateComponents(
                    [
                        .year,
                        .month,
                        .day
                    ],
                    from: Date()
                )

        components.hour =
            time.hour

        components.minute =
            time.minute

        return Calendar.current.date(
            from: components
        ) ?? Date()
    }
}
