#NoEnv
#SingleInstance Off
#Persistent
#MaxThreadsPerHotkey 3
SetWorkingDir %A_ScriptDir%
SendMode, Input
SetMouseDelay, 10
SetBatchLines, -1
CoordMode, Mouse, Screen

DllCall("SetProcessDPIAware")

; ============================================================
;  BA CUSTOM PRODUCTS - CONTROL BOX REMAPPER v4.1
;  bacustomproducts@gmail.com   GitHub: DiyGolfGuy
;
;  CHANGES IN v4.1
;  - Builder window redesigned to mirror the physical control
;    box panel exactly: 4 across the top, CLUB column on the
;    left, AIM cluster on the right, TEE POS pair at the
;    bottom center, RESET AIM / SHOT CAM in the corners.
;  - Reopen detection rewritten around a Windows mutex.  The
;    second instance now knows the first is running no matter
;    what (independent of window titles), signals it, exits.
;  - Stale trigger file is cleared at launch so the window
;    can no longer pop open unexpectedly at boot.
;  - Builder stays in sync when you switch profiles while
;    it is open (labels, FN dropdown, subtitle all refresh).
;  - Help text updated for the Startup-folder auto-start
;    method (shell:startup) introduced late in v4.0.
;
;  STORAGE
;    All data lives in:
;      %UserProfile%\Documents\BA Custom Products\Remapper\
;    settings.ini       app-wide preferences (small)
;    profiles\<name>.ini  one file per profile (like JoyToKey)
;
;  REAL-APP BEHAVIOR
;    Double-click .exe        -> shows GUI (running or not)
;    Tray icon click          -> shows GUI
;    Minimize to Tray         -> hides window, mapping continues
;    Exit                     -> full quit, mapping stops
;    Windows boot (auto)      -> loads Boot Profile, mapping ON,
;                                window hidden to tray
;
;  TWO KINDS OF "CURRENT PROFILE"
;    Active Profile           the one you're using right now
;    Boot Profile             the one auto-loaded at Windows boot
;    [BOOT] in the dropdown marks the Boot Profile.
;
;  EVERYTHING AUTO-SAVES
;    Configure a button       -> profile saved instantly
;    Toggle a checkbox        -> settings saved instantly
;    Switch profile           -> old saved before new loaded
;
;  AUTO-START
;    Uses a shortcut in the Windows Startup folder
;    (shell:startup) - visible, reliable, easy to remove.
;    Cleanup button removes it plus all data files.
; ============================================================

; ============================================================
;  CONSTANTS / PATHS
; ============================================================
AppVersion := "4.1"
MainWinTitle    := "BA Custom Control Box Remapper"
BuilderWinTitle := "BA Custom Control Box - Button Builder"
HelpWinTitle    := "BA Custom Control Box - Help"
WM_SHOWAPP      := 0x8001
RegistryRunKey  := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
RegistryRunName := "BARemapper"

; Storage location - visible Documents folder, easy to find
DocsRoot     := A_MyDocuments
ConfigDir    := DocsRoot . "\BA Custom Products\Remapper"
ProfilesDir  := ConfigDir . "\profiles"
ConfigFile   := ConfigDir . "\settings.ini"
TriggerFile  := A_Temp . "\baremapper_show.tmp"

; Legacy locations (for one-time migration on first v4.0 launch)
LegacyScriptIni  := A_ScriptDir . "\ba_remapper.ini"
LegacyAppDataIni := A_AppData . "\BA Custom Products\Remapper\settings.ini"

; ============================================================
;  BUTTON CONSTANTS (fixed for the 12-button BA control box)
;  These never change - they describe the physical hardware.
; ============================================================
AllBtnIds := ["heatmap","putt","flyover","clubup","clubdown","resetaim"
            ,"teeleft","teeright","shotcam","left","right","up","down"]

BtnPrimary := {}
BtnPrimary["heatmap"]   := "y"
BtnPrimary["putt"]      := "u"
BtnPrimary["flyover"]   := "o"
BtnPrimary["clubup"]    := "i"
BtnPrimary["clubdown"]  := "k"
BtnPrimary["resetaim"]  := "a"
BtnPrimary["teeleft"]   := "c"
BtnPrimary["teeright"]  := "v"
BtnPrimary["shotcam"]   := "j"
BtnPrimary["left"]      := "{Left}"
BtnPrimary["right"]     := "{Right}"
BtnPrimary["up"]        := "{Up}"
BtnPrimary["down"]      := "{Down}"
BtnPrimary["mulligan"]  := "^m"

KeyToBtnId := {}
KeyToBtnId["y"]     := "heatmap"
KeyToBtnId["u"]     := "putt"
KeyToBtnId["o"]     := "flyover"
KeyToBtnId["i"]     := "clubup"
KeyToBtnId["k"]     := "clubdown"
KeyToBtnId["a"]     := "resetaim"
KeyToBtnId["c"]     := "teeleft"
KeyToBtnId["v"]     := "teeright"
KeyToBtnId["j"]     := "shotcam"
KeyToBtnId["Left"]  := "left"
KeyToBtnId["Right"] := "right"
KeyToBtnId["Up"]    := "up"
KeyToBtnId["Down"]  := "down"

; ============================================================
;  GSPRO ACTIONS LIST  (for the Builder dropdown)
; ============================================================
GSProActions := "None|"
    . "A - Aim Reset|B - Hide Objects|C - Tee Left|D - Vertical Dots|"
    . "F - FPS Toggle|G - Green Grid|H - Hide UI|I - Club Up|"
    . "J - Shot Cam|K - Club Down|L - Lighting|N - Switch Hand|"
    . "O - Flyover|P - Pin Indicator|Q - Minimap Zoom Out|"
    . "R - Rangefinder|S - Map Expand|T - Scorecard|"
    . "U - Putt Toggle|V - Tee Right|W - Minimap Zoom In|"
    . "Y - Heat Map|Z - 3D Grass Toggle|"
    . "F1 - Clear Tracer|F3 - Aimpoint|F5 - Free Look|"
    . "Tab - Shortcuts|Ctrl+M - Mulligan|Space - Fast Forward|"
    . "Up Arrow|Down Arrow|Left Arrow|Right Arrow|"
    . "Enter|Escape|Backspace"

GSProKeyMap := {}
GSProKeyMap["None"] := ""
GSProKeyMap["A - Aim Reset"]         := "a"
GSProKeyMap["B - Hide Objects"]      := "b"
GSProKeyMap["C - Tee Left"]          := "c"
GSProKeyMap["D - Vertical Dots"]     := "d"
GSProKeyMap["F - FPS Toggle"]        := "f"
GSProKeyMap["G - Green Grid"]        := "g"
GSProKeyMap["H - Hide UI"]           := "h"
GSProKeyMap["I - Club Up"]           := "i"
GSProKeyMap["J - Shot Cam"]          := "j"
GSProKeyMap["K - Club Down"]         := "k"
GSProKeyMap["L - Lighting"]          := "l"
GSProKeyMap["N - Switch Hand"]       := "n"
GSProKeyMap["O - Flyover"]           := "o"
GSProKeyMap["P - Pin Indicator"]     := "p"
GSProKeyMap["Q - Minimap Zoom Out"]  := "q"
GSProKeyMap["R - Rangefinder"]       := "r"
GSProKeyMap["S - Map Expand"]        := "s"
GSProKeyMap["T - Scorecard"]         := "t"
GSProKeyMap["U - Putt Toggle"]       := "u"
GSProKeyMap["V - Tee Right"]         := "v"
GSProKeyMap["W - Minimap Zoom In"]   := "w"
GSProKeyMap["Y - Heat Map"]          := "y"
GSProKeyMap["Z - 3D Grass Toggle"]   := "z"
GSProKeyMap["F1 - Clear Tracer"]     := "{F1}"
GSProKeyMap["F3 - Aimpoint"]         := "{F3}"
GSProKeyMap["F5 - Free Look"]        := "{F5}"
GSProKeyMap["Tab - Shortcuts"]       := "{Tab}"
GSProKeyMap["Ctrl+M - Mulligan"]     := "^m"
GSProKeyMap["Space - Fast Forward"]  := "{Space}"
GSProKeyMap["Up Arrow"]              := "{Up}"
GSProKeyMap["Down Arrow"]            := "{Down}"
GSProKeyMap["Left Arrow"]            := "{Left}"
GSProKeyMap["Right Arrow"]           := "{Right}"
GSProKeyMap["Enter"]                 := "{Enter}"
GSProKeyMap["Escape"]                := "{Escape}"
GSProKeyMap["Backspace"]             := "{Backspace}"

