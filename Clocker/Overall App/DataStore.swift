// Copyright © 2015 Abhishek Banthia

import Cocoa

enum ViewType {
    case futureSlider
    case upcomingEventView
    case twelveHour
    case sunrise
    case seconds
    case showMeetingInMenubar
    case showAllDayEventsInMenubar
    case showAppInForeground
    case dateInMenubar
    case placeInMenubar
    case dayInMenubar
    case menubarCompactMode
}

class DataStore: NSObject {
    private static var sharedStore = DataStore(with: UserDefaults.standard)
    private var userDefaults: UserDefaults!

    // Since these pref can accessed every second, let's cache this
    private var shouldDisplayDayInMenubar: Bool = false
    private var shouldDisplayDateInMenubar: Bool = false

    class func shared() -> DataStore {
        return sharedStore
    }

    init(with defaults: UserDefaults) {
        super.init()
        userDefaults = defaults
        shouldDisplayDayInMenubar = shouldDisplay(.dayInMenubar)
        shouldDisplayDateInMenubar = shouldDisplay(.dateInMenubar)
    }

    func timezones() -> [Data] {
        guard let preferences = userDefaults.object(forKey: CLDefaultPreferenceKey) as? [Data] else {
            return []
        }

        return preferences
    }

    func menubarTimezones() -> [Data]? {
        return timezones().filter {
            let customTimezone = TimezoneData.customObject(from: $0)
            return customTimezone?.isFavourite == 1
        }
    }

    func updateDayPreference() {
        shouldDisplayDayInMenubar = shouldDisplay(.dayInMenubar)
    }

    func updateDateInPreference() {
        shouldDisplayDateInMenubar = shouldDisplay(.dateInMenubar)
    }

    func shouldShowDayInMenubar() -> Bool {
        return shouldDisplayDayInMenubar
    }

    func shouldShowDateInMenubar() -> Bool {
        return shouldDisplayDateInMenubar
    }

    func setTimezones(_ timezones: [Data]) {
        userDefaults.set(timezones, forKey: CLDefaultPreferenceKey)
    }

    func retrieve(key: String) -> Any? {
        return userDefaults.object(forKey: key)
    }

    func addTimezone(_ timezone: TimezoneData) {
        let encodedTimezone = NSKeyedArchiver.archivedData(withRootObject: timezone)

        var defaults: [Data] = (userDefaults.object(forKey: CLDefaultPreferenceKey) as? [Data]) ?? []
        defaults.append(encodedTimezone)

        userDefaults.set(defaults, forKey: CLDefaultPreferenceKey)
    }

    func removeLastTimezone() {
        var currentLineup = timezones()

        if currentLineup.isEmpty {
            return
        }

        currentLineup.removeLast()

        Logger.log(object: [:], for: "Undo Action Executed during Onboarding")

        userDefaults.set(currentLineup, forKey: CLDefaultPreferenceKey)
    }

    private func shouldDisplayHelper(_ key: String) -> Bool {
        guard let value = retrieve(key: key) as? NSNumber else {
            return false
        }
        return value.isEqual(to: NSNumber(value: 0))
    }

    func shouldDisplay(_ type: ViewType) -> Bool {
        switch type {
        case .futureSlider:
            return shouldDisplayHelper(CLDisplayFutureSliderKey)
        case .upcomingEventView:
            guard let value = retrieve(key: CLShowUpcomingEventView) as? NSString else {
                return false
            }
            return value == "YES"
        case .twelveHour:
            return shouldDisplayHelper(CL24hourFormatSelectedKey)
        case .showAllDayEventsInMenubar:
            return shouldDisplayHelper(CLShowAllDayEventsInUpcomingView)
        case .sunrise:
            return shouldDisplayHelper(CLSunriseSunsetTime)
        case .seconds:
            return shouldDisplayHelper(CLShowSecondsInMenubar)
        case .showMeetingInMenubar:
            return shouldDisplayHelper(CLShowMeetingInMenubar)
        case .showAppInForeground:
            guard let value = retrieve(key: CLShowAppInForeground) as? NSNumber else {
                return false
            }
            return value.isEqual(to: NSNumber(value: 1))
        case .dateInMenubar:
            return shouldDisplayHelper(CLShowDateInMenu)
        case .placeInMenubar:
            return shouldDisplayHelper(CLShowPlaceInMenu)
        case .dayInMenubar:
            return shouldDisplayHelper(CLShowDayInMenu)
        case .menubarCompactMode:
            guard let value = retrieve(key: CLMenubarCompactMode) as? Int else {
                return false
            }

            return value == 0
        }
    }
}
