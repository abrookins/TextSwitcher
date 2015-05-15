//
//  ViewController.swift
//  TextSwitcher
//
//  Created by Andrew Brookins on 4/24/15.
//  Copyright (c) 2015 Andrew Brookins. All rights reserved.
//

import Cocoa
import Foundation


class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var searchResult: NSTextFieldCell!
    @IBOutlet weak var searchField: NSSearchFieldCell!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchFieldContainer: NSSearchField!
    @IBOutlet var searchView: NSView!
    
    var windows: [Dictionary<String,String>] = []
    
    override func viewDidLoad() {
        resetWindows()
        searchFieldContainer.becomeFirstResponder()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: Selector("viewWasActivated"),
            name: ApplicationWasActivated, object: notificationCenter)
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        resetWindows()
        searchFieldContainer.becomeFirstResponder()
        super.viewWillAppear()
    }
    
    override func viewDidLayout() {
        resetWindows()
        searchFieldContainer.becomeFirstResponder()
        super.viewDidLayout()
    }
    
    func viewWasActivated() {
        resetWindows()
        searchFieldContainer.becomeFirstResponder()
    }
    
    func resetWindows() {
        if let _windows = AccessibilityWrapper.windowsInCurrentSpace() {
            windows = _windows
            tableView.reloadData()
        }
    }
    
    func doSearch(text: String) {
        let lowerText = text.lowercaseString
        windows = windows.filter { (window) in
            if let name = window["name"], owner = window["owner"] {
                return name.lowercaseString.rangeOfString(lowerText) != nil ||
                    owner.lowercaseString.rangeOfString(lowerText) != nil
            }
            return false
        }
        tableView.reloadData()
    }
    
    func doOpenItem(index: Int = 0) {
        if windows.count > 0 {
            let result = windows[index]
            
            if let pid = result["pid"]?.toInt(), windowName = result["name"] {
                AccessibilityWrapper.openWindow(forApplicationWithPid: pid, named: windowName)
                doCancel()
            }
        }
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return windows.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellIdentifier = ""
        
        if let columnIdentifier = tableColumn?.identifier {
            if columnIdentifier == "ownerColumn" {
                cellIdentifier = "owner"
            }
            else if columnIdentifier == "nameColumn" {
                cellIdentifier = "name"
            }
            if let result = tableView.makeViewWithIdentifier(cellIdentifier, owner: self) as? NSTableCellView {
                var value = windows[row][cellIdentifier]!
                if cellIdentifier == "owner" {
                    // Give the user a one-indexed value for hitting Control+<Index> to open the window
                    value = "⌘\(row + 1) | \(value)"
                }
                result.textField!.stringValue = value
                return result
            }
        }
        return nil
    }
    
    // Close the window.
    func doCancel() {
        let app = NSApplication.sharedApplication()
        if let window = app.mainWindow {
            window.orderOut(self)
        }
    }
    
    @IBAction func cancel(sender: NSSearchFieldCell) {
        doCancel()
    }
    
    @IBAction func search(sender: NSSearchFieldCell) {
        resetWindows()
        if sender.stringValue.isEmpty {
            return
        }
        doSearch(sender.stringValue)
    }
    
    @IBAction func chooseSearchResult(sender: TextSwitcherView) {
        var index = sender.chosenResult
        // We assume that they pressed the enter key, so just open
        // the top item in the search results.
        if index.isEmpty {
            doOpenItem()
            return
        }
        // Negate one because the display indexes are 1-based
        // while the actual array index is zero-based.
        if let onIndexed = index.toInt() {
            let oneIndexed = index.toInt()!
            let zeroIndexed = oneIndexed < 1 ? 0 : oneIndexed - 1
            doOpenItem(index: zeroIndexed)
        }
    }
}

