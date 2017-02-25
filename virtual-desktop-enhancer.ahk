#SingleInstance, force
#WinActivateForce
#HotkeyInterval 20
#MaxHotkeysPerInterval 20000
; Credits to Ciantic: https://github.com/Ciantic/VirtualDesktopAccessor

#Include, %A_ScriptDir%\libraries\read-ini.ahk
#Include, %A_ScriptDir%\libraries\tooltip.ahk

; ======================================================================
; Set Up Library Hooks
; ======================================================================

DetectHiddenWindows, On
hwnd := WinExist("ahk_pid " . DllCall("GetCurrentProcessId","Uint"))
hwnd += 0x1000 << 32

hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", A_ScriptDir . "\libraries\virtual-desktop-accessor.dll", "Ptr") 

global GoToDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GoToDesktopNumber", "Ptr")
global RegisterPostMessageHookProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "RegisterPostMessageHook", "Ptr")
global UnregisterPostMessageHookProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnregisterPostMessageHook", "Ptr")
global GetCurrentDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GetCurrentDesktopNumber", "Ptr")
global GetDesktopCountProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GetDesktopCount", "Ptr")
global IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsWindowOnCurrentVirtualDesktop", "Ptr")
global MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "MoveWindowToDesktopNumber", "Ptr")
global IsPinnedWindowProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsPinnedWindow", "Ptr")
global PinWindowProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "PinWindow", "Ptr")
global UnPinWindowProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnPinWindow", "Ptr")
global IsPinnedAppProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsPinnedApp", "Ptr")
global PinAppProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "PinApp", "Ptr")
global UnPinAppProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnPinApp", "Ptr")

DllCall(RegisterPostMessageHookProc, Int, hwnd, Int, 0x1400 + 30)
OnMessage(0x1400 + 30, "VWMess")
VWMess(wParam, lParam, msg, hwnd) {
    OnDesktopSwitch(lParam + 1)
}

; ======================================================================
; Auto Execute
; ======================================================================

Menu, Tray, NoStandard
Menu, Tray, Add, &Manage Desktops, OpenDesktopManager
Menu, Tray, Default, &Manage Desktops
Menu, Tray, Add, Reload Settings, Reload
Menu, Tray, Add, Exit, Exit
Menu, Tray, Click, 1

ReadIni("settings.ini")

global TooltipsEnabled := (TooltipsEnabled != "" and TooltipsEnabled ~= "^[01]$") ? TooltipsEnabled : 1
global TooltipsLifespan := (TooltipsLifespan != "" and TooltipsLifespan ~= "^\d+$") ? TooltipsLifespan : 750
global TooltipsCentered := (TooltipsCentered != "" and TooltipsCentered ~= "^[01]$") ? TooltipsCentered : 1
global TooltipsFontSize := (TooltipsFontSize != "" and TooltipsFontSize ~= "^\d+$") ? TooltipsFontSize : 11
global TooltipsFontInBold := (TooltipsFontInBold != "" and TooltipsFontInBold ~= "^[01]$") ? (TooltipsFontInBold ? 700 : 400) : 700
global TooltipsFontColor := (TooltipsFontColor != "" and TooltipsFontColor ~= "^0x[0-9A-Fa-f]{1,6}$") ? TooltipsFontColor : "0xFFFFFF"
global TooltipsBackgroundColor := (TooltipsBackgroundColor != "" and TooltipsBackgroundColor ~= "^0x[0-9A-Fa-f]{1,6}$") ? TooltipsBackgroundColor : "0x1F1F1F"
global GeneralUseNativePrevNextDesktopSwitchingIfConflicting := (GeneralUseNativePrevNextDesktopSwitchingIfConflicting ~= "^[01]$" && GeneralUseNativePrevNextDesktopSwitchingIfConflicting == "1" ? true : false)

SwitchToDesktop(GeneralDefaultDesktop)
; Update everything again, if the default desktop matches the current one
OnDesktopSwitch(GeneralDefaultDesktop)

; ======================================================================
; Set Up Key Bindings
; ======================================================================

; Translate the modifier keys strings

