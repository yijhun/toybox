# Time Tracker Architecture Guide

This document outlines the structure of the shared SwiftUI app for iOS, macOS (Catalyst), and watchOS.

## Targets
- **TimeTracker (iOS + Catalyst)**: Uses SwiftUI app lifecycle, SwiftData persistence, and Google Calendar integration.
- **TimeTrackerMac**: Mac Catalyst flavor with menu bar extras and settings enhancements.
- **TimeTrackerWatch**: watchOS app with simplified UI and wrist-friendly controls.

## Shared Layers
- **Models**: `TimeEntry`, `Category`, `PendingSyncTask` are SwiftData models. `TimeEntry` can be mirrored to Google Calendar.
- **Persistence**: `PersistenceController` wraps SwiftData `ModelContainer` to manage storage. The same models can also be persisted with Core Data when SwiftData is unavailable.
- **Timer Logic**: `TimerManager` manages active sessions with async timers (based on `Task.sleep`).
- **Syncing**: `SyncCoordinator` queues `PendingSyncTask` records when offline and replays them when network returns, delegating Google Calendar operations to `GoogleCalendarManager`.
- **ViewModels**: `TimeEntryListViewModel`, `StatisticsViewModel`, `GoogleCalendarManager`, `SyncCoordinator`, and `TimerManager` expose observable state to the UI.
- **Views**: Timer panel, list/calendar views, statistics, settings, and a macOS menu bar extra share the same view models.

## Platform Notes
- **macOS**: Adds a `MenuBarExtra` timer control and mac-specific settings scene.
- **watchOS**: Uses compact controls and complication-friendly layout; sync uses background tasks when possible.

## Build
The repository includes a `project.yml` for use with [XcodeGen](https://github.com/yonaskolb/XcodeGen). Run `xcodegen generate` to produce the Xcode project with iOS, macOS (Catalyst), and watchOS targets.
