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


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let keyMask: NSEventModifierFlags = .CommandKeyMask | .ControlKeyMask
        let shortcut = MASShortcut(keyCode: UInt(kVK_Tab), modifierFlags: keyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(shortcut, withAction: displayWindowsInSpace)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        MASShortcutMonitor.sharedMonitor().unregisterAllShortcuts()
    }
    
    func displayWindowsInSpace() {
        let app = NSApplication.sharedApplication()
        app.unhide(nil)
        app.activateIgnoringOtherApps(true)
        app.windows[0].makeKeyAndOrderFront(nil)
    }
}

