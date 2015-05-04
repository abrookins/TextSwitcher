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
        
        // Catch escape key. `cancelOperation` didn't work for me.
        println(theEvent.keyCode)
        if theEvent.keyCode == 53 {
            println("omgwtfff")
        }
        else if hasModifier {
            chosenResult = theEvent.charactersIgnoringModifiers!
            sendAction(Selector(chooseSearchResultAction), to: target)
        }
        
        super.keyUp(theEvent)
    }
    
    override func cancelOperation(sender: AnyObject?) {
        println("WTTTFF")
    }
}