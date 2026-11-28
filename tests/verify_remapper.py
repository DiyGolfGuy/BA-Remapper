"""Regression checks; Windows runtime tests use a temporary copy and data directory.

python tests/verify_remapper.py --baseline path/to/v5.0.9.ahk
python tests/verify_remapper.py --ahk path/to/AutoHotkeyU64.exe
"""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASE = "a5f762113cc2645a385277b4e4941453c8527b63"


def annotate(level, title, text):
    """On GitHub Actions, also surface text as a check annotation."""
    if os.environ.get("GITHUB_ACTIONS") != "true":
        return
    chunks, cur = [], ""
    for line in text.replace("\r", "").split("\n"):
        if len(cur) + len(line) > 3000 and cur:
            chunks.append(cur)
            cur = ""
        cur += line[:2900] + "\n"
    if cur.strip():
        chunks.append(cur)
    for n, chunk in enumerate(chunks[:8]):
        body = chunk.replace("%", "%25").replace("\n", "%0A")
        print(f"::{level} title={title}{' (' + str(n + 1) + ')' if len(chunks) > 1 else ''}::{body}")


def function(source, name):
    match = re.search(r"(?ms)^" + re.escape(name) + r"\([^\n]*\) \{\n.*?^\}", source)
    assert match, f"Missing function: {name}"
    return match.group()


def static_checks(source, baseline):
    # Compare the production algorithms to the known working release.
    unchanged = [
        "RunOcrAction", "ResolveOcrTarget", "FindMenuLattice", "FindObPair",
        "LearnSpots", "SpotFastResolve", "SpotSlot2Confirm", "SaveSpots",
        "LoadSpots", "DpiClickAt", "DpiRepeatClick", "GsproWinRect",
        "ClientRectByTitle", "ScrambleDecide", "ScrambleSendPick",
        "ScrambleVoteLeader", "ScrambleCountRead",
        "ScrambleVoteSummary", "ScrambleKeepRead",
        "SetAutoStart", "EnsureStartupApproved", "RefreshAutoStartPath",
        "ScanWinClient", "ScanScreen", "OcrRegion", "ocr_words",
    ]
    for name in unchanged:
        assert function(source, name) == function(baseline, name), f"Unexpected core change: {name}"
    # A label (or hotkey) above the end of the auto-execute section would
    # be run, or end startup, before the window and timers exist.
    auto_end = source.index("SetTimer, OcrWarmup, -3000\nReturn")
    early = re.findall(r"(?m)^([A-Za-z_][A-Za-z0-9_]*:|[^;\s][^\n]*::)\s*$", source[:auto_end])
    assert not early, f"Labels or hotkeys before the end of startup: {early}"
    print("PASS: no labels or hotkeys interrupt the startup section")
    for start, end in [
        ("TrayOcrDump:", "; Forget this PC's locked Smart Click spots"),
        ("ScrambleWork:", "OnOpenFolder:"),
        (";  BOX KEY HOTKEYS", ";  HELP WINDOW"),
        ("ExitLabel:", "; ============================================================================"),
    ]:
        # Section comments may surround a block; compare the complete original block.
        old = baseline[baseline.index(start):baseline.index(end, baseline.index(start))]
        if start == "ScrambleWork:":
            # v5.1.2 adds just one recovery call; countdown, cancellation,
            # voting, cooldown, and sending logic must remain untouched.
            old = old.replace('    scrUses := FindAllLinesExact(scrScan, "use")',
                              '    scrScan := ScrambleRecoverCards(scrScan)\n    scrUses := ScrambleButtons(scrScan)', 1)
        # v5.1.5: GSPro renamed the card button USE -> Select; the one
        # card-button lookup in each preserved block accepts both words.
        old = old.replace('        dUses := FindAllLinesExact(dScan, "use")', '        dUses := ScrambleButtons(dScan)', 1)
        # The highlight only observes reads and hides before sending. Strip
        # the explicitly tagged visual hooks, then require the original
        # watcher/cancel/deadline/send code, including its branch structure.
        preserved = source.replace('        if (ScrambleCardsStillUp()) { ; preview only',
                                   '        if (ScrambleCardsStillUp())')
        preserved = "\n".join(line for line in preserved.split("\n") if not line.endswith('; preview only'))
        assert old in preserved, f"Unexpected change to preserved section: {start}"
    # v5.1.5: the still-up check counts USE or Select words; nothing else changed.
    expected_still_up = function(baseline, "ScrambleCardsStillUp").replace(
        '    ; Count USE words, not lines: in a strip this small the reader\n    ; may join two buttons on one baseline into "USE USE".',
        '    ; Count USE/Select words, not lines: in a strip this small the\n    ; reader may join two buttons on one baseline into "USE USE".', 1
    ).replace('            if (A_LoopField = "use")', '            if (ScrambleIsButtonWord(A_LoopField))', 1)
    assert function(source, "ScrambleCardsStillUp") == expected_still_up, "Unexpected change: ScrambleCardsStillUp"
    assert 'return (w = "use" || w = "select")' in function(source, "ScrambleIsButtonWord"), "Card button words are exactly USE and Select"
    assert not re.search(r'FindAllLinesExact\(\w+, "use"\)', source), "Every card-button lookup accepts USE and Select"
    for name in ["ScrambleResetReads", "OcrLockTake"]:
        current = function(source, name)
        current = current.replace('global OcrBusy, OcrBusySince, ScramblePreviewExcluded, CdVisible, ScrambleFrameVisible',
                                  'global OcrBusy, OcrBusySince')
        current = "\n".join(line for line in current.split("\n") if not line.endswith('; preview only'))
        assert current == function(baseline, name), f"Unexpected non-visual change: {name}"
    # v5.1.1 changed the two distance parsers on purpose: typographic
    # quote marks are normalized first, because the Unicode 64-bit build
    # receives them as real Unicode characters (the 32-bit ANSI build got
    # cp1252 bytes 145-148). v5.1.2 also sends both letter-recovery paths
    # through the same distance guard instead of bypassing it.
    expected_parser = function(baseline, "ScrambleParseDistance").replace(
        "t := ScrambleStripMarks(text)", "t := ScrambleStripMarks(ScrambleNormQuotes(text))", 1
    ).replace("return fm1 * 12 + fm2", "return ScrambleFtIn(fm1, fm2)")
    assert function(source, "ScrambleParseDistance") == expected_parser, "Unexpected distance-parser change"
    assert "0x201D" in function(source, "ScrambleNormQuotes"), "Curly inch mark normalized"
    # FeetInches also changed on purpose (real Windows OCR read 29' 7" as
    # "291 71'"): only a tick after TWO numbers is a misread inch mark.
    # A single feet-only number such as 100' keeps its actual feet mark.
    feet = function(source, "FeetInches")
    assert "t := ScrambleNormQuotes(raw)" in feet and feet.count("ScrambleFtIn(") == 4 and "* 12 +" not in feet, "FeetInches routes every result through ScrambleFtIn"
    # Exercise the actual production regex, without a second parser
    # implementation. These patterns have the same syntax in PCRE/Python.
    pattern = re.search(r'RegExMatch\(t, "([^"\n]+)"\)\)\n\s*t := RegExReplace', feet)
    assert pattern, "Missing trailing-tick classification pattern"
    for reading, inch_tick in [("100'", False), ("111'", False), ("199'", False),
                               ("28'", False), ("100 '", False), ("291 71'", True),
                               ("141 7'", True), ("29' 7'", False)]:
        assert bool(re.search(pattern[1], reading)) == inch_tick, f"Wrong trailing-tick interpretation: {reading}"
    print("PASS: 8 production trailing-tick regex cases preserve feet-only readings")
    assert "ft > 199" in function(source, "ScrambleFtIn"), "Oversized green distance refused"
    assert 'ScrambleRecoverCards(scrScan)' in source, "Scramble watcher uses the card recovery path"
    assert 'SendMode, Input' in source  # Primary-key and scramble output mode preserved.
    assert 'if (FnIsDown)\n            return' in function(source, "HandleBoxKeyDown")
    assert 'SetKeyDelay, 15, 60' in function(source, "SendSecondaryKey")
    assert 'SendEvent, %keys%' in function(source, "SendSecondaryKey")
    assert 'gResetSmartSpots, Reset Smart Click Spots' in source
    assert 'gOnCleanup,' not in source
    print(f"PASS: {len(unchanged)} core functions, diagnostics, hotkeys and exit preserved; preview hooks do not change voting, deadlines, cancellation or shot-key delivery")


SINK = r'''
#NoEnv
#SingleInstance Off
SetBatchLines, -1
events := A_Args[1]
Gui, Sink:New, +HwndSinkHwnd, GSPro BA Remapper regression target
Gui, Sink:Add, Edit, x10 y10 w800 h500 vSinkEdit
Gui, Sink:Show, w840 h540
OnMessage(0x100, "RecordKey")
OnMessage(0x101, "RecordKey")
OnMessage(0x104, "RecordKey")
OnMessage(0x105, "RecordKey")
return
RecordKey(wParam, lParam, msg, hwnd) {
    global events
    FileAppend, % A_TickCount . "," . msg . "," . wParam . "`n", %events%
}
SinkGuiClose:
ExitApp
'''


