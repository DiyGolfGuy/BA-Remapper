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
;  BA CUSTOM PRODUCTS - CONTROL BOX REMAPPER v5.0.7
;  bacustomproducts@gmail.com   GitHub: DiyGolfGuy
;
;  CHANGES IN v5.0.7  (from the 4 Oct sim session logs/photos)
;  - Drop Ball locked spot: the second button's word changes
;    (Drop Ball / Rehit / "Go to DZ" in a water drop zone), so it
;    is now confirmed by Move Forward + Move Back in their locked
;    places and clicked whatever it says.  Locked button sizes
;    are judged against the menu's own text-height range, so
;    Drop Ball -> Rehit no longer fails the size check (it fell
;    back to two full reads every time).
;  - OB dialog: its Rehit button wobbles ~30px sideways; the
;    agreement and locked checks follow the button's width.
;  - After a locked spot fails to confirm, up to 8 reads (fast
;    menu-area reads after the first) instead of 3 - a menu that
;    re-slides in after Move Back is waited out - but three empty
;    full reads in a row end a press made with no menu up.
;  - Scramble: cards are remembered across frames (the putting-
;    green grid spoils a different card each frame); stand-alone
;    grid marks ("l", "|") are dropped; on the green a feet/inch
;    distance is read even when its marks misread as letters;
;    6 tries before standing down; the stand-down dump has every
;    line's position (ocr_last_scramble_miss.txt).
;  - Key trace: every FN / button event on a Smart Click profile
;    goes to ocr_trace.txt (Move Forward presses never reached
;    the Smart Click in the field trace - this shows why).
;
;  CHANGES IN v5.0.6
;  - LOCKED SMART CLICK SPOTS: the first verified Smart Click
;    on a PC saves every relief-menu button position (keyed to
;    the GSPro window size); later presses read only the
;    button's small area, confirm the word is there at the
;    saved size, and click - tens of ms instead of two full
;    reads (~1s on the field PC).  Re-learned automatically on
;    a window size change or when the confirm fails; tray menu
;    "Reset Smart Click spots" forces it.
;  - The learn path's confirming read covers only the menu
;    area; the FN prefetch is skipped once spots are locked;
;    the scramble watcher stands aside while FN is held; extra
;    taps of Drop Ball / Rehit made during a press are dropped
;    (they used to run after the drop and search 5s for a menu
;    that was gone).
;  - Scramble rule (Ba): fewest strokes -> GREEN always wins ->
;    shortest distance.  The lie never blocks a pick: v5.0.5
;    stood down on a card it read perfectly as CONCRETE.  Only a
;    word that may be a misread GREEN stands down.
;  - Green distances: the OCR reads the ' mark as "1" (14' 7"
;    -> "141 7"); feet/inches are now parsed with that in mind.
;
;  CHANGES IN v5.0.5
;  - Scramble FIX: the lie row is now every OCR line on the
;    shot-ordinal row, joined.  Depending on screen size the OCR
;    engine returns "ROUGH 4TH" as one line or as two; v5.0.4
;    read only the "4TH" piece, saw no lie and stood down (the
;    countdown ran out and nothing was picked).  Lie words now
;    tolerate one misread letter; a misread shot digit is
;    recovered from its suffix (ZND -> 2).  The distance must be
;    centered on the card, so the corner badge digit can never
;    stand in for it.
;  - Smart Clicks: TWO-FRAME AGREEMENT - a click happens only
;    when two consecutive reads put the button in the same
;    place.  A single frame caught while GSPro animates the menu
;    in could put Next Option's spot between Drop Ball and Move
;    Back.  The FN-press prefetch is now only the first frame.
;  - OCR never throws: a failed decode/recognition step returns
;    an empty read and the next frame is used (the "-4" errors).
;    No second recognition is ever started on top of another
;    (OCR Test and warm-up take the lock; deferred presses wait
;    instead of forcing it; the re-click check releases it
;    between its two looks).
;  - Diagnostics FIX: inside a try block AutoHotkey throws when
;    FileDelete/FileGetSize meet a file that does not exist yet,
;    so OCR Test always failed on a PC that had never written
;    ocr_last_scan.txt, and ocr_trace / ocr_last_miss / error_log
;    were never created on fresh installs.  All file housekeeping
;    now checks first.  scramble_log.txt keeps the last ~100
;    pick attempts with what was read on every card; OCR Test
;    shows what the picker would choose from that frame;
;    launch_log.txt records the version.
;
;  CHANGES IN v5.0.4
;  - Scramble: lie, GREEN and shot number now come from the
;    card's LIE ROW only (the ordinal row above USE).  Reading
;    them from any line in the column let a player NAME win -
;    "DEEP ROUGH DAN", Woods, Sandy, Rocky - so a ball on the
;    green could be scored as rough and lose the pick.  The
;    corner badge digit merged into the name could likewise
;    become the shot number.
;  - A distance candidate containing letters is rejected (a
;    mangled "143" read as "!4E" used to strip to "4").
;  - A failed card parse now retries up to 4 frames before
;    standing down: on the putting green the animated grid can
;    spoil a single capture, which used to end the pick.
;  - Smart Clicks retry over ~3.5s (was ~2s) so a menu still
;    fading in is waited out instead of the customer having to
;    press twice; the scan cache is dropped after every click;
;    a deferred press is never silently discarded.
;
;  CHANGES IN v5.0.3
;  - CRITICAL FIX: the scramble decision logger (added in
;    5.0.1) ran INSIDE the decision path and was not protected.
;    When it threw, ScrambleDecide never returned and the shot
;    keystroke was never sent - countdown finished, nothing
;    happened.  Every diagnostic writer is now self-contained
;    and can never abort a pick, a click or a scan.
;  - error_log now records what/extra/version, and a new
;    ocr_trace.txt records every Smart Click press end to end.
;  - Removed the low-resolution band upscale and the monitor
;    lookup from the window pick: fewer moving parts.
;
;  CHANGES IN v5.0.2
;  - Fixed: a keypress could freeze an in-flight scan (AHK runs
;    one thread at a time), starving the scramble pick and all
;    Smart Clicks.  Presses now queue to a timer; a lock
;    watchdog clears any stale OCR lock after 6s.
;  - Fixed: low-resolution scramble upscale exceeded the OCR
;    engine's max image size; now scans the card band only.
;
;  CHANGES IN v5.0.1
;  - Relief menu: "Options X / 3" counter added as a lattice
;    anchor - full redundancy with mulligans OFF (4-button menu).
;  - FN-hold prefetch: the menu is read the moment FN goes down,
;    so the arrow press clicks from a hot cache.
;  - A press during an in-flight scan now waits for it instead
;    of being dropped.
;  - Slot-mismatch guard: an inferred slot is never clicked if a
;    different menu word is readable there.
;  - OB dialog recognized by its title ("You have hit OB!") -
;    works with or without the Mulligan button.
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
AppVersion := "5.0.7"
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
OcrBusySince := 0            ; when the lock was taken (watchdog)
PendingOcrAction := ""       ; press deferred while a scan is in flight
PendingOcrSince  := 0
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
LastRef := {}                ; geometry of the last resolved target
ScrambleMemo := {}           ; what earlier frames read on each card
SpotWin := ""                ; GSPro client rect the locked spots belong to
Spots := {}                  ; locked Smart Click spots (see LOCKED SPOTS)
OcrWarmedUp  := false

; ---- Auto-Pick Scramble state (settings loaded from ini) ----
ScrambleAutoPick  := false   ; global toggle (all profiles)
ScrambleDelaySec  := 15      ; 5 / 10 / 15 / 20
ScrambleArmedTick := 0       ; tick when USE screen first seen (0 = not armed)
ScrambleCoolDown  := false   ; true after firing until screen disappears
ScrambleBusy      := false   ; re-entrancy guard for the watcher timer
ScrambleDumped    := false   ; one-shot diagnostic dump guard
ScrambleTries     := 0       ; parse attempts for this card screen
ScrambleFbTick    := 0       ; throttle for full-screen fallback scans
ScrambleMissTicks := 0       ; consecutive scans without the cards
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
if (SafeFileSize(llFile) > 20000)
    SafeFileDelete(llFile)
llMode := isStartupLaunch ? "WINDOWS-STARTUP" : "manual"
llLine := A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec
llLine .= "  v" . AppVersion . "  " . llMode . "  " . A_ScriptFullPath . "`n"
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
    global ScrambleAutoPick, ScrambleDelaySec, ScrambleCountdown, ClickDelayMs
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
    ; Power-user knob: Smart Click hover-before-click pacing.
    ; Edit settings.ini [App] ClickDelayMs (100-1000, default
    ; 300) to tune click feel at the sim without a new build.
    IniRead, cdms,           %ConfigFile%, App, ClickDelayMs, 300
    cdms += 0
    if (cdms < 100 || cdms > 1000)
        cdms := 300
    ClickDelayMs := cdms
}

