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
    
    var windows: [WindowData] = []
    
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
            return window.name.lowercaseString.rangeOfString(lowerText) != nil ||
                window.owner.lowercaseString.rangeOfString(lowerText) != nil
        }
        tableView.reloadData()
    }
    
    func doOpenItem(index: Int = 0) {
        if windows.count > 0 {
            let window = windows[index]
            doCancel()
            AccessibilityWrapper.openWindow(forApplicationWithPid: window.pid, named: window.name)
        }
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return windows.count
    }
    
    func makeIconTableCell(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = "appImage"
        if let cellView = tableView.makeViewWithIdentifier(cellIdentifier, owner: self) as? NSTableCellView {
            if let app = NSRunningApplication(processIdentifier: pid_t(windows[row].pid)),
                    appIcon = app.icon,
                    imageView = cellView.imageView {
                imageView.image = appIcon
            }
            return cellView
        }
        return nil
    }

    func makeOwnerTableCell(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = "owner"
        if let cellView = tableView.makeViewWithIdentifier(cellIdentifier, owner: self) as? NSTableCellView {
            let window = windows[row]
            let valueBeforeCommandHint = window.owner
            // Give the user a one-indexed value for hitting Control+<Index> to open the window
            cellView.textField!.stringValue = "⌘\(row + 1) | \(valueBeforeCommandHint)"
            return cellView
        }
        return nil
    }

    func makeNameTableCell(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = "name"
        if let cellView = tableView.makeViewWithIdentifier(cellIdentifier, owner: self) as? NSTableCellView {
            let window = windows[row]
            cellView.textField!.stringValue = window.name
            return cellView
        }
        return nil
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let columnIdentifier = tableColumn?.identifier {
            if columnIdentifier == "ownerColumn" {
                return makeOwnerTableCell(tableView, viewForTableColumn: tableColumn, row: row)
            }
            else if columnIdentifier == "nameColumn" {
                return makeNameTableCell(tableView, viewForTableColumn: tableColumn, row: row)
            }
            else if columnIdentifier == "imageColumn" {
                return makeIconTableCell(tableView, viewForTableColumn: tableColumn, row: row)
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