SMOKE = r'''
UiSmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    SetTimer, OcrWarmup, Off
    SetTimer, ScreenWatchTick, Off
    try {
        Assert(LaunchHow = "show" && RemapActive, "Opened with /show turns mapping on")
        Assert(DllCall("IsWindowVisible", "Ptr", MainHwnd), "Opened with /show shows the window")
        ToggleRemap()   ; the UI checks below start from mapping off, as before
        Assert(!RemapActive, "Mapping button turns mapping off")
        ScrambleAutoPick := true
        UpdateMainStatus()
        GuiControlGet, shown, Main:, ScrambleStatusText
        Assert(InStr(shown, "ON"), "Independent Auto-Pick status")
        ToggleRemap()
        ToggleRemap()
        Assert(ScrambleAutoPick, "Mapping toggle does not turn Auto-Pick off")
        ScrambleAutoPick := false
        UpdateMainStatus()
        CaptureWindow(MainHwnd, "main")

        ActiveProfile := "Basic Secondary"
        LoadProfile(ActiveProfile)
        RefreshProfileDropdown()
        Gosub, ShowBuilder
        GuiControlGet, editable, Builder:Enabled, FnChoice
        Assert(!editable, "Preset FN selector is read only")
        GuiControlGet, editable, Builder:Enabled, BtnLeft
        Assert(!editable, "Preset buttons are visibly read only")
        CaptureWindow(BuilderHwnd, "builder-preset")
        startupBefore := StartupProfile
        FileRead, presetBefore, % ProfilesDir . "\Basic Secondary.ini"
        SetTimer, FillCopyName, 100
        Gosub, OnCopyProfile
        Assert(ActiveProfile = "Regression Copy", "Copy becomes current profile")
        Assert(StartupProfile = startupBefore, "Copy leaves startup profile unchanged")
        Assert(FnButtonId = "resetaim" && SecValue["clubup"] = "b" && SecValue["clubdown"] = "b", "Copy retains hotkeys and FN")
        Assert(SecType["left"] = "ocr" && SecValue["left"] = "NextOption", "Copy retains Smart Clicks")
        FileRead, presetAfter, % ProfilesDir . "\Basic Secondary.ini"
        Assert(presetBefore = presetAfter, "Preset file remains untouched")
        GuiControlGet, editable, Builder:Enabled, FnChoice
        Assert(editable, "Copied profile enables editing")

        ConfigButton("left", "AIM LEFT", "Left Arrow")
        GuiControlGet, enabled, Cfg:Enabled, CfgKeyChoice
        Assert(!enabled, "Inactive key dropdown disabled")
        SelectConfigType("key")
        GuiControl, Cfg:ChooseString, CfgKeyChoice, B - Camera Clip / Clear View
        UpdateConfigPreview()
        GuiControlGet, keySelected, Cfg:, CfgTypeKey
        GuiControlGet, ocrSelected, Cfg:, CfgTypeOcr
        GuiControlGet, ocrEnabled, Cfg:Enabled, CfgOcrChoice
        Assert(keySelected && !ocrSelected && !ocrEnabled, "Action types are mutually exclusive")
        GuiControlGet, preview, Cfg:, CfgPreview
        Assert(InStr(preview, "Reset Aim") && InStr(preview, "AIM LEFT") && InStr(preview, "Clear View"), "Readable action preview")
        CaptureWindow(CfgHwnd, "action-preview")
        Gosub, CfgCancel
        Assert(SecType["left"] = "ocr", "Cancel retains previous action")
        ConfigButton("left", "AIM LEFT", "Left Arrow")
        SelectConfigType("key")
        GuiControl, Cfg:ChooseString, CfgKeyChoice, B - Camera Clip / Clear View
        Gosub, CfgOK
        Assert(SecType["left"] = "key" && SecValue["left"] = "b", "Save applies chosen hotkey")
        IniRead, saved, % ProfilesDir . "\Regression Copy.ini", Profile, left_Value
        Assert(saved = "b", "Saved hotkey persists to disk")
        SetTimer, CloseFnNotice, 100
        ConfigButton("resetaim", "RESET AIM", "A")
        Assert(ConfiguringProfile = "", "FN modifier has no unusable secondary editor")

        Spots := {MoveForward: {x: 5, y: 6, w: 30, h: 12, inferred: 0}}
        SpotWin := "0,0,1920,1080"
        SaveSpots()
        LastActionId := "MoveForward", LastClickX := 123, LastClickY := 456
        LastFireTick := A_TickCount, LastScanObj := {found: true}, LastScanTick := A_TickCount
        PendingOcrAction := "MoveForward", VerifyActionId := "DropRehit"
        FileRead, profileBeforeReset, % ProfilesDir . "\Regression Copy.ini"
        SaveSettings()
        Gosub, ResetSmartSpots
        Assert(SpotWin = "" && Spots.Count() = 0, "Reset clears learned spots")
        Assert(LastActionId = "" && LastClickX = 0 && LastClickY = 0 && LastFireTick = 0, "Reset clears repeat cache")
        Assert(LastScanObj = "" && LastScanTick = 0 && PendingOcrAction = "" && VerifyActionId = "", "Reset clears scan and pending caches")
        FileRead, profileAfterReset, % ProfilesDir . "\Regression Copy.ini"
        Assert(profileBeforeReset = profileAfterReset && StartupProfile = startupBefore, "OCR reset preserves profile and startup")
        IniRead, preference, %ConfigFile%, App, ActiveProfile
        Assert(preference = ActiveProfile, "OCR reset preserves preferences")

        WinMove, ahk_id %BuilderHwnd%, , , , 520, 340
        UpdateSettingsScroll(BuilderHwnd)
        VarSetCapacity(si, 28, 0)
        NumPut(28, si, 0, "UInt"), NumPut(0x17, si, 4, "UInt")
        DllCall("GetScrollInfo", "Ptr", BuilderHwnd, "Int", 1, "Ptr", &si)
        Assert(NumGet(si, 12, "Int") > NumGet(si, 16, "UInt"), "Small Builder has vertical scrolling")
        SettingsScroll(7, 0, 0x115, BuilderHwnd)
        DllCall("GetScrollInfo", "Ptr", BuilderHwnd, "Int", 1, "Ptr", &si)
        Assert(NumGet(si, 20, "Int") > 0, "Scrollbar reaches lower controls")
        CaptureWindow(BuilderHwnd, "builder-scrolled")
        WinMove, ahk_id %MainHwnd%, , 50000, 50000
        KeepWindowOnScreen(MainHwnd)
        WinGetPos, mx, my, mw, mh, ahk_id %MainHwnd%
        SettingsWorkArea(wl, wt, wr, wb, mx, my)
        Assert(mx >= wl && my >= wt && mx + mw <= wr && my + mh <= wb, "Offscreen window recovered")

        Gosub, ShowFactoryReset
        GuiControlGet, backup, Factory:, FactoryBackup
        Assert(backup = 1, "Factory backup defaults on")
        Gosub, FactoryCancel
        Assert(FileExist(ConfigFile), "Cancelling factory reset preserves settings")

        ; A second process records real Windows key messages independently.
        Run, "%A_AhkPath%" /ErrorStdOut "%A_ScriptDir%\sink.ahk" "%A_ScriptDir%\events.txt", , , sinkPid
        WinWait, GSPro BA Remapper regression target, , 10
        Assert(!ErrorLevel, "Key target started")
        LoadProfile("Basic Secondary")
        RemapActive := true
        Loop, 2 {
            SwapIK := A_Index = 2
            HandleBoxKeyDown("a")
            HandleBoxKeyDown("i")
            HandleBoxKeyUp("i")
            HandleBoxKeyDown("a") ; OS repeat after secondary
            Assert(FnUsedAsModifier, "Repeated FN down retains used flag")
            HandleBoxKeyDown("k")
            HandleBoxKeyUp("k")
            HandleBoxKeyUp("a")
        }
        Assert(!FnIsDown, "FN released without stale state")
        Assert(SendSecondaryKey("{Right}"), "Arrow hotkey sent")
        Assert(SendSecondaryKey("^m"), "Compound Ctrl+M hotkey sent")
        ; GSPro 4 relief panel (v5.1.6): with the panel read, the box's
        ; Smart Click buttons press GSPro's own keys.  The choices sit
        ; off screen, so no highlighted card is read (sel 0).
        Critical, On
        fakeOpts := [{x: -900, y: -900, w: 180, h: 32, text: "LATERAL DROP"}, {x: -900, y: -750, w: 120, h: 32, text: "FLAG LINE"}, {x: -900, y: -600, w: 70, h: 32, text: "REHIT"}]
        ReliefLast := {found: true, header: true, opts: fakeOpts, at: A_TickCount}
        HandleBoxKeyDown("a")
        HandleBoxKeyDown("Left")   ; FN + Aim Left = Next Option -> "2"
        HandleBoxKeyUp("a")
        Assert(IsObject(ReliefLast) && ReliefExpectSel = 2, "Next Option on the GSPro 4 panel sent choice 2")
        ReliefLast.at := A_TickCount
        HandleBoxKeyDown("a")
        HandleBoxKeyDown("c")      ; FN + Tee Left = OB Rehit -> "3", Enter
        HandleBoxKeyUp("a")
        Critical, Off
        Assert(ReliefLast = "", "OB Rehit on the GSPro 4 panel sent Rehit's number and Enter")
        ; ---- v5.2.0 custom layouts ----
        ; A profile can only ever press keys.
        Assert(KeyValid("b") && KeyValid("^m") && KeyValid("{Enter}") && KeyValid("^+{F7}") && KeyValid("-") && KeyValid("=") && KeyValid("{Numpad1}"), "Plain keys and combos are valid")
        Assert(!KeyValid("{Click 10 10}") && !KeyValid("#r") && !KeyValid("{Raw}x") && !KeyValid("abc") && !KeyValid("{LWin}") && !KeyValid("") && !KeyValid("^^^^a"), "Clicks, Win key, raw text and strings are refused")
        Assert(HotkeyToSend("^+E") = "^+e" && HotkeyToSend("F7") = "{F7}" && HotkeyToSend("Numpad1") = "{Numpad1}" && HotkeyToSend("#r") = "" && HotkeyToSend("") = "", "Custom key box converts to keys")
        Assert(SendToHotkey("^+{F7}") = "^+F7" && KeyDisplayName("^+e") = "Ctrl+Shift+E" && KeyDisplayName("{F7}") = "F7" && KeyShortName("b") = "B", "Custom keys show readable names")
        sq := SeqParse("150:4|{F2}")
        Assert(IsObject(sq) && sq.pause = 150 && sq.keys.MaxIndex() = 2 && !IsObject(SeqParse("150:a|b|c|d|e")) && !IsObject(SeqParse("5:a")) && !IsObject(SeqParse("150:{Click}")), "Key sequences: 1-4 checked keys, sane pause")
        Assert(SecondaryValid("ocr", "ReliefChoice2") && !SecondaryValid("ocr", "RunAnything") && SecondaryValid("seq", "200:2|{Enter}") && !SecondaryValid("key", "{Click}"), "Saved FN functions are checked")
        ; A key sequence and a custom tap key reach the key target.
        SecType["heatmap"] := "seq", SecValue["heatmap"] := "150:4|{F2}"
        ProfPrimary["teeright"] := "x"
        WinActivate, GSPro BA Remapper regression target
        WinWaitActive, GSPro BA Remapper regression target, , 2
        HandleBoxKeyDown("a")
        HandleBoxKeyDown("y")      ; FN + Heat Map = key sequence 4, F2
        HandleBoxKeyUp("a")
        HandleBoxKeyDown("v")      ; tap Tee Right = custom tap X
        HandleBoxKeyUp("v")
        Assert(BoxTapKey("teeright") = "x" && BoxTapKey("teeleft") = "c", "A custom tap key replaces only that button's tap")
        ; FN cheat sheet: a copy of the box at the bottom left of GSPro while FN is held.
        ShowFnCheat := true
        CheatSizePct := 60
        model := CheatModel()
        byId := {}
        for i, m in model
            byId[m.id] := m
        Assert(byId.clubup.yellow = "CLEAR VIEW" && byId.teeleft.yellow = "OB REHIT" && byId.up.yellow = "MOVE FORWARD" && byId.heatmap.yellow = "4>F2" && byId.resetaim.fn && byId.putt.yellow = "" && model.MaxIndex() = 14, "Cheat sheet prints every button with its yellow function")
        WinActivate, GSPro BA Remapper regression target
        WinWaitActive, GSPro BA Remapper regression target, , 2
        HandleBoxKeyDown("a")
        Sleep, 1100
        cheatShown := CheatVisible && CheatHwnd && DllCall("IsWindowVisible", "Ptr", CheatHwnd)
        Assert(cheatShown, "Holding FN over GSPro shows the control-box cheat sheet")
        gw := ClientRectByTitle(GSProWinNeedle, GSProWinExclude)
        WinGetPos, chx, chy, chw, chh, ahk_id %CheatHwnd%
        Assert(chx >= gw.x && chx <= gw.x + 60 && chy + chh <= gw.y + gw.h + 1 && chy + chh >= gw.y + gw.h - 60 && chw >= 300, "Cheat sheet sits at the bottom left of GSPro: " . chx . "," . chy . " " . chw . "x" . chh . " in " . gw.x . "," . gw.y . " " . gw.w . "x" . gw.h)
        Assert(Abs(chw - Round(Min(gw.w * 0.6, gw.w - 40, (gw.h - 40) * 940 / 710))) <= 2, "Cheat sheet is the chosen size (60% of GSPro): " . chw . " of " . gw.w)
        px := CheatPixels(CheatHwnd, "fn")
        Assert(px.yellow >= 40 && px.button >= 300 && px.fnyellow >= 10, "Cheat sheet draws the box picture's cream buttons, a yellow ring round FN and yellow print (yellow " . px.yellow . ", button " . px.button . ", FN " . px.fnyellow . ")")
        Assert(InStr(CheatShownText, "HOLD FN + BUTTON") && InStr(CheatShownText, "clubup=CLEAR VIEW") && InStr(CheatShownText, "resetaim=FN - HOLD") && !InStr(CheatShownText, "(plain)") && FileExist(BoxPicPath), "The sheet is the box picture with the FN print: " . CheatShownText)
        WinGet, cheatEx, ExStyle, ahk_id %CheatHwnd%
        Assert((cheatEx & 0x08000020) = 0x08000020, "Cheat sheet is click-through and never takes focus")
        ; The B fix (FN + Club Down = Clear View) with the sheet up:
        ; B still reaches GSPro as a real held key, GSPro keeps focus.
        HandleBoxKeyDown("k")
        HandleBoxKeyUp("k")
        Assert(WinActive("GSPro BA Remapper regression target") && CheatVisible, "FN + Club Down sends Clear View (B) to GSPro with the cheat sheet showing; GSPro keeps focus")
        HandleBoxKeyDown("o")      ; FN + Flyover: nothing assigned, FN counts as used
        HandleBoxKeyUp("a")
        Sleep, 150
        Assert(!CheatVisible && !(CheatHwnd && DllCall("IsWindow", "Ptr", CheatHwnd) && DllCall("IsWindowVisible", "Ptr", CheatHwnd)), "Releasing FN hides the cheat sheet")
        ShowFnCheat := false
        HandleBoxKeyDown("a")
        Sleep, 700
        Assert(!CheatVisible, "Cheat sheet stays off when switched off")
        HandleBoxKeyDown("o")
        HandleBoxKeyUp("a")
        ShowFnCheat := true
        Assert(!CheatSizeValid(19) && !CheatSizeValid(81) && !CheatSizeValid("abc") && CheatSizeValid(20) && CheatSizeValid(80) && CheatPosValid(0) && CheatPosValid(1000) && !CheatPosValid(1001) && !CheatPosValid("-5"), "Saved size 20-80 and spot 0-1000 are checked")
        ; A saved spot in the top right puts the sheet there.
        CheatPosX := 1000, CheatPosY := 0
        WinActivate, GSPro BA Remapper regression target
        WinWaitActive, GSPro BA Remapper regression target, , 2
        HandleBoxKeyDown("a")
        Sleep, 800
        g0 := CheatGeom(gw)
        WinGetPos, tx, ty, tw, th, ahk_id %CheatHwnd%
        Assert(CheatVisible && Abs(tx + tw - (gw.x + gw.w - g0.pad)) <= 2 && Abs(ty - (gw.y + g0.pad)) <= 2, "A saved top-right spot shows the sheet top right: " . tx . "," . ty . " " . tw . " in " . gw.x . "," . gw.y . " " . gw.w)
        HandleBoxKeyDown("o")
        HandleBoxKeyUp("a")
        Sleep, 100
        CheatPosX := 0, CheatPosY := 1000
        ; Size and Place: the sheet live over GSPro, a size slider,
        ; drag with the mouse, Lock it in saves both.
        Gosub, OnCheatAdjust
        Sleep, 250
        Assert(CheatAdjusting && CheatVisible && WinExist("ahk_id " . CheatAdjHwnd), "Size and Place shows the sheet and its controls")
        WinGet, adjEx, ExStyle, ahk_id %CheatHwnd%
        Assert(!(adjEx & 0x20) && (adjEx & 0x08000000), "The sheet being placed takes the mouse but never focus")
        GuiControl, CheatAdj:, CheatAdjSize, 50
        Gosub, CheatAdjSizeMove
        Sleep, 300
        WinGetPos, ax, ay, aw, ah, ahk_id %CheatHwnd%
        Assert(Abs(aw - Round(Min(Max(gw.w * 0.5, 300), gw.w - 40, (gw.h - 40) * 940 / 710))) <= 2 && CheatSizePct = 50, "The size slider resizes the sheet live: " . aw)
        ; FN held while placing neither replaces nor hides it.
        HandleBoxKeyDown("a")
        Sleep, 600
        HandleBoxKeyDown("o")
        HandleBoxKeyUp("a")
        WinGet, adjEx2, ExStyle, ahk_id %CheatHwnd%
        Assert(CheatAdjusting && CheatVisible && !(adjEx2 & 0x20), "FN during Size and Place leaves the sheet being placed")
        CoordMode, Mouse, Screen
        dsx := ax + aw // 2, dsy := ay + ah // 2
        MouseMove, %dsx%, %dsy%, 0
        Sleep, 80
        Click, Down
        Sleep, 80
        Loop, 6 {
            mvx := dsx + A_Index * 25, mvy := dsy - A_Index * 16
            MouseMove, %mvx%, %mvy%, 0
            Sleep, 50
        }
        Click, Up
        Sleep, 150
        WinGetPos, bx, by, , , ahk_id %CheatHwnd%
        Assert(bx >= ax + 120 && by <= ay - 70, "Dragging with the mouse moves the sheet: " . ax . "," . ay . " -> " . bx . "," . by)
        dragX := CheatPosX, dragY := CheatPosY
        Assert(dragX > 0 && dragY < 1000, "The dragged spot is noted: " . dragX . " / " . dragY)
        SaveSettings()   ; any other setting saved while placing
        IniRead, duringLock, %ConfigFile%, App, FnCheatSize, 0
        Assert(duringLock = CheatAdjOrig.size && duringLock != CheatSizePct, "Nothing is saved until Lock it in: " . duringLock)
        Gosub, CheatAdjLock
        IniRead, lockSize, %ConfigFile%, App, FnCheatSize, 0
        IniRead, lockX, %ConfigFile%, App, FnCheatX, -1
        IniRead, lockY, %ConfigFile%, App, FnCheatY, -1
        Assert(!CheatAdjusting && !CheatVisible && !WinExist("ahk_id " . CheatAdjHwnd) && lockSize = 50 && lockX = dragX && lockY = dragY, "Lock it in saves the size and spot: " . lockSize . " " . lockX . " " . lockY)
        WinActivate, GSPro BA Remapper regression target
        WinWaitActive, GSPro BA Remapper regression target, , 2
        HandleBoxKeyDown("a")
        Sleep, 800
        WinGetPos, lx, ly, lw, , ahk_id %CheatHwnd%
        Assert(CheatVisible && Abs(lx - bx) <= 2 && Abs(ly - by) <= 2 && Abs(lw - aw) <= 2, "Holding FN shows the sheet at the locked size and spot: " . lx . "," . ly . " " . lw)
        HandleBoxKeyDown("o")
        HandleBoxKeyUp("a")
        Sleep, 100
        ; Cancel puts back what was locked in.
        Gosub, OnCheatAdjust
        Sleep, 150
        GuiControl, CheatAdj:, CheatAdjSize, 25
        Gosub, CheatAdjSizeMove
        Gosub, CheatAdjReset
        Gosub, CheatAdjCancel
        Assert(CheatSizePct = 50 && CheatPosX = dragX && CheatPosY = dragY && !CheatAdjusting && !CheatVisible, "Cancel keeps the locked size and spot")
        CheatSizePct := 35, CheatPosX := 0, CheatPosY := 1000
        ; ---- v5.2.1: the sheet follows GSPro 4's relief list ----
        ; Labels from the plan each press would run, for the choice
        ; highlighted now (ReliefExpectSel stands in for the blue card).
        fakeRel := {found: true, at: A_TickCount, opts: [{text: "LATERAL DROP", x: 5, y: 5, w: 80, h: 20}, {text: "FLAG LINE", x: 5, y: 40, w: 80, h: 20}, {text: "REHIT", x: 5, y: 75, w: 80, h: 20}]}
        ReliefLast := fakeRel, ReliefExpectSel := 2, ReliefExpectTick := A_TickCount
        yl := {}
        for i, m in CheatModel()
            yl[m.id] := m.yellow
        Assert(yl.right = "ENTER: FLAG LINE" && yl.left = "NEXT: 3 REHIT" && yl.up = "CLOSER (F)" && yl.down = "FURTHER BACK (B)" && yl.teeleft = "REHIT + ENTER" && yl.clubup = YellowKeyName("b") && yl.clubdown = YellowKeyName("b") && yl.mulligan = "", "Relief list, Flag Line picked: ENTER: FLAG LINE, NEXT: 3 REHIT, Closer / Further Back on the arrows, Clear View stays Clear View: " . yl.right . " / " . yl.left . " / " . yl.up . " / " . yl.clubup)
        ReliefExpectSel := 1, ReliefExpectTick := A_TickCount
        yl := {}
        for i, m in CheatModel()
            yl[m.id] := m.yellow
        Assert(yl.right = "ENTER: LATERAL" && yl.left = "NEXT: 2 FLAG LINE" && yl.up = "" && yl.down = "" && yl.clubup = YellowKeyName("b"), "Relief list, Lateral Drop picked: no Closer / Further Back: " . yl.right . " / " . yl.left . " / [" . yl.up . "]")
        ReliefLast := {found: true, at: A_TickCount, opts: [{text: "REHIT", x: 5, y: 5, w: 80, h: 20}, {text: "MULLIGAN", x: 5, y: 40, w: 80, h: 20}]}
        ReliefExpectSel := 1, ReliefExpectTick := A_TickCount
        yl := {}
        for i, m in CheatModel()
            yl[m.id] := m.yellow
        Assert(yl.mulligan = "MULLIGAN + ENTER" && yl.left = "NEXT: 2 MULLIGAN" && yl.right = "ENTER: REHIT" && yl.up = "", "OB with mulligans on: Mulligan button MULLIGAN + ENTER, NEXT: 2 MULLIGAN, ENTER: REHIT")
        ReliefLast := "", ReliefExpectSel := 0
        yl := {}
        for i, m in CheatModel()
            yl[m.id] := m.yellow
        Assert(yl.right = YellowOcrName("DropRehit") && yl.mulligan = "", "Without the relief list the printed names are back")
        ; The sheet on screen follows the highlighted choice (no screen
        ; reads: the OCR lock is held so FN-down reads stand aside).
        WinActivate, GSPro BA Remapper regression target
        WinWaitActive, GSPro BA Remapper regression target, , 2
        OcrBusy := true, OcrBusySince := A_TickCount
        ReliefLast := fakeRel, ReliefExpectSel := 2
        SetTimer, KeepReliefExpect, 100
        Gosub, KeepReliefExpect
        HandleBoxKeyDown("a")
        Sleep, 750
        cheatText := CheatShownText
        Assert(CheatVisible && InStr(cheatText, "ENTER: FLAG LINE") && InStr(cheatText, "up=CLOSER") && InStr(cheatText, "2 FLAG LINE PICKED") && InStr(cheatText, "HOLD FN"), "Held FN on the relief list: the sheet shows the Flag Line labels: " . cheatText)
        ReliefExpectSel := 1
        Sleep, 800
        cheatText := CheatShownText
        Assert(CheatVisible && InStr(cheatText, "ENTER: LATERAL") && !InStr(cheatText, "CLOSER") && InStr(cheatText, "1 LATERAL PICKED"), "Picking another choice redraws the sheet for it: " . cheatText)
        SetTimer, KeepReliefExpect, Off
        ReliefLast := "", ReliefExpectSel := 0
        Sleep, 800
        cheatText := CheatShownText
        Assert(CheatVisible && !InStr(cheatText, "RELIEF LIST") && !InStr(cheatText, "ENTER:"), "The list closing puts the printed names back: " . cheatText)
        HandleBoxKeyDown("o")
        HandleBoxKeyUp("a")
        OcrBusy := false
        Sleep, 100
        ; ---- v5.3.0: the screen watch's sheets (no screen reads here) ----
        ; Relief list confirmed by the watch: relief buttons need no FN,
        ; Clear View stays on FN (grey), FN prints as FN.
        fakeRel.at := A_TickCount   ; a fresh read (the sheet uses reads under 4 s old)
        ReliefLast := fakeRel, ReliefExpectSel := 2, ReliefExpectTick := A_TickCount
        ReliefWatchUp := true, ReliefNoFn := true
        wl := {}
        for i, l in CheatSheetLabels(CheatModel(), CheatReliefState())
            wl[l.id] := l
        Assert(wl.right.text = "ENTER: FLAG LINE" && !wl.right.dim && wl.up.text = "CLOSER" && wl.down.text = "FURTHER BACK" && wl.clubup.text = "FN: CLEAR VIEW" && wl.clubup.dim && wl.resetaim.text = "FN" && wl.teeleft.text = "REHIT + ENTER", "Relief list without FN: ENTER: FLAG LINE, CLOSER / FURTHER BACK, FN: CLEAR VIEW in grey, FN [" . wl.right.text . "|" . wl.up.text . "|" . wl.clubup.text . "|" . wl.resetaim.text . "]")
        Assert(ReliefNoFnAction("DropRehit") && ReliefNoFnAction("ReliefZoomIn") && !ReliefNoFnAction(""), "Relief jobs are the ones that switch")
        ReliefWatchUp := false, ReliefLast := "", ReliefExpectSel := 0
        ; Scramble cards (Auto-Pick off, as the screen watch reads them):
        ; the bottom row picks, AIM right takes, the sheet says so.
        ScrambleAutoPick := false
        WinActivate, GSPro BA Remapper regression target
        WinWaitActive, GSPro BA Remapper regression target, , 2
        sinkWin := ClientRectByTitle(GSProWinNeedle, GSProWinExclude)
        cardUses := [{x: sinkWin.x + 200, y: sinkWin.y + 400, w: 40, h: 16}, {x: sinkWin.x + 500, y: sinkWin.y + 400, w: 40, h: 16}]
        ScrambleBoxCards := {uses: cardUses, n: 2, hwnd: sinkWin.hwnd, auto: false, id: "b1"}
        Assert(IsObject(ScrambleBoxCardsNow()) && ScrambleBoxPickNow(ScrambleBoxCards) = 0, "Scramble cards known, nothing picked yet")
        HandleBoxKeyDown("c")      ; Tee Left = card 2 (clicks the name, no V/C key)
        HandleBoxKeyUp("c")
        Assert(ScrambleBoxPickNow(ScrambleBoxCards) = 2, "Tee Left picks card 2")
        HandleBoxKeyDown("v")      ; Tee Right = card 3: not on a 2-card screen
        HandleBoxKeyUp("v")
        Assert(ScrambleBoxPickNow(ScrambleBoxCards) = 2, "Card 3 on a 2-card screen changes nothing")
        CheatDraw()
        cheatText := CheatShownText
        Assert(CheatVisible && InStr(cheatText, "SCRAMBLE:  CARD 2 PICKED") && InStr(cheatText, "resetaim=CARD 1 (TAP)") && InStr(cheatText, "teeleft=CARD 2") && InStr(cheatText, "teeright=|") && InStr(cheatText, "right=TAKE CARD 2") && InStr(cheatText, "NO FN NEEDED"), "Scramble sheet: cards along the bottom row, TAKE CARD 2 on AIM right: " . cheatText)
        px := CheatPixels(CheatHwnd, "scramble")
        CheatHide()
        WinActivate, GSPro BA Remapper regression target
        WinWaitActive, GSPro BA Remapper regression target, , 2
        HandleBoxKeyDown("a")      ; FN tapped alone = card 1 (no A key)
        HandleBoxKeyUp("a")
        Assert(ScrambleBoxPickNow(ScrambleBoxCards) = 1, "Reset Aim tapped picks card 1")
        SendSecondaryKey("{F6}")    ; markers: F6 / F7 (F10 would open the window menu)
        HandleBoxKeyDown("Right")  ; AIM right takes card 1: the key 1, no arrow
        HandleBoxKeyUp("Right")
        SendSecondaryKey("{F7}")
        Assert(ScrambleBoxCards = "" && ScrambleBoxPick = 0, "AIM right took the card; the screen is done")
        ; Auto-Pick on: the box card wins the vote at zero.
        ScrambleAutoPick := true, ScrambleArmedTick := A_TickCount, ScrambleCoolDown := false, ScrambleMissTicks := 0
        ScrambleLastUses := [{x: sinkWin.x + 100, y: sinkWin.y + 400, w: 40, h: 16}, {x: sinkWin.x + 300, y: sinkWin.y + 400, w: 40, h: 16}, {x: sinkWin.x + 500, y: sinkWin.y + 400, w: 40, h: 16}]
        ScrambleLastHwnd := sinkWin.hwnd
        ScrambleReadsN := {3: 4}, ScrambleVotes := {"3-1": 4}, ScrambleVoteLast := "3-1"
        Assert(ScrambleVoteLeader() = 1, "Auto-Pick's own choice is card 1")
        HandleBoxKeyDown("v")      ; Tee Right = card 3
        HandleBoxKeyUp("v")
        Assert(ScrambleVoteLeader() = 3 && ScrambleBoxPickNow(ScrambleBoxCardsNow()) = 3, "Card 3 picked on the box is the one Auto-Pick takes at zero")
        ScrambleAutoPick := false, ScrambleArmedTick := 0, ScrambleLastUses := "", ScrambleResetReads()
        ScrambleBoxPick := 0
        ; ---- v5.2.1 Mulligan button ----
        ; The box's Ctrl+M reaches GSPro untouched (the sink logs it
        ; between F8 and F9); with no relief list nothing follows it.
        SendSecondaryKey("{F8}")
        mulBefore := MulliganPressTick
        SendLevel, 1
        SendEvent, ^m
        SendLevel, 0
        Sleep, 1200
        Assert(MulliganPressTick > mulBefore, "The box's Ctrl+M is watched while GSPro is in front")
        SendSecondaryKey("{F9}")
        Assert(MulliganFollowKeys("").MaxIndex() = "" && MulliganFollowKeys({found: false, opts: []}).MaxIndex() = "" && ReliefKeysText(MulliganFollowKeys({found: true, opts: [{text: "REHIT"}, {text: "MULLIGAN"}]})) = "2 {Enter}" && MulliganFollowKeys({found: true, opts: [{text: "LATERAL DROP"}, {text: "FLAG LINE"}, {text: "REHIT"}]}).MaxIndex() = "", "Mulligan's number and Enter only when Mulligan is a choice")
        ; v5.2.2: a title is the leading capital words of its line, so
        ; GSPro's callout or a map label on the same row (one OCR line)
        ; no longer hides it; off-column titles are dropped.
        Assert(ReliefTitleText("4 MULLIGAN NO STROKE No stroke, re") = "MULLIGAN" && ReliefTitleText("MULLIGAN NO STROKE From your last spot · 475 yd to pin") = "MULLIGAN"
            && ReliefTitleText("3 REHIT +1 From your l") = "REHIT" && ReliefTitleText("1 LATERAL DROP +1") = "LATERAL DROP" && ReliefTitleText("FLAG LINE") = "FLAG LINE"
            && ReliefTitleText("Rough · 472 yd to pin") = "" && ReliefTitleText("RELIEF OPTIONS") = "" && ReliefTitleText("No stroke, replay the shot") = "" && ReliefTitleText("NO STROKE") = "", "Relief titles: leading capital words only")
        water := [{text: "RELIEF OPTIONS", x: 55, y: 300, w: 230, h: 24}
            , {text: "1 LATERAL DROP +1", x: 80, y: 380, w: 650, h: 40}, {text: "Rough · 160 yd to pin", x: 157, y: 430, w: 270, h: 30}
            , {text: "2 FLAG LINE +1", x: 80, y: 530, w: 650, h: 40}, {text: "Rough · 163 yd to pin", x: 157, y: 580, w: 270, h: 30}
            , {text: "3 REHIT +1", x: 80, y: 680, w: 650, h: 40}, {text: "From your last spot · 163 yd to pin", x: 157, y: 730, w: 420, h: 30}
            , {text: "MULLIGAN", x: 900, y: 740, w: 128, h: 40}, {text: "From your last spot · 475 yd to pin", x: 870, y: 790, w: 158, h: 30}
            , {text: "4 MULLIGAN NO STROKE No stroke, re", x: 80, y: 830, w: 948, h: 40}, {text: "Replay the shot, it doesn't count", x: 157, y: 880, w: 380, h: 30}]
        wrel := ReliefParse(water)
        Assert(ReliefNote(wrel) = "4 choices: 1 LATERAL DROP, 2 FLAG LINE, 3 REHIT, 4 MULLIGAN" && ReliefKeysText(MulliganFollowKeys(wrel)) = "4 {Enter}", "Water with the Mulligan callout on card 4's row and beside the panel: 4 choices, Mulligan = 4 Enter (" . ReliefNote(wrel) . ")")
        ob := [{text: "YOUR OPTIONS", x: 55, y: 300, w: 200, h: 24}
            , {text: "1 REHIT +1", x: 80, y: 380, w: 650, h: 40}, {text: "From your last spot · 200 yd to pin", x: 157, y: 430, w: 420, h: 30}
            , {text: "MULLIGAN", x: 900, y: 382, w: 128, h: 40}, {text: "From your last spot · 200 yd to pin", x: 870, y: 432, w: 158, h: 30}]
        orel := ReliefParse(ob)
        Assert(ReliefNote(orel) = "1 choices: 1 REHIT" && !MulliganFollowKeys(orel).MaxIndex(), "OB with a callout title on Rehit's row: the panel column wins, no Mulligan (" . ReliefNote(orel) . ")")
        ; Bruce's log (2026-11-24): on water the highlighted Mulligan card
        ; was not read.  Its white-on-blue number starts the line ~1.6
        ; title heights left of the title column; the grey numbers of
        ; the other cards are not read.  v5.2.1 dropped it as off-column.
        hl := [{text: "RELIEF OPTIONS", x: 55, y: 300, w: 230, h: 24}
            , {text: "LATERAL DROP +1", x: 157, y: 380, w: 573, h: 40}, {text: "Rough · 472 yd to pin", x: 157, y: 430, w: 270, h: 30}
            , {text: "FLAG LINE +1", x: 157, y: 530, w: 573, h: 40}, {text: "Rough · 475 yd to pin", x: 157, y: 580, w: 270, h: 30}
            , {text: "REHIT +1", x: 157, y: 680, w: 573, h: 40}, {text: "From your last spot · 475 yd to pin", x: 157, y: 730, w: 420, h: 30}
            , {text: "4 MULLIGAN NO STROKE", x: 92, y: 830, w: 638, h: 42}, {text: "Replay the shot, it doesn't count", x: 157, y: 880, w: 380, h: 30}]
        hrel := ReliefParse(hl)
        Assert(ReliefNote(hrel) = "4 choices: 1 LATERAL DROP, 2 FLAG LINE, 3 REHIT, 4 MULLIGAN" && ReliefKeysText(MulliganFollowKeys(hrel, 4)) = "{Enter}", "Highlighted Mulligan with its number read on its line: still choice 4, Enter takes it (" . ReliefNote(hrel) . ")")
        ; ... and with its detail line lost: the card one spacing below
        ; the last one is the next choice.
        hl.RemoveAt(9)
        hrel := ReliefParse(hl)
        Assert(ReliefNote(hrel) = "4 choices: 1 LATERAL DROP, 2 FLAG LINE, 3 REHIT, 4 MULLIGAN", "Mulligan card without its detail line: still choice 4 (" . ReliefNote(hrel) . ")")
        ; A map label under the panel and off the column is no choice.
        lbl := [{text: "RELIEF OPTIONS", x: 55, y: 300, w: 230, h: 24}
            , {text: "REHIT +1", x: 157, y: 380, w: 573, h: 40}, {text: "From your last spot · 200 yd to pin", x: 157, y: 430, w: 420, h: 30}
            , {text: "MULLIGAN NO STROKE", x: 157, y: 530, w: 573, h: 40}, {text: "Replay the shot, it doesn't count", x: 157, y: 580, w: 380, h: 30}
            , {text: "3 REHIT", x: 330, y: 680, w: 140, h: 36}]
        lrel := ReliefParse(lbl)
        Assert(ReliefNote(lrel) = "2 choices: 1 REHIT, 2 MULLIGAN", "A map label under the panel is not read as a choice (" . ReliefNote(lrel) . ")")
        RemapActive := false
        mulBefore := MulliganPressTick
        SendLevel, 1
        SendEvent, ^m
        SendLevel, 0
        Sleep, 150
        RemapActive := true
        Assert(MulliganPressTick = mulBefore, "Mapping OFF: Ctrl+M is not watched")
        Gui, Main:Show
        WinActivate, ahk_id %MainHwnd%
        WinWaitActive, ahk_id %MainHwnd%, , 2
        mulBefore := MulliganPressTick
        SendLevel, 1
        SendEvent, ^m
        SendLevel, 0
        Sleep, 150
        Assert(MulliganPressTick = mulBefore, "Ctrl+M in the Remapper's own window is not watched")
        ; v5.2.2: GSPro open but another program in front (GSPro can
        ; take Ctrl+M unfocused) - watched; nothing more without a list.
        Run, notepad.exe, %A_WinDir%   ; not the test folder: it must not hold that open
        WinWait, ahk_exe notepad.exe, , 10
        WinActivate, ahk_exe notepad.exe
        WinWaitActive, ahk_exe notepad.exe, , 3
        mulBefore := MulliganPressTick
        SendLevel, 1
        SendEvent, ^m
        SendLevel, 0
        Sleep, 900
        Assert(MulliganPressTick > mulBefore && WinActive("ahk_exe notepad.exe"), "Ctrl+M with GSPro open behind another program is watched; nothing is pressed without the relief list")
        WinKill, ahk_exe notepad.exe   ; Ctrl+M typed a line break: no save prompt
        WinWaitClose, ahk_exe notepad.exe, , 5
        ; Builder test mode: box presses show what they do, nothing is sent.
        Gosub, ShowBuilder
        GuiControl, Builder:, BuilderTest, 1
        BuilderTestMode := true
        WinActivate, ahk_id %BuilderHwnd%
        WinWaitActive, ahk_id %BuilderHwnd%, , 2
        HandleBoxKeyDown("a")
        HandleBoxKeyDown("i")
        GuiControlGet, testStatus, Builder:, BuilderStatus
        Assert(InStr(testStatus, "FN + Club Up") && InStr(testStatus, "Clear View") && InStr(testStatus, "nothing sent"), "Builder test mode shows FN + Club Up: " . testStatus)
        HandleBoxKeyUp("i")
        HandleBoxKeyUp("a")
        HandleBoxKeyDown("v")
        GuiControlGet, testStatus, Builder:, BuilderStatus
        Assert(InStr(testStatus, "Tee Right") && InStr(testStatus, "custom tap"), "Builder test mode shows the custom tap: " . testStatus)
        HandleBoxKeyUp("v")
        HandleBoxKeyDown("a")
        HandleBoxKeyUp("a")
        GuiControlGet, testStatus, Builder:, BuilderStatus
        Assert(InStr(testStatus, "Reset Aim tapped alone"), "Builder test mode shows FN tapped alone: " . testStatus)
        BuilderTestMode := false
        Gosub, BuilderClose
        ; Typing in the app's own text box gets the plain box keys.
        Gui, PassTest:New, +AlwaysOnTop +HwndPassHwnd, Pass-through test
        Gui, PassTest:Add, Edit, w200 vPassEdit
        Gui, PassTest:Show, w240 h80
        WinActivate, ahk_id %PassHwnd%
        WinWaitActive, ahk_id %PassHwnd%, , 2
        ControlFocus, Edit1, ahk_id %PassHwnd%
        HandleBoxKeyDown("y")
        HandleBoxKeyUp("y")
        HandleBoxKeyDown("k")
        HandleBoxKeyUp("k")
        Sleep, 150
        GuiControlGet, passText, PassTest:, PassEdit
        Gui, PassTest:Destroy
        Assert(passText = "yk", "Typing in the app's own text box gets the plain box keys: " . passText)
        ; Layout check
        ResetProfile()
        SecType["shotcam"] := "click", SecX["shotcam"] := 0, SecY["shotcam"] := 0
        ProfPrimary["teeright"] := "c"
        joined := ""
        for i, n in ProfileCheck()
            joined .= n . "|"
        Assert(InStr(joined, "Shot Cam: Taught Screen Click has no position") && InStr(joined, "Tee Left and Tee Right both tap C"), "Layout check finds an empty screen click and a doubled tap: " . joined)
        ; Export / Import: a round trip keeps everything; a hostile file only keeps plain keys.
        ResetProfile()
        FnButtonId := "shotcam"
        SecType["clubup"] := "key", SecValue["clubup"] := "^+{F7}"
        SecType["left"] := "ocr", SecValue["left"] := "ReliefChoice2"
        SecType["heatmap"] := "seq", SecValue["heatmap"] := "300:2|{Enter}"
        SecType["putt"] := "click", SecX["putt"] := 640, SecY["putt"] := 360
        ProfPrimary["teeright"] := "x"
        SaveProfile("Export Source")
        ProfileList.Push("Export Source")
        expFile := A_ScriptDir . "\layout-test.baprofile"
        Assert(ExportProfile("Export Source", expFile), "Profile exported to a .baprofile file")
        imp := ImportProfileFile(expFile)
        Assert(imp.name = "Export Source (imported)", "Import picks a free name: " . imp.name)
        LoadProfile(imp.name)
        Assert(FnButtonId = "shotcam" && SecValue["clubup"] = "^+{F7}" && SecValue["left"] = "ReliefChoice2" && SecValue["heatmap"] = "300:2|{Enter}" && SecX["putt"] = 640 && ProfPrimary["teeright"] = "x" && imp.notes.MaxIndex() = 1, "Import keeps every function and notes the screen click from another PC")
        hostile := A_ScriptDir . "\hostile.baprofile"
        if (FileExist(hostile))
            FileDelete, %hostile%
        FileAppend, % "[BA Remapper]`nName=Basic Secondary`n[Profile]`nFnButtonId=mulligan`nheatmap_Type=key`nheatmap_Value={Click 100 100}`nputt_Type=seq`nputt_Value=100:{LWin}`nflyover_Type=ocr`nflyover_Value=RunAnything`nclubup_Type=key`nclubup_Value=#r`nteeleft_Primary={Raw}abc`nclubdown_Type=key`nclubdown_Value=b`n", %hostile%
        imp2 := ImportProfileFile(hostile)
        Assert(imp2.name = "Basic Secondary (imported)" && imp2.notes.MaxIndex() >= 6, "Hostile import renamed off the preset and every unsafe entry noted: " . imp2.name . " " . imp2.notes.MaxIndex())
        LoadProfile(imp2.name)
        okHostile := (FnButtonId = "resetaim") && !SecType.HasKey("heatmap") && !SecType.HasKey("putt") && !SecType.HasKey("flyover") && !SecType.HasKey("clubup") && !ProfPrimary.HasKey("teeleft") && SecValue["clubdown"] = "b"
        Assert(okHostile, "Hostile import keeps only the plain key")
        LoadProfile("Basic Secondary")
        RemapActive := false
        Sleep, 300
        Process, Close, %sinkPid%
        ActiveProfile := "Regression Copy"
        StartupProfile := "Basic Secondary"
        SaveSettings()
        FileAppend, % "PASS: UI, profile, reset, scrollbar and FN runtime checks`n", % A_ScriptDir . "\result.txt"
        Gosub, DoFullExit
    } catch failure {
        Process, Close, %sinkPid%
        FileAppend, % "FAIL: " . failure.Message . " (line " . failure.Line . ")`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
Return

; Repeats until the dialog is up: on a slow runner the InputBox can
; take longer than one tick to appear (main run 44010896827 hung).
KeepReliefExpect:
    ReliefExpectTick := A_TickCount
    if (IsObject(ReliefLast))
        ReliefLast.at := A_TickCount
Return

FillCopyName:
    if (!WinExist("Customize a Copy"))
        Return
    SetTimer, FillCopyName, Off
    ControlSetText, Edit1, Regression Copy, Customize a Copy
    ControlClick, Button1, Customize a Copy
Return

CloseFnNotice:
    if (!WinExist("FN Button"))
        Return
    SetTimer, CloseFnNotice, Off
    ControlClick, Button1, FN Button
Return

; Capture the cheat sheet from the screen and count its grey button,
; yellow print and yellow FN-button pixels.  Its capture exclusion is
; lifted for the capture, the way CapturePreview does it.
CheatPixels(hwnd, name := "") {
    WinGetPos, wx, wy, w, h, ahk_id %hwnd%
    DllCall("SetWindowDisplayAffinity", "Ptr", hwnd, "UInt", 0)
    DllCall("dwmapi\DwmFlush")
    Sleep, 150
    scr := DllCall("GetDC", "Ptr", 0, "Ptr")
    mdc := DllCall("CreateCompatibleDC", "Ptr", scr, "Ptr")
    bmp := DllCall("CreateCompatibleBitmap", "Ptr", scr, "Int", w, "Int", h, "Ptr")
    old := DllCall("SelectObject", "Ptr", mdc, "Ptr", bmp, "Ptr")
    DllCall("BitBlt", "Ptr", mdc, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", scr, "Int", wx, "Int", wy, "UInt", 0x40CC0020)
    DllCall("SetWindowDisplayAffinity", "Ptr", hwnd, "UInt", 0x11)
    out := {yellow: 0, button: 0, fnyellow: 0}
    y := 0
    while (y < h) {
        x := 0
        while (x < w) {
            c := DllCall("GetPixel", "Ptr", mdc, "Int", x, "Int", y, "UInt")
            r := c & 0xFF, g := (c >> 8) & 0xFF, b := (c >> 16) & 0xFF
            if (r > 215 && g > 165 && b < 90) {
                out.yellow += 1
                if (x < w * 0.25 && y > h * 0.72)
                    out.fnyellow += 1
            }
            if (r > 200 && g > 190 && b > 165 && r >= b && r - b < 50)
                out.button += 1
            x += 3
        }
        y += 3
    }
    if (name != "") {
        ; the sheet as drawn, for the verification artifacts
        VarSetCapacity(bi, 40, 0)
        NumPut(40, bi, 0, "UInt"), NumPut(w, bi, 4, "Int"), NumPut(-h, bi, 8, "Int"), NumPut(1, bi, 12, "UShort"), NumPut(32, bi, 14, "UShort")
        VarSetCapacity(px, w * h * 4, 0)
        DllCall("SelectObject", "Ptr", mdc, "Ptr", old, "Ptr")
        DllCall("GetDIBits", "Ptr", mdc, "Ptr", bmp, "UInt", 0, "UInt", h, "Ptr", &px, "Ptr", &bi, "UInt", 0)
        SaveDibBmp(A_ScriptDir . "\cheat-" . name . ".bmp", &px, w, h)
    } else {
        DllCall("SelectObject", "Ptr", mdc, "Ptr", old, "Ptr")
    }
    DllCall("DeleteObject", "Ptr", bmp)
    DllCall("DeleteDC", "Ptr", mdc)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", scr)
    return out
}

Assert(ok, message) {
    if (!ok)
        throw Exception(message)
    FileAppend, % "PASS: " . message . "`n", % A_ScriptDir . "\checks.txt"
}

CaptureWindow(hwnd, name) {
    DllCall("RedrawWindow", "Ptr", hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185)
    Sleep, 100
    WinGetPos, , , w, h, ahk_id %hwnd%
    dc := DllCall("GetDC", "Ptr", 0, "Ptr")
    memory := DllCall("CreateCompatibleDC", "Ptr", dc, "Ptr")
    VarSetCapacity(info, 40, 0)
    NumPut(40, info, 0, "UInt"), NumPut(w, info, 4, "Int"), NumPut(-h, info, 8, "Int")
    NumPut(1, info, 12, "UShort"), NumPut(32, info, 14, "UShort")
    bitmap := DllCall("CreateDIBSection", "Ptr", dc, "Ptr", &info, "UInt", 0, "Ptr*", pixels, "Ptr", 0, "UInt", 0, "Ptr")
    old := DllCall("SelectObject", "Ptr", memory, "Ptr", bitmap, "Ptr")
    DllCall("PrintWindow", "Ptr", hwnd, "Ptr", memory, "UInt", 2)
    SaveDibBmp(A_ScriptDir . "\" . name . ".bmp", pixels, w, h)
    DllCall("SelectObject", "Ptr", memory, "Ptr", old)
    DllCall("DeleteObject", "Ptr", bitmap)
    DllCall("DeleteDC", "Ptr", memory)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", dc)
}
'''