SaveSettings() {
    global ConfigFile, ActiveProfile, StartupProfile, SwapIK
    global ScrambleAutoPick, ScrambleDelaySec, ScrambleCountdown, ClickDelayMs
    IniWrite, %ActiveProfile%,  %ConfigFile%, App, ActiveProfile
    IniWrite, %StartupProfile%, %ConfigFile%, App, StartupProfile
    swapWrite := SwapIK ? 1 : 0
    IniWrite, %swapWrite%, %ConfigFile%, App, SwapIK
    spWrite := ScrambleAutoPick ? 1 : 0
    IniWrite, %spWrite%, %ConfigFile%, App, ScrambleAutoPick
    IniWrite, %ScrambleDelaySec%, %ConfigFile%, App, ScrambleDelay
    cdWrite := ScrambleCountdown ? 1 : 0
    IniWrite, %cdWrite%, %ConfigFile%, App, ScrambleCountdown
    IniWrite, %ClickDelayMs%, %ConfigFile%, App, ClickDelayMs
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
    global FnLastDownTime, BtnPrimary, OcrBusy
    btnId := KeyToBtnId[keyName]
    if (btnId = "")
        return

    if (btnId = FnButtonId) {
        ; Key trace (Smart Click profiles only): every FN and
        ; button event lands in ocr_trace.txt, so a press that
        ; never reached a Smart Click shows exactly why.
        if (!FnIsDown && AnyOcrSecondary())
            OcrTrace("key FN (" . keyName . ") down")
        FnIsDown := true
        FnUsedAsModifier := false
        FnLastDownTime := A_TickCount
        ; Prefetch: start reading the GSPro menu NOW, so by the
        ; time the arrow lands (~half a second later for a human)
        ; the scan is already cached and the click is instant.
        if (AnyOcrSecondary() && !OcrBusy)
            SetTimer, OcrPrefetch, -1
        return
    }

    fnHeld := FnIsDown
    if (!fnHeld)
        fnHeld := FnPhysicallyHeld()
    if (!fnHeld && FnLastDownTime > 0 && (A_TickCount - FnLastDownTime < 80))
        fnHeld := true

    if (fnHeld) {
        FnUsedAsModifier := true
        if (AnyOcrSecondary())
            OcrTrace("key " . keyName . " (" . btnId . ") down with FN held")
        FireSecondary(btnId)
        return
    }

    pk := BtnPrimary[btnId]
    pk := ApplyIKSwap(pk)
    if (AnyOcrSecondary())
        OcrTrace("key " . keyName . " (" . btnId . ") down, FN not held -> sent " . pk)
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
        if (AnyOcrSecondary())
            OcrTrace("key FN (" . keyName . ") up" . (FnUsedAsModifier ? "" : " - tapped alone, sent its own key"))
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
        ParkMouse()
    }
    else if (stype = "ocr") {
        OcrTrace("secondary fired: " . btnId . " -> " . SecValue[btnId])
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
    global GSProWinNeedle, GSProWinExclude, PendingOcrAction, PendingOcrSince
    global LastActionId, LastClickX, LastClickY, LastFireTick
    global LastScanObj, LastScanTick, VerifyActionId, VerifyY, VerifyBandPx
    global LastResolveBand, LastLatticeNote, LastRef, SpotWin
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
    ; A new press supersedes any pending background re-click of
    ; the previous closing action.
    VerifyActionId := ""
    ; A scan in flight (prefetch, watcher, verify) cannot finish
    ; while this keypress thread runs, so never wait here: hand
    ; the press to a timer that fires once the lock is free.
    OcrTrace("press " . actionId)
    OcrStaleCheck()
    if (OcrBusy) {
        PendingOcrAction := actionId
        PendingOcrSince := A_TickCount
        SetTimer, OcrDeferred, -60
        OcrTrace("  deferred (scan in flight)")
        return
    }
    OcrLockTake()
    try {

    ; FAST PATH 1 - identical repeat: the menu stack does not
    ; move while it is up, and the cursor is still hovering the
    ; button (parking waits for the burst to end).  Tap the same
    ; combo again within 4s -> click the cached spot instantly.
    if (!closesMenu && actionId = LastActionId && LastClickX
        && (now - LastFireTick) < 4000) {
        OcrTrace("  repeat click at " . LastClickX . "," . LastClickY)
        DpiRepeatClick(LastClickX, LastClickY)
        LastFireTick := A_TickCount
        SetTimer, ParkTick, -1200
        OcrBusy := false
        return
    }

    found := false
    learnNow := false
    cx := 0
    cy := 0
    scan := {found: false, lines: [], text: "", lc: ""}

    ; FAST PATH 2 - LOCKED SPOTS.  This PC's menu positions were
    ; verified and saved on an earlier press (same GSPro window
    ; size): read only the button's own small area, confirm its
    ; word sits there at the saved size, click.  Tens of ms
    ; instead of two full-window reads.
    curWr := ClientRectByTitle(GSProWinNeedle, GSProWinExclude)
    curKey := curWr.found ? curWr.x . "," . curWr.y . "," . curWr.w . "," . curWr.h : ""
    spotsValid := (curKey != "" && curKey = SpotWin)
    if (spotsValid) {
        if (SpotFastResolve(actionId, cx, cy, 12)) {
            found := true
            LastScanObj := {found: true, lines: [], text: "", lc: "", win: curWr}
        } else {
            OcrTrace("  locked spot not confirmed - reading the whole screen")
        }
    }

    ; LEARN PATH - TWO-FRAME AGREEMENT.  A click is authorized
    ; only when two consecutive reads put the menu in the same
    ; place.  GSPro slides its menus in: a frame caught mid-slide
    ; forms a perfectly consistent menu ~100px from where it ends
    ; up (field trace 4 Oct: the FN-press read had Drop Ball where
    ; Move Back settles).  The first read is the whole window (or
    ; the FN-press prefetch); the confirming read covers only the
    ; menu's area, so it is fast.  When the two agree, the click
    ; goes out and every button's position is LOCKED for next time.
    if (!found) {
        ; Up to 8 reads (after the first, each is the fast menu-
        ; area read).  With locked spots the poll above already
        ; waited for the menu, so three empty full reads in a row
        ; mean no menu is up: stop instead of searching for 4s.
        maxReads := 8
        missRun := 0
        prevOk := false
        prevRef := ""
        lastWin := curWr.found ? curWr : ""
        px := 0
        py := 0
        if (!spotsValid && actionId != "Rehit" && IsObject(LastScanObj) && (A_TickCount - LastScanTick) <= 2500) {
            tx := 0
            ty := 0
            if (ResolveOcrTarget(actionId, LastScanObj, tx, ty)) {
                prevOk := true
                prevRef := LastRef
                px := LastRef.rx
                py := LastRef.ry
                OcrTrace("  frame A (prefetch): " . tx . "," . ty . "  " . LastLatticeNote)
            }
        }
        Loop, %maxReads% {
            useArea := (prevOk && IsObject(prevRef) && prevRef.kind = "menu" && IsObject(lastWin))
            if (useArea) {
                scan := ScanMenuArea(prevRef, lastWin)
            } else {
                scan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
                if (!scan.found)
                    scan := ScanScreen()   ; window title fallback
                if (scan.HasKey("win"))
                    lastWin := scan.win
            }
            LastScanObj := scan
            LastScanTick := A_TickCount
            tx := 0
            ty := 0
            ok := ResolveOcrTarget(actionId, scan, tx, ty)
            OcrTrace("  read " . A_Index . (useArea ? " (menu area)" : " (full)") . ": " . (ok ? tx . "," . ty : "no target") . "  " . LastLatticeNote)
            if (ok && prevOk) {
                agreeTol := LastResolveBand // 4
                if (agreeTol < 4)
                    agreeTol := 4
                agreeX := agreeTol
                agreeY := agreeTol
                ; The OB dialog's Rehit button wobbles sideways
                ; (field trace 1788 -> 1817 -> 1788): agree on
                ; the button, not on one pixel.
                if (LastRef.kind = "ob") {
                    agreeX := Round(LastRef.w * 0.6) + 4
                    agreeY := Round(LastRef.h * 0.6) + 4
                }
                if (Abs(LastRef.rx - px) <= agreeX && Abs(LastRef.ry - py) <= agreeY) {
                    found := true
                    learnNow := true
                    cx := tx
                    cy := ty
                    break
                }
                OcrTrace("    moved since last read - waiting for the menu to settle")
            }
            prevOk := ok
            if (ok) {
                prevRef := LastRef
                px := LastRef.rx
                py := LastRef.ry
            }
            if (!ok) {
                missRun += 1
                if (spotsValid && missRun >= 3)
                    break
                Sleep, 120
            } else {
                missRun := 0
            }
        }
    }

    if (found) {
        OcrTrace("  resolved at " . cx . "," . cy)
        ; Lock in this PC's spots from the verified frames.
        if (learnNow && IsObject(LastScanObj) && LastScanObj.HasKey("win") && LastScanObj.win.found) {
            lw := LastScanObj.win
            LearnSpots(lw.x . "," . lw.y . "," . lw.w . "," . lw.h)
        }
        ; The click is about to change the screen, so this scan
        ; is spent: the next press must read fresh rather than
        ; resolve against a pre-click cache.
        LastScanTick := 0
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
            ; Extra taps of the same button made while this one
            ; was working are impatience, not new requests: the
            ; menu is closing.  (Field trace: a queued Drop Ball
            ; ran after the drop and searched 5s for a menu that
            ; was gone, then showed "not found".)
            if (PendingOcrAction = actionId) {
                PendingOcrAction := ""
                OcrTrace("  extra " . actionId . " tap made during this press dropped")
            }
        } else {
            LastActionId := actionId
            LastClickX := cx
            LastClickY := cy
        }
        SetTimer, ParkTick, -1200
    } else {
        dispName := OcrActionName.HasKey(actionId) ? OcrActionName[actionId] : actionId
        OcrTrace("  NOT FOUND (" . LastLatticeNote . ")")
        ShowGsproTip(dispName . " - not found on screen", 1800)
        OcrDumpMiss("SmartClick " . actionId . " (" . LastLatticeNote . ")", scan)
    }
    } catch appErr {
        LogAppError("SmartClick", appErr)
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

FindAllFuzzy(scan, needle) {
    out := []
    for i, ln in scan.lines {
        if (FuzzyIs(ln.text, needle))
            out.Push({found: true, x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text})
    }
    return out
}

; Pick, for each anchor word, the candidate line nearest the
; menu column.  A stray match elsewhere on screen (the HUD's
; "SHOT OPTIONS", a hallucinated line over grass) can never
; displace the real button: the column is set by the words
; that matched exactly once, and ambiguous words snap to it.
PickAnchors(scan) {
    words := {0: "options", 1: "move forward", 3: "move back", 4: "next option", 5: "mulligan"}
    cands := {}
    refXs := []
    for slot, nd in words {
        c := FindAllFuzzy(scan, nd)
        if (c.MaxIndex() = "")
            continue
        cands[slot] := c
        if (c.MaxIndex() = 1)
            refXs.Push(c[1].x + c[1].w // 2)
    }
    refX := ""
    if (refXs.MaxIndex() != "") {
        Loop, % refXs.MaxIndex() - 1 {
            i := A_Index + 1
            j := i
            while (j > 1 && refXs[j-1] > refXs[j]) {
                tmp := refXs[j-1]
                refXs[j-1] := refXs[j]
                refXs[j] := tmp
                j--
            }
        }
        refX := refXs[(refXs.MaxIndex() + 1) // 2]
    }
    anch := {}
    for slot, c in cands {
        if (c.MaxIndex() = 1 || refX = "") {
            anch[slot] := c[1]
            continue
        }
        bestD := 999999
        for i, cd in c {
            d := Abs((cd.x + cd.w // 2) - refX)
            if (d < bestD) {
                bestD := d
                anch[slot] := cd
            }
        }
    }
    ; Size sanity: anchors are the same font; drop any line whose
    ; height is wildly off the median (junk lines from textures).
    hs := []
    for slot, a in anch
        hs.Push(a.h)
    if (hs.MaxIndex() >= 3) {
        Loop, % hs.MaxIndex() - 1 {
            i := A_Index + 1
            j := i
            while (j > 1 && hs[j-1] > hs[j]) {
                tmp := hs[j-1]
                hs[j-1] := hs[j]
                hs[j] := tmp
                j--
            }
        }
        medH := hs[(hs.MaxIndex() + 1) // 2]
        for slot, a in anch {
            if (a.h < medH * 0.5 || a.h > medH * 2.0)
                anch.Delete(slot)
        }
    }
    return anch
}

FindMenuLattice(scan) {
    global LastLatticeNote
    lat := {found: false}
    ; Anchors: slot 0 = the "Options X / 3" counter (always
    ; present, one pitch above Move Forward - with mulligans OFF
    ; the menu has no Mulligan button, and this anchor is what
    ; keeps redundancy in that four-button stack), slot 1 Move
    ; Forward, 3 Move Back, 4 Next Option, 5 Mulligan.
    anch := PickAnchors(scan)
    cnt := 0
    for slot, a in anch
        cnt += 1
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
    ; An anchor word read OFF the menu column (the HUD's "SHOT
    ; OPTIONS" while the menu's own "Options 3/3" misread) is not
    ; part of the menu: drop it and judge the stack on the rest.
    ; Fewer than 3 in-column anchors is still a refusal.
    offCol := []
    for sIdx, a in anch {
        if (Abs((a.x + a.w // 2) - colX) > wavg * 0.6)
            offCol.Push(sIdx)
    }
    for i, sIdx in offCol
        anch.Delete(sIdx)
    if (offCol.MaxIndex() != "") {
        cnt := 0
        sumW := 0
        for sIdx, a in anch {
            cnt += 1
            sumW += a.w
        }
        if (cnt < 3) {
            LastLatticeNote .= " colfail"
            return lat
        }
        wavg := sumW / cnt
    }
    ; One consistent pitch across known anchors
    order := []
    Loop, 6 {
        if (anch.HasKey(A_Index - 1))
            order.Push(A_Index - 1)
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
    lat.havg := havg
    lat.wavg := wavg
    lat.pitch := pitch
    lat.slotY := slotY
    lat.anch := anch
    lat.s2 := s2
    an := ""
    for sIdx, a in anch
        an .= (an = "" ? "" : " ") . sIdx . ":" . Round(a.y + a.h / 2)
    LastLatticeNote := "anchors=" . cnt . " [" . an . "] pitch=" . Round(pitch) . " col=" . Round(colX)
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

; The line (if any) sitting at a lattice slot position.
LineAtSlot(scan, lat, slotIdx) {
    for i, ln in scan.lines {
        lcx := ln.x + ln.w // 2
        lcy := ln.y + ln.h // 2
        if (Abs(lcx - lat.colX) <= lat.wavg * 0.8 && Abs(lcy - lat.slotY[slotIdx]) <= lat.pitch * 0.35)
            return {found: true, x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text}
    }
    return {found: false}
}

; Does this text read as one of the menu's stack words?
IsStackWord(t) {
    return (FuzzyIs(t, "move forward") || FuzzyIs(t, "move back") || FuzzyIs(t, "next option")
         || FuzzyIs(t, "mulligan") || FuzzyIs(t, "drop ball") || FuzzyIs(t, "rehit"))
}

; OB dialog by its TITLE: "You have hit OB!" directly above a
; Rehit button.  Covers both variants - with Mulligan (mulligans
; on) and Rehit-only (mulligans off).
FindObTitleRehit(scan) {
    for i, ln in scan.lines {
        tn := OcrNorm(ln.text)
        if (!(FuzzyIs(ln.text, "you have hit ob") || InStr(tn, "hitob")))
            continue
        tcx := ln.x + ln.w // 2
        tcy := ln.y + ln.h / 2
        for j, ln2 in scan.lines {
            if (j = i || !FuzzyIs(ln2.text, "rehit"))
                continue
            rcy := ln2.y + ln2.h / 2
            rcx := ln2.x + ln2.w // 2
            if (rcy > tcy && (rcy - tcy) < ln.h * 8 && Abs(rcx - tcx) < ln.w)
                return {found: true, x: ln2.x, y: ln2.y, w: ln2.w, h: ln2.h, text: ln2.text}
        }
    }
    return {found: false}
}

; Resolve an action to an authorized click point.  Returns
; true and sets cx/cy; sets LastResolveBand (the vertical
; tolerance used by the background verify).
ResolveOcrTarget(actionId, scan, ByRef cx, ByRef cy) {
    global LastResolveBand, LastLatticeNote, LastRef
    LastRef := {kind: ""}
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
            LastRef := MenuRef(lat, 2)
            return true
        }
        if (lat.anch.HasKey(target)) {
            a := lat.anch[target]
            cx := a.x + a.w // 2
            cy := a.y + a.h // 2
            LastRef := MenuRef(lat, target)
            return true
        }
        ; Inferred position: refuse if a DIFFERENT stack word is
        ; readable at that spot (geometry/word mismatch = the
        ; one-button-off failure).  Only an unreadable or empty
        ; slot may be clicked by inference.
        atSlot := LineAtSlot(scan, lat, target)
        if (atSlot.found && IsStackWord(atSlot.text)) {
            LastLatticeNote .= " slotmismatch"
            return false
        }
        cx := lat.colX
        cy := lat.slotY[target]
        LastRef := MenuRef(lat, target)
        return true
    }
    ; actionId = "Rehit": the OB dialog (by title, or by the
    ; Mulligan pair), or the relief menu's slot 2 showing Rehit.
    pr := FindObTitleRehit(scan)
    if (!pr.found)
        pr := FindObPair(scan)
    if (pr.found) {
        LastResolveBand := Round(pr.h * 2)
        cx := pr.x + pr.w // 2
        cy := pr.y + pr.h // 2
        LastRef := {kind: "ob", rx: cx, ry: cy, w: pr.w, h: pr.h}
        LastLatticeNote := "OB dialog"
        return true
    }
    lat := FindMenuLattice(scan)
    if (lat.found && lat.s2.found && FuzzyIs(lat.s2.text, "rehit")) {
        LastResolveBand := Round(lat.pitch)
        cx := lat.s2.x + lat.s2.w // 2
        cy := lat.s2.y + lat.s2.h // 2
        LastRef := MenuRef(lat, 2)
        return true
    }
    return false
}

; Geometry of a verified relief menu, for agreement checks, the
; small confirm read, and learning the locked spots.
MenuRef(lat, target) {
    return {kind: "menu", rx: lat.colX, ry: lat.slotY[target], colX: lat.colX
        , slotY: lat.slotY, pitch: lat.pitch, wavg: lat.wavg, havg: lat.havg
        , anch: lat.anch, s2: lat.s2}
}

; ============================================================
;  LOCKED SMART CLICK SPOTS  (v5.0.6)
;
;  The first Smart Click on a PC that two agreeing screen reads
;  verify saves where every relief-menu button sits (and the OB
;  dialog's Rehit), keyed to the GSPro window's exact position
;  and size, in settings.ini [SmartSpots].  From then on a press
;  reads ONLY that button's small area - tens of milliseconds
;  instead of two full-window reads - confirms the button's own
;  word is there at the saved size (a menu still sliding in is
;  neither in place nor full size), and clicks.  Anything else -
;  menu not up yet, a different layout - falls back to the full
;  read, which re-learns.  A different GSPro window size or
;  position (new resolution) never uses old spots: they are
;  re-learned on the next press automatically.  Tray menu: Reset
;  Smart Click spots forces a fresh learn.
; ============================================================
SpotKeys() {
    return ["MoveForward", "DropRehit", "MoveBack", "NextOption", "ObRehit"]
}

LoadSpots() {
    global ConfigFile, SpotWin, Spots
    Spots := {}
    SpotWin := ""
    IniRead, sw, %ConfigFile%, SmartSpots, Win, %A_Space%
    sw := Trim(sw)
    if (!RegExMatch(sw, "^-?\d+,-?\d+,\d+,\d+$"))
        return
    SpotWin := sw
    for i, k in SpotKeys() {
        IniRead, v, %ConfigFile%, SmartSpots, %k%, %A_Space%
        p := StrSplit(Trim(v), ",")
        if (p.MaxIndex() >= 4 && p[3] > 0 && p[4] > 0)
            Spots[k] := {x: p[1] + 0, y: p[2] + 0, w: p[3] + 0, h: p[4] + 0, inferred: (p[5] = "1" ? 1 : 0)}
    }
}

SaveSpots() {
    global ConfigFile, SpotWin, Spots
    try {
        IniWrite, %SpotWin%, %ConfigFile%, SmartSpots, Win
        for i, k in SpotKeys() {
            v := ""
            if (Spots.HasKey(k))
                v := Spots[k].x . "," . Spots[k].y . "," . Spots[k].w . "," . Spots[k].h . "," . Spots[k].inferred
            IniWrite, %v%, %ConfigFile%, SmartSpots, %k%
        }
    } catch spErr {
        LogAppError("SaveSpots", spErr)
    }
}

; Are this PC's locked spots valid for the GSPro window as it is
; right now?  (Cheap: a window lookup, no screen read.)
SpotsValidNow() {
    global GSProWinNeedle, GSProWinExclude, SpotWin
    if (SpotWin = "")
        return false
    wr := ClientRectByTitle(GSProWinNeedle, GSProWinExclude)
    if (!wr.found)
        return false
    return ((wr.x . "," . wr.y . "," . wr.w . "," . wr.h) = SpotWin)
}

; Save the spots from the frame just verified (LastRef).
LearnSpots(winKey) {
    global Spots, SpotWin, LastRef
    if (winKey = "" || !IsObject(LastRef) || LastRef.kind = "")
        return
    if (SpotWin != winKey) {
        Spots := {}
        SpotWin := winKey
    }
    if (LastRef.kind = "menu") {
        keys := {1: "MoveForward", 2: "DropRehit", 3: "MoveBack", 4: "NextOption"}
        for slot, key in keys {
            a := ""
            if (slot = 2) {
                if (LastRef.s2.found)
                    a := LastRef.s2
            } else if (LastRef.anch.HasKey(slot)) {
                a := LastRef.anch[slot]
            }
            if (IsObject(a))
                Spots[key] := {x: a.x + a.w // 2, y: a.y + a.h // 2, w: a.w, h: a.h, inferred: 0}
            else
                Spots[key] := {x: LastRef.colX, y: LastRef.slotY[slot], w: Round(LastRef.wavg), h: Round(LastRef.havg), inferred: 1}
        }
        OcrTrace("  spots locked for this PC: menu at col " . LastRef.colX . ", pitch " . Round(LastRef.pitch))
    } else if (LastRef.kind = "ob") {
        Spots["ObRehit"] := {x: LastRef.rx, y: LastRef.ry, w: LastRef.w, h: LastRef.h, inferred: 0}
        OcrTrace("  spot locked for this PC: OB Rehit at " . LastRef.rx . "," . LastRef.ry)
    }
    SaveSpots()
}

; Confirm a locked spot with a small read of the button's own
; area.  The word must be the right one, centered where it was
; learned, at the learned size - a menu still sliding in is not
; there yet and a menu zooming in is too small, so neither is
; ever clicked; the read simply repeats (up to `tries` times,
; ~0.1s apart) until the menu holds still.
;
; The second button changes its word with the option shown -
; Drop Ball, Rehit, Go to DZ (water drop zone, field photo
; 4 Oct) - so Drop Ball / Rehit is confirmed by the two buttons
; that never change, Move Forward above it and Move Back below
; it, both in their locked places; then the second button is
; clicked whatever it says.
SpotFastResolve(actionId, ByRef cx, ByRef cy, tries := 12) {
    global Spots, LastResolveBand
    ; The menu's text heights (words with and without descenders)
    ; - a size check that does not depend on which word a button
    ; shows.
    hMin := 0
    hMax := 0
    for i, k in ["MoveForward", "DropRehit", "MoveBack", "NextOption"] {
        if (Spots.HasKey(k) && !Spots[k].inferred) {
            hv := Spots[k].h
            if (hMin = 0 || hv < hMin)
                hMin := hv
            if (hv > hMax)
                hMax := hv
        }
    }
    cands := []
    if (actionId = "MoveForward")
        cands.Push(["MoveForward", ["move forward"]])
    else if (actionId = "MoveBack")
        cands.Push(["MoveBack", ["move back"]])
    else if (actionId = "NextOption")
        cands.Push(["NextOption", ["next option"]])
    else if (actionId = "DropRehit")
        cands.Push(["DropRehit", ["drop ball", "rehit", "go to dz"]])
    else if (actionId = "Rehit") {
        cands.Push(["ObRehit", ["rehit"]])
        cands.Push(["DropRehit", ["rehit"]])
    }
    useFrame := (actionId = "DropRehit" && Spots.HasKey("MoveForward")
        && Spots.HasKey("MoveBack") && Spots.HasKey("DropRehit"))
    have := useFrame
    for i, c in cands {
        if (Spots.HasKey(c[1]))
            have := true
    }
    if (!have)
        return false
    Loop, %tries% {
        tryN := A_Index
        if (useFrame) {
            if (SpotSlot2Confirm(cx, cy, hMin, hMax)) {
                LastResolveBand := Round(Spots["DropRehit"].h * 2)
                OcrTrace("  locked spot DropRehit confirmed by Move Forward + Move Back, read " . tryN)
                return true
            }
        } else {
            for i, c in cands {
                if (!Spots.HasKey(c[1]))
                    continue
                sp := Spots[c[1]]
                isMenu := (c[1] != "ObRehit")
                hx := sp.w // 2 + sp.h * 2
                hy := Round(sp.h * 1.3)
                o := OcrRegion(sp.x - hx, sp.y - hy, hx * 2, hy * 2)
                for j, ln in o.lines {
                    hit := false
                    for k, nd in c[2] {
                        if (FuzzyIs(ln.text, nd))
                            hit := true
                    }
                    if (!hit || !SpotLineOk(ln, sp, isMenu, hMin, hMax))
                        continue
                    cx := ln.x + ln.w // 2
                    cy := ln.y + ln.h // 2
                    LastResolveBand := Round(sp.h * 2)
                    OcrTrace("  locked spot " . c[1] . " confirmed |" . ln.text . "| read " . tryN)
                    ; A spot learned by inference (its word did not
                    ; read that time) takes the real box the first
                    ; time the word is seen.
                    if (sp.inferred) {
                        Spots[c[1]] := {x: cx, y: cy, w: ln.w, h: ln.h, inferred: 0}
                        SaveSpots()
                    }
                    return true
                }
            }
        }
        if (tryN < tries)
            Sleep, 50
    }
    return false
}

; Is this OCR line the locked button, settled: in its place and
; at its size?  Menu buttons are sized against the menu's own
; text-height range (Drop Ball has a descender, Rehit does not).
; The OB dialog's Rehit button wobbles sideways (field trace:
; 1788 -> 1817 -> 1788), so its sideways tolerance follows the
; word's width.
SpotLineOk(ln, sp, isMenu, hMin, hMax) {
    lx := ln.x + ln.w / 2
    ly := ln.y + ln.h / 2
    tolY := sp.h * 0.25
    if (isMenu && hMax > hMin && (hMax - hMin) / 2 + 4 > tolY)
        tolY := (hMax - hMin) / 2 + 4
    if (!isMenu)
        tolY := sp.h * 0.4
    if (tolY < 5)
        tolY := 5
    tolX := sp.h * 0.6
    if (!isMenu && sp.w * 0.4 > tolX)
        tolX := sp.w * 0.4
    if (tolX < 8)
        tolX := 8
    if (Abs(ly - sp.y) > tolY || Abs(lx - sp.x) > tolX)
        return false
    if (isMenu && hMin > 0)
        return (ln.h >= hMin * 0.8 && ln.h <= hMax * 1.2)
    return (ln.h >= sp.h * 0.72 && ln.h <= sp.h * 1.3)
}

; Drop Ball / Rehit / Go to DZ: one small read covering Move
; Forward, the second button and Move Back.  Both fixed words
; must sit in their locked places at menu size; then the second
; button is clicked - at its word if one reads there, else at
; its locked spot.
SpotSlot2Confirm(ByRef cx, ByRef cy, hMin, hMax) {
    global Spots
    mf := Spots["MoveForward"]
    mb := Spots["MoveBack"]
    s2 := Spots["DropRehit"]
    hx := s2.w // 2 + s2.h * 2
    if (mf.w // 2 + mf.h > hx)
        hx := mf.w // 2 + mf.h
    if (mb.w // 2 + mb.h > hx)
        hx := mb.w // 2 + mb.h
    y1 := Round(mf.y - mf.h * 1.3)
    y2 := Round(mb.y + mb.h * 1.3)
    if (y2 - y1 < 20)
        return false
    o := OcrRegion(s2.x - hx, y1, hx * 2, y2 - y1)
    okF := false
    okB := false
    best := ""
    for i, ln in o.lines {
        if (FuzzyIs(ln.text, "move forward")) {
            if (SpotLineOk(ln, mf, true, hMin, hMax))
                okF := true
            continue
        }
        if (FuzzyIs(ln.text, "move back")) {
            if (SpotLineOk(ln, mb, true, hMin, hMax))
                okB := true
            continue
        }
        if (FuzzyIs(ln.text, "next option") || FuzzyIs(ln.text, "mulligan"))
            continue
        lcy := ln.y + ln.h / 2
        lcx := ln.x + ln.w / 2
        if (Abs(lcy - s2.y) <= s2.h * 0.6 && Abs(lcx - s2.x) <= s2.w)
            best := ln
    }
    if (!okF || !okB)
        return false
    if (IsObject(best)) {
        cx := best.x + best.w // 2
        cy := best.y + best.h // 2
    } else {
        cx := s2.x
        cy := s2.y
    }
    return true
}

; Confirming read for the learn path: just the menu's area
; (around a tenth of a 1440p window), padded so a menu that is
; still settling stays inside it.
ScanMenuArea(ref, win) {
    r := {found: true, lines: [], text: "", lc: "", win: win}
    x1 := Round(ref.colX - ref.wavg * 0.6 - ref.pitch * 2)
    x2 := Round(ref.colX + ref.wavg * 0.6 + ref.pitch * 2)
    y1 := Round(ref.slotY[1] - ref.pitch * 2.3)
    y2 := Round(ref.slotY[4] + ref.pitch * 2.3)
    if (x1 < win.x)
        x1 := win.x
    if (y1 < win.y)
        y1 := win.y
    if (x2 > win.x + win.w)
        x2 := win.x + win.w
    if (y2 > win.y + win.h)
        y2 := win.y + win.h
    if (x2 - x1 < 20 || y2 - y1 < 20)
        return r
    o := OcrRegion(x1, y1, x2 - x1, y2 - y1)
    r.lines := o.lines
    r.text := o.text
    r.lc := LowerStr(o.text)
    return r
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

; The GSPro GAME window: among all windows whose title contains
; the needle (minus the exclude), pick the LARGEST.  GSPro's
; launch-monitor connector app also carries "GSPro" in its
; title; the library's first-match lookup could hand us that
; small window on some PCs and every scan would read the wrong
; thing.  The game is always the biggest window on the machine.
GsproWinRect(include, exclude := "") {
    incL := LowerStr(include)
    excL := LowerStr(exclude)
    best := {found: false}
    bestArea := 0
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
        ; Size floor: a real game window is large.  A browser tab
        ; or an open folder titled "GSPro" never comes close.
        ; (Fixed pixel floor rather than a monitor lookup - fewer
        ; moving parts in the scan path.)
        if (ww < 640 || wh < 480)
            continue
        if (ww * wh > bestArea) {
            bestArea := ww * wh
            best := {found: true, x: wx, y: wy, w: ww, h: wh, hwnd: id, title: t}
        }
    }
    return best
}

; Client-area rect of a window: excludes the title bar, borders
; and minimize/X caption entirely.  Fullscreen GSPro: identical
; to the window rect.  Windowed GSPro: the caption can never
; enter the OCR image.  Falls back to the full window rect if
; the API calls fail.
ClientRectByTitle(include, exclude := "") {
    wr := GsproWinRect(include, exclude)
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

; Capture a screen rectangle UPSCALED by an integer factor
; (HALFTONE stretch), OCR it, and map the boxes back to real
; screen pixels.  Same closed loop - one explicit, reversible
; transform - used only where text would otherwise be at the
; engine's size floor (scramble cards on 1080p projectors).
OcrRegionScaled(x, y, w, h, scale) {
    o := {lines: [], text: ""}
    if (w <= 0 || h <= 0)
        return o
    if (scale <= 1)
        return OcrRegion(x, y, w, h)
    sw := w * scale
    sh := h * scale
    HDC := DllCall("GetDC", "Ptr", 0, "UPtr")
    HBM := DllCall("CreateCompatibleBitmap", "Ptr", HDC, "Int", sw, "Int", sh, "UPtr")
    PDC := DllCall("CreateCompatibleDC", "Ptr", HDC, "UPtr")
    DllCall("SelectObject", "Ptr", PDC, "Ptr", HBM)
    DllCall("SetStretchBltMode", "Ptr", PDC, "Int", 4)
    DllCall("SetBrushOrgEx", "Ptr", PDC, "Int", 0, "Int", 0, "Ptr", 0)
    DllCall("StretchBlt", "Ptr", PDC, "Int", 0, "Int", 0, "Int", sw, "Int", sh
                        , "Ptr", HDC, "Int", x, "Int", y, "Int", w, "Int", h, "UInt", 0x00CC0020)
    DllCall("DeleteDC", "Ptr", PDC)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", HDC)
    stream := HBitmapToRandomAccessStream(HBM)
    DllCall("DeleteObject", "Ptr", HBM)
    res := ocr_words(stream)
    for i, ln in res.lines {
        ln.x := Round(ln.x / scale) + x
        ln.y := Round(ln.y / scale) + y
        ln.w := Round(ln.w / scale)
        ln.h := Round(ln.h / scale)
        o.lines.Push(ln)
    }
    o.text := res.text
    return o
}

; Scramble-watcher scan: client area, upscaled 2x when the
; window is under 1300px tall (1080p and below), where the
; cards' USE and lie text sits at the OCR engine's size floor.
; At 1440p/4K this is the identical full-resolution path.
ScanWinClientAuto(include, exclude := "") {
    r := {found: false, lines: [], text: "", lc: ""}
    wr := ClientRectByTitle(include, exclude)
    if (!wr.found)
        return r
    r.found := true
    r.win := wr
    ; Low resolution (under 1300px tall): the cards' text sits at
    ; the OCR engine's size floor, so read the CARD BAND (center
    ; of the lower half) at 2x - proportional to the window, and
    ; kept under the engine's max image dimension.  If that band
    ; shows no cards, fall through to the normal full scan, so
    ; this can never do worse than the plain path.
    if (wr.h < 1300 && wr.w * 0.6 * 2 <= 2500) {
        bx := wr.x + Round(wr.w * 0.20)
        by := wr.y + Round(wr.h * 0.45)
        bw := Round(wr.w * 0.60)
        bh := Round(wr.h * 0.45)
        o := OcrRegionScaled(bx, by, bw, bh, 2)
        band := {lines: o.lines, text: o.text}
        if (FindAllLinesExact(band, "use").MaxIndex() >= 2) {
            r.lines := o.lines
            r.text  := o.text
            r.lc    := LowerStr(o.text)
            return r
        }
    }
    o := OcrRegion(wr.x, wr.y, wr.w, wr.h)
    r.lines := o.lines
    r.text  := o.text
    r.lc    := LowerStr(o.text)
    return r
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

; Lightweight trace of every Smart Click press: received,
; deferred, resolved, clicked or missed.  Self-wrapped like all
; diagnostics.  ocr_trace.txt answers "did the press even reach
; the engine" without guesswork.
OcrTrace(msg) {
    global ConfigDir
    try {
        f := ConfigDir . "\ocr_trace.txt"
        if (SafeFileSize(f) > 60000)
            SafeFileDelete(f)
        b := A_Hour . ":" . A_Min . ":" . A_Sec . "." . A_MSec . "  " . msg . "`n"
        FileAppend, %b%, %f%
    } catch tErr {
    }
}

; ---- file helpers that can never throw ----
; Inside any try block (and every function called from one),
; AutoHotkey turns a command's ErrorLevel failure into a thrown
; exception.  FileDelete of a file that does not exist yet sets
; ErrorLevel 1, so "delete the old dump, write the new one"
; threw on every PC where the dump had never been written - the
; OCR Test failed, and ocr_trace / ocr_last_miss / error_log
; were silently never created on a fresh install (v5.0.4 field
; log: [OcrTest] 1 | what=FileDelete).  Check first, always.
SafeFileDelete(f) {
    if (!FileExist(f))
        return
    try {
        FileDelete, %f%
    } catch sfdErr {
    }
}
SafeFileSize(f) {
    if (!FileExist(f))
        return 0
    sz := 0
    try {
        FileGetSize, sz, %f%
    } catch sfsErr {
        sz := 0
    }
    return sz + 0
}

; Show a message ON the GSPro window (any monitor), not the
; primary monitor's corner where a player at a projector would
; never see it.  Falls back to the primary corner if no window.
ShowGsproTip(msg, ms) {
    global GSProWinNeedle, GSProWinExclude
    wr := GsproWinRect(GSProWinNeedle, GSProWinExclude)
    tx := 20
    ty := 20
    if (wr.found) {
        tx := wr.x + 30
        ty := wr.y + 30
    }
    CoordMode, ToolTip, Screen
    ToolTip, %msg%, %tx%, %ty%
    SetTimer, ClearOcrTip, % -ms
}

; Park the cursor at the GSPro window's own top-left corner
; (stays on the sim screen on multi-monitor rigs); primary
; corner if the window isn't known.
ParkMouse() {
    global LastScanObj
    if (IsObject(LastScanObj) && LastScanObj.HasKey("win") && LastScanObj.win.found)
        DpiSetCursor(LastScanObj.win.x, LastScanObj.win.y)
    else
        DpiSetCursor(0, 0)
}

; OCR lock watchdog.  AHK runs one thread at a time: a keypress
; that interrupts a scanning timer FREEZES that timer until the
; keypress code returns, so nothing may ever wait on OcrBusy in
; place.  Presses are deferred to a timer instead (OcrDeferred),
; and any lock older than 6s is treated as stale and cleared so
; no glitch can starve the watcher, the clicks, or the prefetch.
OcrLockTake() {
    global OcrBusy, OcrBusySince
    OcrBusy := true
    OcrBusySince := A_TickCount
}
OcrStaleCheck() {
    global OcrBusy, OcrBusySince, ScrambleBusy
    if (OcrBusy && (A_TickCount - OcrBusySince) > 6000) {
        OcrBusy := false
        ScrambleBusy := false
        LogAppError("OcrLock", {Message: "stale OCR lock cleared by watchdog", Line: 0})
    }
}

; Does the active profile map any Smart Click at all?
AnyOcrSecondary() {
    global SecType
    for id, t in SecType {
        if (t = "ocr")
            return true
    }
    return false
}

; Background-failure logger: any runtime error inside a timer
; or the Smart Click engine lands here instead of showing a raw
; error dialog, and the guarding flags always release so one
; glitch can never silently kill a subsystem.
LogAppError(where, e) {
    global ConfigDir, AppVersion
    try {
        f := ConfigDir . "\error_log.txt"
        if (SafeFileSize(f) > 30000)
            SafeFileDelete(f)
        msg := "unknown error"
        try {
            ; What/Extra name the actual command or function that
            ; raised it - the reported Line alone can point at the
            ; wrong statement when the error crosses a call.
            msg := e.Message . " | what=" . e.What . " | extra=" . e.Extra . " | line " . e.Line
        } catch dummy {
        }
        b := A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec
        b .= "  v" . AppVersion . "  [" . where . "]  " . msg . "`n"
        FileAppend, %b%, %f%
    } catch outerErr {
    }
}

; Write the full text of a failed scan for diagnosis.  Every
; "OCR missed it" report is really "the wording was different
; on that machine" - this file shows the exact wording seen.
OcrDumpMiss(context, scan, fname := "ocr_last_miss.txt") {
    global ConfigDir, AppVersion
    try {
    f := ConfigDir . "\" . fname
    SafeFileDelete(f)
    body := "BARemapper OCR diagnostic  (v" . AppVersion . ")`n"
    body .= "Time: " . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "`n"
    body .= "Context: " . context . "`n"
    body .= "------------------------------------------`n"
    ; Every line with its position and size, so a miss shows
    ; exactly what sat where.
    for i, ln in scan.lines
        body .= ln.x . "," . ln.y . "  " . ln.w . "x" . ln.h . "  |" . ln.text . "|`n"
    FileAppend, %body%, %f%
    } catch logErr {
    }
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
;  Decision (Ba's rule): FEWEST STROKES first; among those a
;  ball on the GREEN always wins; then the SHORTEST distance;
;  tie -> first card.  The lie is otherwise ignored - a group
;  that wants the longer ball out of the woods picks it.  Then
;  it SENDS THE KEYSTROKE (1-4) - no clicking involved.
;
;  Stands down (tooltip + diagnostic dump, the players choose)
;  only when a contender's distance cannot be read, when only
;  some shot numbers read, or when a lie word may be a misread
;  GREEN.
; ============================================================
; Letters-only exact match.  GSPro's animated green grid runs
; right up to the card edges, and a moving grid dot absorbed
; into a text line turns "USE" into "USE ." for one frame -
; which used to read as "cards gone" and reset the countdown.
; Stripping non-letters before comparing makes the trigger
; immune to that noise, while real words (HOUSE, MOUSE) still
; cannot false-match.
FindAllLinesExact(scan, needle) {
    nl := RegExReplace(LowerStr(needle), "[^a-z]", "")
    out := []
    for i, ln in scan.lines {
        if (RegExReplace(LowerStr(ln.text), "[^a-z]", "") = nl)
            out.Push({x: ln.x, y: ln.y, w: ln.w, h: ln.h, text: ln.text})
    }
    return out
}

ScrambleDecide(scan, uses, ctx := "") {
    global ScrambleMemo
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
    ; Parse each card: lie row (lie + shot number) and distance
    cards := []
    Loop, %n% {
        c := A_Index
        cx := centers[c]
        useY := uses[c].y
        useH := uses[c].h
        useW := uses[c].w
        topY := useY - useH * 9
        card := {lie: "", green: false, shot: 0, dist: -1, row: "", distRaw: ""}
        ; Every OCR line in this card's column, above its USE
        colLines := []
        for i, ln in scan.lines {
            lcx := ln.x + ln.w // 2
            if (Abs(lcx - cx) > colHalf)
                continue
            if (ln.y >= useY || ln.y < topY)
                continue
            colLines.Push(ln)
        }
        ; ---- Step 1: THE LIE ROW ----
        ; A card reads NAME / DISTANCE / LIE + SHOT / USE.  The
        ; row is anchored on the shot ordinal ("4TH") nearest
        ; above USE - names never carry a whole-word ordinal - or,
        ; when the ordinal misread, on the line closest above USE.
        ; Then EVERY line on that row is joined, left to right:
        ; the OCR engine may return "ROUGH 4TH" as one line or as
        ; two ("ROUGH" | "4TH") depending on the screen size.
        ; v5.0.4 read only the ordinal's own line, so on screens
        ; where the engine split the row it saw "4TH" with no lie
        ; word and stood down (field log: lie unreadable, shot=4,
        ; distances fine).  The joined row handles both forms.
        anchor := ""
        anchorY := -999999
        for i, ln in colLines {
            if (ScrambleOrdinal(ln.text) > 0 && ln.y > anchorY) {
                anchorY := ln.y
                anchor := ln
            }
        }
        ; An ordinal proves this is the lie row; without one the
        ; row is a best guess, so only a known lie word counts.
        anchorProven := IsObject(anchor)
        if (!IsObject(anchor)) {
            for i, ln in colLines {
                if (ln.y > anchorY) {
                    anchorY := ln.y
                    anchor := ln
                }
            }
        }
        rowCy := 0
        rowBand := 0
        if (IsObject(anchor)) {
            rowCy := anchor.y + anchor.h / 2
            rowBand := anchor.h * 0.6
            rowParts := []
            for i, ln in colLines {
                if (Abs((ln.y + ln.h / 2) - rowCy) <= rowBand)
                    rowParts.Push(ln)
            }
            Loop, % rowParts.MaxIndex() - 1 {
                i := A_Index + 1
                j := i
                while (j > 1 && rowParts[j-1].x > rowParts[j].x) {
                    tmp := rowParts[j-1]
                    rowParts[j-1] := rowParts[j]
                    rowParts[j] := tmp
                    j--
                }
            }
            rowText := ""
            for i, p in rowParts
                rowText .= (rowText = "" ? "" : " ") . Trim(p.text)
            card.row := rowText
            lieWord := ScrambleLieWord(rowText, anchorProven)
            if (lieWord != "") {
                card.lie := lieWord
                card.green := (lieWord = "green")
            }
            card.shot := ScrambleShotNumber(rowText)
        }
        ; ---- Earlier frames ----
        ; The cards do not change while they are up, so anything an
        ; earlier frame read clearly fills in what this frame
        ; missed.  On the putting green the animated grid spoils a
        ; different card in each frame (field log 4 Oct: one card's
        ; distance read in frame 1, the other's never in the same
        ; frame) - together the frames read every card.
        mk := n . "-" . c
        mm := ScrambleMemo.HasKey(mk) ? ScrambleMemo[mk] : {dist: -1, distRaw: "", shot: 0, lie: "", green: false}
        if ((card.lie = "" || card.lie = "?green") && mm.lie != "") {
            card.lie := mm.lie
            card.green := mm.green
        }
        if (card.shot = 0 && mm.shot > 0)
            card.shot := mm.shot
        ; ---- Step 2: DISTANCE ----
        ; The tallest line ABOVE the lie row, centered on the card
        ; (the corner badge digit sits far off-center), taller than
        ; the USE text.  Stand-alone grid marks ("l", "|", "!" - a
        ; green-grid line crossing the card) are dropped first.
        ; Then any LETTER disqualifies a yards distance - a mangled
        ; "143" read as "!4E" must never strip down to "4" - but on
        ; the GREEN, feet-and-inches is accepted with its two marks
        ; misread as anything ("9l 7u" is 9' 7").
        distH := 0
        distClean := ""
        distDirect := -1
        for i, ln in colLines {
            lcx := ln.x + ln.w // 2
            if (Abs(lcx - cx) > useW * 0.8)
                continue
            if (IsObject(anchor) && (ln.y + ln.h / 2) >= rowCy - rowBand)
                continue
            if (ln.h <= useH || ln.h <= distH)
                continue
            t := ScrambleStripMarks(ln.text)
            if (!RegExMatch(t, "i)[a-z]")) {
                clean := RegExReplace(t, "[^0-9 ]", " ")
                clean := Trim(RegExReplace(clean, " +", " "))
                if (clean != "" && RegExMatch(clean, "^\d+( \d+){0,2}$")) {
                    distH := ln.h
                    distClean := clean
                    distDirect := -1
                    card.distRaw := t
                }
            } else if (card.green) {
                if (RegExMatch(t, "^\D{0,2}(\d{1,3})\D{1,3}(\d{1,2})\D{0,3}$", fm) && fm2 <= 11) {
                    distH := ln.h
                    distClean := ""
                    distDirect := fm1 * 12 + fm2
                    card.distRaw := t
                }
            }
        }
        ; Convert to inches.  Feet (+inches) when the card is on
        ; the green or the distance carries a feet/inch mark;
        ; otherwise yards.
        if (distDirect >= 0) {
            card.dist := distDirect
        } else if (distClean != "") {
            feetMarks := "['" . Chr(34) . Chr(145) . Chr(146) . Chr(147) . Chr(148) . "``]"
            if (card.green || RegExMatch(card.distRaw, feetMarks) || InStr(distClean, " "))
                card.dist := FeetInches(card.distRaw)
            else
                card.dist := distClean * 36
        }
        if (card.dist < 0 && mm.dist >= 0) {
            card.dist := mm.dist
            card.distRaw := mm.distRaw . " (earlier frame)"
        }
        ; Remember what this frame read clearly.
        if (card.dist >= 0 && !InStr(card.distRaw, "(earlier frame)")) {
            mm.dist := card.dist
            mm.distRaw := card.distRaw
        }
        if (card.shot > 0)
            mm.shot := card.shot
        if (card.lie != "" && card.lie != "?green") {
            mm.lie := card.lie
            mm.green := card.green
        }
        ScrambleMemo[mk] := mm
        cards.Push(card)
    }
    ; The lie itself never blocks a pick (rough, concrete, woods
    ; - players who want the longer ball from a bad lie choose it
    ; themselves).  The ONE lie that changes the decision is
    ; GREEN, so a word that may be a badly misread GREEN stands
    ; down rather than risk breaking the green rule.
    Loop, %n% {
        if (cards[A_Index].lie = "?green") {
            ScrambleLogDecision(n, cards, 0, 0, "GATE: card " . A_Index . " lie may be a misread GREEN" . ctx)
            return 0
        }
    }
    ; Shot numbers: if NONE were readable, everyone is treated
    ; as equal (the original behavior, proven live).  If only
    ; SOME read, the comparison would be a guess - stand down.
    knownShots := 0
    Loop, %n% {
        if (cards[A_Index].shot >= 1)
            knownShots += 1
    }
    if (knownShots = 0) {
        Loop, %n%
            cards[A_Index].shot := 1
    } else if (knownShots < n) {
        ScrambleLogDecision(n, cards, 0, 0, "GATE: shot numbers partial" . ctx)
        return 0
    }
    ; PENALTY RULE: the fewest-strokes balls are considered
    ; FIRST, absolutely.  A 2nd-shot ball always beats a closer
    ; 3rd-shot ball (someone who took a penalty drop may sit
    ; closer, but choosing them costs the group a stroke).
    minShot := 99
    Loop, %n% {
        if (cards[A_Index].shot < minShot)
            minShot := cards[A_Index].shot
    }
    ; Green check runs among the eligible (fewest-shot) balls
    anyGreen := false
    Loop, %n% {
        if (cards[A_Index].shot = minShot && cards[A_Index].green)
            anyGreen := true
    }
    ; Decision within eligible: green first, then lowest
    ; distance; tie -> first card
    bestIdx := 0
    bestVal := 0x7FFFFFFF
    Loop, %n% {
        c := A_Index
        if (cards[c].shot != minShot)
            continue
        if (anyGreen && !cards[c].green)
            continue
        ; Gate 2: contender distances must parse
        if (cards[c].dist < 0) {
            ScrambleLogDecision(n, cards, minShot, 0, "GATE: contender distance unreadable" . ctx)
            return 0
        }
        if (cards[c].dist < bestVal) {
            bestVal := cards[c].dist
            bestIdx := c
        }
    }
    ScrambleLogDecision(n, cards, minShot, bestIdx, "OK" . ctx)
    return bestIdx
}

; Drop stand-alone marks that are not part of a number: a grid
; line on the putting green crossing a card reads as "l", "I",
; "|", "!" or a dot.
ScrambleStripMarks(t) {
    t := " " . t . " "
    t := RegExReplace(t, "(?<=\s)[lIi|!.:;,]+(?=\s)", " ")
    return Trim(RegExReplace(t, "\s+", " "))
}

; Shot number from a whole-word ordinal ("2ND", "3RD", "4TH").
; Whole word only: a badge digit merged into a name ("2 THOMAS",
; "1 STEVE") must not read as an ordinal.  Returns 0 if none.
ScrambleOrdinal(t) {
    if (RegExMatch(t, "i)(?:^|[^a-z0-9])([1-9])\s?(st|nd|rd|th)(?![a-z])", m))
        return m1 + 0
    return 0
}

; Green distance (feet + inches, e.g. 14' 7") to inches.  The
; OCR engine often reads the ' mark as a "1" (field log 4 Oct:
; 14' 7" -> "141 7"" and 33' 10" -> "33110""), which v5.0.5 took
; as 141 ft and 33110 ft.  With an inch mark present, a trailing
; 1 on the feet is that misread mark; inches are 0-11, so in a
; run with no space the last digit (or a final 10/11) is inches.
; Returns -1 if nothing usable.
FeetInches(raw) {
    q := Chr(34)
    t := raw
    t := StrReplace(t, Chr(147), q)
    t := StrReplace(t, Chr(148), q)
    t := StrReplace(t, "''", q)
    t := StrReplace(t, Chr(145), "'")
    t := StrReplace(t, Chr(146), "'")
    t := StrReplace(t, "``", "'")
    ; An explicit feet mark: split on it.
    ap := InStr(t, "'")
    if (ap) {
        ft := RegExReplace(SubStr(t, 1, ap - 1), "[^0-9]", "")
        inch := RegExReplace(SubStr(t, ap + 1), "[^0-9]", "")
        if (ft = "")
            return -1
        if (inch = "")
            inch := 0
        return ft * 12 + inch
    }
    hasQ := InStr(t, q)
    d := Trim(RegExReplace(RegExReplace(t, "[^0-9 ]", " "), " +", " "))
    if (d = "")
        return -1
    if (InStr(d, " ")) {
        parts := StrSplit(d, " ")
        a := parts[1]
        inch := parts[parts.MaxIndex()]
        if (hasQ && StrLen(a) >= 2 && SubStr(a, 0) = "1")
            a := SubStr(a, 1, StrLen(a) - 1)
        return a * 12 + inch
    }
    if (!hasQ || StrLen(d) < 3)
        return d * 12
    last2 := SubStr(d, -1)
    if (last2 = "10" || last2 = "11") {
        inch := last2 + 0
        a := SubStr(d, 1, StrLen(d) - 2)
    } else {
        inch := SubStr(d, 0) + 0
        a := SubStr(d, 1, StrLen(d) - 1)
    }
    if (StrLen(a) >= 2 && SubStr(a, 0) = "1")
        a := SubStr(a, 1, StrLen(a) - 1)
    if (a = "")
        return -1
    return a * 12 + inch
}

; Shot number from the joined lie row.  The clean ordinal first;
; then a digit with a misread suffix ("4IH"); then a suffix whose
; digit misread ("ZND" -> 2, "IST" -> 1, "3RO" keeps its 3).
ScrambleShotNumber(rowText) {
    s := ScrambleOrdinal(rowText)
    if (s > 0)
        return s
    if (RegExMatch(rowText, "i)(?:^|[^a-z0-9])([1-9])[a-z]{1,2}(?![a-z])", m))
        return m1 + 0
    if (RegExMatch(rowText, "i)(?:^|[^a-z0-9])[a-z0-9](nd|rd|st)(?![a-z])", m)) {
        sfx := LowerStr(m1)
        if (sfx = "nd")
            return 2
        if (sfx = "rd")
            return 3
        if (sfx = "st")
            return 1
    }
    return 0
}

; The lie, read from the joined row.  Only GREEN changes the
; decision, so the rules are built around it:
;   1. a word that reads as GREEN (one misread letter allowed)
;      -> "green"
;   2. a known lie word (one misread letter allowed on long ones)
;   3. a word that could be a BADLY misread GREEN (two letters
;      off) -> "" : stand down rather than score it as rough
;   4. any other real word is accepted as an ordinary lie.
; v5.0.5 stopped at step 2, so a lie GSPro has that was not on
; the list - CONCRETE, in the field log, read perfectly - counted
; as unreadable and the pick stood down.  GSPro adds surfaces
; with course designers' choices; the list can never be complete,
; and it does not need to be: only "is it green" matters.
ScrambleLieWord(rowText, allowUnknown := true) {
    static words := ["fairway", "rough", "deep", "fringe", "collar", "apron", "tee"
        , "sand", "bunker", "waste", "native", "pine", "straw", "recovery", "fescue"
        , "path", "cart", "cartpath", "dirt", "mulch", "hardpan", "gravel", "rock", "rocks"
        , "wood", "woods", "leaves", "grass", "heather", "gorse", "tree", "trees", "hazard"
        , "water", "drop", "desert", "mud", "first", "cut", "area", "concrete", "asphalt"
        , "bridge", "stone", "brick", "pavement", "deck", "boardwalk", "chips", "bark"]
    t := LowerStr(rowText)
    ; A digit misread INSIDE a word splits it ("R0UGH" would read
    ; as "r" + "ugh"): map the usual look-alikes back to letters,
    ; and drop any other digit that sits between two letters.
    t := RegExReplace(t, "(?<=[a-z])0(?=[a-z])", "o")
    t := RegExReplace(t, "(?<=[a-z])1(?=[a-z])", "i")
    t := RegExReplace(t, "(?<=[a-z])5(?=[a-z])", "s")
    t := RegExReplace(t, "(?<=[a-z])[0-9](?=[a-z])", "")
    t := RegExReplace(t, "[^a-z]+", " ")
    ; Word tokens, minus what is left of the shot ordinal after the
    ; digit is stripped ("2ND" -> "nd", a misread "ZND" -> "znd").
    toks := []
    Loop, Parse, t, %A_Space%
    {
        tok := A_LoopField
        if (StrLen(tok) < 3)
            continue
        if (RegExMatch(tok, "^[a-z](st|nd|rd|th)$"))
            continue
        toks.Push(tok)
    }
    ; 1. GREEN
    for i, tok in toks {
        if (tok = "green")
            return "green"
        if (Abs(StrLen(tok) - 5) <= 1 && LevDist(tok, "green") <= 1)
            return "green"
    }
    ; 2. a known lie word
    for i, tok in toks {
        for k, w in words {
            if (tok = w)
                return w
            if (StrLen(w) >= 5 && Abs(StrLen(tok) - StrLen(w)) <= 1 && LevDist(tok, w) <= 1)
                return w
        }
    }
    ; 3. possibly a mangled GREEN: never guess
    for i, tok in toks {
        if (Abs(StrLen(tok) - 5) <= 2 && LevDist(tok, "green") <= 2)
            return "?green"
    }
    ; 4. any other real word (has a vowel - "XQZT" is noise), but
    ;    only on a row the shot ordinal proved is the lie row: a
    ;    guessed row could be a player's name.
    if (!allowUnknown)
        return ""
    for i, tok in toks {
        if (RegExMatch(tok, "[aeiouy]"))
            return tok
    }
    return ""
}

; ---- diagnostics must never break the feature ----
; Every writer below is self-contained: any failure inside is
; swallowed, so a logging problem can never abort a pick, a
; click, or a scan.  (v5.0.2 shipped the scramble logger
; UNPROTECTED inside the decision path: when it threw,
; ScrambleDecide never returned and the keystroke was never
; sent - the countdown finished and nothing happened.)

; Written on EVERY pick attempt, success or stand-down, so any
; wrong or missing pick arrives with its own explanation:
; Documents\BA Custom Products\Remapper\scramble_last_decision.txt
; and appended to scramble_log.txt (the last ~100 attempts), so
; an earlier failure is not lost when a later pick succeeds.
ScrambleLogDecision(n, cards, minShot, winner, note) {
    global ConfigDir, AppVersion
    try {
        b := "BARemapper scramble decision  (v" . AppVersion . ")`n"
        b .= "Time: " . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "`n"
        b .= "Cards: " . n . "   MinShot: " . minShot . "   Winner: " . winner . "   " . note . "`n"
        Loop, %n% {
            cd := cards[A_Index]
            b .= "  card " . A_Index . ": lie=" . cd.lie . "  green=" . (cd.green ? 1 : 0)
            b .= "  shot=" . cd.shot . "  dist_inches=" . cd.dist
            b .= "   read: row=|" . cd.row . "|  distance=|" . cd.distRaw . "|`n"
        }
        f := ConfigDir . "\scramble_last_decision.txt"
        SafeFileDelete(f)
        FileAppend, %b%, %f%
        lf := ConfigDir . "\scramble_log.txt"
        if (SafeFileSize(lf) > 60000)
            SafeFileDelete(lf)
        lb := b . "`n"
        FileAppend, %lb%, %lf%
    } catch logErr {
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
LoadSpots()
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
Menu, Tray, Add, Reset Smart Click spots, ResetSmartSpots
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
    OcrStaleCheck()
    if (OcrBusy) {
        SetTimer, OcrVerifyTick, -300
        Return
    }
    OcrLockTake()
    vAgain := false
    try {
        vx := 0
        vy := 0
        if (SpotsValidNow()) {
            vHit := SpotFastResolve(VerifyActionId, vx, vy, 1)
        } else {
            vScan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
            vHit := ResolveOcrTarget(VerifyActionId, vScan, vx, vy)
        }
        if (vHit && Abs(vy - VerifyY) < VerifyBandPx)
            vAgain := true
    } catch appErr {
        LogAppError("ClickVerify", appErr)
    }
    OcrBusy := false
    ; The lock is released between the two looks, so a press in
    ; the meantime is never kept waiting behind this check (and a
    ; press cancels the pending re-click outright).
    if (vAgain)
        SetTimer, OcrVerifyTick2, -450
    else
        VerifyActionId := ""
Return

OcrVerifyTick2:
    if (VerifyActionId = "")
        Return
    OcrStaleCheck()
    if (OcrBusy) {
        SetTimer, OcrVerifyTick2, -200
        Return
    }
    OcrLockTake()
    try {
        vx := 0
        vy := 0
        if (SpotsValidNow()) {
            vHit := SpotFastResolve(VerifyActionId, vx, vy, 1)
        } else {
            vScan2 := ScanWinClient(GSProWinNeedle, GSProWinExclude)
            vHit := ResolveOcrTarget(VerifyActionId, vScan2, vx, vy)
        }
        if (vHit && Abs(vy - VerifyY) < VerifyBandPx) {
            OcrTrace("  verify: " . VerifyActionId . " still on screen - clicked again at " . vx . "," . vy)
            DpiClickAt(vx, vy)
            ParkMouse()
        }
    } catch appErr {
        LogAppError("ClickVerify", appErr)
    }
    VerifyActionId := ""
    OcrBusy := false
Return

; FN-hold prefetch: one background scan into the shared cache.
OcrPrefetch:
    ; Locked spots confirm with their own small read - a full
    ; prefetch would only hold the lock the press needs.
    if (SpotsValidNow())
        Return
    OcrStaleCheck()
    if (OcrBusy) {
        if (FnIsDown)
            SetTimer, OcrPrefetch, -300   ; keep the FN-held chain alive
        Return
    }
    OcrLockTake()
    try {
        pfScan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
        if (pfScan.found) {
            LastScanObj := pfScan
            LastScanTick := A_TickCount
        }
    } catch appErr {
        LogAppError("Prefetch", appErr)
    }
    OcrBusy := false
    ; Keep the cache warm for as long as FN stays held, so a
    ; player who reads the menu for a while never waits on a
    ; scan when the arrow finally lands.
    if (FnIsDown)
        SetTimer, OcrPrefetch, -1500
Return

; Deferred Smart Click: fires the queued press as soon as the
; OCR lock is free (up to 3s), from a timer thread so the scan
; holding the lock is never frozen underneath a waiting press.
OcrDeferred:
    if (PendingOcrAction = "")
        Return
    OcrStaleCheck()
    if (OcrBusy) {
        ; The scan holding the lock is a single read (well under
        ; a second); this timer returns between checks so that
        ; read keeps running.  Forcing the lock open used to start
        ; a second recognition on top of the first - both could
        ; fail together (field log: SmartClick + ClickVerify in
        ; the same second).  A genuinely stuck lock is cleared by
        ; OcrStaleCheck after 6s, and the press then runs.
        SetTimer, OcrDeferred, -60
        Return
    }
    dfAct := PendingOcrAction
    PendingOcrAction := ""
    RunOcrAction(dfAct)
Return

; Parks the cursor at the corner once a click burst ends (kept
; hovering between rapid repeats so repeat clicks are instant).
ParkTick:
    try {
        if (A_TickCount - LastFireTick >= 1100 && !OcrBusy) {
            ParkMouse()
            LastActionId := ""
            LastClickX := 0
            LastClickY := 0
        } else {
            SetTimer, ParkTick, -400
        }
    } catch appErr {
        LogAppError("Park", appErr)
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
    try {
    if (!ScrambleCountdown || !ScrambleAutoPick || ScrambleArmedTick = 0 || ScrambleCoolDown) {
        if (CdVisible) {
            Gui, Countdown:Destroy
            CdVisible := false
        }
        Return
    }
    cdWr := GsproWinRect(GSProWinNeedle, GSProWinExclude)
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
    ; If the pick has not fired within 5s past zero, something
    ; upstream stalled - hide rather than sit on "0s" forever.
    if ((A_TickCount - ScrambleArmedTick) > (ScrambleDelaySec * 1000 + 5000)) {
        if (CdVisible) {
            Gui, Countdown:Destroy
            CdVisible := false
        }
        Return
    }
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
        if (cdX = "")
            cdX := cdWr.x + 100   ; blank-proof only: negative is valid (left monitor)
        Gui, Countdown:Show, x%cdX% y%cdY% NoActivate
        DllCall("SetWindowDisplayAffinity", "Ptr", CdHwndVar, "UInt", 0x11)
        CdVisible := true
    } else {
        GuiControl, Countdown:, CdText, Auto-pick: %cdRemain%s
        cdX := cdWr.x + (cdWr.w - CdWinW) // 2
        if (cdX = "")
            cdX := cdWr.x + 100
        Gui, Countdown:Show, x%cdX% y%cdY% NoActivate
    }
    } catch appErr {
        LogAppError("Countdown", appErr)
    }
Return

; Tray-menu diagnostic: dump exactly what the OCR reads right
; now (GSPro window if found, else all monitors) with line
; coordinates.  This is the tuning loop for needles and the
; scramble trigger on any machine.
TrayOcrDump:
    ; One OCR engine is shared by the watcher, the Smart Clicks
    ; and this test: wait for any scan in flight instead of
    ; starting a second recognition underneath it.
    OcrStaleCheck()
    if (OcrBusy) {
        SetTimer, TrayOcrDump, -150
        Return
    }
    OcrLockTake()
    dOk := false
    dFile := ConfigDir . "\ocr_last_scan.txt"
    try {
        dScan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
        dMode := "GSPro window client area (title contains 'gspro')"
        if (dScan.found)
            dMode := "GSPro window '" . dScan.win.title . "' client area " . dScan.win.w . "x" . dScan.win.h . " at " . dScan.win.x . "," . dScan.win.y
        if (!dScan.found) {
            dScan := ScanScreen()
            dMode := "FULL SCREEN (no window title containing 'gspro' was found!)"
        }
        SafeFileDelete(dFile)
        dBody := "BARemapper OCR test dump  (v" . AppVersion . ")`n"
        dBody .= "Time: " . A_YYYY . "-" . A_MM . "-" . A_DD . " " . A_Hour . ":" . A_Min . ":" . A_Sec . "`n"
        dBody .= "Scanned: " . dMode . "`n"
        dBody .= "Lines found: " . (dScan.lines.MaxIndex() = "" ? 0 : dScan.lines.MaxIndex()) . "`n"
        dBody .= "------------------------------------------`n"
        for dI, dLn in dScan.lines
            dBody .= dLn.x . "," . dLn.y . "  " . dLn.w . "x" . dLn.h . "  |" . dLn.text . "|`n"
        ; Scramble cards on screen: show what the picker would
        ; choose from this exact frame (no key is sent).
        dUses := FindAllLinesExact(dScan, "use")
        if (dUses.MaxIndex() >= 2) {
            dWin := ScrambleDecide(dScan, dUses, " (OCR Test, no key sent)")
            dBody .= "------------------------------------------`n"
            dBody .= "Scramble cards seen: " . dUses.MaxIndex() . "   would pick: " . (dWin > 0 ? dWin : "NONE - see scramble_last_decision.txt") . "`n"
        }
        FileAppend, %dBody%, %dFile%
        dOk := true
    } catch appErr {
        LogAppError("OcrTest", appErr)
    }
    OcrBusy := false
    if (dOk) {
        TrayTip, BA Remapper, OCR dump written to ocr_last_scan.txt, 4, 1
        Run, notepad.exe "%dFile%"
    } else {
        TrayTip, BA Remapper, OCR Test failed - see error_log.txt, 4, 2
    }
Return

; Forget this PC's locked Smart Click spots; the next press
; re-learns them with two full screen reads.
ResetSmartSpots:
    Spots := {}
    SpotWin := ""
    SaveSpots()
    TrayTip, BA Remapper, Smart Click spots cleared - the next press re-learns them, 4, 1
Return

; One-time OCR engine warm-up (first call pays ~1s engine
; init; do it in the background at launch, not on the first
; real button press at the tee).
OcrWarmup:
    OcrStaleCheck()
    if (OcrBusy) {
        SetTimer, OcrWarmup, -500
        Return
    }
    OcrLockTake()
    try {
        OcrRegion(0, 0, 48, 48)
    } catch appErr {
        LogAppError("OcrWarmup", appErr)
    }
    OcrWarmedUp := true
    OcrBusy := false
Return

ScrambleTick:
    ; One OCR call at a time: if a Smart Click scan is in flight
    ; this tick is skipped (the next comes in 2s); while the
    ; watcher scans, a press waits on OcrBusy instead of
    ; interleaving two engine calls.  While FN is held a Smart
    ; Click is coming: the watcher stands aside so the press
    ; never waits behind a full-window read.
    if (FnIsDown)
        Return
    OcrStaleCheck()
    if (ScrambleBusy || OcrBusy)
        Return
    ScrambleBusy := true
    OcrLockTake()
    try {
        Gosub, ScrambleWork
    } catch appErr {
        LogAppError("ScrambleWatcher", appErr)
    }
    OcrBusy := false
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
        ; Cards not seen THIS scan.  The animated green grid can
        ; spoil a single frame, so require TWO consecutive empty
        ; scans (~4s) before treating the screen as really gone -
        ; a one-frame flicker can no longer reset the countdown,
        ; while a genuine manual pick still cancels cleanly.
        ScrambleMissTicks += 1
        if (ScrambleMissTicks < 2)
            Return
        ScrambleArmedTick := 0
        ScrambleCoolDown := false
        ScrambleDumped := false
        ScrambleMissTicks := 0
        ScrambleTries := 0
        ScrambleMemo := {}
        Return
    }
    ScrambleMissTicks := 0
    if (ScrambleCoolDown)
        Return   ; already acted on this appearance; wait for it to clear
    if (ScrambleArmedTick = 0) {
        ScrambleArmedTick := A_TickCount
        ScrambleMemo := {}
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
        ScrambleCoolDown := true
        ScrambleArmedTick := 0
        ScrambleTries := 0
        Return
    }
    ; Parse failed on THIS frame.  On the putting green the
    ; animated grid runs right around the cards and can spoil a
    ; single capture, so give the next frames a chance (4 tries,
    ; one per 2s watcher tick) before standing down - a one-frame
    ; glitch used to end the pick permanently.
    ScrambleTries += 1
    if (ScrambleTries < 6) {
        ScrambleArmedTick := A_TickCount - (ScrambleDelaySec * 1000)
        Return
    }
    if (!ScrambleDumped) {
        OcrDumpMiss("Scramble parse failure", scrScan, "ocr_last_scramble_miss.txt")
        ShowGsproTip("Auto-pick: could not read all cards - please pick manually", 2500)
        ScrambleDumped := true
    }
    ScrambleCoolDown := true
    ScrambleArmedTick := 0
    ScrambleTries := 0
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
      Forward, Move Back, Next Option, Drop Ball / Rehit
      (also "Go to DZ" in a water drop zone), OB Rehit.
      Needs Windows 10 or 11.
      The first press on a PC learns where the menu buttons
      sit and LOCKS them in - every press after that is
      fast.  Changed the resolution?  It re-learns by itself
      on the next press (or tray menu: Reset Smart Click
      spots).
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
    wins; otherwise the shortest distance.  The lie is not
    judged: if the group wants a longer ball from a better
    lie than one in the woods, pick it yourself before the
    countdown ends.  Pick manually any time - if the cards close,
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

    ; NULL-SAFE: any failed step returns an EMPTY read (the caller
    ; simply reads the next frame) instead of calling into a null
    ; object.  Before, one failed async step made the next DllCall
    ; target address "" -> ErrorLevel -4 -> thrown inside the
    ; caller's try, aborting that scan, click or pick outright
    ; (field log: "-4" entries in SmartClick/ScrambleWatcher).
    if (!file)
        return out
    IRandomAccessStream := file
    BitmapDecoder := 0
    DllCall(NumGet(NumGet(BitmapDecoderStatics + 0) + 14 * A_PtrSize), "ptr", BitmapDecoderStatics, "ptr", IRandomAccessStream, "ptr*", BitmapDecoder)   ; CreateAsync
    WaitForAsync(BitmapDecoder)
    if (!BitmapDecoder) {
        OcrDebug("OCR: image decode failed - frame skipped")
        CleanupStream(IRandomAccessStream)
        return out
    }
    BitmapFrame := ComObjQuery(BitmapDecoder, IBitmapFrame := "{72A49A1C-8081-438D-91BC-94ECFC8185C6}")
    if (!BitmapFrame) {
        CleanupStream(IRandomAccessStream)
        ObjRelease(BitmapDecoder)
        return out
    }
    DllCall(NumGet(NumGet(BitmapFrame + 0) + 12 * A_PtrSize), "ptr", BitmapFrame, "uint*", width)
    DllCall(NumGet(NumGet(BitmapFrame + 0) + 13 * A_PtrSize), "ptr", BitmapFrame, "uint*", height)
    if (width > MaxDimension) || (height > MaxDimension) {
        OcrDebug("OCR skipped a capture too large: " width "x" height " (max " MaxDimension ").")
        CleanupStream(IRandomAccessStream)
        ObjRelease(BitmapDecoder), ObjRelease(BitmapFrame)
        return out
    }
    BitmapFrameWithSoftwareBitmap := ComObjQuery(BitmapDecoder, IBitmapFrameWithSoftwareBitmap := "{FE287C9A-420C-4963-87AD-691436E08383}")
    if (!BitmapFrameWithSoftwareBitmap) {
        CleanupStream(IRandomAccessStream)
        ObjRelease(BitmapDecoder), ObjRelease(BitmapFrame)
        return out
    }
    SoftwareBitmap := 0
    DllCall(NumGet(NumGet(BitmapFrameWithSoftwareBitmap + 0) + 6 * A_PtrSize), "ptr", BitmapFrameWithSoftwareBitmap, "ptr*", SoftwareBitmap)   ; GetSoftwareBitmapAsync
    WaitForAsync(SoftwareBitmap)
    if (!SoftwareBitmap) {
        OcrDebug("OCR: bitmap conversion failed - frame skipped")
        CleanupStream(IRandomAccessStream)
        ObjRelease(BitmapDecoder), ObjRelease(BitmapFrame), ObjRelease(BitmapFrameWithSoftwareBitmap)
        return out
    }
    OcrResult := 0
    DllCall(NumGet(NumGet(OcrEngine + 0) + 6 * A_PtrSize), "ptr", OcrEngine, "ptr", SoftwareBitmap, "ptr*", OcrResult)   ; RecognizeAsync
    WaitForAsync(OcrResult)
    if (!OcrResult) {
        OcrDebug("OCR: recognition failed - frame skipped")
        CleanupStream(IRandomAccessStream)
        CleanupBitmap(SoftwareBitmap)
        ObjRelease(BitmapDecoder), ObjRelease(BitmapFrame), ObjRelease(BitmapFrameWithSoftwareBitmap)
        return out
    }

    LinesList := 0
    DllCall(NumGet(NumGet(OcrResult + 0) + 6 * A_PtrSize), "ptr", OcrResult, "ptr*", LinesList)   ; get_Lines
    if (!LinesList) {
        CleanupStream(IRandomAccessStream)
        CleanupBitmap(SoftwareBitmap)
        ObjRelease(BitmapDecoder), ObjRelease(BitmapFrame), ObjRelease(BitmapFrameWithSoftwareBitmap), ObjRelease(OcrResult)
        return out
    }
    lineCount := 0
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
    if (!Object) {
        Object := 0
        return
    }
    AsyncInfo := ComObjQuery(Object, IAsyncInfo := "{00000036-0000-0000-C000-000000000046}")
    if (!AsyncInfo) {
        ObjRelease(Object)
        Object := 0
        return
    }
    loop {
        DllCall(NumGet(NumGet(AsyncInfo + 0) + 7 * A_PtrSize), "ptr", AsyncInfo, "uint*", status)   ; Status
        if (status != 0) {
            if (status != 1) {
                DllCall(NumGet(NumGet(AsyncInfo + 0) + 8 * A_PtrSize), "ptr", AsyncInfo, "uint*", ErrorCode)
                OcrDebug("OCR async error: " ErrorCode)
                ObjRelease(AsyncInfo)
                ObjRelease(Object)
                Object := 0
                return
            }
            ObjRelease(AsyncInfo)
            break
        }
        sleep 10
    }
    ObjectResult := 0
    DllCall(NumGet(NumGet(Object + 0) + 8 * A_PtrSize), "ptr", Object, "ptr*", ObjectResult)   ; GetResults
    ObjRelease(Object)
    Object := ObjectResult
}

