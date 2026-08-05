import Foundation

extension ReminderDefinition {
    static func fromHydrationSettings(
        _ hydration: HydrationSettings
    ) -> ReminderDefinition {
        ReminderDefinition(
            title: "Drink Water",
            message:
                "Take a moment to drink some water.",
            category: .hydration,
            isEnabled: hydration.isEnabled,
            weekdays: hydration.weekdays,
            schedule: .interval(
                IntervalReminderSchedule(
                    intervalMinutes:
                        hydration.intervalMinutes,
                    startTime: ReminderTime(
                        hour: hydration.startHour,
                        minute: hydration.startMinute
                    ),
                    endTime: ReminderTime(
                        hour: hydration.endHour,
                        minute: hydration.endMinute
                    )
                )
            ),
            actions: .hydration
        )
    }

    func applyingToHydrationSettings(
        preservingRuntimeState existing:
            HydrationSettings
    ) -> HydrationSettings? {
        guard category == .hydration else {
            return nil
        }

        guard case .interval(let intervalSchedule) =
            schedule
        else {
            return nil
        }

        return HydrationSettings(
            isEnabled: isEnabled,
            intervalMinutes:
                intervalSchedule.intervalMinutes,
            startHour:
                intervalSchedule.startTime.hour,
            startMinute:
                intervalSchedule.startTime.minute,
            endHour:
                intervalSchedule.endTime.hour,
            endMinute:
                intervalSchedule.endTime.minute,
            weekdays: weekdays,
            lastCompleted: existing.lastCompleted,
            lastHandled: existing.lastHandled
        )
    }
}
