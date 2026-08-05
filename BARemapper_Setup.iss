; ============================================================
;  BA Remapper - Inno Setup installer script
;  BA Custom Products
;
;  Compile with Inno Setup 6 (free): https://jrsoftware.org
;  Put this .iss, BARemapper.exe, and BARemapper.ico in one
;  folder, open the .iss in Inno Setup, press Compile.
;  Output: Output\BARemapper_Setup_v5.0.exe
;
;  The AppId GUID below identifies BA Remapper to Windows
;  permanently. NEVER change it - every future installer with
;  the same GUID upgrades the existing install in place.
; ============================================================

#define MyAppName "BA Remapper"
#define MyAppVersion "5.0"
#define MyAppPublisher "BA Custom Products"
#define MyAppURL "https://bacustomproducts.com"
#define MyAppExeName "BARemapper.exe"

[Setup]
AppId={{E1DCB3CE-3D6F-4C93-A9EC-7229383955F0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\BA Custom Products\BA Remapper
DisableProgramGroupPage=yes
DefaultGroupName=BA Custom Products
OutputBaseFilename=BARemapper_Setup_v{#MyAppVersion}
SetupIconFile=BARemapper.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0
PrivilegesRequired=admin
; Our app's own single-instance mutex: Inno detects a running
; copy during install/upgrade/uninstall and asks to close it.
AppMutex=BARemapper_BACustomProducts_SingleInstance
; Branding on the Setup exe itself (Properties > Details)
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoVersion=5.0.0.0
VersionInfoProductName={#MyAppName}

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"
Name: "startupicon"; Description: "&Start BA Remapper with Windows (recommended for sim PCs)"

[Files]
Source: "BARemapper.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\BA Remapper"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall BA Remapper"; Filename: "{uninstallexe}"
Name: "{autodesktop}\BA Remapper"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
; Same shortcut name and /startup argument the app itself
; manages - the app's "Start with Windows" checkbox and this
; task create the identical shortcut, so they stay in sync.
Name: "{userstartup}\BARemapper"; Filename: "{app}\{#MyAppExeName}"; Parameters: "/startup"; Tasks: startupicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch BA Remapper now"; Flags: postinstall nowait skipifsilent runascurrentuser

[UninstallDelete]
; Remove the startup shortcut even if the app (not the task)
; created it via its own checkbox.
Type: files; Name: "{userstartup}\BARemapper.lnk"

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  DataDir: string;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    DataDir := ExpandConstant('{userdocs}\BA Custom Products\Remapper');
    if DirExists(DataDir) then
    begin
      if MsgBox('Also remove your BA Remapper settings and profiles?' + #13#10#13#10
                + DataDir + #13#10#13#10
                + 'Choose No to keep them for a future reinstall.',
                mbConfirmation, MB_YESNO) = IDYES then
        DelTree(DataDir, True, True, True);
    end;
  end;
end;