GSProNameMap := {}
for name, key in GSProKeyMap {
    if (key != "")
        GSProNameMap[key] := name
}

FnChoiceMap := {}
FnChoiceMap["Reset Aim (A)"]   := "resetaim"
FnChoiceMap["Heat Map (Y)"]    := "heatmap"
FnChoiceMap["Putt (U)"]        := "putt"
FnChoiceMap["Flyover (O)"]     := "flyover"
FnChoiceMap["Club Up (I)"]     := "clubup"
FnChoiceMap["Club Down (K)"]   := "clubdown"
FnChoiceMap["Tee Left (C)"]    := "teeleft"
FnChoiceMap["Tee Right (V)"]   := "teeright"
FnChoiceMap["Shot Cam (J)"]    := "shotcam"

; ============================================================
;  GLOBAL STATE
; ============================================================
RemapActive := false
SwapIK      := false

ActiveProfile  := "Default"
StartupProfile := "Default"
ProfileList    := []

; Per-profile data loaded into these
FnButtonId  := "resetaim"
FnSendKey   := "a"
SecType     := {}
SecValue    := {}
SecX        := {}
SecY        := {}

; FN-detection state
FnIsDown        := false
FnUsedAsModifier := false
FnLastDownTime  := 0
SETTLE_MS       := 150

; Dialog/config dialog temp state
ConfiguringBtnId         := ""
ConfiguringDisplayName   := ""

; ============================================================
;  STARTUP-LAUNCH DETECTION
;  /startup arg means Windows booted us via the registry Run
;  entry. Manual launch = no arg = treat as user open.
; ============================================================
isStartupLaunch := false
for n, arg in A_Args {
    if (arg = "/startup") {
        isStartupLaunch := true
        break
    }
}

; ============================================================
;  FILESYSTEM SETUP - happens before anything else reads/writes
; ============================================================
InitConfigPaths()
MigrateLegacyFiles()

InitConfigPaths() {
    global ConfigDir, ProfilesDir
    IfNotExist, %ConfigDir%
        FileCreateDir, %ConfigDir%
    IfNotExist, %ProfilesDir%
        FileCreateDir, %ProfilesDir%
}

; If the user is upgrading from v3.1.x, parse the old one-big-INI
; format and split into the new per-profile files.  Touches only
; the new Documents location - leaves old files alone (user can
; delete them via Cleanup later).
MigrateLegacyFiles() {
    global ConfigFile, ProfilesDir, LegacyScriptIni, LegacyAppDataIni, AllBtnIds
    ; If new settings already exist, nothing to do
    if (FileExist(ConfigFile))
        return

    ; Find a legacy source file
    sourceFile := ""
    if (FileExist(LegacyScriptIni))
        sourceFile := LegacyScriptIni
    else if (FileExist(LegacyAppDataIni))
        sourceFile := LegacyAppDataIni
    if (sourceFile = "")
        return  ; first-time user, nothing to migrate

    ; Read app-level keys
    IniRead, profList,   %sourceFile%, App, Profiles,      Default
    IniRead, activeProf, %sourceFile%, App, ActiveProfile, Default
    IniRead, swapVal,    %sourceFile%, App, SwapIK,        0
    IniRead, wx,         %sourceFile%, App, WinX,          CENTER
    IniRead, wy,         %sourceFile%, App, WinY,          CENTER

    ; Write new settings.ini
    IniWrite, %activeProf%, %ConfigFile%, App, ActiveProfile
    IniWrite, %activeProf%, %ConfigFile%, App, StartupProfile
    IniWrite, %swapVal%,    %ConfigFile%, App, SwapIK
    IniWrite, %wx%,         %ConfigFile%, App, WinX
    IniWrite, %wy%,         %ConfigFile%, App, WinY

    ; Parse profile names then migrate each profile section
    legacyProfiles := []
    Loop, Parse, profList, |
    {
        if (A_LoopField != "")
            legacyProfiles.Push(A_LoopField)
    }
    for i, pname in legacyProfiles
    {
        oldSection := "Profile_" . pname
        newProfFile := ProfilesDir . "\" . pname . ".ini"
        IniRead, fnBtn, %sourceFile%, %oldSection%, FnButtonId, resetaim
        IniWrite, %fnBtn%, %newProfFile%, Profile, FnButtonId
        for j, bid in AllBtnIds
        {
            IniRead, st, %sourceFile%, %oldSection%, %bid%_Type,  none
            IniRead, sv, %sourceFile%, %oldSection%, %bid%_Value,
            IniRead, sx, %sourceFile%, %oldSection%, %bid%_X,     0
            IniRead, sy, %sourceFile%, %oldSection%, %bid%_Y,     0
            IniWrite, %st%, %newProfFile%, Profile, %bid%_Type
            IniWrite, %sv%, %newProfFile%, Profile, %bid%_Value
            IniWrite, %sx%, %newProfFile%, Profile, %bid%_X
            IniWrite, %sy%, %newProfFile%, Profile, %bid%_Y
        }
    }
    TrayTip, BA Remapper, Profiles migrated to Documents folder, 4, 1
}

; ============================================================
;  SECOND-INSTANCE HANDLER  (mutex-based, v4.1)
;
;  A named Windows mutex tells us with 100% certainty whether
;  another BARemapper instance is already running - no window
;  title matching involved, works compiled or uncompiled.
;
;  When user double-clicks the .exe while already running:
;    1. CreateMutex reports ERROR_ALREADY_EXISTS (183)
;    2. This (second) instance drops a trigger file AND tries
;       PostMessage for an instant response
;    3. Second instance exits
;    4. Running instance picks up either signal -> shows GUI
;       (trigger file is polled every 500ms as the fallback)
; ============================================================
MutexHandle := DllCall("CreateMutex", "Ptr", 0, "Int", 0, "Str", "BARemapper_BACustomProducts_SingleInstance", "Ptr")
if (DllCall("GetLastError") = 183) {   ; ERROR_ALREADY_EXISTS
    FileAppend, show, %TriggerFile%
    DetectHiddenWindows, On
    SetTitleMatchMode, 2
    existingHwnd := WinExist(MainWinTitle)
    if (existingHwnd)
        PostMessage, %WM_SHOWAPP%, 0, 0, , ahk_id %existingHwnd%
    DetectHiddenWindows, Off
    Sleep, 100
    ExitApp
}
; We are the first (only) instance.  Clear any stale trigger
; file left over from a crash so the window doesn't pop open
; unexpectedly (especially during a hidden boot launch).
FileDelete, %TriggerFile%

; Register message handler for future second-instance signals
OnMessage(WM_SHOWAPP, "ShowMainFromMessage")

ShowMainFromMessage(wParam, lParam, msg, hwnd) {
    Gui, Main:Show
    WinActivate, BA Custom Control Box Remapper
}

; ============================================================
;  EXIT  (no OnExit handler - auto-save during operation
;  means we don't need to save on exit, which keeps the exit
;  path completely uninterruptible)
; ============================================================

; ============================================================
;  HELPER FUNCTIONS
; ============================================================
StripBraces(s) {
    s := Trim(s)
    if (SubStr(s, 1, 1) = "{" && SubStr(s, 0) = "}")
        return SubStr(s, 2, StrLen(s) - 2)
    return s
}

ApplyIKSwap(pk) {
    global SwapIK
    if (!SwapIK)
        return pk
    if (pk = "i")
        return "k"
    if (pk = "k")
        return "i"
    return pk
}

