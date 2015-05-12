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
    let cancelAction = "cancel"
    var chosenResult: String = ""

    override func keyUp(theEvent: NSEvent) {
        let hasModifier = theEvent.modifierFlags & NSEventModifierFlags.ControlKeyMask != nil
        let isReturnKey = theEvent.keyCode == UInt16(kVK_Return)
        let isEscapeKey = theEvent.keyCode == UInt16(kVK_Escape)
        let chooseResult = Selector(chooseSearchResultAction)
        let cancel = Selector(cancelAction)
        chosenResult = ""
        
        if isEscapeKey {
            // Canceling sometimes crashes the app if I don't check that the target responds
            // to "cancel" first, for some reason.
            // TODO: Cast to ViewController?
            if let theTarget = target {
                if theTarget.respondsToSelector(cancel) {
                    sendAction(cancel, to: theTarget)
                }
            }
        }
        if hasModifier {
            chosenResult = theEvent.charactersIgnoringModifiers!
            sendAction(chooseResult, to: target)
        } else if isReturnKey {
            sendAction(chooseResult, to: target)
        }
        
        super.keyUp(theEvent)
    }
}