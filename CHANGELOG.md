## 1.0.1

* **FIX:** Add missing changelog entries

## 1.0.0

* **BREAKING**: **`LegacyCalendarWidget` is replaced by `LegacyCalendar`:** The main widget has been rewritten and requires a different set of parameters.
* **FEATURE **State Management:** The calendar now relies on the `provider` package for state management. You need to set up the necessary providers in your app.
* **FEATURE **Event Handling:** Event handling is now done through callbacks on the `LegacyCalendar` widget.
* **FEATURE** **API Integration:** The calendar now uses an `AbstractApiInterface` to fetch and manage events.

## 0.0.8

* **FIX**: Update README.md

## 0.0.7

* **FIX**: Screenshot properly mapped

## 0.0.6

* **FIX**: Actually, don't pubignore the example...

## 0.0.5

* **FIX**: 0.0.4 didn't properly pubignore

## 0.0.4

* Properly pubignore example and build dirs

## 0.0.3

* Add screenshot to pubspec.yaml

## 0.0.2

* **FIX**: Fix up old dependencies

## 0.0.1

*   Initial release of the `legacy_calendar` package.
*   Provides customizable day, week, and month calendar views.
*   Supports event display and interaction.
*   Supports responsive scaling.