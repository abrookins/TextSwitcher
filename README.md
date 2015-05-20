# TextSwitcher

![Screenshot](https://raw.githubusercontent.com/abrookins/TextSwitcher/master/screenshots/openwindow.png)

This app is essentially a text-based Command+Tab that works how I wish that command worked. Right now the keyboard shortcut is Option+Tab.

## How to use it
* Pressing Option-Tab from any application while TextSwitcher is open displays a window that
allows the user to filter a list of open windows by partial text-matching against the window
title or application name.

* Pressing Command and the number key displayed next to an item in the list brings that window to the foreground.

* Pressing Enter brings the top-most window in the list to the foreground.

* Pressing Escape clears the current search or hides the app if there is no current search.

## Architecture

### AppDelegate
`AppDelegate` sets up the app's global system hotkey using the MASShortcut library.

TODO: A preference pane allows the user to edit the keyboard shortcut.

When the app is on screen, a nameless view containing a search input and a text
box are displayed. These classes are all defined in `Main.storyboard` using
Interface Builder, with the exception of the search control, which is an
instance of `TextSwitcherView`.

### TextSwitcherView
`TextSwitcherView` is a `NSSearchField` subclass that listens for
Command+number key presses when the search field is focused. If it detects
a Command+number key press, it sends the `chooseSearchResult:` message
up the responder chain with the number pressed.

TODO: Should a protocol define this interface? What's the Cocoa pattern?

### ViewController
`ViewController` is responsible for setting up the list of windows that appears
in the nameless text box in the app's main view, changing the list depending on
text that the user provides in the search input, and handling the message
that a user chose a window to open.

#### Getting windows
`ViewController` uses `AccessibilityWrapper` to get a list of windows on screen
using the Cocoa API call `CGWindowListCopyWindowInfo`. It populates a TableView
with this data, including hints for the keyboard shortcuts that the user can
press to activate each window.

#### Handling searches
The controller receives text that the user searches for because it has an
`IBAction` wired up to the `NSSearchFieldCell` in the app's storyboard.

When this happens, the controller filters the list of windows to those
that have the text that the user typed in their name or owner name (like
"Firefox" for the owner or the name of a particular window - usually the
currently-displayed tab).

#### Handling user selection of a window
A one-indexed number like (1) or (2) is displayed next to each window in the
search results box. By pressing Command+number, the user can select a window
from the list to bring it on screen.

The user can press Enter to select the top-most item in the list, or Command+number
to select an item by its index in the list.

`TextSwitcherView` accomplishes listening to these key presses through use of both
`keyUp` and `performKeyEquivalent`. Then it sends a `chooseSearchResult:` message
with the index chosen by the user.

`ViewController` listens for this message and, when it is received, uses
`AccessibilityWrapper` to try to find a window in the filtered list of windows
whose index matches the number chosen by the user (after being converted into
a zero-indexed number, because the array in which the window descriptions are
stored is zero-indexed).

### AccessibilityWrapper
`AccessibilityWrapper` houses a collection of class methods designed to retrieve
and take action on windows currently open on the system in any non-system
and non-menu application on the system. These are all convenience wrappers around
low-level Accessibility API functions.

## Current problems
* No tests
* If instead of choosing a window, you hit Escape to close TextSwitcher, the window you were on before is not refocused
* Should pressing the keyboard shortcut to launch the app while it is already on screen return you to the window you were on when you opened the app?
* Runs as a menu bar app, but you can't quit it or view preferences
* Ideally it would show separate lists of applications, one for each open space, not just the current one
