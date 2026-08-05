; ============================================================
;  BA Remapper - NSIS installer script
;  BA Custom Products
;  Same feature set as the Inno .iss: Program Files install,
;  Start Menu, Add/Remove Programs uninstaller, optional
;  desktop icon and start-with-Windows, running-app detection
;  via the app's own mutex, upgrade-in-place, uninstall asks
;  before touching settings.
; ============================================================
!include "MUI2.nsh"

!define APPNAME "BA Remapper"
!define COMPANY "BA Custom Products"
!define VERSION "5.0"
!define VERSION4 "5.0.0.0"
!define EXENAME "BARemapper.exe"
!define MUTEX "BARemapper_BACustomProducts_SingleInstance"
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\BARemapper"

Name "${APPNAME}"
OutFile "BARemapper_Setup_v${VERSION}.exe"
InstallDir "$PROGRAMFILES\BA Custom Products\BA Remapper"
InstallDirRegKey HKLM "${UNINSTKEY}" "InstallLocation"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
Unicode true

VIProductVersion "${VERSION4}"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "CompanyName" "${COMPANY}"
VIAddVersionKey "FileDescription" "${APPNAME} Setup"
VIAddVersionKey "FileVersion" "${VERSION4}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "(c) 2026 ${COMPANY}"

!define MUI_ICON "BARemapper.ico"
!define MUI_UNICON "BARemapper.ico"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${EXENAME}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APPNAME} now"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Function .onInit
retryMutex:
  System::Call 'kernel32::OpenMutex(i 0x100000, i 0, t "${MUTEX}") p .r0'
  IntPtrCmp $0 0 mutexDone
  System::Call 'kernel32::CloseHandle(p r0)'
  MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
    "${APPNAME} is currently running.$\r$\n$\r$\nRight-click the green BA tray icon and choose Exit, then press Retry." \
    IDRETRY retryMutex
  Abort
mutexDone:
FunctionEnd

Function un.onInit
retryMutexU:
  System::Call 'kernel32::OpenMutex(i 0x100000, i 0, t "${MUTEX}") p .r0'
  IntPtrCmp $0 0 mutexDoneU
  System::Call 'kernel32::CloseHandle(p r0)'
  MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
    "${APPNAME} is currently running.$\r$\n$\r$\nRight-click the green BA tray icon and choose Exit, then press Retry." \
    IDRETRY retryMutexU
  Abort
mutexDoneU:
FunctionEnd

Section "${APPNAME} (required)" SecMain
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "${EXENAME}"
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\BA Custom Products"
  CreateShortCut "$SMPROGRAMS\BA Custom Products\BA Remapper.lnk" "$INSTDIR\${EXENAME}"
  CreateShortCut "$SMPROGRAMS\BA Custom Products\Uninstall BA Remapper.lnk" "$INSTDIR\Uninstall.exe"

  WriteRegStr   HKLM "${UNINSTKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr   HKLM "${UNINSTKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr   HKLM "${UNINSTKEY}" "Publisher" "${COMPANY}"
  WriteRegStr   HKLM "${UNINSTKEY}" "DisplayIcon" "$INSTDIR\${EXENAME}"
  WriteRegStr   HKLM "${UNINSTKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr   HKLM "${UNINSTKEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr   HKLM "${UNINSTKEY}" "URLInfoAbout" "https://bacustomproducts.com"
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTKEY}" "NoRepair" 1
  WriteRegDWORD HKLM "${UNINSTKEY}" "EstimatedSize" 1180
SectionEnd

Section "Desktop icon" SecDesktop
  CreateShortCut "$DESKTOP\BA Remapper.lnk" "$INSTDIR\${EXENAME}"
SectionEnd

Section "Start BA Remapper with Windows (recommended)" SecStartup
  ; Identical shortcut name and /startup argument the app's own
  ; "Start with Windows" checkbox manages - the two stay in sync.
  CreateShortCut "$SMSTARTUP\BARemapper.lnk" "$INSTDIR\${EXENAME}" "/startup"
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} "The BA Remapper application."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Create a shortcut on the desktop."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartup} "Launch hidden to the tray at every Windows boot with mapping ON - recommended for sim PCs."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  Delete "$SMSTARTUP\BARemapper.lnk"
  Delete "$DESKTOP\BA Remapper.lnk"
  Delete "$SMPROGRAMS\BA Custom Products\BA Remapper.lnk"
  Delete "$SMPROGRAMS\BA Custom Products\Uninstall BA Remapper.lnk"
  RMDir  "$SMPROGRAMS\BA Custom Products"
  Delete "$INSTDIR\${EXENAME}"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir  "$INSTDIR"
  RMDir  "$PROGRAMFILES\BA Custom Products"
  DeleteRegKey HKLM "${UNINSTKEY}"

  MessageBox MB_YESNO|MB_ICONQUESTION \
    "Also remove your BA Remapper settings and profiles?$\r$\n$\r$\n$DOCUMENTS\BA Custom Products\Remapper$\r$\n$\r$\nChoose No to keep them for a future reinstall." \
    IDNO keepData
  RMDir /r "$DOCUMENTS\BA Custom Products\Remapper"
  RMDir "$DOCUMENTS\BA Custom Products"
keepData:
SectionEnd
