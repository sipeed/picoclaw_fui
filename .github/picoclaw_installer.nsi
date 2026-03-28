!include MUI2.nsh

!ifndef RELEASE_BASE
  !define RELEASE_BASE "unknown"
!endif

!define APP_NAME "PicoClaw FUI"
!define INSTALL_DIR_D "D:\\Program Files\\picoclaw_fui"
!define INSTALL_DIR_C "C:\\Program Files\\picoclaw_fui"
!define INSTALL_DIR_PF "$PROGRAMFILES\\picoclaw_fui"
!define REGKEY_UNINSTALL "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\picoclaw_fui"

Name "${APP_NAME}"
OutFile "picoclaw_fui-${RELEASE_BASE}-windows-x64-installer.exe"
InstallDir "${INSTALL_DIR_D}"
InstallDirRegKey HKLM "${REGKEY_UNINSTALL}" "InstallLocation"
RequestExecutionLevel admin

Function .onInit
  ; default to D:\\Program Files\\picoclaw_fui if exists or can be created
  StrCpy $INSTDIR "${INSTALL_DIR_D}"
  ; try check path exists or is creatable
  IfFileExists "${INSTALL_DIR_D}\\*" 0 +3
    Goto done
  ; path absent, check C:
  StrCpy $INSTDIR "${INSTALL_DIR_C}"
  IfFileExists "${INSTALL_DIR_C}\\*" 0 +3
    Goto done
  ; fallback to Program Files
  StrCpy $INSTDIR "${INSTALL_DIR_PF}"

  done:
FunctionEnd

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "build\\windows\\x64\\runner\\Release\\*"

  CreateDirectory "$SMPROGRAMS\\PicoClaw FUI"
  CreateShortcut "$SMPROGRAMS\\PicoClaw FUI\\PicoClaw FUI.lnk" "$INSTDIR\\picoclaw-launcher.exe"

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