PROGRAM = r'''
ProgramSmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    try {
        Assert(RegExMatch(LaunchParent, "i)^python"), "Parent program read from Windows: " . LaunchParent)
        Assert(LaunchHow = "program" && !isStartupLaunch, "No argument from a program is a program launch")
        Assert(RemapActive, "Opened by a program turns mapping on")
        Assert(!DllCall("IsWindowVisible", "Ptr", MainHwnd), "Opened by a program stays in the tray")
        Assert(ActiveProfile = "Basic Secondary", "Opened by a program loads the startup profile")
        Assert(LaunchMode([], "explorer.exe") = "hand" && LaunchMode([], "EXPLORER.EXE") = "hand", "Desktop, Start menu or taskbar open shows the window")
        Assert(LaunchMode([], "BayLauncher.exe") = "program" && LaunchMode([], "") = "program", "BayLauncher or an unknown opener stays in the tray")
        Assert(LaunchMode(["/startup"], "explorer.exe") = "startup" && LaunchMode(["/show"], "BayLauncher.exe") = "show", "Arguments decide before the opener")
        ToggleRemap()
        Assert(!RemapActive, "Mapping turned off by hand")
        Run, "%A_AhkPath%" /ErrorStdOut "%A_ScriptFullPath%", , , againPid
        Process, WaitClose, %againPid%, 10
        Assert(!ErrorLevel, "Second program launch exits")
        Sleep, 1200
        Assert(RemapActive, "A program opening it again turns mapping back on")
        Assert(!DllCall("IsWindowVisible", "Ptr", MainHwnd), "A program opening it again does not pop the window up")
        Run, "%A_AhkPath%" /ErrorStdOut "%A_ScriptFullPath%" /show, , , showPid
        Process, WaitClose, %showPid%, 10
        Assert(!ErrorLevel, "Second /show launch exits")
        Sleep, 1200
        Assert(DllCall("IsWindowVisible", "Ptr", MainHwnd), "Opening it again with /show brings the window up")
        Assert(RemapActive, "Showing the window leaves mapping on")
        FileRead, launches, % ConfigDir . "\launch_log.txt"
        Assert(InStr(launches, "opened-by-program") && RegExMatch(launches, "i)from python") && RegExMatch(launches, "i)from AutoHotkey"), "Launch log names the opener")
        ActiveProfile := "Regression Copy"
        SaveSettings()
        FileAppend, % "PASS: program launch, reopen signals and launch log`n", % A_ScriptDir . "\result.txt"
        Gosub, DoFullExit
    } catch failure {
        FileAppend, % "FAIL: " . failure.Message . "`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
Return
'''