hkModifiersSwitch          := KeyboardShortcutsModifiersSwitchDesktop
hkModifiersMove            := KeyboardShortcutsModifiersMoveWindowToDesktop
hkModifiersMoveAndSwitch   := KeyboardShortcutsModifiersMoveWindowAndSwitchToDesktop
hkModifiersPlusTen         := KeyboardShortcutsModifiersNextTenDesktops
hkIdentifierPrevious       := KeyboardShortcutsIdentifiersPreviousDesktop
hkIdentifierNext           := KeyboardShortcutsIdentifiersNextDesktop
hkComboPinWin              := KeyboardShortcutsCombinationsPinWindow
hkComboUnpinWin            := KeyboardShortcutsCombinationsUnpinWindow
hkComboTogglePinWin        := KeyboardShortcutsCombinationsTogglePinWindow
hkComboPinApp              := KeyboardShortcutsCombinationsPinApp
hkComboUnpinApp            := KeyboardShortcutsCombinationsUnpinApp
hkComboTogglePinApp        := KeyboardShortcutsCombinationsTogglePinApp
hkComboOpenDesktopManager  := KeyboardShortcutsCombinationsOpenDesktopManager

arrayS := Object(),                     arrayR := Object()
arrayS.Insert("\s*|,"),                 arrayR.Insert("")
arrayS.Insert("L(Ctrl|Shift|Alt|Win)"), arrayR.Insert("<$1")
arrayS.Insert("R(Ctrl|Shift|Alt|Win)"), arrayR.Insert(">$1")
arrayS.Insert("Ctrl"),                  arrayR.Insert("^")
arrayS.Insert("Shift"),                 arrayR.Insert("+")
arrayS.Insert("Alt"),                   arrayR.Insert("!")
arrayS.Insert("Win"),                   arrayR.Insert("#")

for index in arrayS {
    hkModifiersSwitch         := RegExReplace(hkModifiersSwitch, arrayS[index], arrayR[index])
    hkModifiersMove           := RegExReplace(hkModifiersMove, arrayS[index], arrayR[index])
    hkModifiersMoveAndSwitch  := RegExReplace(hkModifiersMoveAndSwitch, arrayS[index], arrayR[index])
    hkModifiersPlusTen        := RegExReplace(hkModifiersPlusTen, arrayS[index], arrayR[index])
    hkComboPinWin             := RegExReplace(hkComboPinWin, arrayS[index], arrayR[index])
    hkComboUnpinWin           := RegExReplace(hkComboUnpinWin, arrayS[index], arrayR[index])
    hkComboTogglePinWin       := RegExReplace(hkComboTogglePinWin, arrayS[index], arrayR[index])
    hkComboPinApp             := RegExReplace(hkComboPinApp, arrayS[index], arrayR[index])
    hkComboUnpinApp           := RegExReplace(hkComboUnpinApp, arrayS[index], arrayR[index])
    hkComboTogglePinApp       := RegExReplace(hkComboTogglePinApp, arrayS[index], arrayR[index])
    hkComboOpenDesktopManager := RegExReplace(hkComboOpenDesktopManager, arrayS[index], arrayR[index])
}

; Setup key bindings dynamically
;  If they are set incorrectly in the settings, an error will be thrown.

