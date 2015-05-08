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
        for window in windows {
            let ownerNameKey = kCGWindowOwnerName as String
            let windowNameKey = kCGWindowName as String
            let pidKey = kCGWindowOwnerPID as String
            
            if let owner = window[ownerNameKey] as? String,
                name = window[windowNameKey] as? String,
                pid = window[pidKey] as? Int {
                    
                // Windows named "TextSwitcher" are this app.
                // Windows named "Menubar" are not windows. ;)
                let ignoredApps = Set(["Menubar", "TextSwitcher"])
                    
                // Windows without a name appear to be menu items or backgrounded.
                if !name.isEmpty && !ignoredApps.contains(name) && !ignoredApps.contains(owner) {
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
        
        AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, windowListRef);
        
        let windowList: CFArray = windowListRef.memory!.takeRetainedValue() as! CFArray
        
        if CFArrayGetCount(windowList) < 1 {
            return
        }
        
        // TODO: Use windowName to open the window with that name.
        let windowRef: AXUIElement = unsafeBitCast(CFArrayGetValueAtIndex(windowList, 0), AXUIElement.self)
        
        AXUIElementPerformAction(windowRef, kAXRaiseAction)
    }
}