BOOT = r'''
BootSmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    try {
        Assert(isStartupLaunch, "Startup argument recognized")
        Assert(RemapActive, "Windows startup turns mapping on")
        Assert(ActiveProfile = "Basic Secondary", "Startup loads the separate startup profile")
        Assert(!DllCall("IsWindowVisible", "Ptr", MainHwnd), "Startup stays hidden in tray")
        FileAppend, % "PASS: startup profile and hidden launch`n", % A_ScriptDir . "\result.txt"
        Gosub, DoFullExit
    } catch failure {
        FileAppend, % "FAIL: " . failure.Message . "`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
Return
'''

FACTORY = r'''
FactorySmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    FileAppend, factory test started`n, % A_ScriptDir . "\factory-checks.txt"
    Gosub, ShowFactoryReset
    SetTimer, AcceptFactoryNotice, 150
    FileAppend, factory dialog opened`n, % A_ScriptDir . "\factory-checks.txt"
    Gosub, FactoryConfirm
    ExitApp, 1
Return
AcceptFactoryNotice:
    WinGetTitle, noticeTitle, A
    WinGetText, noticeText, A
    if (noticeTitle != lastNoticeTitle)
        FileAppend, % "Active: " . noticeTitle . " | " . noticeText . "`n", % A_ScriptDir . "\factory-checks.txt"
    lastNoticeTitle := noticeTitle
    if (!factoryCaptured) {
        CaptureWindow(WinExist("A"), "factory-dialog")
        factoryCaptured := true
    }
    if WinExist("Backup Failed") {
        FileAppend, % "FAIL: backup dialog reported failure`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
    ; The two explicit confirmation/result dialogs have this exact
    ; title. The parent settings dialog starts with "BA Remapper".
    ControlClick, Button1, Factory Reset
Return
'''