FnPhysicallyHeld() {
    global FnButtonId, BtnPrimary
    if (!BtnPrimary.HasKey(FnButtonId))
        return false
    physKey := StripBraces(BtnPrimary[FnButtonId])
    if (physKey = "")
        return false
    return GetKeyState(physKey, "P")
}

FriendlyAction(k) {
    if (k = "{Click Left}")   return "Left Click"
    if (k = "{Click Right}")  return "Right Click"
    if (k = "{Click Middle}") return "Middle Click"
    return k
}

; ============================================================
;  SETTINGS I/O
; ============================================================
LoadSettings() {
    global ConfigFile, ActiveProfile, StartupProfile, SwapIK
    IniRead, ActiveProfile,  %ConfigFile%, App, ActiveProfile,  Default
    IniRead, StartupProfile, %ConfigFile%, App, StartupProfile, %ActiveProfile%
    IniRead, swapVal,        %ConfigFile%, App, SwapIK,         0
    SwapIK := (swapVal + 0) ? true : false
}

SaveSettings() {
    global ConfigFile, ActiveProfile, StartupProfile, SwapIK
    IniWrite, %ActiveProfile%,  %ConfigFile%, App, ActiveProfile
    IniWrite, %StartupProfile%, %ConfigFile%, App, StartupProfile
    swapWrite := SwapIK ? 1 : 0
    IniWrite, %swapWrite%, %ConfigFile%, App, SwapIK
}

LoadWindowPos(ByRef wx, ByRef wy) {
    global ConfigFile
    IniRead, wx, %ConfigFile%, App, WinX, CENTER
    IniRead, wy, %ConfigFile%, App, WinY, CENTER
}

SaveWindowPos() {
    global ConfigFile, MainWinTitle
    WinGetPos, wx, wy, , , %MainWinTitle%
    if (wx != "")
        IniWrite, %wx%, %ConfigFile%, App, WinX
    if (wy != "")
        IniWrite, %wy%, %ConfigFile%, App, WinY
}

; ============================================================
;  PROFILE I/O  (one file per profile)
; ============================================================
ScanProfileList() {
    global ProfilesDir, ProfileList
    ProfileList := []
    Loop, %ProfilesDir%\*.ini
    {
        SplitPath, A_LoopFileName, , , , baseName
        ProfileList.Push(baseName)
    }
    if (ProfileList.MaxIndex() = "") {
        ; First run with no profiles - create Default
        ProfileList.Push("Default")
        SaveProfile("Default")
    }
}

LoadProfile(profileName) {
    global ProfilesDir, BtnPrimary, AllBtnIds
    global FnButtonId, FnSendKey, SecType, SecValue, SecX, SecY
    pf := ProfilesDir . "\" . profileName . ".ini"
    IniRead, FnButtonId, %pf%, Profile, FnButtonId, resetaim
    if (BtnPrimary.HasKey(FnButtonId))
        FnSendKey := BtnPrimary[FnButtonId]
    SecType  := {}
    SecValue := {}
    SecX     := {}
    SecY     := {}
    for i, id in AllBtnIds
    {
        IniRead, st, %pf%, Profile, %id%_Type,  none
        IniRead, sv, %pf%, Profile, %id%_Value,
        IniRead, sx, %pf%, Profile, %id%_X,     0
        IniRead, sy, %pf%, Profile, %id%_Y,     0
        if (st != "none" && st != "ERROR" && st != "") {
            SecType[id]  := st
            SecValue[id] := sv
            SecX[id]     := sx + 0
            SecY[id]     := sy + 0
        }
    }
}

SaveProfile(profileName) {
    global ProfilesDir, AllBtnIds, FnButtonId, SecType, SecValue, SecX, SecY
    pf := ProfilesDir . "\" . profileName . ".ini"
    IniWrite, %FnButtonId%, %pf%, Profile, FnButtonId
    for i, id in AllBtnIds
    {
        st := SecType.HasKey(id)  ? SecType[id]  : "none"
        sv := SecValue.HasKey(id) ? SecValue[id] : ""
        sx := SecX.HasKey(id)     ? SecX[id]     : 0
        sy := SecY.HasKey(id)     ? SecY[id]     : 0
        IniWrite, %st%, %pf%, Profile, %id%_Type
        IniWrite, %sv%, %pf%, Profile, %id%_Value
        IniWrite, %sx%, %pf%, Profile, %id%_X
        IniWrite, %sy%, %pf%, Profile, %id%_Y
    }
}

ResetProfile() {
    global FnButtonId, FnSendKey, SecType, SecValue, SecX, SecY, BtnPrimary
    FnButtonId := "resetaim"
    FnSendKey  := BtnPrimary["resetaim"]
    SecType  := {}
    SecValue := {}
    SecX     := {}
    SecY     := {}
}

; ============================================================
;  AUTO-START via Windows Startup folder shortcut
;
;  Puts a "BARemapper.lnk" shortcut into:
;    %AppData%\Microsoft\Windows\Start Menu\Programs\Startup
;
;  Windows always runs everything in that folder at login.
;  This is more reliable and more user-visible than the
;  registry Run key (which can be silently blocked by AV,
;  Windows startup-app filtering, or other gatekeeping).
;  The user can navigate to the Startup folder in Explorer
;  and see the shortcut directly.
; ============================================================
StartupLink() {
    return A_Startup . "\BARemapper.lnk"
}

IsAutoStart() {
    return FileExist(StartupLink()) ? true : false
}

SetAutoStart(enable) {
    global RegistryRunKey, RegistryRunName
    link := StartupLink()

    ; Always remove any legacy Run-key entry from earlier versions
    ; so the two methods don't fight each other.
    RegDelete, %RegistryRunKey%, %RegistryRunName%

    if (enable) {
        if (A_IsCompiled) {
            ; Compiled .exe - direct shortcut to the exe with /startup arg
            FileCreateShortcut, %A_ScriptFullPath%, %link%, %A_ScriptDir%, /startup, BA Custom Control Box Remapper
        } else {
            ; Uncompiled .ahk - shortcut to AutoHotkey.exe with script as arg
            args := """" . A_ScriptFullPath . """ /startup"
            FileCreateShortcut, %A_AhkPath%, %link%, %A_ScriptDir%, %args%, BA Custom Control Box Remapper
        }
    } else {
        if FileExist(link)
            FileDelete, %link%
    }
}

; Refresh the shortcut on every launch so its target stays
; current if the user moved the .exe to a new folder.
RefreshAutoStartPath() {
    if (IsAutoStart())
        SetAutoStart(true)
}

; ============================================================
;  KEY HANDLERS
;
;  Triple-layer FN detection:
;    1. Software flag (FnIsDown) - fast normal case
;    2. Physical state check - catches dropped wireless events
;    3. 80ms grace window - catches very brief flicker
;  Any one true -> secondary fires.
; ============================================================
HandleBoxKeyDown(keyName) {
    global KeyToBtnId, FnButtonId, FnIsDown, FnUsedAsModifier
    global FnLastDownTime, BtnPrimary
    btnId := KeyToBtnId[keyName]
    if (btnId = "")
        return

    if (btnId = FnButtonId) {
        FnIsDown := true
        FnUsedAsModifier := false
        FnLastDownTime := A_TickCount
        return
    }

    fnHeld := FnIsDown
    if (!fnHeld)
        fnHeld := FnPhysicallyHeld()
    if (!fnHeld && FnLastDownTime > 0 && (A_TickCount - FnLastDownTime < 80))
        fnHeld := true

    if (fnHeld) {
        FnUsedAsModifier := true
        FireSecondary(btnId)
        return
    }

    pk := BtnPrimary[btnId]
    pk := ApplyIKSwap(pk)
    if (pk != "")
        Send, %pk%
}

HandleBoxKeyUp(keyName) {
    global KeyToBtnId, FnButtonId, FnIsDown, FnUsedAsModifier
    global FnLastDownTime, BtnPrimary
    btnId := KeyToBtnId[keyName]
    if (btnId = "")
        return
    if (btnId = FnButtonId) {
        if (!FnUsedAsModifier) {
            pk := BtnPrimary[btnId]
            pk := ApplyIKSwap(pk)
            if (pk != "")
                Send, %pk%
        }
        FnIsDown := false
        FnUsedAsModifier := false
        FnLastDownTime := 0
    }
}

