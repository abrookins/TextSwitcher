//
//  ViewController.swift
//  TextSwitcher
//
//  Created by Andrew Brookins on 4/24/15.
//  Copyright (c) 2015 Andrew Brookins. All rights reserved.
//

import Cocoa
import Foundation


func getWindowsInSpace() -> [Dictionary<String,String>] {
    // get an array of all the windows in the current Space
    let windowInfosRef = CGWindowListCopyWindowInfo(CGWindowListOption(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements), CGWindowID(0))
    let windowInfos = windowInfosRef.takeRetainedValue() as [AnyObject]
    let windowsDowncasted = windowInfos as! [NSDictionary]
    var windows = [Dictionary<String,String>]()
    
    for window in windowsDowncasted {
        let ownerNameKey = kCGWindowOwnerName as String
        let windowNameKey = kCGWindowName as String
        let pidKey = kCGWindowOwnerPID as String
        let owner = window[ownerNameKey] as! String
        let name = window[windowNameKey] as! String
        let pid = window[pidKey] as! Int
        
        // Windows without a name appear to be menu items or backgrounded.
        // Windows named "Menubar" are not windows. ;)
        if !name.isEmpty && name != "Menubar" {
            windows.append([
                "owner": owner,
                "name": name,
                "pid": String(pid)
            ])
        }
    }
    
    return windows
}


class ViewController: NSViewController {
    @IBOutlet weak var searchResult: NSTextFieldCell!
    @IBOutlet weak var searchField: NSSearchFieldCell!
    @IBOutlet weak var searchFieldContainer: NSSearchField!
    @IBOutlet var searchView: NSView!
    
    var lastSearchResults: [Dictionary<String,String>] = []
    
    override func viewDidLoad() {
        doSearch("")
        searchFieldContainer.becomeFirstResponder()
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        doSearch("")
        searchFieldContainer.becomeFirstResponder()
        super.viewWillAppear()
    }
    
    func clearResults() {
        searchResult.stringValue = ""
    }
    
    func displayResults() {
        var results = ""
        
        for (idx, window) in enumerate(self.lastSearchResults) {
            let owner = window["owner"]!
            let name = window["name"]!
            // Show idx+1 to avoid using 0, which is hard to press with Control
            // and is also the last key on most keyboards, rather than the first.
            results += "(\(idx + 1)) \(owner): \(name)\n"
        }
        
        searchResult.stringValue = results
    }
    
    func doSearch(text: String) {
        clearResults()
        let windows = getWindowsInSpace()
        let lowerText = text.lowercaseString
        
        if text.isEmpty {
            self.lastSearchResults = windows
            displayResults()
        }
        else {
            self.lastSearchResults = windows.filter { (window) in
                window["name"]!.lowercaseString.rangeOfString(lowerText) != nil ||
                window["owner"]!.lowercaseString.rangeOfString(lowerText) != nil
            }
            displayResults()
        }
    }
    
    func doOpenItem(index: Int) {
        let result = lastSearchResults[index]
        let pid: pid_t = pid_t(result["pid"]!.toInt()!)
        
        let appRef: AXUIElement = AXUIElementCreateApplication(pid).takeRetainedValue()
        let systemWideElement : AXUIElement = AXUIElementCreateSystemWide().takeRetainedValue()
        let windowListRef = UnsafeMutablePointer<Unmanaged<AnyObject>?>.alloc(1)
        
        AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, windowListRef);
        
        let windowList: CFArray = windowListRef.memory!.takeRetainedValue() as! CFArray
        
        if CFArrayGetCount(windowList) < 1 {
            return
        }
        
        let windowRef: AXUIElement = unsafeBitCast(CFArrayGetValueAtIndex(windowList, 0), AXUIElement.self)
        
        AXUIElementPerformAction(windowRef, kAXRaiseAction)
    }

    @IBAction func search(sender: NSSearchFieldCell) {
        doSearch(sender.stringValue)
    }
    
    @IBAction func chooseSearchResult(sender: TextSwitcherView) {
        var index = sender.chosenResult
        if !index.isEmpty {
            // Negate one because the display indexes are 1-based
            // while the actual array index is zero-based.
            let oneIndexed = index.toInt()!
            let zeroIndexed = oneIndexed < 1 ? 0 : oneIndexed - 1
            println("displayindex: \(oneIndexed) zeroindexed: \(zeroIndexed)")
            doOpenItem(zeroIndexed)
        }
    }
}