SCRAMBLE = r'''
ScrambleSmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    SetTimer, OcrWarmup, Off
    SetTimer, ScreenWatchTick, Off
    fails := 0
    try {
        q := Chr(34)
        rs := Chr(0x2019), rd := Chr(0x201D), pr := Chr(0x2032), pd := Chr(0x2033)
        ; ---- single distance reads -> inches, in this exact build ----
        cases := [["28' 0" . q, 1, 336], ["29' 7" . q, 1, 355], ["141 7" . q, 1, 175], ["291 7" . q, 1, 355]
            , ["33110" . q, 1, 406], ["28' O" . q, 1, 336], ["9l 7u", 1, 115], ["0' 6" . q, 1, 6]
            , ["14" . rs . "7" . rd, 1, 175], ["141 7" . rd, 1, 175], ["33110" . rd, 1, 406], ["14" . pr . " 7" . pd, 1, 175]
            , ["291 71'", 1, 355], ["29' 71" . q, 1, 355], ["28'", 1, 336], ["5' 11" . q, 1, 71], ["33110", 1, -1], ["9' 74" . q, 1, -1]
            , ["189", 0, 6804], ["8", 0, 288], ["15", 0, 540], ["!4E", 0, -1], ["l 87", 0, 3132]]
        cases.Push(["100'", 1, 1200], ["111'", 1, 1332], ["199'", 1, 2388], ["100 '", 1, 1200])
        cases.Push(["100" . rs, 1, 1200], ["111" . pr, 1, 1332], ["100' 0" . q, 1, 1200])
        cases.Push(["291 71" . rs, 1, 355], ["8'", 0, 96], ["8", 1, 96], ["8", 0, 288])
        cases.Push(["200'", 1, -1], ["200l 7u", 1, -1], ["200l Ou", 1, -1], ["199l 7u", 1, 2395])
        for i, c in cases {
            got := ScrambleParseDistance(c[1], c[2])
            ScrambleNote((got = c[3]) ? "PASS" : "FAIL", "parse [" . c[1] . "] " . (c[2] ? "green" : "yards") . " -> " . got . " (want " . c[3] . ")")
            if (got != c[3])
                fails += 1
        }
        ; The recovery rectangle follows GSPro, including negative
        ; desktop origins, and never extends outside its client area.
        band := ScrambleCardBand({x: -1920, y: -400, w: 1920, h: 1080})
        bandOk := (band.x = -1920 && band.y = 86 && band.w = 1920 && band.h = 508)
        ScrambleNote(bandOk ? "PASS" : "FAIL", "card strip preserves negative monitor coordinates")
        if (!bandOk)
            fails += 1
        if (A_Args[1] = "ocr") {
            ; ---- real Windows OCR on rendered scramble cards ----
            sc := []
            sc.Push({name: "three cards first 150 / 98 / 121", want: 2, cards: [["JIM", "150", "ROUGH   2ND"], ["TOM", "98", "FAIRWAY   2ND"], ["SUE", "121", "FAIRWAY   2ND"]]})
            sc.Push({name: "putting green 28' 0 vs 29' 7", want: 1, cards: [["CARTER", "28' 0" . q, "GREEN   4TH"], ["AL", "29' 7" . q, "GREEN   4TH"]]})
            sc.Push({name: "green 14' 7 vs 9' 11", want: 2, cards: [["CARTER", "14' 7" . q, "GREEN   3RD"], ["AL", "9' 11" . q, "GREEN   3RD"]]})
            sc.Push({name: "around the green: lone 8 yds fringe vs 13 yds rough", want: 1, cards: [["CARTER", "8", "FRINGE   4TH"], ["AL", "13", "ROUGH   4TH"]]})
            sc.Push({name: "green 9' 2 beats fringe 3 yds", want: 2, cards: [["CARTER", "3", "FRINGE   4TH"], ["AL", "9' 2" . q, "GREEN   4TH"]]})
            sc.Push({name: "yards: fairway 2nd 179 beats tee 3rd 363", want: 2, cards: [["CARTER", "363", "TEE   3RD"], ["AL", "179", "FAIRWAY   2ND"]]})
            sc.Push({name: "three cards 212 / 87 / 143", want: 2, cards: [["AL", "212", "FAIRWAY   2ND"], ["ADY", "87", "FAIRWAY   2ND"], ["BOB", "143", "FAIRWAY   2ND"]]})
            sc.Push({name: "four cards 212 / 87 / 143 / 98", want: 2, cards: [["AL", "212", "FAIRWAY   2ND"], ["ADY", "87", "FAIRWAY   2ND"], ["BOB", "143", "ROUGH   2ND"], ["JIM", "98", "ROUGH   2ND"]], cw: 200, gap: 30})
            sc.Push({name: "green feet only 100 vs 99", want: 2, cards: [["AL", "100'", "GREEN   3RD"], ["BOB", "99'", "GREEN   3RD"]]})
            sc.Push({name: "fewest strokes beats green preference", want: 2, cards: [["AL", "1' 0" . q, "GREEN   3RD"], ["BOB", "100", "FAIRWAY   2ND"]]})
            ; GSPro's late-2026 update labels the card button "Select":
            ; every scenario again with that word.
            scCount := sc.MaxIndex()
            Loop, %scCount% {
                o := sc[A_Index]
                sc.Push({name: o.name . " [Select button]", want: o.want, cards: o.cards, cw: o.HasKey("cw") ? o.cw : 210, gap: o.HasKey("gap") ? o.gap : 50, word: "Select"})
            }
            for i, s in sc {
                ShowCards(s.cards, s.HasKey("cw") ? s.cw : 210, s.HasKey("gap") ? s.gap : 50, false, s.HasKey("word") ? s.word : "USE")
                ScrambleResetReads()
                seen := ""
                Loop, 3 {
                    scan := ScrambleRecoverCards(ScanWinClient(GSProWinNeedle, GSProWinExclude))
                    uses := ScrambleButtons(scan)
                    n := uses.MaxIndex()
                    lc := scan.lines.MaxIndex()
                    seen .= (seen = "" ? "" : ",") . (scan.found ? (lc = "" ? 0 : lc) . " lines/" . (n = "" ? 0 : n) . " USE in " . scan.win.title . " " . scan.win.w . "x" . scan.win.h . "@" . scan.win.x . "," . scan.win.y . (scan.win.hwnd = SmokeCardsHwnd ? "" : " (NOT the test window)") : "no GSPro window")
                    w := (n >= 2) ? ScrambleDecide(scan, uses, "", true) : 0
                    ScrambleCountRead(n, w)
                    Sleep, 150
                }
                pick := ScrambleVoteLeader()
                if ((lc = "" || lc = 0) && !InStr(s.name, "three cards")) {
                    ; Nothing read at all: is the window painted, and does a
                    ; smaller or enlarged read of one card see anything?
                    PixelGetColor, pc1, 240, 150, RGB
                    PixelGetColor, pc2, 240, 325, RGB
                    PixelGetColor, pc3, 50, 50, RGB
                    part := OcrRegion(135, 100, 210, 290)
                    big := OcrRegionScaled(135, 100, 210, 290, 2)
                    full := ScanScreen()
                    ScrambleNote("INFO", "0 lines: pixels card=" . pc1 . " use=" . pc2 . " bg=" . pc3 . "; one-card read " . Cnt(part.lines) . " lines [" . StrReplace(part.text, "`n", " / ") . "]; 2x read " . Cnt(big.lines) . " lines; whole screen " . Cnt(full.lines) . " lines [" . SubStr(StrReplace(full.text, "`n", " / "), 1, 300) . "]")
                }
                OcrDumpMiss("OCR scenario " . i . ": " . s.name, scan, "ocr_scenario_" . i . ".txt")
                CaptureWindow(SmokeCardsHwnd, "ocr_scenario_" . i)
                reads := ""
                lr := ScrambleLastRead
                if (IsObject(lr)) {
                    for k, cd in lr.cards
                        reads .= "  card " . k . ": " . cd.lie . " shot " . cd.shot . " dist " . cd.dist . " [" . cd.distRaw . "]"
                }
                ScrambleNote((pick = s.want) ? "PASS" : "FAIL", "OCR " . s.name . ": picked " . pick . " (want " . s.want . ", " . ScrambleVoteSummary() . "; reads saw " . seen . ")" . reads)
                if (pick != s.want)
                    fails += 1
            }
            ; ---- known Windows OCR behavior (2026-10-27, windows-latest) ----
            ; With 3 or 4 cards side by side, a read of the WHOLE window
            ; returned none of the card text (0 lines with no HUD; only the
            ; HUD lines with it), while a read of just the card strip, or of
            ; the window in halves/thirds/quarters, found every card.  Two
            ; cards read fine either way.  Not confirmed on a live GSPro
            ; screen.  Recorded here so a change in that behavior shows up.
            c4 := [["CARTER", "212", "FAIRWAY   2ND"], ["AL", "87", "FAIRWAY   2ND"], ["BOB", "143", "ROUGH   2ND"], ["JIM", "98", "ROUGH   2ND"]]
            exps := [["2 cards + HUD", [c4[1], c4[2]], 210, 50, true], ["3 cards + HUD", [c4[1], c4[2], c4[3]], 210, 50, true], ["4 cards + HUD", c4, 200, 30, true]]
            exps.Push(["3 cards + HUD, Select button", [c4[1], c4[2], c4[3]], 210, 50, true, "Select"], ["4 cards + HUD, Select button", c4, 200, 30, true, "Select"])
            for i, e in exps {
                ShowCards(e[2], e[3], e[4], e[5], e.HasKey(6) ? e[6] : "USE")
                ww := 1000, wh := 540
                scan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
                r := e[1] . ": full " . Cnt(ScrambleButtons(scan))
                recovered := ScrambleRecoverCards(scan)
                actualN := Cnt(ScrambleButtons(recovered))
                ScrambleResetReads()
                actualPick := actualN >= 2 ? ScrambleDecide(recovered, ScrambleButtons(recovered), "", true) : 0
                ok := (actualN = e[2].MaxIndex() && actualPick = 2)
                ScrambleNote(ok ? "PASS" : "FAIL", e[1] . " recovery sees " . actualN . " cards and picks " . actualPick)
                if (!ok)
                    fails += 1
                big := OcrRegionScaled(0, 0, ww, wh, 2)
                r .= " | 2x " . Cnt(ScrambleButtons(big))
                band := OcrRegion(0, 150, ww, 250)
                r .= " | band " . Cnt(ScrambleButtons(band))
                r .= " | halves " . TileUses(0, 0, ww, wh, 2)
                r .= " | thirds " . TileUses(0, 0, ww, wh, 3)
                r .= " | quarters " . TileUses(0, 0, ww, wh, 4)
                r .= "   (USE found; " . e[2].MaxIndex() . " cards)"
                ScrambleNote("INFO", r)
            }
            ; No cards and a single USE are not a scramble trigger.
            ShowCards([])
            empty := ScrambleRecoverCards(ScanWinClient(GSProWinNeedle, GSProWinExclude))
            ok := (Cnt(ScrambleButtons(empty)) = 0)
            ScrambleNote(ok ? "PASS" : "FAIL", "no cards remains unarmed")
            if (!ok)
                fails += 1
            ShowCards([["AL", "212", "FAIRWAY   2ND"]])
            single := ScrambleRecoverCards(ScanWinClient(GSProWinNeedle, GSProWinExclude))
            ok := (Cnt(ScrambleButtons(single)) < 2)
            ScrambleNote(ok ? "PASS" : "FAIL", "one card remains unarmed")
            if (!ok)
                fails += 1
            ShowCards([["AL", "212", "FAIRWAY   2ND"]], 210, 50, false, "Select")
            single := ScrambleRecoverCards(ScanWinClient(GSProWinNeedle, GSProWinExclude))
            ok := (Cnt(ScrambleButtons(single)) < 2)
            ScrambleNote(ok ? "PASS" : "FAIL", "one Select card remains unarmed")
            if (!ok)
                fails += 1
            ; Words that are not the card button never count.
            wordsOk := ScrambleIsButtonWord("Select") && ScrambleIsButtonWord("SELECT .") && ScrambleIsButtonWord("USE")
                && !ScrambleIsButtonWord("Selected") && !ScrambleIsButtonWord("Select Course") && !ScrambleIsButtonWord("HOUSE")
            ScrambleNote(wordsOk ? "PASS" : "FAIL", "card button words: USE / Select only, letters-only match")
            if (!wordsOk)
                fails += 1
            Loop, 4 {
                Gui, SmokeUse%A_Index%:Destroy
                Gui, SmokeCard%A_Index%:Destroy
            }
            Gui, SmokeCards:Destroy
        } else {
            ScrambleNote("SKIP", "Windows OCR is not available on this runner - real-OCR card reads not run")
        }
        FileAppend, % (fails ? "FAIL: " . fails . " scramble checks failed" : "PASS: scramble parsing and card reads") . "`n", % A_ScriptDir . "\result.txt"
        ExitApp, % fails ? 1 : 0
    } catch failure {
        FileAppend, % "FAIL: " . failure.Message . " (line " . failure.Line . ")`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
Return

; USE buttons found reading the area in n side-by-side tiles that
; overlap by 70 px (a button on a seam is read by both; counted once).
TileUses(x, y, w, h, n) {
    seen := {}
    tw := w // n
    Loop, %n% {
        tx := x + (A_Index - 1) * tw - 70
        if (tx < x)
            tx := x
        o := OcrRegion(tx, y, tw + 140, h)
        for k, u in ScrambleButtons(o)
            seen[Round((u.x + u.w / 2) / 40)] := 1
    }
    c := 0
    for k, v in seen
        c += 1
    return c
}

Cnt(arr) {
    n := IsObject(arr) ? arr.MaxIndex() : ""
    return (n = "") ? 0 : n
}

ScrambleNote(status, msg) {
    FileAppend, % status . ": " . msg . "`n", % A_ScriptDir . "\scramble-checks.txt", UTF-8
}

; Scramble shot-select cards drawn the way GSPro lays them out:
; dark cards on green, NAME / big DISTANCE / LIE + SHOT /
; USE button, centered on each card, in GSPro's proportions from
; the 4K field dump (USE text height h: lie row 3.0h above USE, a
; 1.55h-tall distance 5.7h above, name 9.4h above).  Cards and
; buttons are child windows with their own colors (plain GDI).
; No grid lines: this checks the 64-bit read path and the parsing,
; not the putting-green noise the field logs already cover.
ShowCards(cards, cw := 210, gap := 50, hud := false, word := "USE") {
    global SmokeCardsHwnd
    Loop, 4 {
        Gui, SmokeUse%A_Index%:Destroy
        Gui, SmokeCard%A_Index%:Destroy
    }
    Gui, SmokeCards:Destroy
    Gui, SmokeCards:New, -Caption +AlwaysOnTop +ToolWindow -DPIScale +HwndSmokeCardsHwnd, GSPro
    Gui, SmokeCards:Color, 3C7A3C
    Gui, SmokeCards:Margin, 0, 0
    if (hud) {
        ; GSPro's HUD around the edges (course, hole, shot data)
        Gui, SmokeCards:Font, s12 cFFFFFF Bold, Arial
        Gui, SmokeCards:Add, Text, x20 y12 BackgroundTrans, Acorns Golf Links
        Gui, SmokeCards:Add, Text, x20 y34 BackgroundTrans, PAR 4   286 YDS
        Gui, SmokeCards:Add, Text, x860 y12 BackgroundTrans, CLUB SPEED
        Gui, SmokeCards:Add, Text, x860 y34 BackgroundTrans, CARRY (game)
        Gui, SmokeCards:Add, Text, x860 y56 BackgroundTrans, BALL SPEED
        Gui, SmokeCards:Add, Text, x20 y500 BackgroundTrans, 17.70 UP
        Gui, SmokeCards:Add, Text, x860 y500 BackgroundTrans, L Wedge
    }
    Gui, SmokeCards:Show, x0 y0 w1000 h540 NoActivate
    n := cards.MaxIndex()
    uw := cw - 100
    x0 := (1000 - (n * cw + (n - 1) * gap)) // 2
    for i, c in cards {
        cx := x0 + (i - 1) * (cw + gap)
        Gui, SmokeCard%i%:New, -Caption +ParentSmokeCards -DPIScale
        Gui, SmokeCard%i%:Color, 1B2233
        Gui, SmokeCard%i%:Margin, 0, 0
        Gui, SmokeCard%i%:Font, s15 cFFFFFF Bold, Arial
        Gui, SmokeCard%i%:Add, Text, x0 y100 w%cw% Center BackgroundTrans, % c[1]
        Gui, SmokeCard%i%:Font, s19 cFFFFFF Bold, Arial
        Gui, SmokeCard%i%:Add, Text, x0 y146 w%cw% Center BackgroundTrans, % c[2]
        Gui, SmokeCard%i%:Font, s13 cE8E8E8 Bold, Arial
        Gui, SmokeCard%i%:Add, Text, x0 y179 w%cw% Center BackgroundTrans, % c[3]
        Gui, SmokeCard%i%:Show, x%cx% y100 w%cw% h290 NoActivate
        Gui, SmokeUse%i%:New, -Caption +ParentSmokeCard%i% -DPIScale
        Gui, SmokeUse%i%:Color, 2F6FD0
        Gui, SmokeUse%i%:Margin, 0, 0
        Gui, SmokeUse%i%:Font, s13 cFFFFFF Bold, Arial
        Gui, SmokeUse%i%:Add, Text, x0 y10 w%uw% Center BackgroundTrans, % word
        ux := (cw - uw) // 2
        Gui, SmokeUse%i%:Show, x%ux% y205 w%uw% h42 NoActivate
    }
    WinWait, ahk_id %SmokeCardsHwnd%, , 3
    Sleep, 1200
}
'''


PREVIEW = r'''
PreviewSmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    SetTimer, OcrWarmup, Off
    SetTimer, ScreenWatchTick, Off
    try {
        ; Geometry uses physical coordinates at 1x/2x and negative
        ; desktop origins, for every card in 2/3/4-player groups.
        for a, n in [2, 3, 4] {
            for b, scale in [1, 2] {
                wr := {found: true, hwnd: 1, x: -2000, y: -500, w: 1000 * scale, h: 540 * scale}
                us := []
                Loop, %n%
                    us.Push({x: wr.x + (100 + (A_Index - 1) * 230) * scale, y: wr.y + 320 * scale, w: 32 * scale, h: 16 * scale})
                Loop, %n% {
                    chosen := A_Index
                    r := ScramblePreviewRect(us, chosen, wr)
                    Assert(IsObject(r) && r.x >= wr.x && r.y >= wr.y && r.x + r.w <= wr.x + wr.w && r.y + r.h <= wr.y + wr.h, "Frame stays in game at negative origin " . n . "/" . chosen . "/" . scale)
                    for k, u in us {
                        if (k != chosen)
                            Assert(u.x + u.w / 2 < r.x || u.x + u.w / 2 > r.x + r.w, "Frame excludes neighboring card " . n . "/" . chosen . "/" . k)
                    }
                }
            }
        }
        wr := {found: true, hwnd: 1, x: -2000, y: -500, w: 1000, h: 540}
        us := [{x: -1700, y: -180, w: 32, h: 16}, {x: -1400, y: -180, w: 32, h: 16}]
        examples := [{reason: "Fewest strokes", inches: 175, green: false, raw: "14" . Chr(0x2019) . "7" . Chr(0x201D), lie: "fringe", shot: 2, otherShot: 3, otherDist: 72}
            , {reason: "Green preferred", inches: 110, green: true, raw: "91 2" . Chr(34), lie: "green", shot: 4, otherShot: 4, otherDist: 108}]
        for i, ex in examples {
            ScrambleResetReads()
            ScrambleCountRead(2, 1)
            ScrambleLastRead := {n: 2, winner: 1, cards: [{dist: ex.inches, green: ex.green, distRaw: ex.raw, lie: ex.lie, shot: ex.shot}
                , {dist: ex.otherDist, green: false, distRaw: "3", lie: "fringe", shot: ex.otherShot}]}
            ScrambleRememberPreview({win: wr}, us)
            example := ScramblePreviewModel(wr)
            Assert(example.reason = ex.reason, "Preview explains actual ranking: " . ex.reason)
            wanted := (ex.inches // 12) . Chr(0x2032) . " " . Mod(ex.inches, 12) . Chr(0x2033)
            Assert(InStr(example.detail, wanted), "Preview normalizes explicit/green feet marks: " . wanted)
        }
        q := Chr(34)
        for scenario, n in [2, 4] {
            cards := [["CARTER", "28' 0" . q, "GREEN   4TH"], ["AL", "29' 7" . q, "GREEN   4TH"]]
            if (n = 4)
                cards := [["AL", "212", "FAIRWAY   2ND"], ["ADY", "87", "FAIRWAY   2ND"], ["BOB", "143", "ROUGH   2ND"], ["JIM", "98", "ROUGH   2ND"]]
            ShowCards(cards, n = 4 ? 200 : 210, n = 4 ? 30 : 50)
            WinActivate, ahk_id %SmokeCardsHwnd%
            WinWaitActive, ahk_id %SmokeCardsHwnd%, , 3
            ScrambleResetReads()
            scan := ScrambleRecoverCards(ScanWinClient(GSProWinNeedle, GSProWinExclude))
            uses := ScrambleButtons(scan)
            winner := ScrambleDecide(scan, uses, "", true)
            ScrambleCountRead(Cnt(uses), winner)
            ScrambleRememberPreview(scan, uses)
            ScrambleAutoPick := true
            ScrambleCountdown := true
            ScrambleArmedTick := A_TickCount
            ScrambleCoolDown := false
            ScrambleMissTicks := 0
            model := ScramblePreviewModel(scan.win)
            Assert(IsObject(model) && model.pick = (n = 4 ? 2 : 1), "Preview matches voted card in " . n . "-card real OCR scene")
            Assert(InStr(model.detail, n = 4 ? "87 yd" : "28" . Chr(0x2032) . " 0" . Chr(0x2033)), "Preview displays parsed units in " . n . "-card scene: " . model.detail)
            activeBefore := WinExist("A")
            Gosub, CdTick
            Assert(CdVisible && ScrambleFrameVisible, "Countdown and frame are shown for " . n . " cards")
            Assert(WinExist("A") = activeBefore, "Showing preview keeps GSPro focused")
            Assert(ScramblePreviewExcluded, "Windows confirms all preview windows excluded from capture")
            for i, h in ScramblePreviewWindows {
                WinGet, style, ExStyle, ahk_id %h%
                Assert((style & 0x08080020) = 0x08080020, "Overlay is layered, transparent and no-activate " . i)
            }
            ; The actual production reader must still see the cards, with
            ; all five overlays visible. No screenshot-only OCR substitute.
            again := ScrambleRecoverCards(ScanWinClient(GSProWinNeedle, GSProWinExclude))
            againUses := ScrambleButtons(again)
            againWinner := ScrambleDecide(again, againUses, "", true)
            Assert(Cnt(againUses) = n && againWinner = winner, "Visible preview does not contaminate real OCR for " . n . " cards")
            Assert(ScrambleCardsStillUpForTest(uses), "USE-strip confirmation still succeeds under preview")
            ; Temporarily remove display affinity solely to capture the
            ; user-visible composition as evidence, then restore it.
            CapturePreview(scan.win, "scramble-preview-" . n)
            OnMessage(0x201, "PreviewClick")
            PreviewClickRoot := 0
            u := uses[model.pick]
            DpiClickAt(u.x + u.w // 2, u.y + u.h // 2)
            Assert(PreviewClickRoot = SmokeCardsHwnd, "Click reaches original USE button under preview")
            PreviewClickRoot := 0
            DpiClickAt(model.rect.x + 1, model.rect.y + model.rect.h // 2)
            Assert(PreviewClickRoot = SmokeCardsHwnd, "Click passes through highlight border to GSPro")
            OnMessage(0x201, "")
            Assert(WinExist("A") = SmokeCardsHwnd, "Click-through preview leaves game focused")
            ; Vote leader is the real pick even when the latest read
            ; votes differently. Partial sets cannot misnumber a frame.
            ScrambleCountRead(n, winner)
            other := winner = 1 ? 2 : 1
            ScrambleCountRead(n, other)
            ScrambleLastRead.winner := other
            ScrambleRememberPreview(scan, uses)
            model2 := ScramblePreviewModel(scan.win)
            Assert(model2.pick = winner, "Highlight follows majority rather than latest vote")
            ScrambleCountRead(n, other)
            model2 := ScramblePreviewModel(scan.win)
            Assert(model2.pick = other, "Highlight updates with vote-leader tie breaker")
            saved := ScramblePreviewRead
            if (n = 4) {
                ScramblePreviewRead := {win: scan.win, uses: [uses[1], uses[2]], cards: saved.cards, n: 2, at: A_TickCount}
                Assert(!IsObject(ScramblePreviewModel(scan.win)), "Partial card read cannot highlight wrong shot number")
                ScramblePreviewRead := saved
            }
            ScrambleLastRead.winner := 0
            ScrambleRememberPreview(scan, uses)
            Gosub, CdTick
            Assert(CdVisible && !ScrambleFrameVisible, "Unreadable decision shows reading status without a chosen frame")
            ScramblePreviewRead := saved
            Gosub, CdTick
            Gui, Main:Show
            WinActivate, ahk_id %MainHwnd%
            WinWaitActive, ahk_id %MainHwnd%, , 3
            Gosub, CdTick
            Assert(!CdVisible && !ScrambleFrameVisible, "Preview hides when another app has focus")
            Gui, Main:Hide
            WinActivate, ahk_id %SmokeCardsHwnd%
            WinWaitActive, ahk_id %SmokeCardsHwnd%, , 3
            Gosub, CdTick
            WinMove, ahk_id %SmokeCardsHwnd%, , 40, 20
            Gosub, CdTick
            Assert(!ScrambleFrameVisible, "Moved game invalidates old highlight coordinates")
            WinMove, ahk_id %SmokeCardsHwnd%, , 0, 0
            ScramblePreviewRead.at := A_TickCount
            Gosub, CdTick
            Assert(ScrambleFrameVisible, "Highlight returns at verified game geometry")
            WinMinimize, ahk_id %SmokeCardsHwnd%
            Gosub, CdTick
            Assert(!CdVisible && !ScrambleFrameVisible, "Minimized GSPro hides preview")
            WinRestore, ahk_id %SmokeCardsHwnd%
            WinActivate, ahk_id %SmokeCardsHwnd%
            WinWaitActive, ahk_id %SmokeCardsHwnd%, , 3
            ScramblePreviewRead.at := A_TickCount
            Gosub, CdTick
            ScramblePreviewExcluded := false
            OcrLockTake()
            Assert(!CdVisible && !ScrambleFrameVisible, "Capture-exclusion fallback hides overlays before OCR")
            Gosub, CdTick
            Assert(!CdVisible, "Fallback cannot reappear during an OCR lock")
            OcrBusy := false
            ScramblePreviewExcluded := true
            ScramblePreviewRead.at := A_TickCount
            Gosub, CdTick
            Assert(CdVisible && ScrambleFrameVisible, "Preview resumes after fallback read")
            ScrambleCountdown := false
            Gosub, CdTick
            Assert(!CdVisible && !ScrambleFrameVisible, "Existing countdown preference hides all visual feedback")
            ScrambleCountdown := true
            ScrambleAutoPick := false
            Gosub, CdTick
            Assert(!CdVisible, "Auto-Pick off hides preview")
            ScrambleAutoPick := true
            ScrambleCoolDown := true
            Gosub, CdTick
            Assert(!CdVisible, "Sent or stood-down pick hides preview")
            ScrambleCoolDown := false
            ScrambleMissTicks := 1
            Gosub, CdTick
            Assert(!CdVisible, "First missing-card scan hides preview without changing cancellation rule")
            ScrambleMissTicks := 0
            ScramblePreviewRead.at := A_TickCount - 5000
            Gosub, CdTick
            Assert(!ScrambleFrameVisible, "Stale card geometry is never highlighted")
            ScramblePreviewRead.at := A_TickCount
            ScrambleArmedTick := A_TickCount - ScrambleDelaySec * 1000 - 9000
            Gosub, CdTick
            Assert(!CdVisible, "Stalled countdown clears visual feedback")
            ScrambleResetReads()
            Assert(!IsObject(ScramblePreviewRead) && !CdVisible && !ScrambleFrameVisible, "New card set clears previous highlight")
        }
        FileAppend, PASS: scramble preview geometry and Windows UI/OCR checks`n, % A_ScriptDir . "\result.txt"
        ExitApp, 0
    } catch failure {
        FileAppend, % "FAIL: " . failure.Message . " (line " . failure.Line . ")`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
Return

PreviewClick(wParam, lParam, msg, hwnd) {
    global PreviewClickRoot
    PreviewClickRoot := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
}

ScrambleCardsStillUpForTest(uses) {
    global ScrambleLastUses
    ScrambleLastUses := uses
    return ScrambleCardsStillUp()
}

CapturePreview(win, name) {
    global ScramblePreviewWindows
    for i, h in ScramblePreviewWindows
        DllCall("SetWindowDisplayAffinity", "Ptr", h, "UInt", 0)
    DllCall("dwmapi\DwmFlush")
    Sleep, 150
    dc := DllCall("GetDC", "Ptr", 0, "Ptr")
    memory := DllCall("CreateCompatibleDC", "Ptr", dc, "Ptr")
    VarSetCapacity(info, 40, 0)
    NumPut(40, info, 0, "UInt"), NumPut(win.w, info, 4, "Int"), NumPut(-win.h, info, 8, "Int")
    NumPut(1, info, 12, "UShort"), NumPut(32, info, 14, "UShort")
    bitmap := DllCall("CreateDIBSection", "Ptr", dc, "Ptr", &info, "UInt", 0, "Ptr*", pixels, "Ptr", 0, "UInt", 0, "Ptr")
    old := DllCall("SelectObject", "Ptr", memory, "Ptr", bitmap, "Ptr")
    DllCall("BitBlt", "Ptr", memory, "Int", 0, "Int", 0, "Int", win.w, "Int", win.h, "Ptr", dc, "Int", win.x, "Int", win.y, "UInt", 0x40CC0020)
    SaveDibBmp(A_ScriptDir . "\" . name . ".bmp", pixels, win.w, win.h)
    DllCall("SelectObject", "Ptr", memory, "Ptr", old)
    DllCall("DeleteObject", "Ptr", bitmap)
    DllCall("DeleteDC", "Ptr", memory)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", dc)
    for i, h in ScramblePreviewWindows
        DllCall("SetWindowDisplayAffinity", "Ptr", h, "UInt", 0x11)
}
'''