FireSecondary(btnId) {
    global SecType, SecValue, SecX, SecY, SETTLE_MS
    if (!SecType.HasKey(btnId) || SecType[btnId] = "" || SecType[btnId] = "none")
        return
    stype := SecType[btnId]
    if (stype = "key") {
        sval := SecValue[btnId]
        if (sval != "")
            Send, %sval%
    }
    else if (stype = "click") {
        tx := SecX[btnId]
        ty := SecY[btnId]
        CoordMode, Mouse, Screen
        MouseMove, %tx%, %ty%, 0
        Sleep, %SETTLE_MS%
        Click, %tx%, %ty%
        Sleep, 80
        MouseMove, 0, 0, 0
    }
}

; ============================================================
;  TOGGLE
; ============================================================
ToggleRemap() {
    global RemapActive, FnIsDown, FnUsedAsModifier, FnLastDownTime, ActiveProfile, AppVersion
    RemapActive := !RemapActive
    if (!RemapActive) {
        FnIsDown := false
        FnUsedAsModifier := false
        FnLastDownTime := 0
        Menu, Tray, Tip, BA Remapper v%AppVersion% - Mapping OFF
    } else {
        Menu, Tray, Tip, BA Remapper - Mapping ON (%ActiveProfile%)
    }
    UpdateMainStatus()
}

UpdateMainStatus() {
    global RemapActive
    Gui, Main:Default
    if (RemapActive) {
        GuiControl,, StatusText, STATUS: ON
        Gui, Main:Font, s22 c00FF00 Bold
        GuiControl, Font, StatusText
        GuiControl,, ToggleBtn, Turn OFF
    } else {
        GuiControl,, StatusText, STATUS: OFF
        Gui, Main:Font, s22 cFF4444 Bold
        GuiControl, Font, StatusText
        GuiControl,, ToggleBtn, Turn ON
    }
}

; ============================================================
;  INIT  -  call order matters
; ============================================================
LoadSettings()
RefreshAutoStartPath()
ScanProfileList()
LoadProfile(ActiveProfile)

; ============================================================
;  TRAY MENU
; ============================================================
Menu, Tray, NoStandard
Menu, Tray, Add, Show Window,      ShowMainFromTray
Menu, Tray, Add, Open Builder,     ShowBuilder
Menu, Tray, Add, Toggle Mapping,   ToggleFromTray
Menu, Tray, Add,
Menu, Tray, Add, Open Settings Folder, OpenSettingsFolder
Menu, Tray, Add,
Menu, Tray, Add, Exit,             ExitLabel
Menu, Tray, Tip, BA Custom Control Box Remapper v%AppVersion%
Menu, Tray, Default, Show Window

; ============================================================
;  MAIN WINDOW
;
;  Layout (480 x 504):
;
;   Title / subtitle / divider
;   STATUS (big colored)
;   [Turn ON]
;   --- divider ---
;   Profile dropdown row  [New][Rename][Delete]
;   Boot Profile: Default     [Set as Boot Profile]
;   --- divider ---
;   [Open Button Builder]    (wide)
;   --- divider ---
;   [x] Start with Windows   [x] Swap I/K
;   --- divider ---
;   Files saved at: <path>
;   [Open Folder] [Cleanup] [Help]
;   --- divider ---
;   [Minimize to Tray] [Exit]
; ============================================================
Gui, Main:New, , %MainWinTitle%
Gui, Main:Color, 1a1a2e

Gui, Main:Font, s18 cWhite Bold, Segoe UI
Gui, Main:Add, Text, x20 y12 w440 Center, BA Custom Products
Gui, Main:Font, s10 cSilver Normal, Segoe UI
Gui, Main:Add, Text, x20 y42 w440 Center, Golf Simulator Control Box Remapper v%AppVersion%
Gui, Main:Add, Text, x30 y65 w420 0x10

; STATUS
Gui, Main:Font, s22 cFF4444 Bold, Segoe UI
Gui, Main:Add, Text, x20 y75 w440 Center vStatusText, STATUS: OFF

Gui, Main:Font, s13 c000000 Bold, Segoe UI
Gui, Main:Add, Button, x95 y115 w290 h45 gToggleFromMain vToggleBtn, Turn ON

Gui, Main:Add, Text, x30 y170 w420 0x10

; PROFILES
Gui, Main:Font, s10 cFFFF00 Bold, Segoe UI
Gui, Main:Add, Text, x30 y180 w70, Profile:
Gui, Main:Font, s10 c000000 Normal, Segoe UI

profDDL := BuildProfileDropdownString()
Gui, Main:Add, DropDownList, x100 y178 w195 vProfileChoice gOnProfileChange, %profDDL%
SelectProfileInDropdown()

Gui, Main:Font, s9 c000000 Normal, Segoe UI
Gui, Main:Add, Button, x305 y178 w50 h25 gOnNewProfile,    + New
Gui, Main:Add, Button, x360 y178 w55 h25 gOnRenameProfile, Rename
Gui, Main:Add, Button, x420 y178 w40 h25 gOnDeleteProfile, Del

; BOOT PROFILE
Gui, Main:Font, s9 cCCCCCC Normal, Segoe UI
Gui, Main:Add, Text, x30 y210 w130, Boot Profile:
Gui, Main:Font, s9 cFFFF00 Bold, Segoe UI
Gui, Main:Add, Text, x115 y210 w180 vBootProfileLabel, %StartupProfile%
Gui, Main:Font, s9 c000000 Normal, Segoe UI
Gui, Main:Add, Button, x305 y207 w155 h22 gOnSetBootProfile, Set Current as Boot Profile

Gui, Main:Add, Text, x30 y238 w420 0x10

; BUILDER LAUNCHER
Gui, Main:Font, s13 c000000 Bold, Segoe UI
Gui, Main:Add, Button, x95 y248 w290 h40 gShowBuilder, Open Button Builder

Gui, Main:Add, Text, x30 y298 w420 0x10

; OPTIONS
Gui, Main:Font, s10 cCCCCCC Normal, Segoe UI
autoStartChecked := IsAutoStart()
swapChecked := SwapIK ? 1 : 0
Gui, Main:Add, Checkbox, x30 y308 w200 vAutoStartCheck gOnAutoStartToggle Checked%autoStartChecked%, Start with Windows
Gui, Main:Add, Checkbox, x250 y308 w220 vSwapIKCheck gOnSwapIKToggle Checked%swapChecked%, Swap Club Up/Down (I/K)

Gui, Main:Add, Text, x30 y338 w420 0x10

; FILE LOCATION + ACCESS
Gui, Main:Font, s9 c999999 Normal, Segoe UI
Gui, Main:Add, Text, x30 y348 w430, Files are saved at:
Gui, Main:Font, s9 cWhite Normal, Consolas
Gui, Main:Add, Text, x30 y364 w430, %ConfigDir%

Gui, Main:Font, s9 c000000 Normal, Segoe UI
Gui, Main:Add, Button, x30  y388 w125 h28 gOnOpenFolder, Open Folder
Gui, Main:Add, Button, x162 y388 w125 h28 gOnCleanup,    Cleanup / Reset
Gui, Main:Add, Button, x294 y388 w166 h28 gShowHelp,     Help / Guide

Gui, Main:Add, Text, x30 y424 w420 0x10

; FOOTER
Gui, Main:Font, s9 cAAAAAA Normal, Segoe UI
Gui, Main:Add, Text, x20 y432 w440 Center, Ctrl+F12 toggles ON/OFF    |    Turn OFF to type normally

Gui, Main:Font, s10 c000000 Normal, Segoe UI
Gui, Main:Add, Button, x95  y454 w140 h35 gMinimizeMain, Minimize to Tray
Gui, Main:Add, Button, x245 y454 w140 h35 gDoFullExit,   Exit

