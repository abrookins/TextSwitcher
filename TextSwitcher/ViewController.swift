//
//  ViewController.swift
//  TextSwitcher
//
//  Created by Andrew Brookins on 4/24/15.
//  Copyright (c) 2015 Andrew Brookins. All rights reserved.
//

import Cocoa
import Foundation


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
            if let owner = window["owner"], name = window["name"] {
                // Show idx+1 to avoid using 0, which is hard to press with Control
                // and is also the last key on most keyboards, rather than the first.
                results += "(\(idx + 1)) \(owner): \(name)\n"
            }
        }
        
        searchResult.stringValue = results
    }
    
    func doSearch(text: String) {
        clearResults()
        if let windows = AccessibilityWrapper.windowsInCurrentSpace() {
            let lowerText = text.lowercaseString
            
            if text.isEmpty {
                self.lastSearchResults = windows
                displayResults()
            }
            else {
                self.lastSearchResults = windows.filter { (window) in
                    if let name = window["name"], owner = window["owner"] {
                        return name.lowercaseString.rangeOfString(lowerText) != nil ||
                            owner.lowercaseString.rangeOfString(lowerText) != nil
                    }
                    return false
                }
                displayResults()
            }
        }
    }
    
    func doOpenItem(index: Int) {
        let result = lastSearchResults[index]
        
        if let pid = result["pid"]?.toInt(), windowName = result["name"] {
            AccessibilityWrapper.openWindow(pid, windowName: windowName)
            let app = NSApplication.sharedApplication()
            app.hide(nil)
        }
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