REALSHOT = r'''
RealShotSmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    SetTimer, OcrWarmup, Off
    SetTimer, ScreenWatchTick, Off
    fails := 0
    try {
        dir := A_Args[1]
        ; Bruce's own GSPro scramble screenshots (player names replaced),
        ; read at full resolution with the real Windows OCR through the
        ; same bitmap -> stream -> ocr_words path as a screen capture.
        ; [file, cards, expected pick, card top, card bottom] - the card
        ; edges were measured from the pixels (outer edge, incl. border).
        shots := [["gspro-2p.jpg", 2, 2, 1349, 1656], ["gspro-3p.jpg", 3, 3, 1337, 1644], ["gspro-4p.jpg", 4, 4, 1344, 1651]]
        ; The same screens with the button word repainted "Select", as
        ; GSPro shows it since its late-2026 update (see fixtures README).
        shots.Push(["gspro-2p-select.jpg", 2, 2, 1349, 1656], ["gspro-3p-select.jpg", 3, 3, 1337, 1644], ["gspro-4p-select.jpg", 4, 4, 1344, 1651])
        for i, s in shots {
            hbm := LoadPicture(dir . "\" . s[1])
            VarSetCapacity(bm, 32, 0)
            DllCall("GetObject", "Ptr", hbm, "Int", A_PtrSize = 8 ? 32 : 24, "Ptr", &bm)
            w := NumGet(bm, 4, "Int"), h := NumGet(bm, 8, "Int")
            win := {found: true, x: 0, y: 0, w: w, h: h, hwnd: 0, title: "GSPro"}
            full := ShotOcr(hbm, 0, 0, w, h)
            fu := Cnt(ScrambleButtons(full))
            b := ScrambleCardBand(win)
            band := ShotOcr(hbm, b.x, b.y, b.w, b.h)
            bu := Cnt(ScrambleButtons(band))
            r := s[1] . " (" . w . "x" . h . "): full read " . fu . " USE, card strip y " . b.y . "-" . (b.y + b.h) . " " . bu . " USE"
            ok := (fu = s[2] && bu = s[2])
            ; the pick from the full read and from the strip alone
            for k, pair in [["full read", full], ["card strip", band]] {
                sc := {found: true, win: win, lines: pair[2].lines, text: pair[2].text}
                uses := ScrambleButtons(sc)
                ScrambleMemo := {}
                pick := (Cnt(uses) >= 2) ? ScrambleDecide(sc, uses, "", true) : 0
                cards := ""
                if (pick > 0 && IsObject(ScrambleLastRead)) {
                    for c, cd in ScrambleLastRead.cards
                        cards .= " [" . c . ": " . cd.lie . " " . cd.shot . " " . cd.distRaw . "]"
                }
                r .= "`n    " . pair[1] . ": pick " . pick . " (want " . s[3] . ")" . cards
                ok := ok && pick = s[3]
                if (k = 1) {
                    ; the highlight frame for every card, from the sorted USE boxes
                    for c, u in uses {
                        f := ScramblePreviewRect(uses, c, win)
                        cx := u.x + u.w / 2
                        fit := IsObject(f) && f.y >= s[4] - 30 && f.y <= s[4] + 12 && f.y + f.h >= s[5] - 12 && f.y + f.h <= s[5] + 30
                            && f.x >= cx - 150 && f.x <= cx - 118 && f.x + f.w >= cx + 118 && f.x + f.w <= cx + 150
                        r .= "`n      frame " . c . ": x " . (IsObject(f) ? f.x . "-" . (f.x + f.w) . " y " . f.y . "-" . (f.y + f.h) : "none") . " vs card y " . s[4] . "-" . s[5] . " center " . Round(cx) . (fit ? " fits" : " DOES NOT FIT")
                        ok := ok && fit
                    }
                }
            }
            ScrambleNote(ok ? "PASS" : "FAIL", r)
            if (!ok)
                fails += 1
            DllCall("DeleteObject", "Ptr", hbm)
        }
        FileAppend, % (fails ? "FAIL: " . fails . " real screenshots misread" : "PASS: real GSPro screenshots read, picked and framed") . "`n", % A_ScriptDir . "\result.txt"
        ExitApp, % fails ? 1 : 0
    } catch failure {
        FileAppend, % "FAIL: " . failure.Message . " (line " . failure.Line . ")`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
Return

; OCR a rectangle of a loaded picture exactly as OcrRegion does a
; screen rectangle: copy it to its own bitmap, stream, ocr_words.
ShotOcr(hbm, x, y, w, h) {
    scr := DllCall("GetDC", "Ptr", 0, "Ptr")
    sdc := DllCall("CreateCompatibleDC", "Ptr", scr, "Ptr")
    old1 := DllCall("SelectObject", "Ptr", sdc, "Ptr", hbm, "Ptr")
    part := DllCall("CreateCompatibleBitmap", "Ptr", scr, "Int", w, "Int", h, "Ptr")
    ddc := DllCall("CreateCompatibleDC", "Ptr", scr, "Ptr")
    old2 := DllCall("SelectObject", "Ptr", ddc, "Ptr", part, "Ptr")
    DllCall("BitBlt", "Ptr", ddc, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", sdc, "Int", x, "Int", y, "UInt", 0x00CC0020)
    DllCall("SelectObject", "Ptr", ddc, "Ptr", old2, "Ptr")
    DllCall("DeleteDC", "Ptr", ddc)
    DllCall("SelectObject", "Ptr", sdc, "Ptr", old1, "Ptr")
    DllCall("DeleteDC", "Ptr", sdc)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", scr)
    stream := HBitmapToRandomAccessStream(part)
    DllCall("DeleteObject", "Ptr", part)
    res := ocr_words(stream)
    o := {lines: [], text: res.text}
    for k, ln in res.lines {
        ln.x += x
        ln.y += y
        o.lines.Push(ln)
    }
    return o
}
'''


