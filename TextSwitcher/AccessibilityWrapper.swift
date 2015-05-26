//
//  AccessibilityWrapper.swift
//  TextSwitcher
//
//  Created by Andrew Brookins on 5/8/15.
//  Copyright (c) 2015 Andrew Brookins. All rights reserved.
//

import Foundation


class WindowData: Equatable, Printable {
    var owner: String = ""
    var name: String = ""
    var pid: Int = 0

    init(owner: String, name: String, pid: Int) {
        self.owner = owner
        self.name = name
        self.pid = pid
    }

    var description: String {
        return "WindowData(owner=\(owner), name=\(name), pid=\(pid)"
    }
}


// Fulfill the Equatable protocol for WindowData.
func ==(lhs: WindowData, rhs: WindowData) -> Bool {
    return lhs.owner == rhs.owner && lhs.name == rhs.name && lhs.pid == rhs.pid
}


// A wrapper around C Accessibility APIs that TextSwitcher uses.
class AccessibilityWrapper {

    // A helper method that builds an array of WindowData objects from
    // the C types that CGWindowListCopyWindowInfo returns.
    // TODO: Exclusions and ignored apps should be parameterized.
    class func buildWindowDicts(windows: [AnyObject]) -> [WindowData] {
        var data = [WindowData]()
        for window in windows {
            let ownerNameKey = kCGWindowOwnerName as String
            let windowNameKey = kCGWindowName as String
            let pidKey = kCGWindowOwnerPID as String
            let layerKey = kCGWindowLayer as String
            
            // Ignore menubar and system applications.
            if let layer = window[layerKey] as? Int {
                if layer != 0 {
                    continue
                }
            }
            
            if let owner = window[ownerNameKey] as? String,
                    name = window[windowNameKey] as? String,
                    pid = window[pidKey] as? Int {
                    
                // Windows named "TextSwitcher" are this app.
                // Windows named "Menubar" are not windows.
                let ignoredApps = Set(["Menubar", "TextSwitcher", "SystemUIServer"])

                // Windows we will show even though they don't have a name (???)
                let includedApps = Set(["Messages"])
                    
                if includedApps.contains(owner) || !ignoredApps.contains(name) && !ignoredApps.contains(owner) {
                    data.append(WindowData(owner: owner, name: name, pid: Int(pid)))
                }
            }
        }
        return data
    }

    // Get data about windows in the current space.
    class func windowsInCurrentSpace() -> [WindowData]? {
        // get an array of all the windows in the current Space
        // Note: CGWindowID(0) == kCGNullWindowID
        let windowInfosRef = CGWindowListCopyWindowInfo(CGWindowListOption(
            kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements), CGWindowID(0))
        let windowInfos = windowInfosRef.takeRetainedValue() as [AnyObject]
        if let windowsDowncasted = windowInfos as? [NSDictionary] {
            return buildWindowDicts(windowsDowncasted)
        }
        return nil
    }

    class func windowsBelowCurrent() -> [WindowData]? {
        let windowInfosRef = CGWindowListCopyWindowInfo(CGWindowListOption(
            kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements | kCGWindowListOptionOnScreenBelowWindow),
            CGWindowID(0))
        let windowInfos = windowInfosRef.takeRetainedValue() as [AnyObject]
        if let windowsDowncasted = windowInfos as? [NSDictionary] {
            return buildWindowDicts(windowsDowncasted)
        }
        return nil
    }

    class func raiseWindow(windowRef: AXUIElement) {
        AXUIElementPerformAction(windowRef, kAXRaiseAction)
        AXUIElementSetAttributeValue(windowRef, kAXFrontmostAttribute, kCFBooleanTrue);
    }

    class func windowAtIndex(i: Int, fromWindows windows: CFArray) -> AXUIElement {
        return unsafeBitCast(CFArrayGetValueAtIndex(windows, i), AXUIElement.self)
    }
    
    // Open the first window for an application with `applicationPid` whose title matches
    // `windowName`.
    //
    // Note: We could go farther with this and compare more details about a source window,
    // like its size and position. E.g.: http://stackoverflow.com/questions/6178860/getting-window-number-through-osx-accessibility-api
    class func openWindow(forApplicationWithPid applicationPid: Int, named windowName: String) {
        let pid: pid_t = pid_t(applicationPid)
        let appRef: AXUIElement = AXUIElementCreateApplication(pid).takeRetainedValue()
        let systemWideElement : AXUIElement = AXUIElementCreateSystemWide().takeRetainedValue()
        let windowListRef = UnsafeMutablePointer<Unmanaged<AnyObject>?>.alloc(1)

        AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, windowListRef)
        
        // XXX: I can't figure out how to unwrap these two values. Xcode hates me no matter what I do.
        let windows: CFArray = windowListRef.memory!.takeRetainedValue() as! CFArray
        let numWindows = CFArrayGetCount(windows)

        // Whether or not we found a title match. If we don't, we'll try to show the first app window.
        var foundMatch = false
        
        if numWindows == 0 {
            return
        }
        
        for var i = 0; i < numWindows; i++ {
            let windowRef = windowAtIndex(i, fromWindows: windows)
            let titleValue = UnsafeMutablePointer<Unmanaged<AnyObject>?>.alloc(1)
            
            AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, titleValue);
            
            if let title = titleValue.memory?.takeRetainedValue() as? String {
                if title == windowName {
                    raiseWindow(windowRef)
                    foundMatch = true
                }
            }
        }
        if !foundMatch {
            let windowRef = windowAtIndex(0, fromWindows: windows)
            raiseWindow(windowRef)
        }
        AXUIElementSetAttributeValue(appRef, kAXFrontmostAttribute, kCFBooleanTrue);
    }
}