LoadWindowPos(wx, wy)
if (isStartupLaunch) {
    ; Boot launch - create window hidden so user sees no flash
    Gui, Main:Show, Hide w480 h504
} else if (wx = "CENTER" || wy = "CENTER") {
    Gui, Main:Show, w480 h504
} else {
    Gui, Main:Show, w480 h504 x%wx% y%wy%
}

; ============================================================
;  STARTUP-LAUNCH FLOW
;  Boot launch: switch to Boot Profile if different, turn on
;  mapping, stay hidden in tray.
;  Manual launch: window already visible above, mapping stays OFF.
; ============================================================
if (isStartupLaunch) {
    Sleep, 1500   ; USB enumeration delay
    if (StartupProfile != "" && StartupProfile != ActiveProfile) {
        ActiveProfile := StartupProfile
        LoadProfile(ActiveProfile)
        SaveSettings()
        RefreshMainGuiFromState()
    }
    ToggleRemap()
    Menu, Tray, Tip, BA Remapper - Mapping ON (%ActiveProfile%)
    TrayTip, BA Remapper, Mapping is ACTIVE  (profile: %ActiveProfile%), 5, 1
}

; Trigger-file polling for reopen
SetTimer, CheckTriggerFile, 500
Return

; ============================================================
;  MAIN GUI HELPERS  (called from build + event handlers)
; ============================================================

; Build pipe-separated string of profile names, with [BOOT] prefix
; on the boot profile so it's visually distinguished.
BuildProfileDropdownString() {
    global ProfileList, StartupProfile
    out := ""
    for i, p in ProfileList
    {
        if (i > 1)
            out .= "|"
        if (p = StartupProfile)
            out .= "[BOOT] " . p
        else
            out .= p
    }
    return out
}

; Profile dropdown items prefix the boot profile with "[BOOT] "
; so when we select the active profile we need to look for either
; "Active" or "[BOOT] Active" depending on which one is boot.
SelectProfileInDropdown() {
    global ActiveProfile, StartupProfile
    if (ActiveProfile = StartupProfile)
        target := "[BOOT] " . ActiveProfile
    else
        target := ActiveProfile
    GuiControl, Main:ChooseString, ProfileChoice, %target%
}

; Strip a leading "[BOOT] " from a dropdown selection to get the
; underlying profile name.
StripBootMarker(s) {
    marker := "[BOOT] "
    if (SubStr(s, 1, StrLen(marker)) = marker)
        return SubStr(s, StrLen(marker) + 1)
    return s
}

RefreshProfileDropdown() {
    out := BuildProfileDropdownString()
    GuiControl, Main:, ProfileChoice, |%out%
    SelectProfileInDropdown()
}

RefreshBootProfileLabel() {
    global StartupProfile
    GuiControl, Main:, BootProfileLabel, %StartupProfile%
    RefreshProfileDropdown()  ; [BOOT] marker needs to move
}

; Pull values from state vars back into main GUI controls
RefreshMainGuiFromState() {
    global SwapIK
    GuiControl, Main:, SwapIKCheck, % (SwapIK ? 1 : 0)
    RefreshProfileDropdown()
    RefreshBootProfileLabel()
    UpdateMainStatus()
}

; ============================================================
;  MAIN GUI EVENT HANDLERS
; ============================================================
ToggleFromMain:
    ToggleRemap()
Return

OnProfileChange:
    Gui, Main:Submit, NoHide
    selected := StripBootMarker(ProfileChoice)
    if (selected = "" || selected = ActiveProfile)
        Return
    ; Auto-save current, switch to new
    SaveProfile(ActiveProfile)
    ActiveProfile := selected
    LoadProfile(ActiveProfile)
    SaveSettings()
    RefreshBuilderIfOpen()
Return

OnNewProfile:
    InputBox, newName, New Profile, Enter a name for the new profile:, , 320, 150
    if (ErrorLevel || newName = "")
        Return
    newName := Trim(newName)
    ; No special characters that break filenames
    if RegExMatch(newName, "[\\/:*?""<>|]") {
        MsgBox, 48, Invalid Name, A profile name cannot contain any of these characters:`n  \ / : * ? " < > |
        Return
    }
    ; No duplicates
    for i, p in ProfileList
    {
        if (p = newName) {
            MsgBox, 48, Already Exists, A profile named "%newName%" already exists.
            Return
        }
    }
    ; Save current, then create new
    SaveProfile(ActiveProfile)
    ActiveProfile := newName
    ResetProfile()
    SaveProfile(newName)
    ProfileList.Push(newName)
    SaveSettings()
    RefreshProfileDropdown()
    RefreshBuilderIfOpen()
Return

OnRenameProfile:
    oldName := ActiveProfile
    InputBox, newName, Rename Profile, Rename "%oldName%" to:, , 320, 150
    if (ErrorLevel || newName = "" || newName = oldName)
        Return
    newName := Trim(newName)
    if RegExMatch(newName, "[\\/:*?""<>|]") {
        MsgBox, 48, Invalid Name, A profile name cannot contain any of these characters:`n  \ / : * ? " < > |
        Return
    }
    for i, p in ProfileList
    {
        if (p = newName) {
            MsgBox, 48, Already Exists, A profile named "%newName%" already exists.
            Return
        }
    }
    oldFile := ProfilesDir . "\" . oldName . ".ini"
    newFile := ProfilesDir . "\" . newName . ".ini"
    FileMove, %oldFile%, %newFile%
    for i, p in ProfileList
    {
        if (p = oldName) {
            ProfileList[i] := newName
            break
        }
    }
    ActiveProfile := newName
    if (StartupProfile = oldName)
        StartupProfile := newName
    SaveSettings()
    RefreshBootProfileLabel()
    RefreshProfileDropdown()
    RefreshBuilderIfOpen()
Return

OnDeleteProfile:
    if (ProfileList.MaxIndex() <= 1) {
        MsgBox, 48, Cannot Delete, You must have at least one profile.
        Return
    }
    MsgBox, 4, Delete Profile, Delete "%ActiveProfile%"?`n`nThis cannot be undone.
    IfMsgBox, No
        Return
    delFile := ProfilesDir . "\" . ActiveProfile . ".ini"
    FileDelete, %delFile%
    deletedName := ActiveProfile
    newList := []
    for i, p in ProfileList
    {
        if (p != deletedName)
            newList.Push(p)
    }
    ProfileList := newList
    ActiveProfile := ProfileList[1]
    if (StartupProfile = deletedName)
        StartupProfile := ActiveProfile
    LoadProfile(ActiveProfile)
    SaveSettings()
    RefreshBootProfileLabel()
    RefreshProfileDropdown()
    RefreshBuilderIfOpen()
Return

OnSetBootProfile:
    StartupProfile := ActiveProfile
    SaveSettings()
    RefreshBootProfileLabel()
    TrayTip, BA Remapper, Boot profile set to: %ActiveProfile%, 2, 1
Return