RELIEF = r'''
ReliefShotSmoke:
    SetTimer, ScrambleTick, Off
    SetTimer, CdTick, Off
    SetTimer, OcrWarmup, Off
    SetTimer, ScreenWatchTick, Off
    fails := 0
    try {
        dir := A_Args[1]
        ; Bruce's own GSPro 4 relief screenshots.  [file, choices top to
        ; bottom, highlighted, OB Rehit keys, Next Option keys, Move
        ; Forward keys, Move Back keys]; Drop Ball / Rehit is always Enter.
        shots := [["relief-water-lateral.jpg", "LATERAL DROP|FLAG LINE|REHIT", 1, "3 {Enter}", "2", "", "", 1572, 2036]
            , ["relief-water-flagline.jpg", "LATERAL DROP|FLAG LINE|REHIT", 2, "3 {Enter}", "3", "f", "b", 1569, 2034]
            , ["relief-ob-rehit.jpg", "REHIT", 1, "1 {Enter}", "", "", "", 1569, 2039]
            , ["relief-water-mulligan.jpg", "LATERAL DROP|FLAG LINE|REHIT|MULLIGAN", 1, "3 {Enter}", "2", "", "", 1572, 2036]
            , ["relief-water-mulligan-picked.jpg", "LATERAL DROP|FLAG LINE|REHIT|MULLIGAN", 4, "3 {Enter}", "1", "", "", 1572, 2036]
            , ["relief-water-mulligan-callout.jpg", "LATERAL DROP|FLAG LINE|REHIT|MULLIGAN", 4, "3 {Enter}", "1", "", "", 1572, 2036]
            , ["relief-water-mulligan-callout-row.jpg", "LATERAL DROP|FLAG LINE|REHIT|MULLIGAN", 4, "3 {Enter}", "1", "", "", 1572, 2036]]
        ; v5.2.0 relief-list actions: [Choice 1, Choice 2, Choice 3, Lateral, Flag Line, Mulligan, Rotate L, Rotate R, Zoom In, Zoom Out, Recenter]
        more := {}
        more["relief-water-lateral.jpg"] := "1 {Enter}|2 {Enter}|3 {Enter}|1 {Enter}|2 {Enter}||q|e|@wheelup|@wheeldown|@recenter"
        more["relief-water-flagline.jpg"] := "1 {Enter}|2 {Enter}|3 {Enter}|1 {Enter}|2 {Enter}||q|e|@wheelup|@wheeldown|@recenter"
        more["relief-ob-rehit.jpg"] := "1 {Enter}||||||q|e|@wheelup|@wheeldown|@recenter"
        more["relief-water-mulligan.jpg"] := "1 {Enter}|2 {Enter}|3 {Enter}|1 {Enter}|2 {Enter}|4 {Enter}|q|e|@wheelup|@wheeldown|@recenter"
        more["relief-water-mulligan-picked.jpg"] := more["relief-water-mulligan.jpg"]
        more["relief-water-mulligan-callout.jpg"] := more["relief-water-mulligan.jpg"]
        more["relief-water-mulligan-callout-row.jpg"] := more["relief-water-mulligan.jpg"]
        ; v5.2.1 cheat sheet labels [Drop Ball, Next Option, Move Forward, Move Back, OB Rehit] and the Mulligan button's follow-up
        labels := {}
        labels["relief-water-lateral.jpg"] := "ENTER: LATERAL|NEXT: 2 FLAG LINE|||REHIT + ENTER|mulligan:"
        labels["relief-water-flagline.jpg"] := "ENTER: FLAG LINE|NEXT: 3 REHIT|CLOSER (F)|FURTHER BACK (B)|REHIT + ENTER|mulligan:"
        labels["relief-ob-rehit.jpg"] := "ENTER: REHIT||||REHIT + ENTER|mulligan:"
        labels["relief-water-mulligan.jpg"] := "ENTER: LATERAL|NEXT: 2 FLAG LINE|||REHIT + ENTER|mulligan:4 {Enter}"
        labels["relief-water-mulligan-picked.jpg"] := "ENTER: MULLIGAN|NEXT: 1 LATERAL|||REHIT + ENTER|mulligan:{Enter}"
        labels["relief-water-mulligan-callout.jpg"] := labels["relief-water-mulligan-picked.jpg"]
        labels["relief-water-mulligan-callout-row.jpg"] := labels["relief-water-mulligan-picked.jpg"]
        for i, s in shots {
            src := LoadPicture(dir . "\" . s[1])
            VarSetCapacity(bm, 32, 0)
            DllCall("GetObject", "Ptr", src, "Int", A_PtrSize = 8 ? 32 : 24, "Ptr", &bm)
            W := NumGet(bm, 4, "Int"), H := NumGet(bm, 8, "Int")
            ; as captured, and shrunk to a 1920-wide window (a 1080p
            ; projector: the 2x read path)
            for k, tw in [W, 1920] {
                th := Round(H * tw / W)
                hbm := (tw = W) ? src : ShotScaled(src, W, H, tw, th)
                win := {found: true, x: 0, y: 0, w: tw, h: th, hwnd: 0}
                rel := ReliefRead(win, Func("ShotRead").Bind(hbm))
                sel := ReliefSelected(rel, Func("ShotPixel").Bind(hbm))
                names := ""
                for j, o in rel.opts
                    names .= (j > 1 ? "|" : "") . o.text
                plans := []
                for j, a in ["Rehit", "NextOption", "MoveForward", "MoveBack", "DropRehit"]
                    plans.Push(ReliefKeysText(ReliefPlan(a, rel, sel).keys))
                ok := rel.found && names = s[2] && sel = s[3] && plans[1] = s[4] && plans[2] = s[5] && plans[3] = s[6] && plans[4] = s[7] && plans[5] = "{Enter}"
                extra := ""
                for j, a in ["ReliefChoice1", "ReliefChoice2", "ReliefChoice3", "ReliefLateral", "ReliefFlagLine", "ReliefMulligan", "ReliefRotateLeft", "ReliefRotateRight", "ReliefZoomIn", "ReliefZoomOut", "ReliefRecenter"]
                    extra .= (j > 1 ? "|" : "") . ReliefKeysText(ReliefPlan(a, rel, sel).keys)
                ok := ok && extra = more[s[1]]
                lab := ""
                for j, a in ["DropRehit", "NextOption", "MoveForward", "MoveBack", "Rehit"]
                    lab .= YellowReliefLabel(a, rel, sel) . "|"
                lab .= "mulligan:" . ReliefKeysText(MulliganFollowKeys(rel, sel))
                ok := ok && lab = labels[s[1]]
                ScrambleNote(lab = labels[s[1]] ? "PASS" : "FAIL", "  sheet labels [" . lab . "]")
                rc := ReliefFindRecenter(win, Func("ShotRead").Bind(hbm))
                f := tw / W
                rcOk := IsObject(rc) && Abs(rc.x + rc.w / 2 - s[8] * f) <= 60 * f + 4 && Abs(rc.y + rc.h / 2 - s[9] * f) <= 25 * f + 4
                ok := ok && rcOk
                ScrambleNote(ok ? "PASS" : "FAIL", "  new actions [" . extra . "]; Recenter " . (IsObject(rc) ? "at " . Round(rc.x + rc.w / 2) . "," . Round(rc.y + rc.h / 2) . " (want " . Round(s[8] * f) . "," . Round(s[9] * f) . ")" : "not found"))
                ScrambleNote(ok ? "PASS" : "FAIL", s[1] . " at " . tw . "x" . th . ": " . (rel.found ? ReliefNote(rel) : "no panel") . "; highlighted " . sel . " (want " . s[3] . "); OB Rehit [" . plans[1] . "] Next Option [" . plans[2] . "] Move Forward [" . plans[3] . "] Move Back [" . plans[4] . "] Drop Ball/Rehit [" . plans[5] . "]")
                if (!ok) {
                    fails += 1
                    ScrambleNote("FAIL", "  read: " . ReliefLinesText(rel))
                }
                if (hbm != src)
                    DllCall("DeleteObject", "Ptr", hbm)
            }
            DllCall("DeleteObject", "Ptr", src)
        }
        ; Screens without the panel are never taken for it.
        for i, f in ["gspro-2p.jpg", "gspro-4p-select.jpg"] {
            src := LoadPicture(dir . "\" . f)
            VarSetCapacity(bm, 32, 0)
            DllCall("GetObject", "Ptr", src, "Int", A_PtrSize = 8 ? 32 : 24, "Ptr", &bm)
            W := NumGet(bm, 4, "Int"), H := NumGet(bm, 8, "Int")
            rel := ReliefRead({found: true, x: 0, y: 0, w: W, h: H, hwnd: 0}, Func("ShotRead").Bind(src))
            ok := !rel.found
            ScrambleNote(ok ? "PASS" : "FAIL", f . ": no relief panel (" . (rel.found ? ReliefNote(rel) : "none found") . ")")
            if (!ok)
                fails += 1
            DllCall("DeleteObject", "Ptr", src)
        }
        ; The older relief menu's words veto the panel; titles need their
        ; detail line; badges and a misread I are handled.
        lines := [{x: 100, y: 100, w: 120, h: 30, text: "REHIT"}, {x: 100, y: 140, w: 200, h: 20, text: "From your last spot"}]
        ok := ReliefParse(lines).found
        lone := ReliefParse([{x: 100, y: 100, w: 120, h: 30, text: "REHIT"}]).found
        lines.Push({x: 100, y: 200, w: 120, h: 20, text: "Move Forward"})
        ok := ok && !lone && !ReliefParse(lines).found
        ok := ok && ReliefTitleText("1 LATERAL DROP +1") = "LATERAL DROP" && ReliefTitleText("REHlT") = "REHlT" && ReliefTitleText("MULLIGAN NO STROKE") = "MULLIGAN"
            && ReliefTitleText("Rough") = "" && ReliefTitleText("From your last spot") = "" && ReliefTitleText("RELIEF OPTIONS") = "" && ReliefTitleText("160 yd") = ""
        ScrambleNote(ok ? "PASS" : "FAIL", "panel rules: old-menu words veto, title needs its detail line, badges stripped, I/l misread kept")
        if (!ok)
            fails += 1
        ; Mulligans on: OB shows 1 Rehit, 2 Mulligan.
        mul := {found: true, opts: [{text: "REHIT"}, {text: "MULLIGAN"}]}
        ok := ReliefKeysText(ReliefPlan("Rehit", mul, 2).keys) = "1 {Enter}" && ReliefKeysText(ReliefPlan("NextOption", mul, 1).keys) = "2"
            && ReliefKeysText(ReliefPlan("NextOption", mul, 2).keys) = "1" && ReliefKeysText(ReliefPlan("NextOption", mul, 0).keys) = "2"
            && ReliefKeysText(ReliefPlan("MoveForward", mul, 1).keys) = "" && ReliefKeysText(ReliefPlan("DropRehit", mul, 2).keys) = "{Enter}"
        ok := ok && ReliefKeysText(MulliganFollowKeys(mul)) = "2 {Enter}" && ReliefKeysText(MulliganFollowKeys(mul, 2)) = "{Enter}" && YellowReliefLabel("NextOption", mul, 1) = "NEXT: 2 MULLIGAN" && YellowReliefLabel("NextOption", mul, 2) = "NEXT: 1 REHIT"
            && YellowReliefLabel("DropRehit", mul, 2) = "ENTER: MULLIGAN" && YellowReliefLabel("MoveForward", mul, 1) = ""
        ScrambleNote(ok ? "PASS" : "FAIL", "OB with Mulligan: Rehit = 1 Enter, Next Option cycles 1-2, no Flag Line keys; Mulligan button = 2 Enter; labels NEXT: 2 MULLIGAN / ENTER: MULLIGAN")
        if (!ok)
            fails += 1
        ; ---- v5.3.0 screen watch ----
        ; The cheap looks on Bruce's screenshots, as captured and at 1920
        ; wide: the relief panel only on relief screens, the scramble
        ; cards only on scramble screens.
        for i, f in ["relief-water-lateral.jpg", "relief-water-flagline.jpg", "relief-ob-rehit.jpg", "relief-water-mulligan-picked.jpg", "gspro-2p.jpg", "gspro-3p.jpg", "gspro-4p-select.jpg"] {
            src := LoadPicture(dir . "\" . f)
            VarSetCapacity(bm, 32, 0)
            DllCall("GetObject", "Ptr", src, "Int", A_PtrSize = 8 ? 32 : 24, "Ptr", &bm)
            W := NumGet(bm, 4, "Int"), H := NumGet(bm, 8, "Int")
            isRelief := InStr(f, "relief") ? 1 : 0
            for k, tw in [W, 1920] {
                th := Round(H * tw / W)
                hbm := (tw = W) ? src : ShotScaled(src, W, H, tw, th)
                dc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
                o := DllCall("SelectObject", "Ptr", dc, "Ptr", hbm, "Ptr")
                lwin := {found: true, x: 0, y: 0, w: tw, h: th}
                rl := ReliefLook(lwin, dc)
                sl := ScrambleBoxLook(lwin, dc) ? 1 : 0
                DllCall("SelectObject", "Ptr", dc, "Ptr", o, "Ptr")
                DllCall("DeleteDC", "Ptr", dc)
                ok := ((rl.up ? 1 : 0) = isRelief) && (sl = 1 - isRelief)
                ScrambleNote(ok ? "PASS" : "FAIL", "screen watch look, " . f . " at " . tw . "x" . th . ": relief panel " . (rl.up ? "seen" : "not seen") . " (panel " . Round(rl.panel * 100) . "%, cards " . Round((rl.card + rl.blue) * 100) . "%), scramble cards " . (sl ? "seen" : "not seen"))
                if (!ok)
                    fails += 1
                if (hbm != src)
                    DllCall("DeleteObject", "Ptr", hbm)
            }
            DllCall("DeleteObject", "Ptr", src)
        }
        ; The whole thing on screen, timer running as in the program:
        ; a screenshot in a window named like GSPro.
        LoadProfile("Basic Secondary")
        RemapActive := true, ReliefAutoSheet := true, ReliefNoFn := true, ScrambleAutoPick := false
        ScrambleNote(A_ScreenHeight >= 1000 ? "PASS" : "FAIL", "on screen: test screen " . A_ScreenWidth . "x" . A_ScreenHeight . " (needs 1080 lines, like a bay)")
        if (A_ScreenHeight < 1000)
            fails += 1
        for j, shotFile in ["relief-water-flagline.jpg", "gspro-2p.jpg"] {
            sw := A_ScreenWidth - 20, sh := Round(sw * 2137 / 3438)
            if (sh > A_ScreenHeight - 60)
                sh := A_ScreenHeight - 60, sw := Round(sh * 3438 / 2137)
            ; shrunk smoothly first (like GSPro drawing at this size), so
            ; the window shows clean text rather than a jagged resize
            src := LoadPicture(dir . "\" . shotFile)
            VarSetCapacity(bm, 32, 0)
            DllCall("GetObject", "Ptr", src, "Int", A_PtrSize = 8 ? 32 : 24, "Ptr", &bm)
            showBmp := ShotScaled(src, NumGet(bm, 4, "Int"), NumGet(bm, 8, "Int"), sw, sh)
            DllCall("DeleteObject", "Ptr", src)
            Gui, Shot:New, -Caption +ToolWindow +HwndShotHwnd, GSPro screen watch test
            Gui, Shot:Margin, 0, 0
            Gui, Shot:Add, Picture, x0 y0 w%sw% h%sh%, HBITMAP:%showBmp%
            Gui, Shot:Show, x0 y0 w%sw% h%sh%
            WinActivate, ahk_id %ShotHwnd%
            WinWaitActive, ahk_id %ShotHwnd%, , 3
            SetTimer, ScreenWatchTick, 400
            t0 := A_TickCount
            if (j = 1) {
                while (!(ReliefWatchUp && CheatVisible) && A_TickCount - t0 < 9000)
                    Sleep, 100
                ok := ReliefWatchUp && CheatVisible && InStr(CheatShownText, "NO FN NEEDED") && InStr(CheatShownText, "right=ENTER: FLAG LINE") && InStr(CheatShownText, "up=CLOSER") && InStr(CheatShownText, "clubup=FN: CLEAR VIEW")
                ScrambleNote(ok ? "PASS" : "FAIL", "on screen " . sw . "x" . sh . ": the water list was seen in " . (A_TickCount - t0) . " ms and the sheet came up by itself [" . CheatShownText . "]")
                if (!ok)
                    fails += 1
                if (CheatVisible)
                    CheatPixels(CheatHwnd, "relief")
                ; What the watch costs: the window check and both looks,
                ; 50 times, on this 1080p screen.
                tc0 := 0, tc1 := 0, tcf := 0
                DllCall("QueryPerformanceFrequency", "Int64*", tcf)
                DllCall("QueryPerformanceCounter", "Int64*", tc0)
                Loop, 50 {
                    w2 := ReliefWatchWin()
                    ReliefLook(w2)
                    ScrambleBoxLook(w2)
                }
                DllCall("QueryPerformanceCounter", "Int64*", tc1)
                perLook := (tc1 - tc0) * 1000 / tcf / 50
                ; parts, for the record: each look alone, one screen row,
                ; and one copy of the whole panel corner
                parts := ""
                for pk, part in ["win", "relief", "scramble", "row", "block"] {
                    DllCall("QueryPerformanceCounter", "Int64*", tc0)
                    Loop, 20 {
                        if (part = "win")
                            ReliefWatchWin()
                        else if (part = "relief")
                            ReliefLook(w2)
                        else if (part = "scramble")
                            ScrambleBoxLook(w2)
                        else if (part = "row")
                            ScreenRowsFree(ScreenRows(0, w2.x, Round(w2.h * 0.5), [w2.y + 100]))
                        else {
                            bys := []
                            Loop, % Round(w2.h * 0.24)
                                bys.Push(w2.y + A_Index)
                            ScreenRowsFree(ScreenRows(0, w2.x, Round(w2.h * 0.5), bys))
                        }
                    }
                    DllCall("QueryPerformanceCounter", "Int64*", tc1)
                    parts .= part . " " . Round((tc1 - tc0) * 1000 / tcf / 20, 2) . " ms, "
                }
                ok := w2.found && perLook < 25
                ScrambleNote(ok ? "PASS" : "FAIL", "watch cost: " . Round(perLook, 2) . " ms per look (window check + relief look + scramble look) = " . Round(perLook / 4, 2) . "% of one CPU core at one look every 400 ms [" . parts . "]")
                if (!ok)
                    fails += 1
                ReliefLastAct := ""
                HandleBoxKeyDown("Right")   ; no FN: Drop Ball = Enter on Flag Line
                HandleBoxKeyUp("Right")
                ok := (ReliefLastAct = "DropRehit")
                ScrambleNote(ok ? "PASS" : "FAIL", "AIM right without FN on the relief list ran Drop Ball (Enter): [" . ReliefLastAct . "]")
                if (!ok)
                    fails += 1
                Sleep, 2500
                ok := ReliefWatchUp && IsObject(ReliefLast) && ReliefLast.found
                ScrambleNote(ok ? "PASS" : "FAIL", "the list still up after Enter was read again (Flag Line shows the lie with the list up)")
                if (!ok)
                    fails += 1
            } else {
                while (!(IsObject(ScrambleBoxCards) && CheatVisible) && A_TickCount - t0 < 12000)
                    Sleep, 100
                ok := IsObject(ScrambleBoxCards) && ScrambleBoxCards.n = 2 && CheatVisible && InStr(CheatShownText, "SCRAMBLE:") && InStr(CheatShownText, "teeleft=CARD 2") && InStr(CheatShownText, "teeright=|") && !ReliefWatchUp
                sw2 := ReliefWatchWin()
                ScrambleNote(ok ? "PASS" : "FAIL", "on screen, Auto-Pick off: the 2 scramble cards were seen in " . (A_TickCount - t0) . " ms and the sheet shows the bottom row [" . CheatShownText . "] (look " . (sw2.found ? (ScrambleBoxLook(sw2) ? "sees the cards" : "does not see the cards") : "no GSPro window") . ")")
                if (!ok)
                    fails += 1
                if (CheatVisible)
                    CheatPixels(CheatHwnd, "scramble-screen")
            }
            Gui, Shot:Destroy
            Sleep, 1200
            ok := !ReliefWatchUp && !IsObject(ScrambleBoxCards) && !CheatVisible
            ScrambleNote(ok ? "PASS" : "FAIL", "screen gone: sheet and box jobs back to normal")
            if (!ok)
                fails += 1
        }
        SetTimer, ScreenWatchTick, Off
        FileAppend, % (fails ? "FAIL: " . fails . " relief checks failed" : "PASS: GSPro 4 relief screens read and planned") . "`n", % A_ScriptDir . "\result.txt"
        ExitApp, % fails ? 1 : 0
    } catch failure {
        FileAppend, % "FAIL: " . failure.Message . " (line " . failure.Line . ")`n", % A_ScriptDir . "\result.txt"
        ExitApp, 1
    }
Return

; A picture shrunk or grown to tw x th (HALFTONE, like a smaller window).
ShotScaled(src, W, H, tw, th) {
    scr := DllCall("GetDC", "Ptr", 0, "Ptr")
    sdc := DllCall("CreateCompatibleDC", "Ptr", scr, "Ptr")
    old1 := DllCall("SelectObject", "Ptr", sdc, "Ptr", src, "Ptr")
    out := DllCall("CreateCompatibleBitmap", "Ptr", scr, "Int", tw, "Int", th, "Ptr")
    ddc := DllCall("CreateCompatibleDC", "Ptr", scr, "Ptr")
    old2 := DllCall("SelectObject", "Ptr", ddc, "Ptr", out, "Ptr")
    DllCall("SetStretchBltMode", "Ptr", ddc, "Int", 4)
    DllCall("SetBrushOrgEx", "Ptr", ddc, "Int", 0, "Int", 0, "Ptr", 0)
    DllCall("StretchBlt", "Ptr", ddc, "Int", 0, "Int", 0, "Int", tw, "Int", th, "Ptr", sdc, "Int", 0, "Int", 0, "Int", W, "Int", H, "UInt", 0x00CC0020)
    DllCall("SelectObject", "Ptr", ddc, "Ptr", old2, "Ptr")
    DllCall("DeleteDC", "Ptr", ddc)
    DllCall("SelectObject", "Ptr", sdc, "Ptr", old1, "Ptr")
    DllCall("DeleteDC", "Ptr", sdc)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", scr)
    return out
}

; ReliefRead's reader on a picture: the same region, enlarged by
; `scale` exactly like OcrRegionScaled, boxes mapped back.
ShotRead(hbm, x, y, w, h, scale) {
    if (scale <= 1)
        return ShotOcr(hbm, x, y, w, h)
    part := ShotScaledPart(hbm, x, y, w, h, scale)
    stream := HBitmapToRandomAccessStream(part)
    DllCall("DeleteObject", "Ptr", part)
    res := ocr_words(stream)
    o := {lines: [], text: res.text}
    for k, ln in res.lines {
        ln.x := Round(ln.x / scale) + x
        ln.y := Round(ln.y / scale) + y
        ln.w := Round(ln.w / scale)
        ln.h := Round(ln.h / scale)
        o.lines.Push(ln)
    }
    return o
}

ShotScaledPart(hbm, x, y, w, h, scale) {
    scr := DllCall("GetDC", "Ptr", 0, "Ptr")
    sdc := DllCall("CreateCompatibleDC", "Ptr", scr, "Ptr")
    old1 := DllCall("SelectObject", "Ptr", sdc, "Ptr", hbm, "Ptr")
    out := DllCall("CreateCompatibleBitmap", "Ptr", scr, "Int", w * scale, "Int", h * scale, "Ptr")
    ddc := DllCall("CreateCompatibleDC", "Ptr", scr, "Ptr")
    old2 := DllCall("SelectObject", "Ptr", ddc, "Ptr", out, "Ptr")
    DllCall("SetStretchBltMode", "Ptr", ddc, "Int", 4)
    DllCall("SetBrushOrgEx", "Ptr", ddc, "Int", 0, "Int", 0, "Ptr", 0)
    DllCall("StretchBlt", "Ptr", ddc, "Int", 0, "Int", 0, "Int", w * scale, "Int", h * scale, "Ptr", sdc, "Int", x, "Int", y, "Int", w, "Int", h, "UInt", 0x00CC0020)
    DllCall("SelectObject", "Ptr", ddc, "Ptr", old2, "Ptr")
    DllCall("DeleteDC", "Ptr", ddc)
    DllCall("SelectObject", "Ptr", sdc, "Ptr", old1, "Ptr")
    DllCall("DeleteDC", "Ptr", sdc)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", scr)
    return out
}

; ReliefSelected's pixel source on a picture (0x00BBGGRR, like GetPixel on the screen).
ShotPixel(hbm, x, y) {
    dc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    old := DllCall("SelectObject", "Ptr", dc, "Ptr", hbm, "Ptr")
    c := DllCall("GetPixel", "Ptr", dc, "Int", x, "Int", y, "UInt")
    DllCall("SelectObject", "Ptr", dc, "Ptr", old, "Ptr")
    DllCall("DeleteDC", "Ptr", dc)
    return c
}
'''


