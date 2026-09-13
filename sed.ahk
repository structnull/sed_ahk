#Requires AutoHotkey v2.0

SetWorkingDir A_ScriptDir


; =====================================
; Virtual Desktop Accessor Setup
; =====================================

VDA_PATH := A_ScriptDir "\dll\VirtualDesktopAccessor.dll"

if !FileExist(VDA_PATH) {
    MsgBox "VirtualDesktopAccessor.dll not found:`n" VDA_PATH
    ExitApp
}

hVirtualDesktopAccessor := DllCall(
    "LoadLibrary",
    "Str",
    VDA_PATH,
    "Ptr"
)

if !hVirtualDesktopAccessor {
    MsgBox "Failed to load VirtualDesktopAccessor.dll"
    ExitApp
}


GetProc(name) {
    global hVirtualDesktopAccessor

    proc := DllCall(
        "GetProcAddress",
        "Ptr",
        hVirtualDesktopAccessor,
        "AStr",
        name,
        "Ptr"
    )

    if !proc
        MsgBox "Missing DLL function: " name

    return proc
}


GetDesktopCountProc := GetProc("GetDesktopCount")
GoToDesktopNumberProc := GetProc("GoToDesktopNumber")
GetCurrentDesktopNumberProc := GetProc("GetCurrentDesktopNumber")
MoveWindowToDesktopNumberProc := GetProc("MoveWindowToDesktopNumber")

RegisterPostMessageHookProc := GetProc("RegisterPostMessageHook")
UnregisterPostMessageHookProc := GetProc("UnregisterPostMessageHook")


; =====================================
; Desktop Functions
; =====================================

GetDesktopCount() {
    global GetDesktopCountProc

    return DllCall(
        GetDesktopCountProc,
        "Int"
    )
}


GoToDesktopNumber(num) {
    global GoToDesktopNumberProc

    ; Fix focus issue after switching desktops
    DllCall(
        "User32\AllowSetForegroundWindow",
        "Int",
        -1
    )

    DllCall(
        GoToDesktopNumberProc,
        "Int",
        num
    )
}


MoveCurrentWindowToDesktop(num) {

    global MoveWindowToDesktopNumberProc

    hwnd := WinGetID("A")

    if !hwnd
        return


    DllCall(
        MoveWindowToDesktopNumberProc,
        "Ptr",
        hwnd,
        "Int",
        num
    )

    ; Hyprland style:
    ; move window + follow workspace
    GoToDesktopNumber(num)
}


; =====================================
; Desktop Change Listener
; =====================================

WM_DESKTOP_CHANGED := 0x1400 + 30


DllCall(
    RegisterPostMessageHookProc,
    "Ptr",
    A_ScriptHwnd,
    "Int",
    WM_DESKTOP_CHANGED
)


OnMessage(
    WM_DESKTOP_CHANGED,
    DesktopChanged
)


DesktopChanged(wParam, lParam, msg, hwnd) {

    oldDesktop := wParam + 1
    newDesktop := lParam + 1

    OutputDebug(
        "Desktop changed "
        oldDesktop
        " -> "
        newDesktop
    )
}


; =====================================
; Hyprland Style Workspaces
;
; Alt + number
;      switch workspace
;
; Alt + Shift + number
;      move window to workspace
; =====================================


!1::GoToDesktopNumber(0)
!2::GoToDesktopNumber(1)
!3::GoToDesktopNumber(2)
!4::GoToDesktopNumber(3)
!5::GoToDesktopNumber(4)
!6::GoToDesktopNumber(5)
!7::GoToDesktopNumber(6)
!8::GoToDesktopNumber(7)
!9::GoToDesktopNumber(8)


!+1::MoveCurrentWindowToDesktop(0)
!+2::MoveCurrentWindowToDesktop(1)
!+3::MoveCurrentWindowToDesktop(2)
!+4::MoveCurrentWindowToDesktop(3)
!+5::MoveCurrentWindowToDesktop(4)
!+6::MoveCurrentWindowToDesktop(5)
!+7::MoveCurrentWindowToDesktop(6)
!+8::MoveCurrentWindowToDesktop(7)
!+9::MoveCurrentWindowToDesktop(8)



; =====================================
; Window Controls
; =====================================

; Close window
!q::Send "!{F4}"



; =====================================
; Media Controls
; =====================================

!,::Send "{Media_Prev}"
!.::Send "{Media_Play_Pause}"
!/::Send "{Media_Next}"

!Numpad4::Send "{Media_Prev}"
!Numpad5::Send "{Media_Play_Pause}"
!Numpad6::Send "{Media_Next}"



; =====================================
; Applications
; =====================================


HELIUM := "C:\Users\adharsh\AppData\Local\imput\Helium\Application\chrome.exe"


; Win + F -> Helium Browser
#f::{
    global HELIUM

    if FileExist(HELIUM)
        Run HELIUM
    else
        MsgBox "Helium browser not found:`n" HELIUM
}


; Win + Enter -> Windows Terminal
#Enter::Run "wt.exe"



; =====================================
; Volume
; =====================================

!NumpadAdd::Send "{Volume_Up}"
!NumpadSub::Send "{Volume_Down}"



; =====================================
; Cleanup
; =====================================

OnExit(Cleanup)


Cleanup(*) {

    global UnregisterPostMessageHookProc
    global hVirtualDesktopAccessor


    try {
        DllCall(
            UnregisterPostMessageHookProc,
            "Ptr",
            A_ScriptHwnd
        )
    }


    try {
        DllCall(
            "FreeLibrary",
            "Ptr",
            hVirtualDesktopAccessor
        )
    }
}