OnAutoStartToggle:
    Gui, Main:Submit, NoHide
    SetAutoStart(AutoStartCheck)
    link := StartupLink()
    if (AutoStartCheck) {
        if FileExist(link)
            TrayTip, BA Remapper, Start with Windows ENABLED`nShortcut: %link%, 6, 1
        else
            TrayTip, BA Remapper, START WITH WINDOWS FAILED to create shortcut, 5, 3
    } else {
        TrayTip, BA Remapper, Start with Windows DISABLED, 3, 1
    }
Return

OnSwapIKToggle:
    Gui, Main:Submit, NoHide
    SwapIK := SwapIKCheck ? true : false
    SaveSettings()
Return

OnOpenFolder:
    global ConfigDir
    Run, %ConfigDir%
Return

OnCleanup:
    DoCleanup()
Return

MinimizeMain:
    SaveWindowPos()
    Gui, Main:Hide
Return

MainGuiClose:
    SaveWindowPos()
    Gui, Main:Hide
Return

; ============================================================
;  TRAY HANDLERS
; ============================================================
ShowMainFromTray:
    Gui, Main:Show
    WinActivate, BA Custom Control Box Remapper
Return

ToggleFromTray:
    ToggleRemap()
Return

OpenSettingsFolder:
    global ConfigDir
    Run, %ConfigDir%
Return

; ============================================================
;  TRIGGER FILE POLL  (reopen backup channel)
; ============================================================
CheckTriggerFile:
    if FileExist(TriggerFile) {
        FileDelete, %TriggerFile%
        Gui, Main:Show
        WinActivate, BA Custom Control Box Remapper
    }
Return

; ============================================================
;  TOGGLE HOTKEY
; ============================================================
^F12::
    ToggleRemap()
Return

; ============================================================
;  BOX KEY HOTKEYS  (active only when RemapActive)
; ============================================================
#If (RemapActive)

$y::HandleBoxKeyDown("y")
$y Up::HandleBoxKeyUp("y")
$u::HandleBoxKeyDown("u")
$u Up::HandleBoxKeyUp("u")
$o::HandleBoxKeyDown("o")
$o Up::HandleBoxKeyUp("o")
$i::HandleBoxKeyDown("i")
$i Up::HandleBoxKeyUp("i")
$k::HandleBoxKeyDown("k")
$k Up::HandleBoxKeyUp("k")
$a::HandleBoxKeyDown("a")
$a Up::HandleBoxKeyUp("a")
$c::HandleBoxKeyDown("c")
$c Up::HandleBoxKeyUp("c")
$v::HandleBoxKeyDown("v")
$v Up::HandleBoxKeyUp("v")
$j::HandleBoxKeyDown("j")
$j Up::HandleBoxKeyUp("j")
$Left::HandleBoxKeyDown("Left")
$Left Up::HandleBoxKeyUp("Left")
$Right::HandleBoxKeyDown("Right")
$Right Up::HandleBoxKeyUp("Right")
$Up::HandleBoxKeyDown("Up")
$Up Up::HandleBoxKeyUp("Up")
$Down::HandleBoxKeyDown("Down")
$Down Up::HandleBoxKeyUp("Down")

LWin::return
RWin::return
Pause::return
#p::return
#u::return
#d::return

#If

; ============================================================
;  HELP WINDOW
; ============================================================
ShowHelp:
    if WinExist(HelpWinTitle) {
        WinActivate
        Return
    }
    Gui, Help:Destroy
    Gui, Help:New, +AlwaysOnTop, %HelpWinTitle%
    Gui, Help:Color, 1a1a2e
    Gui, Help:Font, s14 cWhite Bold, Segoe UI
    Gui, Help:Add, Text, x20 y10 w460 Center, BA Custom Control Box Remapper

    Gui, Help:Font, s10 cCCCCCC Normal, Segoe UI

    helpText =
    (LTrim
    HOW IT WORKS
    Your control box sends keystrokes (y, u, i, etc) like a
    normal keyboard.  When mapping is ON, BARemapper intercepts
    those keystrokes and can replace them with anything you
    configure - a different key, a mouse click, or a "secondary"
    action when you hold the FN button.

    FN BUTTON (default: Reset Aim / A)
    - Tap A alone -> sends Aim Reset (normal)
    - Hold A + press another button -> secondary action
    - You can change which button is FN in the Builder

    SECONDARY FUNCTIONS (set in Builder)
    Key Mode: FN + button sends a different GSPro hotkey
    Click Mode: FN + button clicks a specific screen position

    PROFILES
    Each profile is its own .ini file in the profiles folder.
    Use the dropdown to switch.  Every change auto-saves.
    The [BOOT] tag marks your Boot Profile - the one auto-loaded
    when "Start with Windows" is checked.

    "START WITH WINDOWS"
    When checked, a shortcut named BARemapper.lnk is placed
    in your Windows Startup folder.  See it yourself: press
    Win+R, type  shell:startup  and press Enter.  On login,
    Windows runs the shortcut, which loads your Boot Profile,
    turns mapping ON, and hides to the tray.  The shortcut
    re-points itself to the current .exe location on every
    launch, so moving the app never breaks boot.

    IMPORTANT: BEFORE YOU DELETE BAREMAPPER
    Click Cleanup first, OR uncheck Start with Windows.
    That removes the startup shortcut so Windows won't try
    to launch a program that no longer exists.

    WHERE ARE MY FILES?
    The "Files are saved at" line on the main window shows the
    exact path.  Click "Open Folder" to open it in Explorer.

    TIPS
    - Ctrl+F12 toggles mapping ON/OFF system-wide
    - Ctrl+M (Mulligan) always works as normal
    - Double-click the .exe anytime to reopen the GUI
    - Click the tray icon to reopen the GUI
    - Minimize to Tray keeps mapping running; Exit fully quits
    )

    Gui, Help:Add, Edit, x20 y40 w460 h450 ReadOnly -WantReturn, %helpText%
    Gui, Help:Font, s10 c000000 Normal, Segoe UI
    Gui, Help:Add, Button, x180 y500 w140 h35 gHelpClose, Got It
    Gui, Help:Show, w500 h550
Return

HelpClose:
HelpGuiClose:
    Gui, Help:Destroy
Return

; ============================================================
;  BUILDER GUI
;
;  All changes auto-save the moment you make them.  No
;  "Save & Close" needed.  Just configure and close.
; ============================================================
ShowBuilder:
    if WinExist(BuilderWinTitle) {
        WinActivate
        Return
    }
    Gui, Builder:Destroy
    Gui, Builder:New, +AlwaysOnTop, %BuilderWinTitle%
    Gui, Builder:Color, 1c1c1c   ; near-black, like the physical box

    Gui, Builder:Font, s16 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x20 y10 w940 Center, BA CUSTOM PRODUCTS
    Gui, Builder:Font, s10 cC8E6C2 Normal, Segoe UI
    Gui, Builder:Add, Text, x20 y40 w940 Center vBuilderSubtitle, Button Builder  -  Profile: %ActiveProfile%  (auto-saves)

    ; FN selector row
    Gui, Builder:Font, s10 cFFFF00 Bold, Segoe UI
    Gui, Builder:Add, Text, x280 y68 w110 Right, FN BUTTON:
    Gui, Builder:Font, s10 c000000 Normal, Segoe UI
    fnList := "Reset Aim (A)|Heat Map (Y)|Putt (U)|Flyover (O)|Club Up (I)|Club Down (K)|Tee Left (C)|Tee Right (V)|Shot Cam (J)"
    fnDefault := "Reset Aim (A)"
    for dispName, bId in FnChoiceMap {
        if (bId = FnButtonId)
            fnDefault := dispName
    }
    Gui, Builder:Add, DropDownList, x400 y65 w200 vFnChoice gOnFnChange, %fnList%
    GuiControl, Builder:ChooseString, FnChoice, %fnDefault%

    Gui, Builder:Add, Text, x30 y98 w920 0x10

    ; --------------------------------------------------------
    ;  PANEL REPLICA - positions mirror the physical box:
    ;
    ;   MULLIGAN    HEAT MAP     PUTT       FLYOVER
    ;         ^                       ^
    ;      [CLUB UP]              [AIM UP]
    ;               BA CUSTOM PRODUCTS
    ;    CLUB            < [AIM LT]  AIM  [AIM RT] >
    ;      [CLUB DN]              [AIM DN]
    ;         v          TEE POS     v
    ;   RESET AIM   < [TEE L]  [TEE R] >   SHOT CAM
    ; --------------------------------------------------------

    ; Top row
    Gui, Builder:Font, s9 c000000 Normal, Segoe UI
    Gui, Builder:Add, Button, x55  y110 w85 h85 Disabled     vBtnMulligan, MULLIGAN`nCtrl+M
    Gui, Builder:Add, Button, x280 y110 w85 h85 gBtnHeatmap  vBtnHeatmap,  HEAT MAP`nY
    Gui, Builder:Add, Button, x505 y110 w85 h85 gBtnPutt     vBtnPutt,     PUTT`nU
    Gui, Builder:Add, Button, x800 y110 w85 h85 gBtnFlyover  vBtnFlyover,  FLYOVER`nO

    ; Up arrows (panel print)
    Gui, Builder:Font, s11 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x222 y198 w20 Center, ^
    Gui, Builder:Add, Text, x677 y198 w20 Center, ^

    ; Second row: CLUB UP (left) and AIM UP (right)
    Gui, Builder:Font, s9 c000000 Normal, Segoe UI
    Gui, Builder:Add, Button, x190 y218 w85 h85 gBtnClubup vBtnClubup, CLUB UP`nI
    Gui, Builder:Add, Button, x645 y218 w85 h85 gBtnUp     vBtnUp,     AIM UP`nUp

    ; Brand center (like the logo on the physical panel)
    Gui, Builder:Font, s12 c2ECC71 Bold, Segoe UI
    Gui, Builder:Add, Text, x300 y252 w320 Center, BA CUSTOM PRODUCTS

    ; Middle row: AIM LEFT / AIM text / AIM RIGHT, CLUB label at left
    Gui, Builder:Font, s16 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x157 y355 w150 Center, CLUB
    Gui, Builder:Add, Text, x640 y355 w150 Center, AIM
    Gui, Builder:Font, s14 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x505 y358 w20 Center, <
    Gui, Builder:Add, Text, x897 y358 w20 Center, >
    Gui, Builder:Font, s9 c000000 Normal, Segoe UI
    Gui, Builder:Add, Button, x535 y330 w85 h85 gBtnLeft  vBtnLeft,  AIM LEFT`nLeft
    Gui, Builder:Add, Button, x805 y330 w85 h85 gBtnRight vBtnRight, AIM RIGHT`nRight

    ; Fourth row: CLUB DOWN (left) and AIM DOWN (right)
    Gui, Builder:Add, Button, x190 y440 w85 h85 gBtnClubdown vBtnClubdown, CLUB DOWN`nK
    Gui, Builder:Add, Button, x645 y440 w85 h85 gBtnDown     vBtnDown,     AIM DOWN`nDown

    ; Down arrows + TEE POS panel print
    Gui, Builder:Font, s11 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x222 y528 w20 Center, v
    Gui, Builder:Add, Text, x677 y528 w20 Center, v
    Gui, Builder:Add, Text, x455 y528 w120 Center, TEE POS

    ; Bottom row: corners + tee pair
    Gui, Builder:Font, s9 c000000 Normal, Segoe UI
    Gui, Builder:Add, Button, x55  y550 w85 h85 gBtnResetaim vBtnResetaim, RESET AIM`nA
    Gui, Builder:Add, Button, x385 y550 w85 h85 gBtnTeeleft  vBtnTeeleft,  TEE LEFT`nC
    Gui, Builder:Add, Button, x560 y550 w85 h85 gBtnTeeright vBtnTeeright, TEE RIGHT`nV
    Gui, Builder:Add, Button, x800 y550 w85 h85 gBtnShotcam  vBtnShotcam,  SHOT CAM`nJ
    Gui, Builder:Font, s14 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x352 y580 w20 Center, <
    Gui, Builder:Add, Text, x652 y580 w20 Center, >

    ; Bottom action buttons
    Gui, Builder:Font, s11 cWhite Bold, Segoe UI
    Gui, Builder:Add, Button, x340 y655 w150 h40 gBuilderReset, Reset Profile
    Gui, Builder:Add, Button, x510 y655 w150 h40 gBuilderClose, Close

    Gui, Builder:Font, s9 cC8E6C2 Normal, Segoe UI
    Gui, Builder:Add, Text, x20 y705 w940 Center vBuilderStatus, Click a button to configure its secondary (FN) function  -  all changes auto-save

    UpdateBuilderLabels()

    Gui, Builder:Show, w980 h735
Return

OnFnChange:
    Gui, Builder:Submit, NoHide
    if (FnChoiceMap.HasKey(FnChoice)) {
        FnButtonId := FnChoiceMap[FnChoice]
        if (BtnPrimary.HasKey(FnButtonId))
            FnSendKey := BtnPrimary[FnButtonId]
        ; Auto-save
        SaveProfile(ActiveProfile)
        UpdateBuilderLabels()
        GuiControl, Builder:, BuilderStatus, FN button changed to: %FnChoice%  (saved)
    }
Return

; ============================================================
;  BUILDER BUTTON HANDLERS - open the per-button config dialog
; ============================================================
BtnHeatmap:
    ConfigButton("heatmap", "HEAT MAP", "Y")
Return

BtnPutt:
    ConfigButton("putt", "PUTT", "U")
Return

BtnFlyover:
    ConfigButton("flyover", "FLYOVER", "O")
Return

BtnClubup:
    ConfigButton("clubup", "CLUB UP", "I")
Return

BtnLeft:
    ConfigButton("left", "AIM LEFT", "Left Arrow")
Return

BtnUp:
    ConfigButton("up", "AIM UP", "Up Arrow")
Return

BtnRight:
    ConfigButton("right", "AIM RIGHT", "Right Arrow")
Return

BtnResetaim:
    ConfigButton("resetaim", "RESET AIM", "A")
Return

BtnDown:
    ConfigButton("down", "AIM DOWN", "Down Arrow")
Return

BtnTeeleft:
    ConfigButton("teeleft", "TEE LEFT", "C")
Return

BtnTeeright:
    ConfigButton("teeright", "TEE RIGHT", "V")
Return

BtnShotcam:
    ConfigButton("shotcam", "SHOT CAM", "J")
Return

BtnClubdown:
    ConfigButton("clubdown", "CLUB DOWN", "K")
Return

; ============================================================
;  CONFIGURE SECONDARY
;  Every successful configuration auto-saves the profile.
; ============================================================
ConfigButton(btnIdVal, displayName, primaryKey) {
    global ConfiguringBtnId, ConfiguringDisplayName, SecType, SecValue, SecX, SecY
    global GSProActions, GSProNameMap, GSProKeyMap, ActiveProfile
    global KeyChoice   ; control variable - must be global
    ConfiguringBtnId := btnIdVal
    ConfiguringDisplayName := displayName

    Gui, Builder:+OwnDialogs

    MsgBox, 3, %displayName% - Secondary Function
        , Set the secondary (FN + %displayName%) function:`n`nPrimary: %primaryKey% (always works alone)`n`nYes = Map to a GSPro key`nNo = Map to a screen click`nCancel = Remove the secondary
    IfMsgBox, Cancel
    {
        SecType[btnIdVal]  := "none"
        SecValue[btnIdVal] := ""
        SecX[btnIdVal]     := 0
        SecY[btnIdVal]     := 0
        SaveProfile(ActiveProfile)
        UpdateBuilderLabels()
        GuiControl, Builder:, BuilderStatus, %displayName%: secondary removed  (saved)
        Return
    }
    IfMsgBox, Yes
    {
        Gui, KeyPick:New, +AlwaysOnTop +OwnerBuilder, Pick GSPro Action
        Gui, KeyPick:Font, s10, Segoe UI
        Gui, KeyPick:Add, Text, x10 y10 w300, FN + %displayName% will send:
        Gui, KeyPick:Add, ListBox, x10 y40 w300 h300 vKeyChoice, %GSProActions%
        if (SecType.HasKey(btnIdVal) && SecType[btnIdVal] = "key" && SecValue.HasKey(btnIdVal)) {
            sv := SecValue[btnIdVal]
            if (GSProNameMap.HasKey(sv)) {
                cn := GSProNameMap[sv]
                GuiControl, KeyPick:ChooseString, KeyChoice, %cn%
            }
        }
        Gui, KeyPick:Add, Button, x10  y350 w140 h35 gKeyPickOK,     OK
        Gui, KeyPick:Add, Button, x160 y350 w140 h35 gKeyPickCancel, Cancel
        Gui, KeyPick:Show, w320 h400
        Return
    }
    IfMsgBox, No
    {
        Gui, Builder:Hide
        Sleep, 300
        ToolTip, Click the screen position for FN + %displayName%`nPress Esc to cancel, 10, 10
        capturedX := ""
        capturedY := ""
        cancelled := false
        Loop {
            if (GetKeyState("Escape", "P")) {
                cancelled := true
                break
            }
            if (GetKeyState("LButton", "P")) {
                CoordMode, Mouse, Screen
                MouseGetPos, capturedX, capturedY
                KeyWait, LButton
                break
            }
            Sleep, 30
        }
        ToolTip
        if (!cancelled) {
            SecType[btnIdVal]  := "click"
            SecValue[btnIdVal] := ""
            SecX[btnIdVal]     := capturedX
            SecY[btnIdVal]     := capturedY
            SaveProfile(ActiveProfile)
        }
        Gui, Builder:Show
        UpdateBuilderLabels()
        if (cancelled)
            GuiControl, Builder:, BuilderStatus, %displayName%: click setup cancelled
        else
            GuiControl, Builder:, BuilderStatus, %displayName%: click at %capturedX%, %capturedY%  (saved)
        Return
    }
}

