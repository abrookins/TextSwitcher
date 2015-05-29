//
//  AppDelegate.swift
//  TextSwitcher
//
//  Created by Andrew Brookins on 4/24/15.
//  Copyright (c) 2015 Andrew Brookins. All rights reserved.
//

import Cocoa
import QuartzCore
import ApplicationServices

let ApplicationWasActivated = "ts:activationWasActivated"


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()

    override func awakeFromNib() {
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.title = "TS"
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        checkForAccessibilityAccess()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        MASShortcutMonitor.sharedMonitor().unregisterAllShortcuts()
    }
    
    func applicationWillBecomeActive(notification: NSNotification) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.postNotification(NSNotification(name:ApplicationWasActivated, object:notificationCenter))
        center()
    }

    func attachHandlers() {
        let keyMask: NSEventModifierFlags = .AlternateKeyMask
        let shortcut = MASShortcut(keyCode: UInt(kVK_Tab), modifierFlags: keyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(shortcut, withAction: bringToForeground)
    }

    func hasAccessibilityAccess() -> Bool {
        let trustedCheckOption = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options: CFDictionary = [trustedCheckOption: true]
        let hasAccess = AXIsProcessTrustedWithOptions(options)
        return hasAccess == 1
    }

    func checkForAccessibilityAccess() {
        if hasAccessibilityAccess() {
            attachHandlers()
        }
        else {
            requestAccessibilityApiAccess()
        }
    }

    func requestAccessibilityApiAccess() {
        let app = NSApplication.sharedApplication()
        if let window = app.windows[1] as? NSWindow {
            let alert = NSAlert()
            alert.messageText = "Allow TextSwitcher to use Accessibility Features"
            alert.informativeText = "TextSwitcher requires the use of Accessibilty features. Please authorize " +
                "TextSWitcher to control your computer in the Accessibility section of the Security & Privacy " +
                "System Preferences panel."
            alert.beginSheetModalForWindow(window, completionHandler: { response in
                // This seems better than calling `checkForAccessibilityAccess` and
                // potentially displaying the same message again, but I'm not sure.
                if self.hasAccessibilityAccess() {
                    self.attachHandlers()
                }
            })
        }
    }

    func center() {
        let app = NSApplication.sharedApplication()
        // Window 0 is the menubar window, window 1 is the app window.
        app.windows[1].center()
    }
    
    func bringToForeground() {
        let app = NSApplication.sharedApplication()
        app.activateIgnoringOtherApps(true)
        // Window 0 is the menubar window, window 1 is the app window.
        app.windows[1].makeKeyAndOrderFront(nil)
        app.windows[1].orderFront(self)
        center()
    }
}

