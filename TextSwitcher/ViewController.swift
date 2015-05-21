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
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var searchView: NSView!
    @IBOutlet weak var scrollView: NSScrollView!

    var windows: [WindowData] = []
    var incomingWindow: WindowData? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        focusSearchField()

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: Selector("viewWasActivated"),
            name: ApplicationWasActivated, object: notificationCenter)
    }
    
    override func viewDidAppear() {
        super.viewWillAppear()
        resetSearch()
        focusSearchField()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        resetSearch()
        focusSearchField()
    }
    
    func viewWasActivated() {
        setIncomingWindow()
        resetSearch()
        focusSearchField()
    }

    func focusSearchField() {
        searchField.becomeFirstResponder()
    }

    func setIncomingWindow() {
        if let windowsBelowSelf = AccessibilityWrapper.windowsBelowCurrent() {
            incomingWindow = windowsBelowSelf[0]
        }
    }

    func resetWindows() {
        if var _windows = AccessibilityWrapper.windowsInCurrentSpace() {
            if _windows.count > 1 {
                // Swap the first and second items, like Command-Tab does.
                let firstItem = _windows.removeAtIndex(0)
                let secondItem = _windows.removeAtIndex(0)
                _windows.insert(secondItem, atIndex: 0)
                _windows.insert(firstItem, atIndex: 1)
            }
            windows = _windows
            tableView.reloadData()
        }
    }
    
    func resetSearch() {
        resetWindows()
        searchField.stringValue = ""
    }

    // Resize the view to match the number of results.
    func resizeToFitContent() {
        let contentHeight = scrollView.documentView!.frame.size.height
        let searchBoxHeight = searchField.frame.size.height
        let prevScrollHeight = scrollView.frame.size.height
        let prevScrollY = scrollView.frame.origin.y
        println("beep")
        println("view height \(view.frame.size.height)")
        println("scrollview height \(scrollView.frame.size.height)")
        println("scrollview y \(scrollView.frame.origin.y)")
        println("tableview height \(tableView.frame.size.height)")
        // This isn't working. :(
//        view.frame.size.height = contentHeight + searchBoxHeight
//        scrollView.frame.size.height = contentHeight
//        if (prevScrollHeight > contentHeight) {
//            scrollView.frame.origin.y = prevScrollY - (prevScrollHeight - contentHeight)
//        }
//        else if (prevScrollHeight < contentHeight) {
//            scrollView.frame.origin.y = prevScrollY + (contentHeight - prevScrollHeight)
//        }
        println("view height \(view.frame.size.height)")
        println("scrollview height \(scrollView.frame.size.height)")
        println("scrollview y \(scrollView.frame.origin.y)")
        println("tableview height \(tableView.frame.size.height)")
    }

    func doSearch(text: String) {
        resetWindows()
        let lowerText = text.lowercaseString
        windows = windows.filter { (window) in
            return window.name.lowercaseString.rangeOfString(lowerText) != nil ||
                window.owner.lowercaseString.rangeOfString(lowerText) != nil
        }
        tableView.reloadData()
        resizeToFitContent()
    }
    
    func doOpenItem(index: Int = 0) {
        let count = windows.count
        let indexExists = index <= count - 1
        if count > 0 && indexExists  {
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
            let window = windows[row]
            if let app = NSRunningApplication(processIdentifier: pid_t(window.pid)),
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
    func doCancel(openLastWindow: Bool = false) {
        let app = NSApplication.sharedApplication()
        if let window = app.mainWindow {
            window.orderOut(self)
        }
        if openLastWindow {
            if let lastOpenWindow = incomingWindow {
                AccessibilityWrapper.openWindow(forApplicationWithPid: lastOpenWindow.pid, named: lastOpenWindow.name)
            }
        }
    }
    
    @IBAction func cancel(sender: TextSwitcherView) {
        doCancel(openLastWindow: true)
    }
    
    @IBAction func search(sender: TextSwitcherView) {
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

