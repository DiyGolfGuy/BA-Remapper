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
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASE = "a5f762113cc2645a385277b4e4941453c8527b63"


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
        "ScrambleCardsStillUp", "ScrambleParseDistance", "FeetInches",
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
    assert 'SendMode, Input' in source  # Primary-key and scramble output mode preserved.
    assert 'if (FnIsDown)\n            return' in function(source, "HandleBoxKeyDown")
    assert 'SetKeyDelay, 15, 60' in function(source, "SendSecondaryKey")
    assert 'SendEvent, %keys%' in function(source, "SendSecondaryKey")
    assert 'gResetSmartSpots, Reset Smart Click Spots' in source
    assert 'gOnCleanup,' not in source
    print(f"PASS: {len(unchanged)} core functions, diagnostics, hotkeys and exit preserved")


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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--ahk", type=Path)
    args = parser.parse_args()
    source = (ROOT / "BARemapper.ahk").read_text(encoding="utf-8-sig")
    baseline = args.baseline.read_text(encoding="utf-8-sig") if args.baseline else subprocess.check_output(["git", "show", BASE + ":BARemapper.ahk"], cwd=ROOT).decode("utf-8-sig")
    static_checks(source, baseline)
    if args.ahk:
        runtime_checks(source, args.ahk.resolve())


if __name__ == "__main__":
    main()
