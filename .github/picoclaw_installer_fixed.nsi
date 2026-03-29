!include MUI2.nsh

!ifndef RELEASE_BASE
  !define RELEASE_BASE "unknown"
!endif

!ifndef CONTENTS_DIR
  !define CONTENTS_DIR "installer_stage"
!endif

!define APP_NAME "PicoClaw FUI"
!define INSTALL_DIR_D "D:\\Program Files\\picoclaw_fui"
!define INSTALL_DIR_C "C:\\Program Files\\picoclaw_fui"
!define INSTALL_DIR_PF "$PROGRAMFILES\\picoclaw_fui"
!define REGKEY_UNINSTALL "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\picoclaw_fui"

!ifndef LAUNCHER
  !define LAUNCHER "picoclaw_flutter_ui.exe"
!endif

Name "${APP_NAME}"
OutFile "picoclaw_fui-${RELEASE_BASE}-windows-x64-installer.exe"
InstallDir "${INSTALL_DIR_D}"
InstallDirRegKey HKLM "${REGKEY_UNINSTALL}" "InstallLocation"
RequestExecutionLevel admin

Function .onInit
  StrCpy $INSTDIR "${INSTALL_DIR_D}"
  IfFileExists "${INSTALL_DIR_D}\\*" 0 +3
    Goto done
  StrCpy $INSTDIR "${INSTALL_DIR_C}"
  IfFileExists "${INSTALL_DIR_C}\\*" 0 +3
    Goto done
  StrCpy $INSTDIR "${INSTALL_DIR_PF}"
  done:
FunctionEnd

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  ; include compiled build outputs from CONTENTS_DIR (compile-time define)
  File /r "${CONTENTS_DIR}\\*"

  CreateDirectory "$SMPROGRAMS\\PicoClaw FUI"

  ; choose icon at runtime: assets\\icon.ico -> assets\\app_icon.png -> fallback to exe
  StrCpy $IconPath "$INSTDIR\\assets\\icon.ico"
  IfFileExists "$IconPath" 0 +3
    Goto haveIcon
  StrCpy $IconPath "$INSTDIR\\assets\\app_icon.png"
  IfFileExists "$IconPath" 0 +3
    Goto haveIcon
  StrCpy $IconPath "$INSTDIR\\${LAUNCHER}"
  haveIcon:

  CreateShortcut "$SMPROGRAMS\\PicoClaw FUI\\PicoClaw FUI.lnk" "$INSTDIR\\${LAUNCHER}" "" "$IconPath" 0

  WriteUninstaller "$INSTDIR\\uninstall.exe"

  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "UninstallString" "$INSTDIR\\uninstall.exe"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "DisplayVersion" "${RELEASE_BASE}"
  WriteRegStr HKLM "${REGKEY_UNINSTALL}" "Publisher" "PicoClaw"
SectionEnd

Section "Uninstall"
  Delete "$SMPROGRAMS\\PicoClaw FUI\\PicoClaw FUI.lnk"
  RMDir "$SMPROGRAMS\\PicoClaw FUI"
  Delete "$INSTDIR\\uninstall.exe"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKLM "${REGKEY_UNINSTALL}"
SectionEnd
