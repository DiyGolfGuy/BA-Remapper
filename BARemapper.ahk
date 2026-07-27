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
;  BA CUSTOM PRODUCTS - CONTROL BOX REMAPPER v5.0
;  bacustomproducts@gmail.com   GitHub: DiyGolfGuy
;
;  CHANGES IN v5.0  (the OCR release)
;  - SMART CLICKS: secondary functions can now use the OCR
;    engine built into Windows 10/11 to find and click GSPro
;    menu buttons by reading the screen - no taught positions,
;    no setup, resolution-independent.  Available actions:
;    Move Forward, Move Back, Next Option, Drop Ball / Rehit,
;    OB Rehit.  (OCR stack proven in ProTee AutoStart.)
;  - BUILT-IN PRESET: a "Basic Secondary" profile ships with
;    the app, matching the yellow print on the physical box.
;    Select it from the dropdown and everything just works,
;    zero programming.  Delete its file to restore defaults.
;  - SELECT SHOT 1-4: GSPro's scramble shot-select keys are
;    now assignable as secondary functions.
;  - AUTO-PICK SCRAMBLE: optional watcher reads the scramble
;    shot-select cards and, after a configurable delay
;    (5/10/15/20s), presses the key for the best ball:
;    the fewest-strokes balls are considered first (a 2nd
;    shot ball beats a closer 3rd-shot ball after a penalty),
;    then anything on the GREEN wins, then lowest distance.
;    Global setting (applies to all profiles),
;    watching whenever the app is running.
;  - Builder panel now prints each button's secondary function
;    in yellow next to the button, exactly like the physical
;    box print, and updates live as you remap.
;  - New per-button config dialog: GSPro Hotkey / Smart Click
;    (OCR) / Taught Screen Click / None in one window.
;  - Windows OCR library inlined at the end of this file.
;
;  CHANGES IN v4.1
;  - Builder redesigned to mirror the physical control box.
;  - Mutex-based reopen detection; stale trigger file cleanup.
;  - Builder syncs on profile switch.  Startup-folder docs.
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
AppVersion := "5.0"
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
    . "A - Aim Reset|B - Clear View / Hide Objects|C - Tee Left|D - Vertical Dots|"
    . "F - FPS Toggle|G - Green Grid|H - Hide UI|I - Club Up|"
    . "J - Shot Cam|K - Club Down|L - Lighting|N - Switch Hand|"
    . "O - Flyover|P - Pin Indicator|Q - Minimap Zoom Out|"
    . "R - Rangefinder|S - Map Expand|T - Scorecard|"
    . "U - Putt Toggle|V - Tee Right|W - Minimap Zoom In|"
    . "Y - Heat Map|Z - 3D Grass Toggle|"
    . "1 - Select Shot 1|2 - Select Shot 2|3 - Select Shot 3|4 - Select Shot 4|"
    . "F1 - Clear Tracer|F3 - Aimpoint|F5 - Free Look|"
    . "Tab - Shortcuts|Ctrl+M - Mulligan|Space - Fast Forward|"
    . "Up Arrow|Down Arrow|Left Arrow|Right Arrow|"
    . "Enter|Escape|Backspace"

GSProKeyMap := {}
GSProKeyMap["None"] := ""
GSProKeyMap["A - Aim Reset"]         := "a"
GSProKeyMap["B - Clear View / Hide Objects"] := "b"
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
GSProKeyMap["1 - Select Shot 1"]     := "1"
GSProKeyMap["2 - Select Shot 2"]     := "2"
GSProKeyMap["3 - Select Shot 3"]     := "3"
GSProKeyMap["4 - Select Shot 4"]     := "4"
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

; ============================================================
;  SMART CLICK (OCR) ACTIONS
;
;  These read the live GSPro screen with the Windows built-in
;  OCR engine (library inlined at the bottom of this file),
;  find the named menu button, and click it.  No taught
;  coordinates, works at any resolution.
;
;  Needles are tried in order; the first needle with a match
;  wins.  Among multiple matches of a needle, the BOTTOM-MOST
;  is clicked (menu titles repeat the button words above the
;  actual buttons - e.g. the popup titled "Rehit" contains a
;  Rehit button below it).
;
;  Stateless by design: press FN+button -> find text -> click.
;  If the target is grayed out, the click lands harmlessly and
;  the player cycles with Next Option and presses again.  The
;  software never guesses what page the menu is on.
; ============================================================
OcrActionIds   := ["MoveForward","MoveBack","NextOption","DropRehit","Rehit"]
OcrActionName  := {}
OcrActionName["MoveForward"] := "Move Forward"
OcrActionName["MoveBack"]    := "Move Back"
OcrActionName["NextOption"]  := "Next Option"
OcrActionName["DropRehit"]   := "Drop Ball / Rehit"
OcrActionName["Rehit"]       := "OB Rehit"

OcrActionNeedles := {}
OcrActionNeedles["MoveForward"] := ["move forward"]
OcrActionNeedles["MoveBack"]    := ["move back"]
OcrActionNeedles["NextOption"]  := ["next option"]
OcrActionNeedles["DropRehit"]   := ["drop ball", "rehit"]
OcrActionNeedles["Rehit"]       := ["rehit"]

; Dropdown list string + reverse lookup (display name -> id)
OcrActionList := ""
OcrActionByName := {}
for i, aid in OcrActionIds {
    if (i > 1)
        OcrActionList .= "|"
    OcrActionList .= OcrActionName[aid]
    OcrActionByName[OcrActionName[aid]] := aid
}

; GSPro window anchor for all OCR scans (per OCR handoff:
; scan the game window, exclude the "GSPro Configuration" app)
GSProWinNeedle  := "gspro"
GSProWinExclude := "configuration"

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

; ---- OCR / Smart Click state ----
; ClickDelayMs is the OCR library's hover-before-click pacing.
; The library default (1000ms) is tuned for unattended startup
; automation; at the tee a long hover feels broken, so 300ms.
ClickDelayMs := 300
OcrBusy      := false        ; guards against overlapping OCR actions
LastActionId := ""           ; repeat fast path: last smart-click action
LastClickX   := 0            ; ... and where it clicked
LastClickY   := 0
LastFireTick := 0            ; when the last smart click fired
LastScanObj  := ""           ; scan cache (reused across quick presses)
LastScanTick := 0
VerifyActionId := ""         ; background fade-proof verify state
VerifyY      := 0
VerifyBandPx := 90           ; vertical tolerance for verify match
LastLatticeNote := ""        ; diagnostics for miss dumps
LastResolveBand := 90
OcrWarmedUp  := false

; ---- Auto-Pick Scramble state (settings loaded from ini) ----
ScrambleAutoPick  := false   ; global toggle (all profiles)
ScrambleDelaySec  := 15      ; 5 / 10 / 15 / 20
ScrambleArmedTick := 0       ; tick when USE screen first seen (0 = not armed)
ScrambleCoolDown  := false   ; true after firing until screen disappears
ScrambleBusy      := false   ; re-entrancy guard for the watcher timer
ScrambleDumped    := false   ; one-shot diagnostic dump guard
ScrambleFbTick    := 0       ; throttle for full-screen fallback scans
ScrambleCountdown := true    ; show on-screen countdown before auto-pick
CdVisible         := false   ; countdown overlay currently shown
CdWinW            := 240     ; measured overlay size (set at creation)
CdWinH            := 46
CdHwndVar         := 0       ; countdown overlay window handle

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

; Unconditional launch log - answers "did Windows even run us
; at boot" from a file instead of a guess.  Newest entries at
; the bottom; trimmed when it grows past ~20KB.
llFile := ConfigDir . "\launch_log.txt"
FileGetSize, llSize, %llFile%
if (llSize > 20000)
    FileDelete, %llFile%
llMode := isStartupLaunch ? "WINDOWS-STARTUP" : "manual"
llLine := A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec
llLine .= "  " . llMode . "  " . A_ScriptFullPath . "`n"
FileAppend, %llLine%, %llFile%

; Strip our own Mark-of-the-Web.  Downloaded files carry a
; hidden internet tag; Windows screening lets an INTERACTIVE
; launch through (the user clicks Run anyway) but silently
; blocks the same file at LOGON via the Startup shortcut -
; "blocked a file that may be unsafe" with nobody to ask.
; Deleting the tag is exactly what the Properties > Unblock
; checkbox does, so the first manual run permanently clears
; the boot path.  (Locally-compiled exes never carry the tag,
; which is why ProTee AutoStart never hit this.)
if (A_IsCompiled) {
    zid := A_ScriptFullPath . ":Zone.Identifier"
    FileDelete, %zid%
}

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
    global ScrambleAutoPick, ScrambleDelaySec, ScrambleCountdown
    IniRead, ActiveProfile,  %ConfigFile%, App, ActiveProfile,  Default
    IniRead, StartupProfile, %ConfigFile%, App, StartupProfile, %ActiveProfile%
    IniRead, swapVal,        %ConfigFile%, App, SwapIK,         0
    SwapIK := (swapVal + 0) ? true : false
    IniRead, spVal,          %ConfigFile%, App, ScrambleAutoPick, 0
    ScrambleAutoPick := (spVal + 0) ? true : false
    IniRead, sdVal,          %ConfigFile%, App, ScrambleDelay,  15
    sdVal += 0
    if (sdVal != 5 && sdVal != 10 && sdVal != 15 && sdVal != 20)
        sdVal := 15
    ScrambleDelaySec := sdVal
    IniRead, cdVal,          %ConfigFile%, App, ScrambleCountdown, 1
    ScrambleCountdown := (cdVal + 0) ? true : false
}

SaveSettings() {
    global ConfigFile, ActiveProfile, StartupProfile, SwapIK
    global ScrambleAutoPick, ScrambleDelaySec, ScrambleCountdown
    IniWrite, %ActiveProfile%,  %ConfigFile%, App, ActiveProfile
    IniWrite, %StartupProfile%, %ConfigFile%, App, StartupProfile
    swapWrite := SwapIK ? 1 : 0
    IniWrite, %swapWrite%, %ConfigFile%, App, SwapIK
    spWrite := ScrambleAutoPick ? 1 : 0
    IniWrite, %spWrite%, %ConfigFile%, App, ScrambleAutoPick
    IniWrite, %ScrambleDelaySec%, %ConfigFile%, App, ScrambleDelay
    cdWrite := ScrambleCountdown ? 1 : 0
    IniWrite, %cdWrite%, %ConfigFile%, App, ScrambleCountdown
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

; ============================================================
;  BUILT-IN PRESET: "Basic Secondary"
;
;  Matches the yellow print on the physical control box.
;  Ships with the app - select it from the dropdown and every
;  secondary works with zero programming:
;
;    FN + CLUB DOWN (K)  -> Clear View (b)
;    FN + TEE LEFT (C)   -> OB Rehit          (Smart Click)
;    FN + AIM UP         -> Move Forward      (Smart Click)
;    FN + AIM DOWN       -> Move Back         (Smart Click)
;    FN + AIM LEFT       -> Next Option       (Smart Click)
;    FN + AIM RIGHT      -> Drop Ball / Rehit (Smart Click)
;
;  Recreated automatically if its file is missing, so deleting
;  profiles\Basic Secondary.ini restores factory defaults.
;  User edits persist (the file exists, so it is not touched).
; ============================================================
IsPresetProfile(n) {
    return (n = "Basic Secondary")
}

SeedPresetProfiles() {
    global ProfilesDir, ProfileList, AllBtnIds
    pf := ProfilesDir . "\Basic Secondary.ini"
    ; ALWAYS rewritten at launch: the preset is hard-coded and
    ; self-heals no matter what happened to the file.
    FileDelete, %pf%
    IniWrite, resetaim, %pf%, Profile, FnButtonId
    for i, id in AllBtnIds
    {
        st := "none", sv := ""
        if (id = "clubdown") {
            st := "key",  sv := "b"
        } else if (id = "teeleft") {
            st := "ocr",  sv := "Rehit"
        } else if (id = "up") {
            st := "ocr",  sv := "MoveForward"
        } else if (id = "down") {
            st := "ocr",  sv := "MoveBack"
        } else if (id = "left") {
            st := "ocr",  sv := "NextOption"
        } else if (id = "right") {
            st := "ocr",  sv := "DropRehit"
        }
        IniWrite, %st%, %pf%, Profile, %id%_Type
        IniWrite, %sv%, %pf%, Profile, %id%_Value
        IniWrite, 0,   %pf%, Profile, %id%_X
        IniWrite, 0,   %pf%, Profile, %id%_Y
    }
    ; Add to the in-memory list if not present
    already := false
    for i, p in ProfileList
    {
        if (p = "Basic Secondary")
            already := true
    }
    if (!already)
        ProfileList.Push("Basic Secondary")
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
        EnsureStartupApproved()
    } else {
        if FileExist(link)
            FileDelete, %link%
    }
}

