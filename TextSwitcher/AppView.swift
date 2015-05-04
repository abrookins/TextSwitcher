//
//  AppView.swift
//  
//
//  Created by Andrew Brookins on 4/27/15.
//
//

import AppKit

class TextSwitcherView: NSSearchField {
    
    let chooseSearchResultAction = "chooseSearchResult:"
    var chosenResult: String = ""
    
    override func keyUp(theEvent: NSEvent) {
        let keyMask: NSEventModifierFlags = .ControlKeyMask
        let hasModifier = theEvent.modifierFlags & keyMask != nil
        chosenResult = ""
        
        if hasModifier {
            chosenResult = theEvent.charactersIgnoringModifiers!
            sendAction(Selector(chooseSearchResultAction), to: target)
        }
        
        super.keyUp(theEvent)
    }
}