def ocr_available():
    """Ask Windows itself (outside AutoHotkey) whether an OCR engine exists."""
    probe = ("Add-Type -AssemblyName System.Runtime.WindowsRuntime; "
             "$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]; "
             "$e = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages(); "
             "if ($e) { 'OCR ' + $e.RecognizerLanguage.LanguageTag } else { 'NOOCR' }")
    try:
        out = subprocess.run(["powershell", "-NoProfile", "-Command", probe], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as error:
        return False, f"probe failed: {error}"
    text = (out.stdout + out.stderr).strip()
    return text.startswith("OCR "), text


def open_windows_text(pid):
    """Titles and child text of the visible top-level windows of pid
    (a hang is usually an error or message box waiting for a click)."""
    import ctypes
    from ctypes import wintypes
    user32 = ctypes.windll.user32
    found = []
    proc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

    def text_of(hwnd):
        buf = ctypes.create_unicode_buffer(1024)
        user32.GetWindowTextW(hwnd, buf, 1024)
        return buf.value

    def on_child(hwnd, _):
        t = text_of(hwnd)
        if t.strip():
            found.append("    " + t.replace("\r", " ").replace("\n", " | ")[:600])
        return True

    def on_top(hwnd, _):
        owner = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(owner))
        if owner.value == pid and user32.IsWindowVisible(hwnd):
            cls = ctypes.create_unicode_buffer(256)
            user32.GetClassNameW(hwnd, cls, 256)
            found.append(f"[{cls.value}] {text_of(hwnd)}")
            user32.EnumChildWindows(hwnd, proc(on_child), 0)
        return True

    user32.EnumWindows(proc(on_top), 0)
    return "\n".join(found) or "(no visible windows)"


def runtime_checks(source, ahk):
    assert os.name == "nt", "AutoHotkey runtime checks require Windows"
    digest = hashlib.sha256(ahk.read_bytes()).hexdigest()
    assert digest == "effdea83c6b7a1dc2ce9e9d40e91dfd59bed9fcbd580903423648b7ca97d9696", "Use official AutoHotkey v1.1.37.02 Unicode 64-bit"
    with tempfile.TemporaryDirectory(prefix="BA-Remapper-tests-") as directory:
        work = Path(directory)
        shutil.copytree(ROOT / "assets", work / "assets")
        # Parse the exact production source without running its startup section.
        syntax = subprocess.run([str(ahk), "/ErrorStdOut", "/iLib", str(work / "includes.ahk"), str(ROOT / "BARemapper.ahk")], capture_output=True, text=True, timeout=40)
        assert syntax.returncode == 0, syntax.stdout + syntax.stderr
        print("PASS: AutoHotkey parsed production source")
        isolated = source.replace('ConfigDir    := DocsRoot . "\\BA Custom Products\\Remapper"', 'ConfigDir    := A_ScriptDir . "\\data"')
        isolated = isolated.replace('TriggerFile  := A_Temp . "\\baremapper_show.tmp"', 'TriggerFile  := A_ScriptDir . "\\show.tmp"')
        isolated = isolated.replace("BARemapper_BACustomProducts_SingleInstance", "BARemapper_Regression_" + work.name)
        isolated = isolated.replace("\nMigrateLegacyFiles()\n", "\n; migration disabled in isolated test\n")
        isolated = isolated.replace("\nRefreshAutoStartPath()\n", "\n; startup repair disabled in isolated test\n")
        marker = "SetTimer, OcrWarmup, -3000\nReturn"
        assert marker in isolated
        isolated = isolated.replace(marker, "SetTimer, UiSmoke, -50\nReturn", 1)
        (work / "smoke.ahk").write_text(isolated + "\n" + SMOKE, encoding="utf-8-sig")
        (work / "sink.ahk").write_text(SINK, encoding="utf-8-sig")
        smoke = subprocess.Popen([str(ahk), "/ErrorStdOut", str(work / "smoke.ahk"), "/show"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            out, err = smoke.communicate(timeout=120)
        except subprocess.TimeoutExpired:
            windows = open_windows_text(smoke.pid)
            smoke.kill()
            smoke.communicate()
            done = (work / "checks.txt").read_text().splitlines() if (work / "checks.txt").exists() else []
            raise AssertionError("UiSmoke timed out. Last checks:\n" + "\n".join(done[-6:]) + "\nOpen windows:\n" + windows)
        result = subprocess.CompletedProcess(smoke.args, smoke.returncode, out, err)
        artifacts = ROOT / "verification"
        artifacts.mkdir(exist_ok=True)
        for artifact in list(work.glob("*.bmp")) + list(work.glob("*.txt")):
            shutil.copy2(artifact, artifacts / artifact.name)
        print((work / "checks.txt").read_text() if (work / "checks.txt").exists() else "No runtime checks reached")
        report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
        assert result.returncode == 0 and report.startswith("PASS:"), report + "\n" + result.stdout + result.stderr
        rows = [tuple(map(int, row.split(","))) for row in (work / "events.txt").read_text().splitlines()]
        downs, durations = {}, []
        for tick, message, key in rows:
            if message in (0x100, 0x104):
                downs.setdefault(key, tick)
            elif key in downs:
                durations.append((key, tick - downs.pop(key)))
        b_taps = [duration for key, duration in durations if key == 0x42]
        assert len(b_taps) == 5 and all(duration >= 40 for duration in b_taps), f"B taps: {b_taps}, events: {rows}"
        assert not any(key in (0x41, 0x49, 0x4B) for _, _, key in rows), f"Unexpected FN/club key leak: {rows}"
        assert any(key == 0x27 for _, _, key in rows), "Arrow was not received"
        assert any(key == 0x11 for _, _, key in rows) and any(key == 0x4D for _, _, key in rows), "Ctrl+M was not received"
        assert not any(key in (0x43, 0x25) for _, _, key in rows), f"FN + Tee Left / Aim Left leaked their own keys: {rows}"
        downs = [key for _, message, key in rows if message in (0x100, 0x104)]
        assert 0x77 in downs and 0x78 in downs, f"F8 / F9 markers around the Mulligan press: {downs}"
        between = downs[downs.index(0x77) + 1:downs.index(0x78)]
        assert 0x4D in between and 0x0D not in between and not any(0x30 <= key <= 0x39 for key in between), f"Mulligan button without the relief list: Ctrl+M only, got {between}"
        print("PASS: the box's Ctrl+M reached the game untouched; no number or Enter followed it without the relief list")
        assert 0x75 in downs and 0x76 in downs, f"F6 / F7 markers around the scramble take: {downs}"
        take = downs[downs.index(0x75) + 1:downs.index(0x76)]
        assert take == [0x31], f"Scramble screen: AIM right sent the card's number 1 and nothing else, got {take}"
        print("PASS: scramble cards from the box: Tee Left / Reset Aim tap picked, AIM right sent 1; no A, V or arrow leaked")
        relief_downs = [key for _, message, key in rows if message in (0x100, 0x104) and key in (0x32, 0x33, 0x0D, 0x34, 0x71, 0x58)]
        assert relief_downs[:6] == [0x32, 0x33, 0x0D, 0x34, 0x71, 0x58], f"Panel keys 2, 3, Enter; sequence 4, F2; custom tap X: {relief_downs}"
        assert not any(key in (0x59, 0x56, 0x4F) for _, _, key in rows), f"Heat Map / Tee Right / Flyover leaked their printed keys: {rows}"
        print(f"PASS: five real B keypresses held {b_taps} ms (the fifth with the cheat sheet showing); no A/I/K leak; arrow and Ctrl+M received")
        print("PASS: GSPro 4 relief panel: FN + Aim Left sent 2 (Next Option), FN + Tee Left sent 3 then Enter (OB Rehit); no C / Left leak")
        print("PASS: custom layouts: key sequence 4 then F2 and custom tap X reached the key target; no Y / V / O leak")
        print("PASS: Exit completed without hanging")
        for mode, extra, arguments in [("ProgramSmoke", PROGRAM, []), ("BootSmoke", BOOT, ["/startup"]), ("FactorySmoke", FACTORY, [])]:
            (work / "result.txt").unlink(missing_ok=True)
            candidate = isolated.replace("SetTimer, UiSmoke, -50", f"SetTimer, {mode}, -50", 1)
            script = work / (mode + ".ahk")
            script.write_text(candidate + "\n" + SMOKE + "\n" + extra, encoding="utf-8-sig")
            try:
                check = subprocess.run([str(ahk), "/ErrorStdOut", str(script), *arguments], capture_output=True, text=True, timeout=40 if mode == "ProgramSmoke" else 15)
            except subprocess.TimeoutExpired:
                for artifact in list(work.glob("*.bmp")) + list(work.glob("*.txt")):
                    shutil.copy2(artifact, artifacts / artifact.name)
                report = (work / "factory-checks.txt").read_text() if (work / "factory-checks.txt").exists() else "No phase reached"
                raise AssertionError(f"{mode} timed out: {report}")
            report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
            assert check.returncode == 0, mode + ": " + report + check.stdout + check.stderr
            if mode == "ProgramSmoke":
                assert report.startswith("PASS:"), "Program-launch checks failed: " + report
                print("PASS: opened by a program = mapping on, tray only, startup profile; reopen by a program re-enables mapping without the window; /show brings it up; log names the opener")
            elif mode == "BootSmoke":
                assert (work / "result.txt").read_text().startswith("PASS:"), "Startup checks failed"
                print("PASS: startup loads the chosen profile, enables mapping and stays hidden")
            else:
                backups = list((work / "data Backups").glob("*/settings.ini"))
                assert len(backups) == 1, "Factory reset did not create one backup"
                assert (backups[0].parent / "profiles" / "Regression Copy.ini").exists(), "Backup lost custom profile"
                assert not (work / "data" / "settings.ini").exists(), "Factory reset retained preferences"
                assert not (work / "data" / "profiles").exists(), "Factory reset retained profiles"
                assert (work / "data" / "launch_log.txt").exists(), "Factory reset removed diagnostic log"
                print("PASS: factory reset backs up profiles/preferences before clearing them; logs remain")
        has_ocr, ocr_note = ocr_available()
        print(f"Windows OCR on this machine: {ocr_note}")
        (work / "result.txt").unlink(missing_ok=True)
        candidate = isolated.replace("SetTimer, UiSmoke, -50", "SetTimer, ScrambleSmoke, -50", 1)
        script = work / "ScrambleSmoke.ahk"
        script.write_text(candidate + "\n" + SMOKE + "\n" + SCRAMBLE, encoding="utf-8-sig")
        try:
            check = subprocess.run([str(ahk), "/ErrorStdOut", str(script), "ocr" if has_ocr else "noocr"], capture_output=True, text=True, timeout=360)
            returncode = check.returncode
            output = check.stdout + check.stderr
        except subprocess.TimeoutExpired:
            returncode, output = -1, "timed out"
        for artifact in list(work.glob("*.bmp")) + list(work.glob("*.txt")):
            shutil.copy2(artifact, artifacts / artifact.name)
        notes = (work / "scramble-checks.txt").read_text(encoding="utf-8-sig") if (work / "scramble-checks.txt").exists() else "No scramble checks reached"
        print(notes)
        annotate("notice", "Scramble checks (" + ("real Windows OCR: " + ocr_note if has_ocr else "no OCR engine") + ")", notes)
        dumps = sorted((work / "data").glob("ocr_scenario_*.txt"))
        report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
        # GitHub keeps only 10 notices per step: raw OCR dumps only when a read failed,
        # so the real-screenshot summary below is never crowded out.
        if dumps and not report.startswith("PASS:"):
            annotate("notice", "OCR scenario reads", "\n".join(d.read_text(errors="replace") for d in dumps))
        assert returncode == 0 and report.startswith("PASS:"), "ScrambleSmoke: " + report + output
        print("PASS: " + ("green feet/inches, around-the-green and yards cards read with the real Windows OCR in this build" if has_ocr else "distance parsing in this build (real-OCR card reads skipped: no OCR engine)"))

        if has_ocr:
            (work / "result.txt").unlink(missing_ok=True)
            (work / "checks.txt").unlink(missing_ok=True)
            candidate = isolated.replace("SetTimer, UiSmoke, -50", "SetTimer, PreviewSmoke, -50", 1)
            script = work / "PreviewSmoke.ahk"
            script.write_text(candidate + "\n" + SMOKE + "\n" + SCRAMBLE + "\n" + PREVIEW, encoding="utf-8-sig")
            try:
                check = subprocess.run([str(ahk), "/ErrorStdOut", str(script)], capture_output=True, text=True, timeout=90)
                returncode, output = check.returncode, check.stdout + check.stderr
            except subprocess.TimeoutExpired:
                returncode, output = -1, "timed out"
            for artifact in list(work.glob("*.bmp")) + list(work.glob("*.txt")):
                shutil.copy2(artifact, artifacts / artifact.name)
            checks = (work / "checks.txt").read_text() if (work / "checks.txt").exists() else "No preview checks reached"
            print(checks)
            annotate("notice", "Scramble preview checks", checks)
            report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
            assert returncode == 0 and report.startswith("PASS:"), "PreviewSmoke: " + report + output
            print("PASS: voted-card preview, parsed units, physical geometry, focus, click-through, capture exclusion, real OCR and visual cleanup")

            # Bruce's real GSPro scramble screenshots (2/3/4 players, names
            # replaced): the real Windows OCR must find every card in a full
            # read and in the card strip alone, pick correctly from both, and
            # the highlight frame must sit on the real card edges.
            (work / "result.txt").unlink(missing_ok=True)
            (work / "scramble-checks.txt").unlink(missing_ok=True)
            candidate = isolated.replace("SetTimer, UiSmoke, -50", "SetTimer, RealShotSmoke, -50", 1)
            script = work / "RealShotSmoke.ahk"
            script.write_text(candidate + "\n" + SMOKE + "\n" + SCRAMBLE + "\n" + REALSHOT, encoding="utf-8-sig")
            try:
                check = subprocess.run([str(ahk), "/ErrorStdOut", str(script), str(ROOT / "tests" / "fixtures" / "gspro")], capture_output=True, text=True, timeout=360)
                returncode, output = check.returncode, check.stdout + check.stderr
            except subprocess.TimeoutExpired:
                returncode, output = -1, "timed out"
            notes = (work / "scramble-checks.txt").read_text(encoding="utf-8-sig") if (work / "scramble-checks.txt").exists() else "No real-screenshot reads recorded"
            print(notes)
            annotate("notice", "Real GSPro screenshots", notes)
            report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
            assert returncode == 0 and report.startswith("PASS:"), "RealShotSmoke: " + report + output
            print("PASS: real GSPro 2/3/4-player screenshots: every card read (full and strip), correct pick, frame on the card edges")

            # Bruce's GSPro 4 relief screenshots (water: Lateral Drop and
            # Flag Line highlighted; OB: Rehit), as captured and at 1920
            # wide: the panel, every choice, the highlighted one, and the
            # keys each box button would press.
            (work / "result.txt").unlink(missing_ok=True)
            (work / "scramble-checks.txt").unlink(missing_ok=True)
            candidate = isolated.replace("SetTimer, UiSmoke, -50", "SetTimer, ReliefShotSmoke, -50", 1)
            script = work / "ReliefShotSmoke.ahk"
            script.write_text(candidate + "\n" + SMOKE + "\n" + SCRAMBLE + "\n" + REALSHOT + "\n" + RELIEF, encoding="utf-8-sig")
            try:
                check = subprocess.run([str(ahk), "/ErrorStdOut", str(script), str(ROOT / "tests" / "fixtures" / "gspro")], capture_output=True, text=True, timeout=240)
                returncode, output = check.returncode, check.stdout + check.stderr
            except subprocess.TimeoutExpired:
                returncode, output = -1, "timed out"
            notes = (work / "scramble-checks.txt").read_text(encoding="utf-8-sig") if (work / "scramble-checks.txt").exists() else "No relief reads recorded"
            print(notes)
            annotate("notice", "GSPro 4 relief screenshots", notes)
            report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
            failed = "\n".join(line for line in notes.splitlines() if line.startswith("FAIL") or "on screen" in line)
            assert returncode == 0 and report.startswith("PASS:"), "ReliefShotSmoke: " + report + failed + output
            print("PASS: GSPro 4 relief screenshots: panel, choices, highlighted choice and the keys for every box button")



def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--ahk", type=Path)
    args = parser.parse_args()
    source = (ROOT / "BARemapper.ahk").read_text(encoding="utf-8-sig")
    baseline = args.baseline.read_text(encoding="utf-8-sig") if args.baseline else subprocess.check_output(["git", "show", BASE + ":BARemapper.ahk"], cwd=ROOT).decode("utf-8-sig")
    # The scramble checks print feet/inch marks (curly quotes, primes) that
    # the Windows console code page cannot encode.
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")
    try:
        static_checks(source, baseline)
        if args.ahk:
            runtime_checks(source, args.ahk.resolve())
    except Exception as failure:
        annotate("error", "Regression check failed", f"{type(failure).__name__}: {failure}")
        raise


if __name__ == "__main__":
    main()