KeyPickOK:
    Gui, KeyPick:Submit
    Gui, KeyPick:Destroy
    if (KeyChoice != "" && KeyChoice != "None") {
        sendKey := GSProKeyMap[KeyChoice]
        SecType[ConfiguringBtnId]  := "key"
        SecValue[ConfiguringBtnId] := sendKey
        SecX[ConfiguringBtnId]     := 0
        SecY[ConfiguringBtnId]     := 0
        SaveProfile(ActiveProfile)
        UpdateBuilderLabels()
        GuiControl, Builder:, BuilderStatus, % ConfiguringDisplayName . ": FN sends " . KeyChoice . "  (saved)"
    }
Return

KeyPickCancel:
KeyPickGuiClose:
    Gui, KeyPick:Destroy
Return

; ============================================================
;  UPDATE BUILDER LABELS
; ============================================================
UpdateBuilderLabels() {
    UpdateOneLabel("heatmap",  "BtnHeatmap",  "HEAT MAP",  "Y")
    UpdateOneLabel("putt",     "BtnPutt",     "PUTT",      "U")
    UpdateOneLabel("flyover",  "BtnFlyover",  "FLYOVER",   "O")
    UpdateOneLabel("clubup",   "BtnClubup",   "CLUB UP",   "I")
    UpdateOneLabel("left",     "BtnLeft",     "AIM LEFT",  "Left")
    UpdateOneLabel("up",       "BtnUp",       "AIM UP",    "Up")
    UpdateOneLabel("right",    "BtnRight",    "AIM RIGHT", "Right")
    UpdateOneLabel("resetaim", "BtnResetaim", "RESET AIM", "A")
    UpdateOneLabel("down",     "BtnDown",     "AIM DOWN",  "Down")
    UpdateOneLabel("teeleft",  "BtnTeeleft",  "TEE LEFT",  "C")
    UpdateOneLabel("teeright", "BtnTeeright", "TEE RIGHT", "V")
    UpdateOneLabel("shotcam",  "BtnShotcam",  "SHOT CAM",  "J")
    UpdateOneLabel("clubdown", "BtnClubdown", "CLUB DOWN", "K")
}

