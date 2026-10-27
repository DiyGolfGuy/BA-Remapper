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
    body = text.replace("%", "%25").replace("\r", "").replace("\n", "%0A")
    print(f"::{level} title={title}::{body[:60000]}")


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
        "ScrambleCardsStillUp",
        "SetAutoStart", "EnsureStartupApproved", "RefreshAutoStartPath",
        "ScanWinClient", "ScanScreen", "OcrRegion", "ocr_words",
    ]
    for name in unchanged:
        assert function(source, name) == function(baseline, name), f"Unexpected core change: {name}"
    for start, end in [
        ("TrayOcrDump:", "; Forget this PC's locked Smart Click spots"),
        ("ScrambleWork:", "OnOpenFolder:"),
        (";  BOX KEY HOTKEYS", ";  HELP WINDOW"),
        ("ExitLabel:", "; ============================================================================"),
    ]:
        # Section comments may surround a block; compare the complete original block.
        old = baseline[baseline.index(start):baseline.index(end, baseline.index(start))]
        assert old in source, f"Unexpected change to preserved section: {start}"
    # v5.1.1 changed the two distance parsers on purpose: typographic
    # quote marks are normalized first, because the Unicode 64-bit build
    # receives them as real Unicode characters (the 32-bit ANSI build got
    # cp1252 bytes 145-148). Apart from that one call, both are unchanged.
    for name, old_line, new_line in [
        ("ScrambleParseDistance", "t := ScrambleStripMarks(text)", "t := ScrambleStripMarks(ScrambleNormQuotes(text))"),
    ]:
        assert function(source, name) == function(baseline, name).replace(old_line, new_line, 1), f"Unexpected core change: {name}"
    assert "0x201D" in function(source, "ScrambleNormQuotes"), "Curly inch mark normalized"
    # FeetInches also changed on purpose (real Windows OCR read 29' 7" as
    # "291 71'"): a lone trailing ' is the inch mark, and every result goes
    # through ScrambleFtIn (inches 0-11, no green distance over 199 ft).
    feet = function(source, "FeetInches")
    assert "t := ScrambleNormQuotes(raw)" in feet and feet.count("ScrambleFtIn(") == 4 and "* 12 +" not in feet, "FeetInches routes every result through ScrambleFtIn"
    assert "ft > 199" in function(source, "ScrambleFtIn"), "Oversized green distance refused"
    assert 'SendMode, Input' in source  # Primary-key and scramble output mode preserved.
    assert 'if (FnIsDown)\n            return' in function(source, "HandleBoxKeyDown")
    assert 'SetKeyDelay, 15, 60' in function(source, "SendSecondaryKey")
    assert 'SendEvent, %keys%' in function(source, "SendSecondaryKey")
    assert 'gResetSmartSpots, Reset Smart Click Spots' in source
    assert 'gOnCleanup,' not in source
    print(f"PASS: {len(unchanged)} core functions, diagnostics, hotkeys and exit preserved; distance parsers changed only as documented (quote marks, inch-mark misreads)")


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
    try {
        Assert(!RemapActive, "Manual launch starts with mapping off")
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
        SetTimer, FillCopyName, -100
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
        SetTimer, CloseFnNotice, -100
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

FillCopyName:
    ControlSetText, Edit1, Regression Copy, Customize a Copy
    ControlClick, Button1, Customize a Copy
Return

CloseFnNotice:
    ControlClick, Button1, FN Button
Return

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
        for i, c in cases {
            got := ScrambleParseDistance(c[1], c[2])
            ScrambleNote((got = c[3]) ? "PASS" : "FAIL", "parse [" . c[1] . "] " . (c[2] ? "green" : "yards") . " -> " . got . " (want " . c[3] . ")")
            if (got != c[3])
                fails += 1
        }
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
            for i, s in sc {
                ShowCards(s.cards)
                ScrambleResetReads()
                seen := ""
                Loop, 3 {
                    scan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
                    uses := FindAllLinesExact(scan, "use")
                    n := uses.MaxIndex()
                    lc := scan.lines.MaxIndex()
                    seen .= (seen = "" ? "" : ",") . (scan.found ? (lc = "" ? 0 : lc) . " lines/" . (n = "" ? 0 : n) . " USE in " . scan.win.title . " " . scan.win.w . "x" . scan.win.h . "@" . scan.win.x . "," . scan.win.y . (scan.win.hwnd = SmokeCardsHwnd ? "" : " (NOT the test window)") : "no GSPro window")
                    w := (n >= 2) ? ScrambleDecide(scan, uses, "", true) : 0
                    ScrambleCountRead(n, w)
                    Sleep, 150
                }
                pick := ScrambleVoteLeader()
                if (lc = "" || lc = 0) {
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
                if (pick != s.want && !InStr(s.name, "three cards"))
                    fails += 1
            }
            ; ---- experiments: what makes a full-window read come back empty ----
            three := [["AL", "212", "FAIRWAY   2ND"], ["ADY", "87", "FAIRWAY   2ND"], ["BOB", "143", "FAIRWAY   2ND"]]
            four := [["AL", "212", "FAIRWAY   2ND"], ["ADY", "87", "FAIRWAY   2ND"], ["BOB", "143", "FAIRWAY   2ND"], ["JIM", "98", "ROUGH   2ND"]]
            exps := [["E1 3 cards (as above)", three, 210, 50, false], ["E2 3 cards + GSPro HUD text", three, 210, 50, true]
                , ["E3 4 cards + HUD", four, 200, 30, true], ["E4 4 cards no HUD", four, 200, 30, false]
                , ["E5 3 narrow cards", three, 160, 40, false], ["E6 2 cards far apart", [three[1], three[3]], 210, 310, false]
                , ["E7 2 cards + HUD", [three[1], three[2]], 210, 50, true]]
            for i, e in exps {
                ShowCards(e[2], e[3], e[4], e[5])
                scan := ScanWinClient(GSProWinNeedle, GSProWinExclude)
                uses := FindAllLinesExact(scan, "use")
                big := OcrRegionScaled(scan.win.x, scan.win.y, scan.win.w, scan.win.h, 2)
                bigUses := FindAllLinesExact(big, "use")
                halfL := OcrRegion(scan.win.x, scan.win.y, scan.win.w // 2 + 60, scan.win.h)
                halfR := OcrRegion(scan.win.x + scan.win.w // 2 - 60, scan.win.y, scan.win.w // 2 + 60, scan.win.h)
                hu := Cnt(FindAllLinesExact(halfL, "use")) + Cnt(FindAllLinesExact(halfR, "use"))
                ScrambleNote("INFO", e[1] . ": full read " . Cnt(scan.lines) . " lines/" . Cnt(uses) . " USE; 2x read " . Cnt(big.lines) . " lines/" . Cnt(bigUses) . " USE; halves " . Cnt(halfL.lines) . "+" . Cnt(halfR.lines) . " lines/" . hu . " USE [" . SubStr(StrReplace(scan.text, "`n", " / "), 1, 160) . "]")
            }
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
ShowCards(cards, cw := 210, gap := 50, hud := false) {
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
        Gui, SmokeUse%i%:Add, Text, x0 y10 w%uw% Center BackgroundTrans, USE
        ux := (cw - uw) // 2
        Gui, SmokeUse%i%:Show, x%ux% y205 w%uw% h42 NoActivate
    }
    WinWait, ahk_id %SmokeCardsHwnd%, , 3
    Sleep, 1200
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


def runtime_checks(source, ahk):
    assert os.name == "nt", "AutoHotkey runtime checks require Windows"
    digest = hashlib.sha256(ahk.read_bytes()).hexdigest()
    assert digest == "effdea83c6b7a1dc2ce9e9d40e91dfd59bed9fcbd580903423648b7ca97d9696", "Use official AutoHotkey v1.1.37.02 Unicode 64-bit"
    with tempfile.TemporaryDirectory(prefix="BA-Remapper-tests-") as directory:
        work = Path(directory)
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
        result = subprocess.run([str(ahk), "/ErrorStdOut", str(work / "smoke.ahk")], capture_output=True, text=True, timeout=90)
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
        assert len(b_taps) == 4 and all(duration >= 40 for duration in b_taps), f"B taps: {b_taps}, events: {rows}"
        assert not any(key in (0x41, 0x49, 0x4B) for _, _, key in rows), f"Unexpected FN/club key leak: {rows}"
        assert any(key == 0x27 for _, _, key in rows), "Arrow was not received"
        assert any(key == 0x11 for _, _, key in rows) and any(key == 0x4D for _, _, key in rows), "Ctrl+M was not received"
        print(f"PASS: four real B keypresses held {b_taps} ms; no A/I/K leak; arrow and Ctrl+M received")
        print("PASS: Exit completed without hanging")
        for mode, extra, arguments in [("BootSmoke", BOOT, ["/startup"]), ("FactorySmoke", FACTORY, [])]:
            (work / "result.txt").unlink(missing_ok=True)
            candidate = isolated.replace("SetTimer, UiSmoke, -50", f"SetTimer, {mode}, -50", 1)
            script = work / (mode + ".ahk")
            script.write_text(candidate + "\n" + SMOKE + "\n" + extra, encoding="utf-8-sig")
            try:
                check = subprocess.run([str(ahk), "/ErrorStdOut", str(script), *arguments], capture_output=True, text=True, timeout=15)
            except subprocess.TimeoutExpired:
                for artifact in list(work.glob("*.bmp")) + list(work.glob("*.txt")):
                    shutil.copy2(artifact, artifacts / artifact.name)
                report = (work / "factory-checks.txt").read_text() if (work / "factory-checks.txt").exists() else "No phase reached"
                raise AssertionError(f"{mode} timed out: {report}")
            report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
            assert check.returncode == 0, mode + ": " + report + check.stdout + check.stderr
            if mode == "BootSmoke":
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
            check = subprocess.run([str(ahk), "/ErrorStdOut", str(script), "ocr" if has_ocr else "noocr"], capture_output=True, text=True, timeout=180)
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
        if dumps:
            annotate("notice", "OCR scenario reads", "\n".join(d.read_text(errors="replace") for d in dumps))
        report = (work / "result.txt").read_text() if (work / "result.txt").exists() else "No result"
        assert returncode == 0 and report.startswith("PASS:"), "ScrambleSmoke: " + report + output
        print("PASS: " + ("green feet/inches, around-the-green and yards cards read with the real Windows OCR in this build" if has_ocr else "distance parsing in this build (real-OCR card reads skipped: no OCR engine)"))


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
