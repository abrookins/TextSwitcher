//
//  AppView.swift
//
//
//  Created by Andrew Brookins on 4/27/15.
//
//

import AppKit
import Carbon


class TextSwitcherView: NSTextField {

    let chooseSearchResultAction = "chooseSearchResult:"
    let searchAction = "search:"
    let cancelAction = "cancel"
    var chosenResult: String = ""

    override func keyUp(theEvent: NSEvent) {
        let isReturnKey = theEvent.keyCode == UInt16(kVK_Return)
        let isEscapeKey = theEvent.keyCode == UInt16(kVK_Escape)
        let cancel = Selector(cancelAction)
        let chooseResult = Selector(chooseSearchResultAction)
        let search = Selector(searchAction)
        chosenResult = ""
        
        if isEscapeKey {
            // Canceling sometimes crashes the app if I don't check that the target responds
            // to "cancel" first, for some reason.
            if let theTarget: AnyObject = target {
                if theTarget.respondsToSelector(cancel) {
                    sendAction(cancel, to: theTarget)
                }
            }
        }
        else if isReturnKey {
            sendAction(chooseResult, to: target)
        }
        else {
            sendAction(search, to: target)
        }

        super.keyUp(theEvent)
    }
    
    override func performKeyEquivalent(theEvent: NSEvent) -> Bool {
        let chooseResult = Selector(chooseSearchResultAction)
        let usingCommandKey = theEvent.modifierFlags.contains(NSEventModifierFlags.CommandKeyMask)
        
        if usingCommandKey {
            chosenResult = theEvent.charactersIgnoringModifiers!
            sendAction(chooseResult, to: target)
        }
        return super.performKeyEquivalent(theEvent)
    }
}