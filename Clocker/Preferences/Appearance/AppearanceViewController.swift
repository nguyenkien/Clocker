// Copyright © 2015 Abhishek Banthia

import Cocoa

class AppearanceViewController: ParentViewController {
    @IBOutlet var timeFormat: NSSegmentedControl!
    @IBOutlet var theme: NSSegmentedControl!
    @IBOutlet var informationLabel: NSTextField!
    @IBOutlet var sliderDayRangePopup: NSPopUpButton!
    @IBOutlet var visualEffectView: NSVisualEffectView!
    @IBOutlet var menubarMode: NSSegmentedControl!
    @IBOutlet var includeDayInMenubarControl: NSSegmentedControl!
    @IBOutlet var includeDateInMenubarControl: NSSegmentedControl!
    @IBOutlet var includePlaceNameControl: NSSegmentedControl!

    private var themeDidChangeNotification: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        informationLabel.stringValue = "Favourite a timezone to enable menubar display options.".localized()
        informationLabel.textColor = NSColor.secondaryLabelColor

        informationLabel.setAccessibilityIdentifier("InformationLabel")

        sliderDayRangePopup.removeAllItems()
        sliderDayRangePopup.addItems(withTitles: [
            "1 day",
            "2 days",
            "3 days",
            "4 days",
            "5 days",
            "6 days",
            "7 days",
        ])

        setup()

