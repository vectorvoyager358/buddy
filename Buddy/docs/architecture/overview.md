# Buddy Architecture

## Overview

Buddy is a native macOS application built with SwiftUI and AppKit.

## Main Components

### AppDelegate

Responsible for:

- Application startup
- Floating panel creation
- Menu-bar creation
- Dependency construction

### BuddyPanel

Responsible for:

- Transparent floating window behavior
- Always-on-top behavior
- macOS Spaces support
- Dragging behavior

### BuddyView

Responsible for:

- Rendering the desktop companion
- Displaying reminder messages
- Displaying reminder actions
- Observing view-model and animation state

### BuddyViewModel

Responsible for:

- Buddy presentation state
- Reminder reaction state
- Completion, snooze, and skip feedback

### ReminderManager

Responsible for:

- Scheduling reminders
- Snoozing reminders
- Cancelling reminders
- Triggering Buddy reactions

### NotificationManager

Responsible for:

- Notification permission
- Scheduling native notifications
- Cancelling native notifications

### AnimationEngine

Responsible for:

- Current character animation
- Temporary animations
- Returning Buddy to idle state

## Dependency Flow

`AppDelegate → ReminderManager → BuddyViewModel → AnimationEngine → BuddyView`

Native notifications are handled independently through `NotificationManager`.

## Design Principles

- Keep business logic separate from UI
- Keep reminder scheduling separate from notifications
- Keep animation behavior separate from reminder data
- Use dependency injection
- Keep data local and offline by default