UpdateOneLabel(btnIdVal, ctrlName, dispName, priKey) {
    global FnButtonId, SecType, SecValue, GSProNameMap
    label := dispName . "`n" . priKey
    if (btnIdVal = FnButtonId)
        label := "[FN]`n" . dispName . "`n" . priKey
    if (SecType.HasKey(btnIdVal) && SecType[btnIdVal] != "none" && SecType[btnIdVal] != "") {
        if (SecType[btnIdVal] = "key") {
            sv := SecValue[btnIdVal]
            if (GSProNameMap.HasKey(sv))
                label .= "`n> " . GSProNameMap[sv]
            else
                label .= "`n> " . sv
        } else if (SecType[btnIdVal] = "click") {
            label .= "`n> Click"
        }
    }
    GuiControl, Builder:, %ctrlName%, %label%
}

; Keep the Builder in sync when the profile changes while it
; is open: subtitle, FN dropdown, and all button labels.
RefreshBuilderIfOpen() {
    global BuilderWinTitle, ActiveProfile, FnButtonId, FnChoiceMap
    if (!WinExist(BuilderWinTitle))
        return
    GuiControl, Builder:, BuilderSubtitle, Button Builder  -  Profile: %ActiveProfile%  (auto-saves)
    for dispName, bId in FnChoiceMap {
        if (bId = FnButtonId) {
            GuiControl, Builder:ChooseString, FnChoice, %dispName%
            break
        }
    }
    UpdateBuilderLabels()
    GuiControl, Builder:, BuilderStatus, Now editing profile: %ActiveProfile%
}

; ============================================================
;  BUILDER RESET / CLOSE
; ============================================================
BuilderReset:
    Gui, Builder:+OwnDialogs
    MsgBox, 4, Reset Profile, Reset "%ActiveProfile%" to defaults?`n`nThis clears the FN button and all secondary functions.
    IfMsgBox, No
        Return
    ResetProfile()
    SaveProfile(ActiveProfile)
    UpdateBuilderLabels()
    GuiControl, Builder:ChooseString, FnChoice, Reset Aim (A)
    GuiControl, Builder:, BuilderStatus, Profile reset to defaults  (saved)
Return

BuilderClose:
BuilderGuiClose:
    Gui, Builder:Destroy
Return

; ============================================================
;  CLEANUP / RESET
;
;  One-click removal of everything BARemapper has created:
;  - Windows startup registry entry
;  - All profile files
;  - settings.ini
;  - Temp trigger file
;
;  After confirmation, also exits the app so user starts fresh
;  on next launch.  The .exe itself is NOT touched.
; ============================================================
DoCleanup() {
    global RegistryRunKey, RegistryRunName, ConfigDir, ProfilesDir, ConfigFile, TriggerFile
    Gui, Main:+OwnDialogs
    MsgBox, 4 + 48, Cleanup, This will remove EVERYTHING BARemapper has created:`n`n  - Windows Startup folder shortcut`n  - Any legacy registry boot entry`n  - All profile files`n  - Settings file`n  - Temp files`n`nYour BARemapper.exe is NOT touched.`nThe app will then exit so you can start fresh.`n`nContinue?
    IfMsgBox, No
        return

    ; 1. Startup folder shortcut (current method)
    link := StartupLink()
    if FileExist(link)
        FileDelete, %link%

    ; 2. Legacy registry boot entry (older versions used this)
    RegRead, val, %RegistryRunKey%, %RegistryRunName%
    if (!ErrorLevel)
        RegDelete, %RegistryRunKey%, %RegistryRunName%

    ; 3. Profile files
    if FileExist(ProfilesDir)
        FileRemoveDir, %ProfilesDir%, 1

    ; 4. settings.ini
    if FileExist(ConfigFile)
        FileDelete, %ConfigFile%

    ; 5. Trigger file
    if FileExist(TriggerFile)
        FileDelete, %TriggerFile%

    ; 6. The Remapper folder itself if now empty
    if FileExist(ConfigDir) {
        isEmpty := true
        Loop, %ConfigDir%\*.*, 1
        {
            isEmpty := false
            break
        }
        if (isEmpty)
            FileRemoveDir, %ConfigDir%
    }

    MsgBox, 64, Cleanup, Cleanup complete.`n`nBARemapper will now exit.`nLaunch it again any time to start fresh.
    ; Skip OnExit-driven save (it would just recreate settings.ini)
    ExitApp
}

; ============================================================
;  EXIT
;
;  Stripped to the absolute minimum.  No save calls, no OnExit
;  handler, nothing that can hang.  Just TrayTip (so the click
;  is visible) then ExitApp.  Auto-save during normal use means
;  no data is lost.
; ============================================================
SaveState() {
    ; Kept for the rare manual call.  Each step independent so
    ; one failure can't block the others.
    try {
        Gui, Main:Submit, NoHide
    } catch {
    }
    try {
        SaveSettings()
    } catch {
    }
    try {
        SaveWindowPos()
    } catch {
    }
    try {
        SaveProfile(ActiveProfile)
    } catch {
    }
}

ExitLabel:
DoFullExit:
    TrayTip, BA Remapper, Exiting..., 1, 1
    Sleep, 100
    ExitApp
Return