setUpHotkey(hk, handler, settingPaths) {
    Hotkey, %hk%, %handler%, UseErrorLevel
    if (ErrorLevel <> 0) {
        MsgBox, 16, Error, One or more keyboard shortcut settings have been defined incorrectly in the settings file: `n%settingPaths%. `n`nPlease read the README and reconfigure them.
        Exit
    }
}

setUpHotkeyWithOneSetOfModifiersAndIdentifier(modifiers, identifier, handler, settingPaths) {
    modifiers <> "" && identifier <> "" ? setUpHotkey(modifiers . identifier, handler, settingPaths) :
}

setUpHotkeyWithTwoSetOfModifiersAndIdentifier(modifiersA, modifiersB, identifier, handler, settingPaths) {
    modifiersA <> "" && modifiersB <> "" && identifier <> "" ? setUpHotkey(modifiersA . modifiersB . identifier, handler, settingPaths) :
}

setUpHotkeyWithCombo(combo, handler, settingPaths) {
    combo <> "" ? setUpHotkey(combo, handler, settingPaths) :
}

i := 0
while (i < 10) {
    setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitch, i, "OnShiftNumberedPress", "[KeyboardShortcutsModifiers] SwitchDesktop")
    setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMove, i, "OnMoveNumberedPress", "[KeyboardShortcutsModifiers] MoveWindowToDesktop")
    setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, i, "OnMoveAndShiftNumberedPress", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop")
    setUpHotkeyWithTwoSetOfModifiersAndIdentifier(hkModifiersSwitch, hkModifiersPlusTen, i, "OnShiftNumberedPressNextTen", "[KeyboardShortcutsModifiers] SwitchDesktop, [KeyboardShortcutsModifiers] NextTenDesktops")
    setUpHotkeyWithTwoSetOfModifiersAndIdentifier(hkModifiersMove, hkModifiersPlusTen, i, "OnMoveNumberedPressNextTen", "[KeyboardShortcutsModifiers] MoveWindowToDesktop, [KeyboardShortcutsModifiers] NextTenDesktops")
    setUpHotkeyWithTwoSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, hkModifiersPlusTen, i, "OnMoveAndShiftNumberedPressNextTen", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop, [KeyboardShortcutsModifiers] NextTenDesktops")
    i := i + 1
}

if (!(GeneralUseNativePrevNextDesktopSwitchingIfConflicting && _IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitch, hkIdentifierPrevious))) {
    setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitch, hkIdentifierPrevious, "OnShiftLeftPress", "[KeyboardShortcutsModifiers] SwitchDesktop, [KeyboardShortcutsIdentifiers] PreviousDesktop")
}
if (!(GeneralUseNativePrevNextDesktopSwitchingIfConflicting && _IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitch, hkIdentifierNext))) {
    setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersSwitch, hkIdentifierNext, "OnShiftRightPress", "[KeyboardShortcutsModifiers] SwitchDesktop, [KeyboardShortcutsIdentifiers] NextDesktop")
}

setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMove, hkIdentifierPrevious, "OnMoveLeftPress", "[KeyboardShortcutsModifiers] MoveWindowToDesktop, [KeyboardShortcutsIdentifiers] PreviousDesktop")
setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMove, hkIdentifierNext, "OnMoveRightPress", "[KeyboardShortcutsModifiers] MoveWindowToDesktop, [KeyboardShortcutsIdentifiers] NextDesktop")

setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, hkIdentifierPrevious, "OnMoveAndShiftLeftPress", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop, [KeyboardShortcutsIdentifiers] PreviousDesktop")
setUpHotkeyWithOneSetOfModifiersAndIdentifier(hkModifiersMoveAndSwitch, hkIdentifierNext, "OnMoveAndShiftRightPress", "[KeyboardShortcutsModifiers] MoveWindowAndSwitchToDesktop, [KeyboardShortcutsIdentifiers] NextDesktop")

setUpHotkeyWithCombo(hkComboPinWin, "OnPinWindowPress", "[KeyboardShortcutsCombinations] PinWindow")
setUpHotkeyWithCombo(hkComboUnpinWin, "OnUnpinWindowPress", "[KeyboardShortcutsCombinations] UnpinWindow")
setUpHotkeyWithCombo(hkComboTogglePinWin, "OnTogglePinWindowPress", "[KeyboardShortcutsCombinations] TogglePinWindow")

setUpHotkeyWithCombo(hkComboPinApp, "OnPinAppPress", "[KeyboardShortcutsCombinations] PinApp")
setUpHotkeyWithCombo(hkComboUnpinApp, "OnUnpinAppPress", "[KeyboardShortcutsCombinations] UnpinApp")
setUpHotkeyWithCombo(hkComboTogglePinApp, "OnTogglePinAppPress", "[KeyboardShortcutsCombinations] TogglePinApp")

setUpHotkeyWithCombo(hkComboOpenDesktopManager, "OpenDesktopManager", "[KeyboardShortcutsCombinations] OpenDesktopManager")

if (GeneralTaskbarScrollSwitching) {
    Hotkey, ~WheelUp, OnTaskbarScrollUp
    Hotkey, ~WheelDown, OnTaskbarScrollDown
}

; ======================================================================
; Event Handlers
; ======================================================================

OnShiftNumberedPress() {
    SwitchToDesktop(substr(A_ThisHotkey, 0, 1))
}

OnShiftNumberedPressNextTen() {
    SwitchToDesktop(1 . substr(A_ThisHotkey, 0, 1))
}

OnMoveNumberedPress() {
    MoveToDesktop(substr(A_ThisHotkey, 0, 1))
}

OnMoveNumberedPressNextTen() {
    MoveToDesktop(1 . substr(A_ThisHotkey, 0, 1))
}

OnMoveAndShiftNumberedPress() {
    MoveAndSwitchToDesktop(substr(A_ThisHotkey, 0, 1))
}

OnMoveAndShiftNumberedPressNextTen() {
    MoveAndSwitchToDesktop(1 . substr(A_ThisHotkey, 0, 1))
}

OnShiftLeftPress() {
    SwitchToDesktop(_GetPreviousDesktopNumber())
}

OnShiftRightPress() {
    SwitchToDesktop(_GetNextDesktopNumber())
}

OnMoveLeftPress() {
    MoveToDesktop(_GetPreviousDesktopNumber())
}

OnMoveRightPress() {
    MoveToDesktop(_GetNextDesktopNumber())
}

OnMoveAndShiftLeftPress() {
    MoveAndSwitchToDesktop(_GetPreviousDesktopNumber())
}

OnMoveAndShiftRightPress() {
    MoveAndSwitchToDesktop(_GetNextDesktopNumber())
}

OnTaskbarScrollUp() {
    if (_IsCursorHoveringTaskbar()) {
        OnShiftLeftPress()
    }
}

OnTaskbarScrollDown() {
    if (_IsCursorHoveringTaskbar()) {
        OnShiftRightPress()
    }
}

OnPinWindowPress() {
    _PinWindow()
}

OnUnpinWindowPress() {
    _UnPinWindow()
}

OnTogglePinWindowPress() {
    window := _GetCurrentWindow()
    if (_GetIsWindowPinned(window)) {
         _UnpinWindow(window)
    } else {
         _PinWindow(window)
    }
}

OnPinAppPress() {
    _PinApp()
}

OnUnpinAppPress() {
    _UnpinApp()
}

OnTogglePinAppPress() {
    window := _GetCurrentWindow()
    if (_GetIsAppPinned(window)) {
        _UnpinApp(window)
    } else {
        _PinApp(window)
    }
}

OnDesktopSwitch(n:=1) {
    if (TooltipsEnabled) {
        _ShowTooltip(n)
    }
    _ChangeAppearance(n)
    _ChangeBackground(n)
    _FocusIfRequested()
}

; ======================================================================
; Functions
; ======================================================================

global doFocusAfterNextSwitch=0

SwitchToDesktop(n:=1) {
    doFocusAfterNextSwitch=1
    _ChangeDesktop(n)
}

MoveToDesktop(n:=1) {
    _MoveCurrentWindowToDesktop(n)
    _Focus()
}

MoveAndSwitchToDesktop(n:=1) {
    doFocusAfterNextSwitch=1
    _MoveCurrentWindowToDesktop(n)
    _ChangeDesktop(n)
}

OpenDesktopManager() {
    Send #{Tab}
}

Reload() {
    Reload
}

Exit() {
    ExitApp
}

_IsPrevNextDesktopSwitchingKeyboardShortcutConflicting(hkModifiersSwitch, hkIdentifierNextOrPrevious) {
    return ((hkModifiersSwitch == "<#<^" || hkModifiersSwitch == ">#<^" || hkModifiersSwitch == "#<^" || hkModifiersSwitch == "<#>^" || hkModifiersSwitch == ">#>^" || hkModifiersSwitch == "#>^" || hkModifiersSwitch == "<#^" || hkModifiersSwitch == ">#^" || hkModifiersSwitch == "#^") && (hkIdentifierNextOrPrevious == "Left" || hkIdentifierNextOrPrevious == "Right"))
}

global taskbarID=0

_IsCursorHoveringTaskbar() {
    MouseGetPos,,, mouseHoveringID
    if (!taskbarID) {
        WinGet, taskbarID, ID, ahk_class Shell_TrayWnd
    }
    return (mouseHoveringID == taskbarID)
}

_GetCurrentWindow() {
    WinGet, activeHwnd, ID, A
    return activeHwnd
}

_GetDesktopName(n:=1) {
    if (n == 0) {
        n := 10
    }
    name := DesktopNames%n%
    if (!name) {
        name := "Desktop " . n
    }
    return name
}

_GetNextDesktopNumber() {
    i := _GetCurrentDesktopNumber()
    i := (i = _GetNumberOfDesktops() ? 1 : i + 1)
    return i
}

_GetPreviousDesktopNumber() {
    i := _GetCurrentDesktopNumber()
    i := (i = 1 ? _GetNumberOfDesktops() : i - 1)
    return i
}

_GetCurrentDesktopNumber() {
    return DllCall(GetCurrentDesktopNumberProc) + 1
}

_GetNumberOfDesktops() {
    return DllCall(GetDesktopCountProc)
}

_MoveCurrentWindowToDesktop(n:=1) {
    activeHwnd := _GetCurrentWindow()
    DllCall(MoveWindowToDesktopNumberProc, UInt, activeHwnd, UInt, n-1)
}

_ChangeDesktop(n:=1) {
    if (n == 0) {
        n := 10
    }
    DllCall(GoToDesktopNumberProc, Int, n-1)
}

_CallWindowProc(proc, window:="") {
    if (window == "") {
        window := _GetCurrentWindow()
    }
    return DllCall(proc, UInt, window)
}

_PinWindow(window:="") {
    _CallWindowProc(PinWindowProc, window)
}

_UnpinWindow(window:="") {
    _CallWindowProc(UnpinWindowProc, window)
}

_GetIsWindowPinned(window:="") {
    return _CallWindowProc(IsPinnedWindowProc, window)
}

_PinApp(window:="") {
    _CallWindowProc(PinAppProc, window)
}

_UnpinApp(window:="") {
    _CallWindowProc(UnpinAppProc, window)
}

_GetIsAppPinned(window:="") {
    return _CallWindowProc(IsPinnedAppProc, window)
}

_ChangeBackground(n:=1) {
    line := Wallpapers%n%

    isHex := RegExMatch(line, "^0x([0-9A-Fa-f]{1,6})", hexMatchTotal)

    if (isHex) {
        hexColorReversed := SubStr("00000" . hexMatchTotal1, -5)

        RegExMatch(hexColorReversed, "^([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})", match)
        hexColor := "0x" . match3 . match2 . match1, hexColor += 0

        DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "", UInt, 1)
        DllCall("SetSysColors", "Int", 1, "Int*", 1, "UInt*", hexColor)
    }
    else {
        filePath := line

        isRelative := (substr(filePath, 1, 1) == ".")
        if (isRelative) {
            filePath := (A_WorkingDir . substr(filePath, 2))
        }
        if (filePath and FileExist(filePath)) {
            DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, filePath, UInt, 1)
        }
    }
}

_ChangeAppearance(n:=1) {
    Menu, Tray, Tip, % _GetDesktopName(n)
    if (FileExist("./icons/" . n ".ico")) {
        Menu, Tray, Icon, icons/%n%.ico
    }
    else {
        Menu, Tray, Icon, icons/+.ico
    }
}

_FocusIfRequested() {
    if (doFocusAfterNextSwitch) {
        _Focus()
        doFocusAfterNextSwitch=0
    }
}

_Focus() {
    WinActivate, ahk_class Shell_TrayWnd
    SendEvent !{Esc}
}

_ShowTooltip(n:=1) {
    if (n == 0) {
        n := 10
    }
    params := {}
    params.message := _GetDesktopName(n)
    params.lifespan := TooltipsLifespan
    params.position := TooltipsCentered
    params.fontSize := TooltipsFontSize
    params.fontWeight := TooltipsFontInBold
    params.fontColor := TooltipsFontColor
    params.backgroundColor := TooltipsBackgroundColor
    Toast(params)
}