        themeDidChangeNotification = NotificationCenter.default.addObserver(forName: .themeDidChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.setup()
            self.animateBackgroundColorChange()
            self.view.needsDisplay = true // Let's make the color change permanent.
        }
    }

    deinit {
        if let themeDidChangeNotif = themeDidChangeNotification {
            NotificationCenter.default.removeObserver(themeDidChangeNotif)
        }
    }

    private func animateBackgroundColorChange() {
        let colorAnimation = CABasicAnimation(keyPath: "backgroundColor")
        colorAnimation.duration = 0.25
        colorAnimation.fromValue = previousBackgroundColor.cgColor
        colorAnimation.toValue = Themer.shared().mainBackgroundColor().cgColor
        view.layer?.add(colorAnimation, forKey: "backgroundColor")
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if let menubarFavourites = DataStore.shared().menubarTimezones() {
            visualEffectView.isHidden = menubarFavourites.isEmpty ? false : true
            informationLabel.isHidden = menubarFavourites.isEmpty ? false : true
        }

        if let selectedIndex = DataStore.shared().retrieve(key: CLFutureSliderRange) as? NSNumber {
            sliderDayRangePopup.selectItem(at: selectedIndex.intValue)
        }

        if #available(macOS 10.14, *) {
            theme.setEnabled(true, forSegment: 2)
        } else {
            theme.setEnabled(false, forSegment: 2)
        }

        let shouldDisplayCompact = DataStore.shared().shouldDisplay(.menubarCompactMode)
        menubarMode.setSelected(true, forSegment: shouldDisplayCompact ? 0 : 1)
        updateMenubarControls(!shouldDisplayCompact)
    }

    @IBOutlet var headerLabel: NSTextField!
    @IBOutlet var timeFormatLabel: NSTextField!
    @IBOutlet var panelTheme: NSTextField!
    @IBOutlet var dayDisplayOptionsLabel: NSTextField!
    @IBOutlet var showSliderLabel: NSTextField!
    @IBOutlet var showSunriseLabel: NSTextField!
    @IBOutlet var showSecondsLabel: NSTextField!
    @IBOutlet var largerTextLabel: NSTextField!
    @IBOutlet var futureSliderRangeLabel: NSTextField!
    @IBOutlet var includeDateLabel: NSTextField!
    @IBOutlet var includeDayLabel: NSTextField!
    @IBOutlet var includePlaceLabel: NSTextField!
    @IBOutlet var menubarDisplayOptionsLabel: NSTextField!
    @IBOutlet var appDisplayLabel: NSTextField!
    @IBOutlet var menubarModeLabel: NSTextField!

    private func setup() {
        headerLabel.stringValue = "Main Panel Options".localized()
        timeFormatLabel.stringValue = "Time Format".localized()
        panelTheme.stringValue = "Panel Theme".localized()
        dayDisplayOptionsLabel.stringValue = "Day Display Options".localized()
        showSliderLabel.stringValue = "Show Future Slider".localized()
        showSunriseLabel.stringValue = "Show Sunrise/Sunset".localized()
        showSecondsLabel.stringValue = "Display the time in seconds".localized()
        largerTextLabel.stringValue = "Larger Text".localized()
        futureSliderRangeLabel.stringValue = "Future Slider Range".localized()
        includeDateLabel.stringValue = "Include Date".localized()
        includeDayLabel.stringValue = "Include Day".localized()
        includePlaceLabel.stringValue = "Include Place Name".localized()
        menubarDisplayOptionsLabel.stringValue = "Menubar Display Options".localized()
        menubarModeLabel.stringValue = "Menubar Mode".localized()

        [headerLabel, timeFormatLabel, panelTheme,
         dayDisplayOptionsLabel, showSliderLabel, showSecondsLabel,
         showSunriseLabel, largerTextLabel, futureSliderRangeLabel,
         includeDayLabel, includeDateLabel, includePlaceLabel,
         menubarDisplayOptionsLabel, appDisplayLabel, menubarModeLabel].forEach {
            $0?.textColor = Themer.shared().mainTextColor()
        }
    }

    @IBAction func timeFormatSelectionChanged(_ sender: NSSegmentedControl) {
        let selection = NSNumber(value: sender.selectedSegment)

        UserDefaults.standard.set(selection, forKey: CL24hourFormatSelectedKey)

        Logger.log(object: ["Time Format": sender.selectedSegment == 0 ? "12 Hour Format" : "24 Hour Format"], for: "Time Format Selected")

        refresh(panel: true, floating: true)

        updateStatusItem()
    }

    private var previousBackgroundColor: NSColor = NSColor.white

    @IBAction func themeChanged(_ sender: NSSegmentedControl) {
        previousBackgroundColor = Themer.shared().mainBackgroundColor()

        Themer.shared().set(theme: sender.selectedSegment)

        refresh(panel: false, floating: true)

        guard let panelController = PanelController.panel() else {
            return
        }

        panelController.refreshBackgroundView()

        panelController.shutdownButton.image = Themer.shared().shutdownImage()
        panelController.preferencesButton.image = Themer.shared().preferenceImage()
        panelController.pinButton.image = Themer.shared().pinImage()
        panelController.sharingButton.image = Themer.shared().sharingImage()

        let defaultTimezones = panelController.defaultPreferences
        if defaultTimezones.isEmpty {
            panelController.updatePanelColor()
        }

        panelController.updateTableContent()

        switch sender.selectedSegment {
        case 0:
            Logger.log(object: ["themeSelected": "Light"], for: "Theme")
        case 1:
            Logger.log(object: ["themeSelected": "Dark"], for: "Theme")
        case 2:
            Logger.log(object: ["themeSelected": "System"], for: "Theme")
        default:
            Logger.log(object: ["themeSelected": "System"], for: "Theme")
        }
    }

    @IBAction func changeRelativeDayDisplay(_ sender: NSSegmentedControl) {
        let selectedIndex = NSNumber(value: sender.selectedSegment)
        var selection = "Relative Day"

        if selectedIndex == 1 {
            selection = "Actual Day"
        } else if selectedIndex == 2 {
            selection = "Actual Date Day"
        }

        Logger.log(object: ["dayPreference": selection], for: "RelativeDate")

        refresh(panel: true, floating: true)
    }

    @IBAction func showFutureSlider(_: Any) {
        refresh(panel: false, floating: true)
    }

    @IBAction func showSunriseSunset(_ sender: NSSegmentedControl) {
        Logger.log(object: ["Is It Displayed": sender.selectedSegment == 0 ? "YES" : "NO"], for: "Sunrise Sunset")
    }

    @IBAction func displayTimeWithSeconds(_ sender: NSSegmentedControl) {
        Logger.log(object: ["Displayed": sender.selectedSegment == 0 ? "YES" : "NO"], for: "Display Time With Seconds")

        if DataStore.shared().shouldDisplay(.seconds) {
            guard let panelController = PanelController.panel() else { return }
            panelController.pauseTimer()
        }

        updateStatusItem()
    }

    @IBAction func changeAppDisplayOptions(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            Logger.log(object: ["Selection": "Menubar"], for: "Dock Mode")
            NSApp.setActivationPolicy(.accessory)
        } else {
            Logger.log(object: ["Selection": "Menubar and Dock"], for: "Dock Mode")
            NSApp.setActivationPolicy(.regular)
        }
    }

    private func refresh(panel: Bool, floating: Bool) {
        OperationQueue.main.addOperation {
            if panel, DataStore.shared().shouldDisplay(ViewType.showAppInForeground) == false {
                guard let panelController = PanelController.panel() else { return }

                let futureSliderBounds = panelController.futureSlider.bounds
                panelController.futureSlider.setNeedsDisplay(futureSliderBounds)

                panelController.updateDefaultPreferences()

                panelController.updateTableContent()
                panelController.setupMenubarTimer()
            }

            if floating, DataStore.shared().shouldDisplay(ViewType.showAppInForeground) {
                if DataStore.shared().shouldDisplay(ViewType.showAppInForeground) {
                    let floatingWindow = FloatingWindowController.shared()
                    floatingWindow.updateTableContent()
                    floatingWindow.futureSlider.setNeedsDisplay(floatingWindow.futureSlider.bounds)

                    if !panel {
                        floatingWindow.updatePanelColor()
                    }
                }
            }
        }
    }

    @IBAction func displayDayInMenubarAction(_: Any) {
        DataStore.shared().updateDayPreference()
        updateStatusItem()
    }

    @IBAction func displayDateInMenubarAction(_: Any) {
        DataStore.shared().updateDateInPreference()
        updateStatusItem()
    }

    @IBAction func displayPlaceInMenubarAction(_: Any) {
        updateStatusItem()
    }

    private func updateStatusItem() {
        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        if DataStore.shared().shouldDisplay(.menubarCompactMode) {
            statusItem.setupStatusItem()
        } else {
            statusItem.performTimerWork()
        }
    }

    @IBAction func menubarModeChanged(_ sender: NSSegmentedControl) {
        updateMenubarControls(sender.selectedSegment == 1)

        guard let statusItem = (NSApplication.shared.delegate as? AppDelegate)?.statusItemForPanel() else {
            return
        }

        statusItem.setupStatusItem()

        if sender.selectedSegment == 0 {
            Logger.log(object: ["Context": "In Appearance View"], for: "Switched to Compact Mode")
        } else {
            Logger.log(object: ["Context": "In Appearance View"], for: "Switched to Standard Mode")
        }
    }

    // We don't support showing day or date in the menubar for compact mode yet.
    // Disable those options to let the user know.
    private func updateMenubarControls(_ isEnabled: Bool) {
        [includePlaceNameControl].forEach { $0?.isEnabled = isEnabled }
    }
}