; Windows keeps its OWN enabled/disabled flag for every startup
; item (the Task Manager "Startup apps" list), stored under
; StartupApproved and keyed by the shortcut NAME.  Once marked
; disabled there, the item stays suppressed even if the .lnk is
; deleted and recreated and the exe replaced - a silent, sticky
; boot blocker.  When autostart is ON we verify the flag and
; re-enable it if Windows has it off (first byte 02 = enabled).
EnsureStartupApproved() {
    keyPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
    RegRead, apVal, %keyPath%, BARemapper.lnk
    if (ErrorLevel)
        return   ; no entry = default enabled
    if (SubStr(apVal, 1, 2) = "02")
        return   ; already enabled
    RegWrite, REG_BINARY, %keyPath%, BARemapper.lnk, 020000000000000000000000
    if (!ErrorLevel)
        TrayTip, BA Remapper, Windows had "Start with Windows" DISABLED in Startup apps - re-enabled it. It will now run at boot., 8, 2
    else
        TrayTip, BA Remapper, Windows has this app DISABLED under Task Manager > Startup apps. Please right-click it there and choose Enable., 10, 3
}

; Refresh the shortcut on every launch so its target stays
; current if the user moved the .exe to a new folder.  If it
; was pointing at a DIFFERENT copy (old download, deleted
; file), say so - a silently healed shortcut looks like a
; random boot failure from the outside.
RefreshAutoStartPath() {
    if (!IsAutoStart())
        return
    link := StartupLink()
    oldTarget := ""
    FileGetShortcut, %link%, oldTarget
    SetAutoStart(true)
    if (A_IsCompiled && oldTarget != "" && oldTarget != A_ScriptFullPath)
        TrayTip, BA Remapper, Start with Windows was pointing at a different copy - now fixed to this one. Keep the exe at one permanent location., 8, 2
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
        ; Taught positions are captured AND clicked in physical
        ; pixels (DpiGetCursor / DpiClickAt) so display scaling
        ; can never shift them.
        DpiClickAt(SecX[btnId], SecY[btnId])
        Sleep, 80
        DpiSetCursor(0, 0)
    }
    else if (stype = "ocr") {
        RunOcrAction(SecValue[btnId])
    }
}

; ============================================================
;  SMART CLICK EXECUTION
;
;  Stateless: scan the GSPro window, find the needle text,
;  click the bottom-most match (titles repeat button words
;  above the actual buttons).  Up to 3 scan attempts over
;  ~2 seconds - the menu is normally already on screen when
;  the player presses the combo.  Never blind-clicks; on a
;  miss it shows a tooltip and dumps the scan text to
;  ocr_last_miss.txt for diagnosis (proven support pattern).
; ============================================================
RunOcrAction(actionId) {
    global OcrBusy, OcrActionNeedles, OcrActionName
    global GSProWinNeedle, GSProWinExclude
    global LastActionId, LastClickX, LastClickY, LastFireTick
    global LastScanObj, LastScanTick, VerifyActionId, VerifyY, VerifyBandPx
    global LastResolveBand, LastLatticeNote
    if (!OcrActionNeedles.HasKey(actionId))
        return
    closesMenu := (actionId = "DropRehit" || actionId = "Rehit")
    now := A_TickCount
    ; Per-action minimum gap: menu-cycling actions allow rapid
    ; intentional taps (120ms absorbs only the OS auto-repeat
    ; flood); menu-closing actions hold 900ms so a repeat can
    ; never fire into the closing fade.
    minGap := closesMenu ? 900 : 120
    if (actionId = LastActionId && (now - LastFireTick) < minGap)
        return
    if (OcrBusy)
        return
    OcrBusy := true
    needles := OcrActionNeedles[actionId]

    ; FAST PATH 1 - identical repeat: the menu stack does not
    ; move while it is up, and the cursor is still hovering the
    ; button (parking waits for the burst to end).  Tap the same
    ; combo again within 4s -> click the cached spot instantly.
    if (!closesMenu && actionId = LastActionId && LastClickX
        && (now - LastFireTick) < 4000) {
        DpiRepeatClick(LastClickX, LastClickY)
        LastFireTick := A_TickCount
        SetTimer, ParkTick, -1200
        OcrBusy := false
        return
    }

    ; FAST PATH 2 - fresh scan cache: a scan taken within the
    ; last 1.5s (previous press or the scramble watcher) already
    ; contains this menu; resolve without re-scanning.
    found := false
    cx := 0
    cy := 0
    if (IsObject(LastScanObj) && (now - LastScanTick) <= 1500)
        found := ResolveOcrTarget(actionId, LastScanObj, cx, cy)

    ; FULL PATH - scan the GSPro window (up to 4 attempts).
    ; Every attempt requires the verified menu lattice (or the
    ; OB pair); a mid-animation or partial read just rescans.
    if (!found) {
        Loop, 4 {
            scan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
            if (!scan.found)
                scan := ScanScreen()   ; window title fallback
            LastScanObj := scan
            LastScanTick := A_TickCount
            found := ResolveOcrTarget(actionId, scan, cx, cy)
            if (found)
                break
            Sleep, 250
        }
    }

    if (found) {
        ; Foreground guard: a click into an inactive window can
        ; be consumed activating it, so the press never lands.
        if (IsObject(LastScanObj) && LastScanObj.HasKey("win") && LastScanObj.win.hwnd) {
            gsHwnd := LastScanObj.win.hwnd
            if (!WinActive("ahk_id " . gsHwnd)) {
                WinActivate, ahk_id %gsHwnd%
                Sleep, 150
            }
        }
        DpiClickAt(cx, cy)
        LastFireTick := A_TickCount
        if (closesMenu) {
            ; No repeat cache after a closing action; hand the
            ; fade-proof verify to a background timer so the
            ; next press is never swallowed by a busy lock.
            LastActionId := ""
            LastClickX := 0
            LastClickY := 0
            LastScanTick := 0
            VerifyActionId := actionId
            VerifyY := cy
            VerifyBandPx := LastResolveBand
            SetTimer, OcrVerifyTick, -900
        } else {
            LastActionId := actionId
            LastClickX := cx
            LastClickY := cy
        }
        SetTimer, ParkTick, -1200
    } else {
        dispName := OcrActionName.HasKey(actionId) ? OcrActionName[actionId] : actionId
        ToolTip, % dispName . " - not found on screen", 20, 20
        SetTimer, ClearOcrTip, -1800
        OcrDumpMiss("SmartClick " . actionId . " (" . LastLatticeNote . ")", scan)
    }
    OcrBusy := false
}

; Repeat click on a cached spot: cursor is already hovering it
; (hover requirement long satisfied), so a short settle + click.
DpiRepeatClick(x, y) {
    CoordMode, Mouse, Screen
    MouseMove, %x%, %y%, 0
    Sleep, 60
    Click
    Sleep, 120
}


; ============================================================
;  MENU LATTICE  (no click without verified geometry)
;
;  The relief menu is always the same five-slot stack:
;    slot 1  Move Forward
;    slot 2  Drop Ball  OR  Rehit   (the only changing word)
;    slot 3  Move Back
;    slot 4  Next Option
;    slot 5  Mulligan
;  The four UNIQUE words are anchors.  A click is authorized
;  only when 3+ anchors read, share one column, and sit on one
;  consistent pitch - that lattice then gives every slot's
;  position, so a target whose own word misread still clicks
;  correctly (slot inference), and clicking the wrong spot is
;  structurally impossible: a lone matched word, a menu mid-
;  animation, or a stray word elsewhere never forms a lattice.
;  The popup title (Lateral / Rehit / Flag Line) sits a full
;  slot above Move Forward, outside every slot band - ignored
;  by construction.
; ============================================================
FuzzyIs(t, needle) {
    nn := OcrNorm(needle)
    ll := OcrNorm(t)
    if (ll = "")
        return false
    if (InStr(ll, nn))
        return true
    tol := StrLen(nn) >= 8 ? 2 : 1
    return (LevDist(ll, nn) <= tol)
}

FindFirstFuzzy(scan, needle) {
    for i, ln in scan.lines {
        if (FuzzyIs(ln.text, needle))
            return {found: true, x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text}
    }
    return {found: false}
}

