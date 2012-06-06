# DayZ Mod Setup
# Created with EclipseNSIS and NSIS
# @version 2012-06-03
# @author Arnaud Ligny <arnaud@ligny.org>

Name "DayZ Mod"

SetCompressor /SOLID lzma

# General Symbol Definitions
!define VERSION 0.0.0.2
!define COMPANY "DayZ Team"
!define URL http://www.dayzmod.com

# DayZ Symbol Definitions
!define INSTALLER_URL        "http://cdn.armafiles.info/installer"
!define INSTALLER_FILES_NAME "installer_files.cfg"
!define INSTALLER_FILES_URL  "${INSTALLER_URL}/${INSTALLER_FILES_NAME}"
!define REGPATH32  "SOFTWARE\Bohemia Interactive Studio\ArmA 2 OA"
!define REGPATH64  "SOFTWARE\Wow6432Node\Bohemia Interactive Studio\ArmA 2 OA"
!define REGKEYMAIN "main"

# MUI Symbol Definitions
!define MUI_ICON "Graphics\Icons\DayZ.ico"
!define MUI_FINISHPAGE_NOAUTOCLOSE

# Included files
!include TextFunc.nsh
!include LogicLib.nsh
!include Sections.nsh
!include MUI.nsh
!include WordFunc.nsh

# Installer pages
!define MUI_PAGE_CUSTOMFUNCTION_PRE preDetect
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

# Installer languages
!insertmacro MUI_LANGUAGE English

# Installer attributes
Outfile "DayZ-Mod-Installer.exe"
BrandingText "Setup created by Narno with NSIS ${NSIS_VERSION}"
SpaceTexts none
CRCCheck on
XPStyle on
ShowInstDetails show
VIProductVersion "${VERSION}"
VIAddVersionKey FileDescription "DayZ Mod"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey ProductName "DayZ Mod"
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey CompanyName "${COMPANY}"
VIAddVersionKey CompanyWebsite "${URL}"
VIAddVersionKey LegalCopyright "${COMPANY}"

Var /GLOBAL RegPath
Var /GLOBAL GamePath

# Installer sections
Section -Main SEC0000
    SetOverwrite on
    SetDetailsView show
    SetDetailsPrint both
    
    # Create temporary directory for downloads
    SetDetailsPrint none
    CreateDirectory "$TEMP\DayZ"
    SetDetailsPrint both
    
    # Download 'dayz_readme.txt', 'dayz_changelog.txt', 'installer_cnc.cfg', 
    # 'installer_files.cfg' and get list of PBO files
    SetOutPath "$INSTDIR"
    NSISdl::download /TIMEOUT=30000 "${INSTALLER_URL}/dayz_readme.txt" "dayz_readme.txt"
    NSISdl::download /TIMEOUT=30000 "${INSTALLER_URL}/dayz_changelog.txt" "dayz_changelog.txt"
    NSISdl::download /TIMEOUT=30000 "${INSTALLER_URL}/installer_cnc.cfg" "installer_cnc.cfg"
    NSISdl::download /TIMEOUT=30000 "${INSTALLER_FILES_URL}" "${INSTALLER_FILES_NAME}"
    Pop $R0
    StrCmp $R0 "success" +3
        MessageBox MB_OK "Download failed (${INSTALLER_FILES_NAME}): $R0"
        Quit
    
    # Download and install each PBO file
    SetDetailsPrint none
    SetOutPath "$INSTDIR\Addons"
    SetDetailsPrint both
    Var /GLOBAL i
    ${LineSum} "$INSTDIR\${INSTALLER_FILES_NAME}" $0
    ${ForEach} $i 1 $0 + 1
    ;${ForEach} $i 1 1 + 1 ; download only 1 file for DEBUG
        ${LineRead} "$INSTDIR\${INSTALLER_FILES_NAME}" $i $1
        ${TrimNewLines} $1 $1
        DetailPrint "Downloading $1"
        NSISdl::download /TIMEOUT=30000 "${INSTALLER_URL}/$1" "$TEMP\DayZ\$1"
        Pop $R0
        StrCmp $R0 "success" +3
            DetailPrint "Download failed: $R0"
            Quit
        DetailPrint "Installing $1"
        Nsis7z::ExtractWithDetails "$TEMP\DayZ\$1" "Installing %s"
    ${Next}
    
    # Create desktop shortcut
    SetDetailsPrint none
    SetOutPath "$INSTDIR"
    File "Graphics\Icons\DayZ.ico"
    SetDetailsPrint both
    CreateShortCut "$DESKTOP\$(^Name).lnk" "$GamePath\ArmA2OA.exe" "-mod=@DayZ -nosplah" "$INSTDIR\DayZ.ico"
    
    # Cleaning temp
    SetDetailsPrint none
    RmDir /r "$TEMP\DayZ"
SectionEnd

# Installer functions
Function .onInit
    InitPluginsDir
    # Windows 32 or 64?
    IfFileExists $WINDIR\SYSWOW64\*.* Is64bit Is32bit
    Is32bit:
        SetRegView 32
        StrCpy $RegPath "${REGPATH32}"
        GOTO End32Bitvs64BitCheck
    Is64bit:
        SetRegView 64
        StrCpy $RegPath "${REGPATH64}"
    End32Bitvs64BitCheck:
        ReadRegStr $GamePath HKLM "$RegPath" "${REGKEYMAIN}"
        StrCpy $INSTDIR "$GamePath\@DayZ"
FunctionEnd

Function preDetect
    Call detectArma2
    Call detectMod
FunctionEnd

Function detectArma2
    ReadRegStr $GamePath HKLM "$RegPath" "${REGKEYMAIN}"
    StrCmp $GamePath "" 0 +3
        MessageBox MB_OK|MB_ICONSTOP "Can't install DayZ Mod: Arma2 AO not found on your system!"
        Quit
FunctionEnd

Function detectMod
    Call getLastVerionNumber
    Call getCurrentVerionNumber
    ${VersionCompare} $1 $2 $R0
    StrCmp $R0 "0" 0 +3 ; =
        MessageBox MB_OK "Last version ($1) of DayZ Mod already installed."
        Return
    StrCmp $R0 "1" 0 +3 ; <
        MessageBox MB_OK "New version of DayZ Mod ($1) available."
        Return
FunctionEnd

Function getLastVerionNumber
    NSISdl::download /TIMEOUT=30000 "${INSTALLER_URL}/installer_cnc.cfg" "$TEMP\installer_cnc.cfg"
    ${ConfigRead} "$TEMP\installer_cnc.cfg" "VERSION=" $R0
    ;MessageBox MB_OK "Last version: $R0"
    StrCpy $1 $R0
FunctionEnd

Function getCurrentVerionNumber
    ${ConfigRead} "$INSTDIR\installer_cnc.cfg" "VERSION=" $R0
    ;MessageBox MB_OK "Current version: $R0"
    StrCpy $2 $R0
FunctionEnd