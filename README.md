# TextSwitcher

This app is essentially a text-based Command+Tab that works how I wish that
command worked. Right now the keyboard shortcut is Command+Control+Tab.
Pressing this from any application while TextSwitcher is open displays a window
that allows the user to filter a list of open windows by partial text-matching
their names. Pressing Control and the number key displayed next to the name of
the window in the list brings that window to the foreground.

## Architecture

### AppDelegate
`AppDelegate` sets up the app's global system hotkey (Command+Control+Tab)
using the MASShortcut library.

When the app is on screen, a nameless view containing a search input and a text
box are displayed. These classes are all defined in `Main.storyboard` using
Interface Builder, with the exception of the search control, which is an
instance of `TextSwitcherView`.

### TextSwitcherView
`TextSwitcherView` is a `NSSearchField` subclass that listens for
Control+number key presses when the search field is focused. If it detects
a Control+number key press, it sends the `chooseSearchResult:` message
up the responder chain with the number pressed.

This is mostly a hack because I could not figure out how to respond to this
keypress somewhere else in the app. Eventually I will figure that out.

### ViewController
`ViewController` is responsible for setting up the list of windows that appears
in the nameless text box in the app's main view, changing the list depending on
text that the user provides in the search input, and handling Control+number
presses which signal that the user chose a window to display.

#### Getting windows
`ViewController` gets a list of windows on screen using the Cocoa API call
`CGWindowListCopyWindowInfo`, then creates a Swift dictionary containing
only the data about the windows that the app cares about (app PID, window
name and owner); also it pairs down the list by removing menu bar items.

#### Handling searches
The controller receives text that the user searches for because it has an
`IBAction` wired up to the `NSSearchFieldCell` in the app's storyboard.

When this happens, the controller filters the list of windows to those
that have the text that the user typed in their name or owner name (like
"Firefox" for the owner or the name of a particular window - usually the
currently-displayed tab).

#### Receiving Control+number presses
A one-indexed number like (1) or (2) is displayed next to each window in the
search results box. By pressing Control+number, the user can select a window
from the list to bring on screen.

For lack of finding the "right" approach to do this, `TextSwitcherView`
receives all `keyUp` calls and checks to see if they included a Control
key press. If they do, it passes the characters up the responder chain
in the `chooseSearchResult:` message.

The controller listens for this message and, when it is received, tries to find
a window in the filtered list of windows whose index matches the number chosen
by the user (after being converted into a zero-indexed number, because the
array in which the window descriptions are stored is zero-indexed).

#### Displaying windows
Once the controller has located window data that matches the user's choice,
it uses the Accessibility API to display the window. This involves a lot of
dark sorcery like `UnsafeMutablePointer<Unmanaged<AnyObject>?>.alloc(1)`
that is really best viewed with a safety visor. However, the Accessibilty
API manages to open the window... usually.

## Current problems
Oh, my! Well, I haven't figured out how to write tests for this Frankenstein
yet. That is problem #1. It will involve some kind of test harness that opens
windows with specific names that I can then verify were brought to the 
foreground. No idea how I'll do that yet.

The app also doesn't actually bring the window the user chose to the foreground!
It won't be hard to do that, but I haven't done it yet; for now it just opens
the first available window for the app.

It should run as a menu bar app, but I haven't built that yet. Perhaps because
of this, you can't simply open it from one Space, move to another Space, and
then open it again with the global hotkey to use it from your new Space --
since the window is open in another Space. The correct behavior is that
if you move to another Space, the TextSwitcher window opens there and 
displays only the windows from that Space.

MEANWHILE, what I actually want, eventually, is for the open window to first
show you all open windows in the current Space, but then break down the
rest of the open Spaces and let you search those too, perhaps by toggling
something with two Shift key depresses, or the like.