FindMenuLattice(scan) {
    global LastLatticeNote
    lat := {found: false}
    anch := {}
    cnt := 0
    hit := FindFirstFuzzy(scan, "move forward")
    if (hit.found) {
        anch[1] := hit
        cnt += 1
    }
    hit := FindFirstFuzzy(scan, "move back")
    if (hit.found) {
        anch[3] := hit
        cnt += 1
    }
    hit := FindFirstFuzzy(scan, "next option")
    if (hit.found) {
        anch[4] := hit
        cnt += 1
    }
    hit := FindFirstFuzzy(scan, "mulligan")
    if (hit.found) {
        anch[5] := hit
        cnt += 1
    }
    LastLatticeNote := "anchors=" . cnt
    if (cnt < 3)
        return lat
    ; One shared column
    xs := []
    sumW := 0
    for sIdx, a in anch {
        xs.Push(a.x + a.w // 2)
        sumW += a.w
    }
    wavg := sumW / cnt
    Loop, % xs.MaxIndex() - 1 {
        i := A_Index + 1
        j := i
        while (j > 1 && xs[j-1] > xs[j]) {
            tmp := xs[j-1]
            xs[j-1] := xs[j]
            xs[j] := tmp
            j--
        }
    }
    colX := xs[(xs.MaxIndex() + 1) // 2]
    for sIdx, a in anch {
        if (Abs((a.x + a.w // 2) - colX) > wavg * 0.6) {
            LastLatticeNote .= " colfail"
            return lat
        }
    }
    ; One consistent pitch across known anchors
    order := []
    Loop, 5 {
        if (anch.HasKey(A_Index))
            order.Push(A_Index)
    }
    pitches := []
    sumP := 0
    Loop, % order.MaxIndex() - 1 {
        a := order[A_Index]
        b := order[A_Index + 1]
        pv := ((anch[b].y + anch[b].h / 2) - (anch[a].y + anch[a].h / 2)) / (b - a)
        pitches.Push(pv)
        sumP += pv
    }
    pitch := sumP / pitches.MaxIndex()
    if (pitch <= 0) {
        LastLatticeNote .= " pitchfail"
        return lat
    }
    for i, pv in pitches {
        if (Abs(pv - pitch) > pitch * 0.2) {
            LastLatticeNote .= " pitchfail"
            return lat
        }
    }
    sumH := 0
    for sIdx, a in anch
        sumH += a.h
    havg := sumH / cnt
    if (pitch < havg * 0.7 || pitch > havg * 4.5) {
        LastLatticeNote .= " pitchrange"
        return lat
    }
    ; Slot positions from least-squares base
    base := 0
    for sIdx, a in anch
        base += (a.y + a.h / 2) - sIdx * pitch
    base := base / cnt
    slotY := []
    Loop, 5
        slotY.Push(Round(base + A_Index * pitch))
    ; Slot-2 line, when its text was readable
    s2 := {found: false}
    for i, ln in scan.lines {
        lcx := ln.x + ln.w // 2
        lcy := ln.y + ln.h // 2
        if (Abs(lcx - colX) <= wavg * 0.8 && Abs(lcy - slotY[2]) <= pitch * 0.35) {
            s2 := {found: true, x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text}
            break
        }
    }
    lat.found := true
    lat.colX := Round(colX)
    lat.pitch := pitch
    lat.slotY := slotY
    lat.anch := anch
    lat.s2 := s2
    LastLatticeNote := "anchors=" . cnt . " pitch=" . Round(pitch)
    return lat
}

; OB dialog: Mulligan and Rehit side by side on ONE row - its
; own two-word lattice.  The relief menu can never satisfy it
; (there Mulligan sits three slots BELOW the rehit slot).
FindObPair(scan) {
    for i, ln in scan.lines {
        if (!FuzzyIs(ln.text, "rehit"))
            continue
        rcy := ln.y + ln.h / 2
        for j, ln2 in scan.lines {
            if (j = i)
                continue
            if (!FuzzyIs(ln2.text, "mulligan"))
                continue
            hMax := ln.h > ln2.h ? ln.h : ln2.h
            if (Abs((ln2.y + ln2.h / 2) - rcy) < hMax * 0.8
                && Abs((ln2.x + ln2.w // 2) - (ln.x + ln.w // 2)) > ln.w) {
                return {found: true, x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text}
            }
        }
    }
    return {found: false}
}

; Resolve an action to an authorized click point.  Returns
; true and sets cx/cy; sets LastResolveBand (the vertical
; tolerance used by the background verify).
ResolveOcrTarget(actionId, scan, ByRef cx, ByRef cy) {
    global LastResolveBand
    target := 0
    if (actionId = "MoveForward")
        target := 1
    else if (actionId = "DropRehit")
        target := 2
    else if (actionId = "MoveBack")
        target := 3
    else if (actionId = "NextOption")
        target := 4
    if (target) {
        lat := FindMenuLattice(scan)
        if (!lat.found)
            return false
        LastResolveBand := Round(lat.pitch)
        if (target = 2) {
            ; The combined Drop Ball / Rehit button: click the
            ; slot whichever word it shows - even unreadable,
            ; the lattice proves which button it is.
            if (lat.s2.found) {
                cx := lat.s2.x + lat.s2.w // 2
                cy := lat.s2.y + lat.s2.h // 2
            } else {
                cx := lat.colX
                cy := lat.slotY[2]
            }
            return true
        }
        if (lat.anch.HasKey(target)) {
            a := lat.anch[target]
            cx := a.x + a.w // 2
            cy := a.y + a.h // 2
        } else {
            cx := lat.colX
            cy := lat.slotY[target]
        }
        return true
    }
    ; actionId = "Rehit": the OB dialog pair, or the relief
    ; menu's slot 2 when it is actually showing Rehit.
    pr := FindObPair(scan)
    if (pr.found) {
        LastResolveBand := Round(pr.h * 2)
        cx := pr.x + pr.w // 2
        cy := pr.y + pr.h // 2
        return true
    }
    lat := FindMenuLattice(scan)
    if (lat.found && lat.s2.found && FuzzyIs(lat.s2.text, "rehit")) {
        LastResolveBand := Round(lat.pitch)
        cx := lat.s2.x + lat.s2.w // 2
        cy := lat.s2.y + lat.s2.h // 2
        return true
    }
    return false
}

; Normalize OCR text for matching: lowercase, strip everything
; except letters and digits (spaces, punctuation, misread marks).
OcrNorm(t) {
    return RegExReplace(LowerStr(t), "[^a-z0-9]", "")
}

; ============================================================
;  SINGLE-SPACE CLICK LAYER  (the closed-loop rule)
;
;  Everything here lives in ONE coordinate space: the process's
;  screen space.  AHK v1.1 declares DPI awareness, so capture
;  (BitBlt), OCR boxes (+origin), WinGetPos, SysGet and AHK
;  mouse commands under CoordMode Screen all speak the same
;  physical pixels: screen -> bitmap -> text box -> +origin ->
;  click, with no transform anywhere.  Nothing resolution- or
;  scale-dependent can drift, because nothing converts.
;  (Proven in ProTee AutoStart at every screen and scale.)
;
;  An earlier build switched the click thread into a different
;  DPI awareness context - that introduced a SECOND coordinate
;  space into a closed loop, the one way this design can break.
;  Reverted: clicks are instant-move (no glide), hover, click,
;  all native.
; ============================================================
DpiSetCursor(x, y) {
    CoordMode, Mouse, Screen
    MouseMove, %x%, %y%, 0
}

DpiGetCursor(ByRef px, ByRef py) {
    CoordMode, Mouse, Screen
    MouseGetPos, px, py
}

DpiClickAt(x, y) {
    global ClickDelayMs
    d := ClickDelayMs ? ClickDelayMs : 1000
    CoordMode, Mouse, Screen
    MouseMove, %x%, %y%, 0
    Sleep, %d%
    Click
    Sleep, 250
}

DpiClickLine(ln) {
    DpiClickAt(ln.x + ln.w // 2, ln.y + ln.h // 2)
}

; Client-area rect of a window: excludes the title bar, borders
; and minimize/X caption entirely.  Fullscreen GSPro: identical
; to the window rect.  Windowed GSPro: the caption can never
; enter the OCR image.  Falls back to the full window rect if
; the API calls fail.
ClientRectByTitle(include, exclude := "") {
    wr := WinRectByTitle(include, exclude)
    if (!wr.found)
        return wr
    VarSetCapacity(rc, 16, 0)
    if (!DllCall("GetClientRect", "Ptr", wr.hwnd, "Ptr", &rc))
        return wr
    cw := NumGet(rc, 8, "Int")
    ch := NumGet(rc, 12, "Int")
    if (cw <= 0 || ch <= 0)
        return wr
    VarSetCapacity(pt, 8, 0)
    if (!DllCall("ClientToScreen", "Ptr", wr.hwnd, "Ptr", &pt))
        return wr
    wr.x := NumGet(pt, 0, "Int")
    wr.y := NumGet(pt, 4, "Int")
    wr.w := cw
    wr.h := ch
    return wr
}

; ScanWin, but on the client area (see ClientRectByTitle).
; Same return shape as the library's ScanWin.
ScanWinClient(include, exclude := "") {
    r := {found: false, lines: [], text: "", lc: ""}
    wr := ClientRectByTitle(include, exclude)
    if (!wr.found)
        return r
    o := OcrRegion(wr.x, wr.y, wr.w, wr.h)
    r.found := true
    r.lines := o.lines
    r.text  := o.text
    r.lc    := LowerStr(o.text)
    r.win   := wr
    return r
}

; Levenshtein edit distance, iterative two-row DP.  Menu words
; are short (< 20 chars) so this is instant.
LevDist(a, b) {
    la := StrLen(a)
    lb := StrLen(b)
    if (la = 0)
        return lb
    if (lb = 0)
        return la
    prev := []
    Loop, % lb + 1
        prev[A_Index] := A_Index - 1
    Loop, %la% {
        i := A_Index
        curr := []
        curr[1] := i
        ca := SubStr(a, i, 1)
        Loop, %lb% {
            j := A_Index
            cb := SubStr(b, j, 1)
            cost := (ca = cb) ? 0 : 1
            m := prev[j] + cost                 ; substitute
            d := prev[j + 1] + 1                ; delete
            if (d < m)
                m := d
            ins := curr[j] + 1                  ; insert
            if (ins < m)
                m := ins
            curr[j + 1] := m
        }
        prev := curr
    }
    return prev[lb + 1]
}

; Write the full text of a failed scan for diagnosis.  Every
; "OCR missed it" report is really "the wording was different
; on that machine" - this file shows the exact wording seen.
OcrDumpMiss(context, scan) {
    global ConfigDir
    f := ConfigDir . "\ocr_last_miss.txt"
    FileDelete, %f%
    body := "BARemapper OCR diagnostic`n"
    body .= "Time: " . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "`n"
    body .= "Context: " . context . "`n"
    body .= "------------------------------------------`n"
    body .= scan.text
    FileAppend, %body%, %f%
}

; ============================================================
;  AUTO-PICK SCRAMBLE WATCHER
;
;  Global option (all profiles), armed only while mapping is
;  ON.  Every 2s it scans the GSPro window for the scramble
;  shot-select cards (trigger: 2+ lines reading exactly "USE").
;  Once seen, a countdown starts (5/10/15/20s, user setting).
;  If the players pick manually, the cards vanish and the
;  countdown cancels silently.  At zero it parses the cards:
;
;    - Column per USE button (left to right = shot key 1-4,
;      matching GSPro's keyboard shortcuts)
;    - Lie line per column (FAIRWAY 2ND, GREEN 2ND, ...)
;    - Distance per column: the tallest digits-only line
;      (feet+inches on the green, yards elsewhere)
;
;  Decision: any card on the GREEN wins; several greens ->
;  shortest; no greens -> lowest distance; tie -> first card.
;  Then it SENDS THE KEYSTROKE (1-4) - no clicking involved.
;
;  Safety gate: every card's lie must be readable, and every
;  contender's distance must parse, or it stands down with a
;  tooltip + diagnostic dump and leaves the choice to people.
; ============================================================
FindAllLinesExact(scan, needle) {
    nl := LowerStr(needle)
    out := []
    for i, ln in scan.lines {
        if (LowerStr(Trim(ln.text)) = nl)
            out.Push({x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text})
    }
    return out
}

ScrambleDecide(scan, uses) {
    ; Sort USE buttons left-to-right (position = shot key number)
    n := uses.MaxIndex()
    if (n > 4)
        return 0
    Loop, % n - 1 {
        i := A_Index + 1
        j := i
        while (j > 1 && uses[j-1].x > uses[j].x) {
            tmp := uses[j-1]
            uses[j-1] := uses[j]
            uses[j] := tmp
            j--
        }
    }
    ; Column geometry: centers + half-width from adjacent gaps
    centers := []
    Loop, %n%
        centers.Push(uses[A_Index].x + uses[A_Index].w // 2)
    colHalf := uses[1].w * 17 // 10
    if (n >= 2) {
        minGap := 999999
        Loop, % n - 1 {
            g := centers[A_Index + 1] - centers[A_Index]
            if (g < minGap)
                minGap := g
        }
        if (minGap // 2 < colHalf)
            colHalf := minGap // 2
    }
    ; Parse each column: lie + shot number + distance
    colLie := [], colGreen := [], colShot := [], colDist := []
    Loop, %n% {
        c := A_Index
        cx := centers[c]
        topY := uses[c].y - uses[c].h * 9
        lieFound := ""
        isGreen := false
        shotN := 0
        distH := 0
        distClean := ""
        for i, ln in scan.lines {
            lcx := ln.x + ln.w // 2
            if (Abs(lcx - cx) > colHalf)
                continue
            if (ln.y >= uses[c].y || ln.y < topY)
                continue
            t := LowerStr(ln.text)
            ; Shot ordinal: digit followed by two letters ("3RD",
            ; "2ND"), space-tolerant - works whether it rides the
            ; lie line or OCR split it onto its own line.  Bare
            ; distances have no trailing letters, so they can
            ; never false-match.
            if (shotN = 0 && RegExMatch(ln.text, "i)([1-9])\s?[A-Za-z]{2}", ordM))
                shotN := ordM1 + 0
            if (lieFound = "") {
                lieHit := false
                if (InStr(t, "green")) {
                    lieFound := "green"
                    isGreen := true
                    lieHit := true
                } else if (InStr(t, "fairway") || InStr(t, "rough") || InStr(t, "deep")
                        || InStr(t, "tee") || InStr(t, "sand") || InStr(t, "bunker")
                        || InStr(t, "fringe") || InStr(t, "waste") || InStr(t, "native")
                        || InStr(t, "pine") || InStr(t, "recovery")) {
                    lieFound := Trim(t)
                    lieHit := true
                }
                ; Fallback when the ordinal letters mangled ("2N0"):
                ; any digit on the lie line is the shot number.
                if (lieHit && shotN = 0 && RegExMatch(ln.text, "([1-9])", shotDigit))
                    shotN := shotDigit1 + 0
            }
            ; Distance candidate: digits only after stripping marks;
            ; tallest such line in the column is the big distance.
            ; Must be taller than the USE text so tiny badge digits
            ; (1-4) can't masquerade as a distance.
            clean := RegExReplace(ln.text, "[^0-9 ]", " ")
            clean := Trim(RegExReplace(clean, " +", " "))
            if (clean != "" && RegExMatch(clean, "^\d+( \d+)?$") && ln.h > uses[c].h) {
                if (ln.h > distH) {
                    distH := ln.h
                    distClean := clean
                }
            }
        }
        colLie.Push(lieFound)
        colGreen.Push(isGreen)
        colShot.Push(shotN)
        ; Convert to inches: green = feet(+inches), else yards
        d := -1
        if (distClean != "") {
            if (InStr(distClean, " ")) {
                StringSplit, part, distClean, %A_Space%
                d := part1 * 12 + part2   ; feet + inches
            } else if (isGreen) {
                d := distClean * 12       ; feet
            } else {
                d := distClean * 36       ; yards
            }
        }
        colDist.Push(d)
    }
    ; Gate 1: every card's lie must be readable
    Loop, %n% {
        if (colLie[A_Index] = "") {
            ScrambleLogDecision(n, colLie, colShot, colDist, 0, 0, "GATE: lie unreadable")
            return 0
        }
    }
    ; Shot numbers: if NONE were readable, everyone is treated
    ; as equal (the original behavior, proven live).  If only
    ; SOME read, the comparison would be a guess - stand down.
    knownShots := 0
    Loop, %n% {
        if (colShot[A_Index] >= 1)
            knownShots += 1
    }
    if (knownShots = 0) {
        Loop, %n%
            colShot[A_Index] := 1
    } else if (knownShots < n) {
        ScrambleLogDecision(n, colLie, colShot, colDist, 0, 0, "GATE: shot numbers partial")
        return 0
    }
    ; PENALTY RULE: the fewest-strokes balls are considered
    ; FIRST, absolutely.  A 2nd-shot ball always beats a closer
    ; 3rd-shot ball (someone who took a penalty drop may sit
    ; closer, but choosing them costs the group a stroke).
    minShot := 99
    Loop, %n% {
        if (colShot[A_Index] < minShot)
            minShot := colShot[A_Index]
    }
    ; Green check runs among the eligible (fewest-shot) balls
    anyGreen := false
    Loop, %n% {
        if (colShot[A_Index] = minShot && colGreen[A_Index])
            anyGreen := true
    }
    ; Decision within eligible: green first, then lowest
    ; distance; tie -> first card
    bestIdx := 0
    bestVal := 0x7FFFFFFF
    Loop, %n% {
        c := A_Index
        if (colShot[c] != minShot)
            continue
        if (anyGreen && !colGreen[c])
            continue
        ; Gate 2: contender distances must parse
        if (colDist[c] < 0) {
            ScrambleLogDecision(n, colLie, colShot, colDist, minShot, 0, "GATE: contender distance unreadable")
            return 0
        }
        if (colDist[c] < bestVal) {
            bestVal := colDist[c]
            bestIdx := c
        }
    }
    ScrambleLogDecision(n, colLie, colShot, colDist, minShot, bestIdx, "OK")
    return bestIdx
}

; Written on EVERY pick attempt, success or stand-down, so any
; wrong or missing pick arrives with its own explanation:
; Documents\BA Custom Products\Remapper\scramble_last_decision.txt
ScrambleLogDecision(n, colLie, colShot, colDist, minShot, winner, note) {
    global ConfigDir
    f := ConfigDir . "\scramble_last_decision.txt"
    FileDelete, %f%
    b := "BARemapper scramble decision`n"
    b .= "Time: " . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "`n"
    b .= "Cards: " . n . "   MinShot: " . minShot . "   Winner: " . winner . "   " . note . "`n"
    Loop, %n%
        b .= "  card " . A_Index . ": lie=" . colLie[A_Index] . "  shot=" . colShot[A_Index] . "  dist_inches=" . colDist[A_Index] . "`n"
    FileAppend, %b%, %f%
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
SeedPresetProfiles()
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
Menu, Tray, Add, OCR Test (dump screen text), TrayOcrDump
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

; AUTO-PICK SCRAMBLE (global - applies to every profile)
scramChecked := ScrambleAutoPick ? 1 : 0
Gui, Main:Add, Checkbox, x30 y338 w250 vScramblePickCheck gOnScrambleToggle Checked%scramChecked%, Auto-Pick Scramble Shot (all profiles)
Gui, Main:Font, s9 cCCCCCC Normal, Segoe UI
Gui, Main:Add, Text, x290 y340 w55 Right, Delay:
Gui, Main:Font, s9 c000000 Normal, Segoe UI
Gui, Main:Add, DropDownList, x350 y336 w110 vScrambleDelayChoice gOnScrambleDelayChange, 5 seconds|10 seconds|15 seconds|20 seconds
GuiControl, Main:ChooseString, ScrambleDelayChoice, %ScrambleDelaySec% seconds
Gui, Main:Font, s10 cCCCCCC Normal, Segoe UI
cdChecked := ScrambleCountdown ? 1 : 0
Gui, Main:Add, Checkbox, x30 y368 w400 vScrambleCdCheck gOnScrambleCdToggle Checked%cdChecked%, Show on-screen countdown before auto-pick

Gui, Main:Add, Text, x30 y400 w420 0x10

; FILE LOCATION + ACCESS
Gui, Main:Font, s9 c999999 Normal, Segoe UI
Gui, Main:Add, Text, x30 y410 w430, Files are saved at:
Gui, Main:Font, s9 cWhite Normal, Consolas
Gui, Main:Add, Text, x30 y426 w430, %ConfigDir%

Gui, Main:Font, s9 c000000 Normal, Segoe UI
Gui, Main:Add, Button, x30  y450 w100 h28 gOnOpenFolder, Open Folder
Gui, Main:Add, Button, x136 y450 w110 h28 gOnCleanup,    Cleanup / Reset
Gui, Main:Add, Button, x252 y450 w95  h28 gTrayOcrDump,  OCR Test
Gui, Main:Add, Button, x353 y450 w107 h28 gShowHelp,     Help / Guide

Gui, Main:Add, Text, x30 y486 w420 0x10

; FOOTER
Gui, Main:Font, s9 cAAAAAA Normal, Segoe UI
Gui, Main:Add, Text, x20 y494 w440 Center, Ctrl+F12 toggles ON/OFF    |    Turn OFF to type normally

Gui, Main:Font, s10 c000000 Normal, Segoe UI
Gui, Main:Add, Button, x95  y516 w140 h35 gMinimizeMain, Minimize to Tray
Gui, Main:Add, Button, x245 y516 w140 h35 gDoFullExit,   Exit

LoadWindowPos(wx, wy)
if (isStartupLaunch) {
    ; Boot launch - create window hidden so user sees no flash
    Gui, Main:Show, Hide w480 h566
} else if (wx = "CENTER" || wy = "CENTER") {
    Gui, Main:Show, w480 h566
} else {
    Gui, Main:Show, w480 h566 x%wx% y%wy%
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
    TrayTip, BA Remapper, Mapping is ACTIVE  (profile: %ActiveProfile%)  -  double-click the tray icon to open, 10, 1
}

; Trigger-file polling for reopen
SetTimer, CheckTriggerFile, 500

; Auto-Pick Scramble watcher (self-gates on RemapActive + setting)
SetTimer, ScrambleTick, 2000

; Countdown overlay updater (light, no OCR)
SetTimer, CdTick, 500

; One-shot OCR engine warm-up in the background
SetTimer, OcrWarmup, -3000
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
    if (IsPresetProfile(ActiveProfile)) {
        MsgBox, 64, Built-In Preset, "%ActiveProfile%" is a built-in preset and cannot be renamed.
        Return
    }
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
    if (IsPresetProfile(ActiveProfile)) {
        MsgBox, 4, Built-In Preset, "%ActiveProfile%" is a built-in preset.`n`nRestore it to factory defaults?
        IfMsgBox, Yes
        {
            SeedPresetProfiles()
            LoadProfile(ActiveProfile)
            RefreshBuilderIfOpen()
            TrayTip, BA Remapper, Basic Secondary restored to factory defaults, 3, 1
        }
        Return
    }
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

OnScrambleToggle:
    Gui, Main:Submit, NoHide
    ScrambleAutoPick := ScramblePickCheck ? true : false
    ScrambleArmedTick := 0
    ScrambleCoolDown := false
    SaveSettings()
    if (ScrambleAutoPick)
        TrayTip, BA Remapper, Auto-Pick Scramble ON (%ScrambleDelaySec%s delay) - watching while the app runs, 3, 1
Return

OnScrambleCdToggle:
    Gui, Main:Submit, NoHide
    ScrambleCountdown := ScrambleCdCheck ? true : false
    SaveSettings()
    if (!ScrambleCountdown && CdVisible) {
        Gui, Countdown:Destroy
        CdVisible := false
    }
Return

OnScrambleDelayChange:
    Gui, Main:Submit, NoHide
    newDelay := ScrambleDelayChoice
    StringReplace, newDelay, newDelay, %A_Space%seconds
    newDelay += 0
    if (newDelay = 5 || newDelay = 10 || newDelay = 15 || newDelay = 20)
        ScrambleDelaySec := newDelay
    SaveSettings()
Return

; ============================================================
;  OCR / SCRAMBLE TIMER LABELS
;  (Labels live BELOW the auto-execute section - top-level
;  label code would otherwise run at launch and its Return
;  would kill the init.  Functions are safe anywhere.)
; ============================================================
ClearOcrTip:
    ToolTip
Return

; Background fade-proof verify for menu-closing smart clicks:
; runs AFTER the busy lock is released so rapid follow-up
; presses are never swallowed.  A swallowed click leaves the
; button in place indefinitely; a closing fade is gone well
; before the second look - only a persistent button earns the
; single retry.
OcrVerifyTick:
    if (VerifyActionId = "")
        Return
    if (OcrBusy) {
        SetTimer, OcrVerifyTick, -300
        Return
    }
    OcrBusy := true
    vScan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
    vx := 0
    vy := 0
    vFound := ResolveOcrTarget(VerifyActionId, vScan, vx, vy)
    if (vFound && Abs(vy - VerifyY) < VerifyBandPx) {
        Sleep, 450
        vScan2 := ScanWinClient(GSProWinNeedle, GSProWinExclude)
        vFound2 := ResolveOcrTarget(VerifyActionId, vScan2, vx, vy)
        if (vFound2 && Abs(vy - VerifyY) < VerifyBandPx) {
            DpiClickAt(vx, vy)
            DpiSetCursor(0, 0)
        }
    }
    VerifyActionId := ""
    OcrBusy := false
Return

; Parks the cursor at the corner once a click burst ends (kept
; hovering between rapid repeats so repeat clicks are instant).
ParkTick:
    if (A_TickCount - LastFireTick >= 1100 && !OcrBusy) {
        DpiSetCursor(0, 0)
        LastActionId := ""
        LastClickX := 0
        LastClickY := 0
    } else {
        SetTimer, ParkTick, -400
    }
Return

; Countdown overlay tick: light 500ms timer, no OCR.  Shows
; "Auto-pick: Ns" over the GSPro window while the scramble
; watcher is armed.  The overlay is click-through and excluded
; from screen capture (SetWindowDisplayAffinity 0x11) so the
; OCR can never read its own countdown; even on Windows builds
; where the affinity call is unavailable, the text and its
; position are chosen so no needle or card column matches it.
CdTick:
    if (!ScrambleCountdown || !ScrambleAutoPick || ScrambleArmedTick = 0 || ScrambleCoolDown) {
        if (CdVisible) {
            Gui, Countdown:Destroy
            CdVisible := false
        }
        Return
    }
    cdWr := WinRectByTitle(GSProWinNeedle, GSProWinExclude)
    if (!cdWr.found) {
        if (CdVisible) {
            Gui, Countdown:Destroy
            CdVisible := false
        }
        Return
    }
    cdRemain := ScrambleDelaySec - ((A_TickCount - ScrambleArmedTick) // 1000)
    if (cdRemain < 0)
        cdRemain := 0
    cdY := cdWr.y + Round(cdWr.h * 0.55)
    if (!CdVisible) {
        Gui, Countdown:Destroy
        ; +Hwnd stores the handle DIRECTLY into CdHwndVar - no
        ; reliance on the last-found window (an empty handle
        ; made WinGetPos return blanks, blank math reached the
        ; Show command, and AHK threw "Invalid option: x").
        Gui, Countdown:New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 +HwndCdHwndVar
        Gui, Countdown:Color, 111111
        Gui, Countdown:Margin, 18, 12
        Gui, Countdown:Font, s22 cFFD400 Bold, Segoe UI
        Gui, Countdown:Add, Text, vCdText, Auto-pick: %cdRemain%s
        ; AutoSize: the DPI scale decides the real pixel height
        ; of the font, so let the window fit the text instead of
        ; forcing a fixed height (fixed h clipped at 150% DPI).
        Gui, Countdown:Show, Hide AutoSize
        WinGetPos, , , CdWinW, CdWinH, ahk_id %CdHwndVar%
        if (CdWinW = "" || CdWinW < 50)
            CdWinW := 320
        cdX := cdWr.x + (cdWr.w - CdWinW) // 2
        if (cdX = "" || cdX < 0)
            cdX := 100
        Gui, Countdown:Show, x%cdX% y%cdY% NoActivate
        DllCall("SetWindowDisplayAffinity", "Ptr", CdHwndVar, "UInt", 0x11)
        CdVisible := true
    } else {
        GuiControl, Countdown:, CdText, Auto-pick: %cdRemain%s
        cdX := cdWr.x + (cdWr.w - CdWinW) // 2
        if (cdX = "" || cdX < 0)
            cdX := 100
        Gui, Countdown:Show, x%cdX% y%cdY% NoActivate
    }
Return

; Tray-menu diagnostic: dump exactly what the OCR reads right
; now (GSPro window if found, else all monitors) with line
; coordinates.  This is the tuning loop for needles and the
; scramble trigger on any machine.
TrayOcrDump:
    dScan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
    dMode := "GSPro window client area (title contains 'gspro')"
    if (!dScan.found) {
        dScan := ScanScreen()
        dMode := "FULL SCREEN (no window title containing 'gspro' was found!)"
    }
    dFile := ConfigDir . "\ocr_last_scan.txt"
    FileDelete, %dFile%
    dBody := "BARemapper OCR test dump`n"
    dBody .= "Time: " . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "`n"
    dBody .= "Scanned: " . dMode . "`n"
    dBody .= "Lines found: " . (dScan.lines.MaxIndex() = "" ? 0 : dScan.lines.MaxIndex()) . "`n"
    dBody .= "------------------------------------------`n"
    for dI, dLn in dScan.lines
        dBody .= dLn.x . "," . dLn.y . "  " . dLn.w . "x" . dLn.h . "  |" . dLn.text . "|`n"
    FileAppend, %dBody%, %dFile%
    TrayTip, BA Remapper, OCR dump written to ocr_last_scan.txt, 4, 1
    Run, notepad.exe "%dFile%"
Return

; One-time OCR engine warm-up (first call pays ~1s engine
; init; do it in the background at launch, not on the first
; real button press at the tee).
OcrWarmup:
    OcrRegion(0, 0, 48, 48)
    OcrWarmedUp := true
Return

ScrambleTick:
    if (ScrambleBusy)
        Return
    ScrambleBusy := true
    Gosub, ScrambleWork
    ScrambleBusy := false
Return

ScrambleWork:
    ; Watches whenever the checkbox is ON and the app is running
    ; (not tied to the mapping toggle - the cards themselves are
    ; the safety: nothing happens unless 2+ USE buttons are seen).
    if (!ScrambleAutoPick) {
        ScrambleArmedTick := 0
        ScrambleCoolDown := false
        Return
    }
    scrScan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
    if (!scrScan.found) {
        ; GSPro window title not matched - fall back to a full
        ; screen scan, throttled to every 3rd tick (6s) since
        ; whole-screen OCR is heavier.
        ScrambleFbTick += 1
        if (Mod(ScrambleFbTick, 3) != 0)
            Return
        scrScan := ScanScreen()
    } else {
        ScrambleFbTick := 0
    }
    scrUses := FindAllLinesExact(scrScan, "use")
    useCount := scrUses.MaxIndex()
    if (useCount = "" || useCount < 2) {
        ; Card screen not present - reset all arming state
        ScrambleArmedTick := 0
        ScrambleCoolDown := false
        ScrambleDumped := false
        Return
    }
    if (ScrambleCoolDown)
        Return   ; already acted on this appearance; wait for it to clear
    if (ScrambleArmedTick = 0) {
        ScrambleArmedTick := A_TickCount
        Return
    }
    if (A_TickCount - ScrambleArmedTick < ScrambleDelaySec * 1000)
        Return
    winner := ScrambleDecide(scrScan, scrUses)
    if (winner > 0) {
        if (scrScan.HasKey("win") && scrScan.win.hwnd) {
            scrHwnd := scrScan.win.hwnd
            if (!WinActive("ahk_id " . scrHwnd)) {
                WinActivate, ahk_id %scrHwnd%
                Sleep, 150
            }
        }
        Send, %winner%
        TrayTip, BA Remapper, Auto-picked scramble shot %winner%, 3, 1
    } else {
        if (!ScrambleDumped) {
            OcrDumpMiss("Scramble parse failure", scrScan)
            ToolTip, Auto-pick: could not read all cards - please pick manually, 20, 20
            SetTimer, ClearOcrTip, -2500
            ScrambleDumped := true
        }
    }
    ; Either way: done with this appearance of the screen
    ScrambleCoolDown := true
    ScrambleArmedTick := 0
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
    GSPro Hotkey: FN + button sends a keyboard key
      (includes Select Shot 1-4 for scrambles)
    Smart Click (OCR): FN + button READS THE SCREEN, finds
      the GSPro menu button by its text, and clicks it.
      No setup, works at any resolution.  Actions: Move
      Forward, Move Back, Next Option, Drop Ball / Rehit,
      OB Rehit.  Needs Windows 10 or 11.
    Taught Screen Click: FN + button clicks a fixed spot
      you captured (the old way - still available).
    Speed: keep FN held and tap the button repeatedly -
      consecutive presses of the same Smart Click fire
      instantly (Next Option a few times in a row, or
      walking the ball with Move Forward / Move Back).

    BUILT-IN PRESET: "Basic Secondary"
    Pick "Basic Secondary" in the profile dropdown and the
    yellow print on your control box just works - zero
    programming: Clear View on Club Down, OB Rehit on Tee
    Left, Move Forward/Back on Aim Up/Down, Next Option on
    Aim Left, Drop Ball / Rehit on Aim Right.
    Basic Secondary is locked - it cannot be edited, reset,
    or renamed, so it always works exactly like the print on
    the box.  To customize, create a new profile.  Pressing
    Del on it restores it to factory defaults instantly.

    AUTO-PICK SCRAMBLE
    Turn on the checkbox on the main window and BARemapper
    watches for GSPro's scramble shot-select cards the whole
    time it is running.  After your chosen delay (5-20s) it picks
    the best ball automatically by pressing its shot key.
    Balls hitting the FEWEST strokes are considered first -
    a 2nd-shot ball always beats a closer 3rd-shot ball from
    a penalty drop.  Among those, a ball on the GREEN always
    wins; otherwise the lowest number.  Pick manually any time - if the cards close,
    the countdown just cancels.  If the cards cannot be
    read, it does nothing and lets you choose.
    An on-screen countdown ("Auto-pick: 12s") shows above
    the cards while the timer runs - turn it off with the
    "Show on-screen countdown" checkbox if you prefer.
    These settings apply to ALL profiles.

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

    ; Top row  (yellow text under each button = its secondary
    ; function, exactly like the yellow print on the real box)
    Gui, Builder:Font, s9 c000000 Normal, Segoe UI
    Gui, Builder:Add, Button, x55  y110 w85 h85 Disabled     vBtnMulligan, MULLIGAN`nCtrl+M
    Gui, Builder:Add, Button, x280 y110 w85 h85 gBtnHeatmap  vBtnHeatmap,  HEAT MAP`nY
    Gui, Builder:Add, Button, x505 y110 w85 h85 gBtnPutt     vBtnPutt,     PUTT`nU
    Gui, Builder:Add, Button, x800 y110 w85 h85 gBtnFlyover  vBtnFlyover,  FLYOVER`nO
    Gui, Builder:Font, s8 cFFD400 Bold, Segoe UI
    Gui, Builder:Add, Text, x262 y197 w121 Center vSecHeatmap,
    Gui, Builder:Add, Text, x487 y197 w121 Center vSecPutt,
    Gui, Builder:Add, Text, x782 y197 w121 Center vSecFlyover,

    ; Up arrows (panel print)
    Gui, Builder:Font, s11 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x222 y198 w20 Center, ^
    Gui, Builder:Add, Text, x677 y198 w20 Center, ^

    ; Second row: CLUB UP (left) and AIM UP (right)
    Gui, Builder:Font, s9 c000000 Normal, Segoe UI
    Gui, Builder:Add, Button, x190 y218 w85 h85 gBtnClubup vBtnClubup, CLUB UP`nI
    Gui, Builder:Add, Button, x645 y218 w85 h85 gBtnUp     vBtnUp,     AIM UP`nUp
    Gui, Builder:Font, s8 cFFD400 Bold, Segoe UI
    Gui, Builder:Add, Text, x172 y305 w121 Center vSecClubup,
    Gui, Builder:Add, Text, x627 y305 w121 Center vSecUp,

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
    Gui, Builder:Font, s8 cFFD400 Bold, Segoe UI
    Gui, Builder:Add, Text, x517 y417 w121 Center vSecLeft,
    Gui, Builder:Add, Text, x787 y417 w121 Center vSecRight,

    ; Fourth row: CLUB DOWN (left) and AIM DOWN (right)
    Gui, Builder:Font, s9 c000000 Normal, Segoe UI
    Gui, Builder:Add, Button, x190 y440 w85 h85 gBtnClubdown vBtnClubdown, CLUB DOWN`nK
    Gui, Builder:Add, Button, x645 y440 w85 h85 gBtnDown     vBtnDown,     AIM DOWN`nDown
    Gui, Builder:Font, s8 cFFD400 Bold, Segoe UI
    Gui, Builder:Add, Text, x172 y527 w121 Center vSecClubdown,
    Gui, Builder:Add, Text, x627 y527 w121 Center vSecDown,

    ; Down arrows (beside the buttons) + TEE POS panel print
    Gui, Builder:Font, s11 cWhite Bold, Segoe UI
    Gui, Builder:Add, Text, x162 y478 w20 Center, v
    Gui, Builder:Add, Text, x740 y478 w20 Center, v
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
    Gui, Builder:Font, s8 cFFD400 Bold, Segoe UI
    Gui, Builder:Add, Text, x42  y639 w121 Center vSecResetaim,
    Gui, Builder:Add, Text, x372 y639 w121 Center vSecTeeleft,
    Gui, Builder:Add, Text, x547 y639 w121 Center vSecTeeright,
    Gui, Builder:Add, Text, x787 y639 w121 Center vSecShotcam,

    ; Bottom action buttons
    Gui, Builder:Font, s11 cWhite Bold, Segoe UI
    Gui, Builder:Add, Button, x340 y662 w150 h40 gBuilderReset, Reset Profile
    Gui, Builder:Add, Button, x510 y662 w150 h40 gBuilderClose, Close

    Gui, Builder:Font, s9 cC8E6C2 Normal, Segoe UI
    Gui, Builder:Add, Text, x20 y712 w940 Center vBuilderStatus, Click a button to set its FN secondary  -  yellow text = current secondary  -  auto-saves

    UpdateBuilderLabels()

    Gui, Builder:Show, w980 h748
Return

OnFnChange:
    Gui, Builder:Submit, NoHide
    if (IsPresetProfile(ActiveProfile)) {
        for revName, revId in FnChoiceMap {
            if (revId = FnButtonId) {
                GuiControl, Builder:ChooseString, FnChoice, %revName%
                break
            }
        }
        GuiControl, Builder:, BuilderStatus, %ActiveProfile% is a built-in preset - create a new profile to customize
        Return
    }
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
    global OcrActionList, OcrActionName, OcrActionByName
    global CfgTypeKey, CfgTypeOcr, CfgTypeClick, CfgTypeNone
    global CfgKeyChoice, CfgOcrChoice, CfgClickPos, CfgCapturedX, CfgCapturedY
    if (IsPresetProfile(ActiveProfile)) {
        Gui, Builder:+OwnDialogs
        MsgBox, 64, Built-In Preset, "%ActiveProfile%" is a built-in preset and cannot be changed.`n`nTo customize: create a new profile (+ New on the main window) and set it up in the Builder.
        Return
    }
    ConfiguringBtnId := btnIdVal
    ConfiguringDisplayName := displayName

    curType := SecType.HasKey(btnIdVal) ? SecType[btnIdVal] : "none"
    curVal  := SecValue.HasKey(btnIdVal) ? SecValue[btnIdVal] : ""
    CfgCapturedX := SecX.HasKey(btnIdVal) ? SecX[btnIdVal] : 0
    CfgCapturedY := SecY.HasKey(btnIdVal) ? SecY[btnIdVal] : 0

    Gui, Cfg:Destroy
    Gui, Cfg:New, +AlwaysOnTop +OwnerBuilder, %displayName% - Secondary Function
    Gui, Cfg:Color, 1a1a2e
    Gui, Cfg:Font, s11 cWhite Bold, Segoe UI
    Gui, Cfg:Add, Text, x15 y10 w370, FN + %displayName%
    Gui, Cfg:Font, s9 cCCCCCC Normal, Segoe UI
    Gui, Cfg:Add, Text, x15 y32 w370, Primary key (%primaryKey%) always works alone. This sets the FN layer.

    Gui, Cfg:Font, s10 cWhite Normal, Segoe UI
    Gui, Cfg:Add, Radio, x15 y62 w360 vCfgTypeKey Group, GSPro Hotkey - send a keyboard key
    Gui, Cfg:Font, s9 c000000 Normal, Segoe UI
    Gui, Cfg:Add, DropDownList, x35 y86 w330 vCfgKeyChoice, %GSProActions%

    Gui, Cfg:Font, s10 cWhite Normal, Segoe UI
    Gui, Cfg:Add, Radio, x15 y122 w360 vCfgTypeOcr, Smart Click - reads the screen, clicks the menu button
    Gui, Cfg:Font, s9 c000000 Normal, Segoe UI
    Gui, Cfg:Add, DropDownList, x35 y146 w330 vCfgOcrChoice, %OcrActionList%

    Gui, Cfg:Font, s10 cWhite Normal, Segoe UI
    Gui, Cfg:Add, Radio, x15 y182 w360 vCfgTypeClick, Taught Screen Click - a fixed position you capture
    Gui, Cfg:Font, s9 c000000 Normal, Segoe UI
    Gui, Cfg:Add, Button, x35 y206 w150 h24 gCfgCapture, Capture Position
    Gui, Cfg:Font, s9 cCCCCCC Normal, Segoe UI
    Gui, Cfg:Add, Text, x195 y210 w180 vCfgClickPos, (none captured)

    Gui, Cfg:Font, s10 cWhite Normal, Segoe UI
    Gui, Cfg:Add, Radio, x15 y242 w360 vCfgTypeNone, None - FN + this button does nothing

    Gui, Cfg:Font, s10 c000000 Normal, Segoe UI
    Gui, Cfg:Add, Button, x70 y280 w120 h32 gCfgOK, Save
    Gui, Cfg:Add, Button, x210 y280 w120 h32 gCfgCancel, Cancel

    ; Preselect from the button's current configuration
    if (curType = "key") {
        GuiControl, Cfg:, CfgTypeKey, 1
        if (GSProNameMap.HasKey(curVal))
            GuiControl, Cfg:ChooseString, CfgKeyChoice, % GSProNameMap[curVal]
    } else if (curType = "ocr") {
        GuiControl, Cfg:, CfgTypeOcr, 1
        if (OcrActionName.HasKey(curVal))
            GuiControl, Cfg:ChooseString, CfgOcrChoice, % OcrActionName[curVal]
    } else if (curType = "click") {
        GuiControl, Cfg:, CfgTypeClick, 1
        GuiControl, Cfg:, CfgClickPos, % "at " . CfgCapturedX . ", " . CfgCapturedY
    } else {
        GuiControl, Cfg:, CfgTypeNone, 1
        GuiControl, Cfg:ChooseString, CfgKeyChoice, None
    }
    Gui, Cfg:Show, w390 h328
}

CfgCapture:
    ; Capture a screen position: hide our windows, wait for a click
    Gui, Cfg:Hide
    Gui, Builder:Hide
    Sleep, 300
    ToolTip, Click the screen position for FN + %ConfiguringDisplayName%`nPress Esc to cancel, 10, 10
    capX := ""
    capY := ""
    capCancelled := false
    Loop {
        if (GetKeyState("Escape", "P")) {
            capCancelled := true
            break
        }
        if (GetKeyState("LButton", "P")) {
            DpiGetCursor(capX, capY)
            KeyWait, LButton
            break
        }
        Sleep, 30
    }
    ToolTip
    Gui, Builder:Show
    Gui, Cfg:Show
    if (!capCancelled) {
        CfgCapturedX := capX
        CfgCapturedY := capY
        GuiControl, Cfg:, CfgClickPos, % "at " . capX . ", " . capY
        GuiControl, Cfg:, CfgTypeClick, 1
    }
Return

CfgOK:
    Gui, Cfg:Submit, NoHide
    if (CfgTypeKey) {
        sendKey := GSProKeyMap.HasKey(CfgKeyChoice) ? GSProKeyMap[CfgKeyChoice] : ""
        if (sendKey = "") {
            ; "None" or no selection = no secondary
            SecType[ConfiguringBtnId]  := "none"
            SecValue[ConfiguringBtnId] := ""
        } else {
            SecType[ConfiguringBtnId]  := "key"
            SecValue[ConfiguringBtnId] := sendKey
        }
        SecX[ConfiguringBtnId] := 0
        SecY[ConfiguringBtnId] := 0
    } else if (CfgTypeOcr) {
        if (!OcrActionByName.HasKey(CfgOcrChoice)) {
            Gui, Cfg:+OwnDialogs
            MsgBox, 48, Pick an action, Choose a Smart Click action from the list first.
            Return
        }
        SecType[ConfiguringBtnId]  := "ocr"
        SecValue[ConfiguringBtnId] := OcrActionByName[CfgOcrChoice]
        SecX[ConfiguringBtnId] := 0
        SecY[ConfiguringBtnId] := 0
    } else if (CfgTypeClick) {
        if (CfgCapturedX = "" || (CfgCapturedX = 0 && CfgCapturedY = 0)) {
            Gui, Cfg:+OwnDialogs
            MsgBox, 48, No position, Click "Capture Position" first to teach the screen spot.
            Return
        }
        SecType[ConfiguringBtnId]  := "click"
        SecValue[ConfiguringBtnId] := ""
        SecX[ConfiguringBtnId] := CfgCapturedX
        SecY[ConfiguringBtnId] := CfgCapturedY
    } else {
        SecType[ConfiguringBtnId]  := "none"
        SecValue[ConfiguringBtnId] := ""
        SecX[ConfiguringBtnId] := 0
        SecY[ConfiguringBtnId] := 0
    }
    Gui, Cfg:Destroy
    SaveProfile(ActiveProfile)
    UpdateBuilderLabels()
    GuiControl, Builder:, BuilderStatus, % ConfiguringDisplayName . ": secondary updated  (saved)"
Return

CfgCancel:
CfgGuiClose:
    Gui, Cfg:Destroy
Return

; ============================================================
;  UPDATE BUILDER LABELS
; ============================================================
UpdateBuilderLabels() {
    UpdateOneLabel("heatmap",  "BtnHeatmap",  "SecHeatmap",  "HEAT MAP",  "Y")
    UpdateOneLabel("putt",     "BtnPutt",     "SecPutt",     "PUTT",      "U")
    UpdateOneLabel("flyover",  "BtnFlyover",  "SecFlyover",  "FLYOVER",   "O")
    UpdateOneLabel("clubup",   "BtnClubup",   "SecClubup",   "CLUB UP",   "I")
    UpdateOneLabel("left",     "BtnLeft",     "SecLeft",     "AIM LEFT",  "Left")
    UpdateOneLabel("up",       "BtnUp",       "SecUp",       "AIM UP",    "Up")
    UpdateOneLabel("right",    "BtnRight",    "SecRight",    "AIM RIGHT", "Right")
    UpdateOneLabel("resetaim", "BtnResetaim", "SecResetaim", "RESET AIM", "A")
    UpdateOneLabel("down",     "BtnDown",     "SecDown",     "AIM DOWN",  "Down")
    UpdateOneLabel("teeleft",  "BtnTeeleft",  "SecTeeleft",  "TEE LEFT",  "C")
    UpdateOneLabel("teeright", "BtnTeeright", "SecTeeright", "TEE RIGHT", "V")
    UpdateOneLabel("shotcam",  "BtnShotcam",  "SecShotcam",  "SHOT CAM",  "J")
    UpdateOneLabel("clubdown", "BtnClubdown", "SecClubdown", "CLUB DOWN", "K")
}

UpdateOneLabel(btnIdVal, ctrlName, secCtrl, dispName, priKey) {
    global FnButtonId, SecType, SecValue
    label := dispName . "`n" . priKey
    if (btnIdVal = FnButtonId)
        label := "[FN]`n" . dispName . "`n" . priKey
    GuiControl, Builder:, %ctrlName%, %label%
    ; Yellow panel print under the button = the secondary
    sec := ""
    if (btnIdVal = FnButtonId) {
        sec := "FN / SHIFT KEY"
    } else if (SecType.HasKey(btnIdVal) && SecType[btnIdVal] != "none" && SecType[btnIdVal] != "") {
        if (SecType[btnIdVal] = "key")
            sec := YellowKeyName(SecValue[btnIdVal])
        else if (SecType[btnIdVal] = "ocr")
            sec := YellowOcrName(SecValue[btnIdVal])
        else if (SecType[btnIdVal] = "click")
            sec := "SCREEN CLICK"
    }
    GuiControl, Builder:, %secCtrl%, %sec%
}

; Short yellow-print name for a key-type secondary
YellowKeyName(sendKey) {
    global GSProNameMap
    name := GSProNameMap.HasKey(sendKey) ? GSProNameMap[sendKey] : sendKey
    ; strip a "X - " prefix if present
    pos := InStr(name, " - ")
    if (pos)
        name := SubStr(name, pos + 3)
    ; keep only the first alternative of "A / B" names
    pos := InStr(name, " / ")
    if (pos)
        name := SubStr(name, 1, pos - 1)
    StringUpper, name, name
    if (StrLen(name) > 17)
        name := SubStr(name, 1, 17)
    return name
}

; Short yellow-print name for a Smart Click secondary
YellowOcrName(actionId) {
    if (actionId = "MoveForward")
        return "MOVE FORWARD"
    if (actionId = "MoveBack")
        return "MOVE BACK"
    if (actionId = "NextOption")
        return "NEXT OPTION"
    if (actionId = "DropRehit")
        return "DROP/REHIT"
    if (actionId = "Rehit")
        return "OB REHIT"
    return actionId
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
    if (IsPresetProfile(ActiveProfile)) {
        MsgBox, 64, Built-In Preset, "%ActiveProfile%" is a built-in preset and cannot be reset or changed.`n`nTo customize: create a new profile (+ New on the main window).
        Return
    }
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
    global ActiveProfile
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

; ============================================================================
;  INLINED: OCR_Library.ahk  (Windows built-in OCR, BA Custom Products)
;  Inlined rather than #Include'd so the single-file compile carries it.
; ============================================================================
; ============================================================================
;  OCR_Library.ahk  -  Windows built-in OCR for AutoHotkey v1.1
;  BA Custom Products
; ----------------------------------------------------------------------------
;  Screen-reading via the OCR engine built into Windows 10/11
;  (Windows.Media.Ocr WinRT API). Nothing to install on the target PC.
;  Proven in production in ProTee AutoStart.
;
;  REQUIREMENTS
;    - Windows 10 or 11 (needs a language pack with OCR support; English is
;      standard). Works compiled or as a plain script, ANSI or Unicode AHK v1.1.
;    - Host script should set:  CoordMode, Mouse, Screen
;      All coordinates in and out of this library are absolute physical screen
;      pixels (multi-monitor safe, DPI-scaling safe).
;
;  QUICK START
;      #NoEnv
;      SetBatchLines, -1
;      CoordMode, Mouse, Screen
;      #Include OCR_Library.ahk
;      scan := ScanScreen()                 ; OCR every monitor
;      hit := FindLine(scan, "log in")      ; case-insensitive, single line
;      if (hit.found)
;          ClickLineObj(hit)                ; click the center of that text
;
;  MAIN API
;    ScanScreen()             OCR all monitors. Returns scan object.
;    ScanWin(incl, excl:="")  OCR one window found by title substring.
;    OcrRegion(x, y, w, h)    OCR any screen rectangle.
;      -> all return: { lines: [ {text, x, y, w, h}, ... ], text: "all text" }
;         plus .lc (lowercased .text) on ScanScreen/ScanWin, and .win on ScanWin.
;    FindLine(scan, needle)       first line CONTAINING needle (case-insens.)
;    FindLineExact(scan, needle)  first line whose whole text equals needle
;      -> { found, x, y, w, h, text }
;    ClickLineObj(line)       move to line center, pause, click
;    ClickAt(x, y)            pause length: global ClickDelayMs (default 1000ms)
;    WinRectByTitle(incl, excl:="")  locate a window by title substring
;    MonitorOf(x, y)          bounds of the monitor containing a point
; ============================================================================

global ClickDelayMs := 1000    ; ms to wait after moving the cursor, before clicking

OcrDebug(msg) {
    OutputDebug, % "[OCR] " msg
}

WinRectByTitle(include, exclude := "") {
    incL := LowerStr(include)
    excL := LowerStr(exclude)
    WinGet, idList, List
    Loop, %idList% {
        id := idList%A_Index%
        WinGetTitle, t, ahk_id %id%
        if (t = "")
            continue
        tl := LowerStr(t)
        if (!InStr(tl, incL))
            continue
        if (exclude != "" && InStr(tl, excL))
            continue
        WinGetPos, wx, wy, ww, wh, ahk_id %id%
        if (ww <= 0 || wh <= 0)
            continue
        return {found: true, x: wx, y: wy, w: ww, h: wh, hwnd: id, title: t}
    }
    return {found: false}
}

ScanWin(include, exclude := "") {
    r := {found: false, lines: [], text: "", lc: ""}
    wr := WinRectByTitle(include, exclude)
    if (!wr.found)
        return r
    o := OcrRegion(wr.x, wr.y, wr.w, wr.h)
    r.found := true
    r.lines := o.lines
    r.text  := o.text
    r.lc    := LowerStr(o.text)
    r.win   := wr
    return r
}

ScanScreen() {
    result := {lines: [], text: "", lc: ""}
    SysGet, monCount, MonitorCount
    Loop, %monCount% {
        SysGet, m, Monitor, %A_Index%
        w := mRight - mLeft, h := mBottom - mTop
        if (w <= 0 || h <= 0)
            continue
        o := OcrRegion(mLeft, mTop, w, h)
        for i, ln in o.lines
            result.lines.Push(ln)
        result.text .= o.text
    }
    result.lc := LowerStr(result.text)
    return result
}

OcrRegion(x, y, w, h) {
    ; NOTE: this is a real screen capture. Anything drawn ON the screen is in the
    ; image, including your own always-on-top GUIs. If this script shows overlays,
    ; either exclude them from capture (SetWindowDisplayAffinity, 0x11, Win10 2004+)
    ; or hide them around the capture, or OCR will read your own overlay.
    o := {lines: [], text: ""}
    if (w <= 0 || h <= 0)
        return o
    hbm := HBitmapFromScreen(x, y, w, h)
    stream := HBitmapToRandomAccessStream(hbm)
    DllCall("DeleteObject", "Ptr", hbm)
    res := ocr_words(stream)
    for i, ln in res.lines {
        ln.x += x
        ln.y += y
        o.lines.Push(ln)
    }
    o.text := res.text
    return o
}

FindLine(scan, needle) {
    nl := LowerStr(needle)
    for i, ln in scan.lines {
        if (InStr(LowerStr(ln.text), nl))
            return {found: true, x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text}
    }
    return {found: false}
}

FindLineExact(scan, needle) {
    nl := LowerStr(needle)
    for i, ln in scan.lines {
        if (LowerStr(Trim(ln.text)) = nl)
            return {found: true, x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text}
    }
    return {found: false}
}

ClickLineObj(ln) {
    ClickAt(ln.x + ln.w // 2, ln.y + ln.h // 2)
}

ClickAt(x, y) {
    global ClickDelayMs
    d := ClickDelayMs ? ClickDelayMs : 1000
    MouseMove, %x%, %y%, 10
    Sleep, %d%
    Click
    Sleep, 250
}

MonitorOf(x, y) {
    SysGet, cnt, MonitorCount
    Loop, %cnt% {
        SysGet, m, Monitor, %A_Index%
        if (x >= mLeft && x < mRight && y >= mTop && y < mBottom)
            return {left: mLeft, top: mTop, right: mRight, bottom: mBottom, w: mRight - mLeft, h: mBottom - mTop}
    }
    SysGet, pw, 0
    SysGet, ph, 1
    return {left: 0, top: 0, right: pw, bottom: ph, w: pw, h: ph}
}

LowerStr(s) {
    StringLower, o, s
    return o
}

HBitmapFromScreen(X, Y, W, H) {
    HDC := DllCall("GetDC", "Ptr", 0, "UPtr")
    HBM := DllCall("CreateCompatibleBitmap", "Ptr", HDC, "Int", W, "Int", H, "UPtr")
    PDC := DllCall("CreateCompatibleDC", "Ptr", HDC, "UPtr")
    DllCall("SelectObject", "Ptr", PDC, "Ptr", HBM)
    DllCall("BitBlt", "Ptr", PDC, "Int", 0, "Int", 0, "Int", W, "Int", H
                    , "Ptr", HDC, "Int", X, "Int", Y, "UInt", 0x00CC0020)
    DllCall("DeleteDC", "Ptr", PDC)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", HDC)
    Return HBM
}

HBitmapToRandomAccessStream(hBitmap) {
    static IID_IRandomAccessStream := "{905A0FE1-BC53-11DF-8C49-001E4FC686DA}"
         , IID_IPicture            := "{7BF80980-BF32-101A-8BBB-00AA00300CAB}"
         , PICTYPE_BITMAP := 1
         , BSOS_DEFAULT   := 0
    DllCall("Ole32\CreateStreamOnHGlobal", "Ptr", 0, "UInt", true, "PtrP", pIStream, "UInt")
    VarSetCapacity(PICTDESC, sz := 8 + A_PtrSize * 2, 0)
    NumPut(sz, PICTDESC)
    NumPut(PICTYPE_BITMAP, PICTDESC, 4)
    NumPut(hBitmap, PICTDESC, 8)
    riid := CLSIDFromString(IID_IPicture, GUID1)
    DllCall("OleAut32\OleCreatePictureIndirect", "Ptr", &PICTDESC, "Ptr", riid, "UInt", false, "PtrP", pIPicture, "UInt")
    DllCall(NumGet(NumGet(pIPicture + 0) + A_PtrSize * 15), "Ptr", pIPicture, "Ptr", pIStream, "UInt", true, "UIntP", size, "UInt")
    riid := CLSIDFromString(IID_IRandomAccessStream, GUID2)
    DllCall("ShCore\CreateRandomAccessStreamOverStream", "Ptr", pIStream, "UInt", BSOS_DEFAULT, "Ptr", riid, "PtrP", pIRandomAccessStream, "UInt")
    ObjRelease(pIPicture)
    ObjRelease(pIStream)
    Return pIRandomAccessStream
}

CLSIDFromString(IID, ByRef CLSID) {
    VarSetCapacity(CLSID, 16, 0)
    if res := DllCall("ole32\CLSIDFromString", "WStr", IID, "Ptr", &CLSID, "UInt")
        throw Exception("CLSIDFromString failed. Error: " . Format("{:#x}", res))
    Return &CLSID
}

ocr_words(file) {
    static OcrEngineStatics, OcrEngine, MaxDimension, BitmapDecoderStatics
    if (OcrEngineStatics = "") {
        CreateClass("Windows.Graphics.Imaging.BitmapDecoder", IBitmapDecoderStatics := "{438CCB26-BCEF-4E95-BAD6-23A822E58D01}", BitmapDecoderStatics)
        CreateClass("Windows.Media.Ocr.OcrEngine", IOcrEngineStatics := "{5BFFA85A-3384-3540-9940-699120D428A8}", OcrEngineStatics)
        DllCall(NumGet(NumGet(OcrEngineStatics + 0) + 6 * A_PtrSize), "ptr", OcrEngineStatics, "uint*", MaxDimension)   ; MaxImageDimension
        DllCall(NumGet(NumGet(OcrEngineStatics + 0) + 10 * A_PtrSize), "ptr", OcrEngineStatics, "ptr*", OcrEngine)      ; TryCreateFromUserProfileLanguages
        if (OcrEngine = 0) {
            MsgBox, 48, OCR, Windows OCR could not start. A language pack with OCR support may be missing.
            ExitApp
        }
    }

    out := {}
    out.lines := []
    out.text  := ""

    IRandomAccessStream := file
    DllCall(NumGet(NumGet(BitmapDecoderStatics + 0) + 14 * A_PtrSize), "ptr", BitmapDecoderStatics, "ptr", IRandomAccessStream, "ptr*", BitmapDecoder)   ; CreateAsync
    WaitForAsync(BitmapDecoder)
    BitmapFrame := ComObjQuery(BitmapDecoder, IBitmapFrame := "{72A49A1C-8081-438D-91BC-94ECFC8185C6}")
    DllCall(NumGet(NumGet(BitmapFrame + 0) + 12 * A_PtrSize), "ptr", BitmapFrame, "uint*", width)
    DllCall(NumGet(NumGet(BitmapFrame + 0) + 13 * A_PtrSize), "ptr", BitmapFrame, "uint*", height)
    if (width > MaxDimension) || (height > MaxDimension) {
        OcrDebug("OCR skipped a capture too large: " width "x" height " (max " MaxDimension ").")
        CleanupStream(IRandomAccessStream)
        ObjRelease(BitmapDecoder), ObjRelease(BitmapFrame)
        return out
    }
    BitmapFrameWithSoftwareBitmap := ComObjQuery(BitmapDecoder, IBitmapFrameWithSoftwareBitmap := "{FE287C9A-420C-4963-87AD-691436E08383}")
    DllCall(NumGet(NumGet(BitmapFrameWithSoftwareBitmap + 0) + 6 * A_PtrSize), "ptr", BitmapFrameWithSoftwareBitmap, "ptr*", SoftwareBitmap)   ; GetSoftwareBitmapAsync
    WaitForAsync(SoftwareBitmap)
    DllCall(NumGet(NumGet(OcrEngine + 0) + 6 * A_PtrSize), "ptr", OcrEngine, "ptr", SoftwareBitmap, "ptr*", OcrResult)   ; RecognizeAsync
    WaitForAsync(OcrResult)

    DllCall(NumGet(NumGet(OcrResult + 0) + 6 * A_PtrSize), "ptr", OcrResult, "ptr*", LinesList)   ; get_Lines
    DllCall(NumGet(NumGet(LinesList + 0) + 7 * A_PtrSize), "ptr", LinesList, "int*", lineCount)   ; Size
    loop % lineCount {
        DllCall(NumGet(NumGet(LinesList + 0) + 6 * A_PtrSize), "ptr", LinesList, "int", A_Index - 1, "ptr*", OcrLine)   ; GetAt
        DllCall(NumGet(NumGet(OcrLine + 0) + 7 * A_PtrSize), "ptr", OcrLine, "ptr*", hText)   ; get_Text
        buffer := DllCall("Combase.dll\WindowsGetStringRawBuffer", "ptr", hText, "uint*", length, "ptr")
        lineText := StrGet(buffer, length, "UTF-16")

        DllCall(NumGet(NumGet(OcrLine + 0) + 6 * A_PtrSize), "ptr", OcrLine, "ptr*", WordsList)   ; get_Words
        DllCall(NumGet(NumGet(WordsList + 0) + 7 * A_PtrSize), "ptr", WordsList, "int*", wordCount)   ; Size
        lx1 := 9999999, ly1 := 9999999, lx2 := -9999999, ly2 := -9999999
        loop % wordCount {
            DllCall(NumGet(NumGet(WordsList + 0) + 6 * A_PtrSize), "ptr", WordsList, "int", A_Index - 1, "ptr*", OcrWord)   ; GetAt
            VarSetCapacity(RECT, 16, 0)
            DllCall(NumGet(NumGet(OcrWord + 0) + 6 * A_PtrSize), "ptr", OcrWord, "ptr", &RECT)   ; get_BoundingRect (X,Y,W,H floats)
            wx := NumGet(RECT, 0, "Float"), wy := NumGet(RECT, 4, "Float"), ww := NumGet(RECT, 8, "Float"), wh := NumGet(RECT, 12, "Float")
            if (wx < lx1)
                lx1 := wx
            if (wy < ly1)
                ly1 := wy
            if (wx + ww > lx2)
                lx2 := wx + ww
            if (wy + wh > ly2)
                ly2 := wy + wh
            ObjRelease(OcrWord)
        }
        ObjRelease(WordsList)

        line := {}
        line.text := lineText
        if (wordCount > 0) {
            line.x := Round(lx1), line.y := Round(ly1), line.w := Round(lx2 - lx1), line.h := Round(ly2 - ly1)
        } else {
            line.x := 0, line.y := 0, line.w := 0, line.h := 0
        }
        out.lines.Push(line)
        out.text .= lineText "`n"
        ObjRelease(OcrLine)
    }

    CleanupStream(IRandomAccessStream)
    CleanupBitmap(SoftwareBitmap)
    ObjRelease(BitmapDecoder)
    ObjRelease(BitmapFrame)
    ObjRelease(BitmapFrameWithSoftwareBitmap)
    ObjRelease(OcrResult)
    ObjRelease(LinesList)
    return out
}

CleanupStream(IRandomAccessStream) {
    Close := ComObjQuery(IRandomAccessStream, IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
    DllCall(NumGet(NumGet(Close + 0) + 6 * A_PtrSize), "ptr", Close)
    ObjRelease(Close)
    ObjRelease(IRandomAccessStream)
}

CleanupBitmap(SoftwareBitmap) {
    Close := ComObjQuery(SoftwareBitmap, IClosable := "{30D5A829-7FA4-4026-83BB-D75BAE4EA99E}")
    DllCall(NumGet(NumGet(Close + 0) + 6 * A_PtrSize), "ptr", Close)
    ObjRelease(Close)
    ObjRelease(SoftwareBitmap)
}

CreateClass(string, interface, ByRef Class) {
    CreateHString(string, hString)
    VarSetCapacity(GUID, 16)
    DllCall("ole32\CLSIDFromString", "wstr", interface, "ptr", &GUID)
    result := DllCall("Combase.dll\RoGetActivationFactory", "ptr", hString, "ptr", &GUID, "ptr*", Class)
    if (result != 0) {
        if (result = 0x80004002)
            MsgBox No such interface supported
        else if (result = 0x80040154)
            MsgBox Class not registered
        else
            MsgBox % "OCR init error: " result
        ExitApp
    }
    DeleteHString(hString)
}

CreateHString(string, ByRef hString) {
    DllCall("Combase.dll\WindowsCreateString", "wstr", string, "uint", StrLen(string), "ptr*", hString)
}

DeleteHString(hString) {
    DllCall("Combase.dll\WindowsDeleteString", "ptr", hString)
}

WaitForAsync(ByRef Object) {
    AsyncInfo := ComObjQuery(Object, IAsyncInfo := "{00000036-0000-0000-C000-000000000046}")
    loop {
        DllCall(NumGet(NumGet(AsyncInfo + 0) + 7 * A_PtrSize), "ptr", AsyncInfo, "uint*", status)   ; Status
        if (status != 0) {
            if (status != 1) {
                DllCall(NumGet(NumGet(AsyncInfo + 0) + 8 * A_PtrSize), "ptr", AsyncInfo, "uint*", ErrorCode)
                OcrDebug("OCR async error: " ErrorCode)
                ObjRelease(AsyncInfo)
                Object := 0
                return
            }
            ObjRelease(AsyncInfo)
            break
        }
        sleep 10
    }
    DllCall(NumGet(NumGet(Object + 0) + 8 * A_PtrSize), "ptr", Object, "ptr*", ObjectResult)   ; GetResults
    ObjRelease(Object)
    Object := ObjectResult
}

