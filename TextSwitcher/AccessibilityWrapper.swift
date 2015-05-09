//
//  AccessibilityWrapper.swift
//  TextSwitcher
//
//  Created by Andrew Brookins on 5/8/15.
//  Copyright (c) 2015 Andrew Brookins. All rights reserved.
//

import Foundation


class AccessibilityWrapper {
    class func buildWindowDicts(windows: [AnyObject]) -> [Dictionary<String,String>] {
        var windowDicts = [Dictionary<String,String>]()
        println(windows)
        for window in windows {
            let ownerNameKey = kCGWindowOwnerName as String
            let windowNameKey = kCGWindowName as String
            let pidKey = kCGWindowOwnerPID as String
            
            if let owner = window[ownerNameKey] as? String,
                name = window[windowNameKey] as? String,
                pid = window[pidKey] as? Int {
                    
                // Windows named "TextSwitcher" are this app.
                // Windows named "Menubar" are not windows. ;)
                let ignoredApps = Set(["Menubar", "TextSwitcher", "SystemUIServer"])
                // Windows we will show even though they don't have a name (???)
                let includedApps = Set(["Messages"])
                    
                if includedApps.contains(owner) || !name.isEmpty && !ignoredApps.contains(name) && !ignoredApps.contains(owner) {
                    windowDicts.append([
                        "owner": owner,
                        "name": name,
                        "pid": String(pid)
                    ])
                }
            }
        }
        return windowDicts
    }

    // Get data about windows in the current space.
    class func windowsInCurrentSpace() -> [Dictionary<String,String>]? {
        // get an array of all the windows in the current Space
        let windowInfosRef = CGWindowListCopyWindowInfo(CGWindowListOption(
            kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements), CGWindowID(0))
        let windowInfos = windowInfosRef.takeRetainedValue() as [AnyObject]
        if let windowsDowncasted = windowInfos as? [NSDictionary] {
            return buildWindowDicts(windowsDowncasted)
        }
        return nil
    }
    
    class func openWindow(applicationPid: Int, windowName: String) {
        let pid: pid_t = pid_t(applicationPid)
        let appRef: AXUIElement = AXUIElementCreateApplication(pid).takeRetainedValue()
        let systemWideElement : AXUIElement = AXUIElementCreateSystemWide().takeRetainedValue()
        let windowListRef = UnsafeMutablePointer<Unmanaged<AnyObject>?>.alloc(1)

        AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, windowListRef)
        
        // XXX: I can't figure out how to unwrap these two values. Xcode hates me no matter what I do.
        let windowList: CFArray = windowListRef.memory!.takeRetainedValue() as! CFArray
        
        if CFArrayGetCount(windowList) < 1 {
            return
        }
        
        // TODO: Use windowName to open the window with that name.
        let windowRef: AXUIElement = unsafeBitCast(CFArrayGetValueAtIndex(windowList, 0), AXUIElement.self)
        
        AXUIElementPerformAction(windowRef, kAXRaiseAction)           
    }
}