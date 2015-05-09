//
//  AppView.swift
//
//
//  Created by Andrew Brookins on 4/27/15.
//
//

import AppKit
import Carbon


class TextSwitcherView: NSSearchField {

    let chooseSearchResultAction = "chooseSearchResult:"
    var chosenResult: String = ""

    override func keyUp(theEvent: NSEvent) {
        let hasModifier = theEvent.modifierFlags & NSEventModifierFlags.ControlKeyMask != nil
        let isReturnKey = theEvent.keyCode == UInt16(kVK_Return)
        let chooseResult = Selector(chooseSearchResultAction)
        chosenResult = ""
        
        if hasModifier {
            chosenResult = theEvent.charactersIgnoringModifiers!
            sendAction(chooseResult, to: target)
        } else if isReturnKey {
            sendAction(chooseResult, to: target)
        }
        
        super.keyUp(theEvent)
    }
}