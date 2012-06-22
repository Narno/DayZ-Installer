# DayZ Mod Setup
# Created with EclipseNSIS and NSIS
# @version 2012-06-22
# @author Arnaud Ligny <arnaud@ligny.org>

Name "DayZ Mod"

SetCompressor /SOLID lzma

# General Symbol Definitions
!define OUTFILE "DayZ-Mod-Installer.exe"
!define VERSION 0.0.1.2
!define COMPANY "DayZ Team"
!define URL http://www.dayzmod.com

# DayZ Symbol Definitions
!define CHECKSUMS_FILENAME "md5checksums.txt"
!define ARCHIVE_EXT        ".rar"
!define TEXT_EXT           ".txt"
!define REGPATH32  "SOFTWARE\Bohemia Interactive Studio\ArmA 2 OA"
!define REGPATH64  "SOFTWARE\Wow6432Node\Bohemia Interactive Studio\ArmA 2 OA"
!define REGKEYMAIN "main"

# MUI Symbol Definitions
!define MUI_ICON "Graphics\Icons\Default.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "Graphics\Bitmaps\Header_Right.bmp"
!define MUI_FINISHPAGE_NOAUTOCLOSE

# Included files
!include Sections.nsh
!include MUI.nsh
!include LogicLib.nsh
!include TextFunc.nsh
!include WordFunc.nsh

# Reserved Files
ReserveFile "DayZMod.ini"
ReserveFile "DayZMod-PageSelectMirror.ini"
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

# Installer pages
!define MUI_PAGE_CUSTOMFUNCTION_PRE preDetect
!insertmacro MUI_PAGE_DIRECTORY
Page custom PageChooseMirror PageLeaveChooseMirror
!insertmacro MUI_PAGE_INSTFILES

# Installer languages
!insertmacro MUI_LANGUAGE English

# Installer attributes
Outfile "${OUTFILE}"
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
Var /GLOBAL CdnUrl
Var /GLOBAL CdnSelected

# Functions
!include DayZMod.nsh

# On Init
Function .onInit   
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
        # Set Install Dir
        StrCpy $INSTDIR "$GamePath"
    # Plugins
    InitPluginsDir
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "DayZMod.ini"
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "DayZMod-PageSelectMirror.ini"
    # Default CDN
    ReadINIStr $0 "$PLUGINSDIR\DayZMod.ini" "Mirrors" "Default"
    StrCpy $CdnUrl $0
FunctionEnd

# Installer sections
Section -Main SEC0000
    SetOverwrite on
    SetDetailsView show
    SetDetailsPrint both
    SetOutPath "$INSTDIR\@DayZ"
    
    # Installer files
    ;DetailPrint "Extract: 7zip"
    SetDetailsPrint none
    SetOutPath "$INSTDIR\@DayZ\Installer"
    ;File /nonfatal ${OUTFILE}
    # 7zip required (7z.dll and 7z.exe to unrar files)
    File /r "7zip"
    SetDetailsPrint lastused
    
    # Getting "md5checksums.txt" file
    SetDetailsPrint none
    SetOutPath "$INSTDIR\@DayZ\Downloads"
    SetDetailsPrint lastused
    DetailPrint "Get files list from: $CdnSelected"
    ;MessageBox MB_OK "DEBUG: '$CdnSelected/${CHECKSUMS_FILENAME}'"    
    inetc::get /SILENT /CAPTION "Downloading..." /BANNER "Get files list from $CdnSelected" \
               "$CdnSelected/${CHECKSUMS_FILENAME}" ${CHECKSUMS_FILENAME} \
               /END
    Pop $R0
    StrCmp $R0 "OK" +3
        DetailPrint "Server unavailable: $R0"
        Abort
    ${LineSum} ${CHECKSUMS_FILENAME} $7
    ;DetailPrint "Files found: $7"
    # Download and install each PBO file
    Var /GLOBAL i
    ${ForEach} $i 1 $7 + 1
        ${LineRead} "$INSTDIR\@DayZ\Downloads\${CHECKSUMS_FILENAME}" $i $1
        ${TrimNewLines} $1 $1 ;"57904b8a2f96c2cc7b6cb7b0ceb87e51  dayz_code_v1.7.0.rar"
        ;DetailPrint "Line: $1"
        ${WordFind} $1 "  " "-2" $R1 ; find hash
        ;DetailPrint "hash: $R0"
        ${WordFind} $1 "  " "+2" $R2 ; find file
        ;DetailPrint "file: $R1"
        # find each RAR file and download it
        ${WordFind} $R2 ${ARCHIVE_EXT} "E+1{" $R0
        IfErrors rarNotFound rarFound
        rarFound:
            # find each torrent file and escape it
            ${WordFind} $R2 ".torrent" "E+1{" $R0
            IfErrors torrentNotFound torrentFound
            torrentFound:
                Goto rarNotFound
            torrentNotFound:
                ;
            # Downloading file
            DetailPrint "Download: $R2"
            inetc::get /CAPTION $R2 /POPUP "" \
                       "$CdnSelected/$R2" $R2 \
                       /END
            Pop $R0
            StrCmp $R0 "OK" +3
                DetailPrint "Download failed: $R0"
                Abort
            # compare hash
            md5dll::GetMD5File $R2
            Pop $0
            StrCmp $0 $R1 +5
                DetailPrint "MD5sum doesn't match for $R2:"
                DetailPrint "- Expected: $R1"
                DetailPrint "- Downloaded: $0"
                Abort
            # Uncompressing
            ;DetailPrint "Uncompress: $R2"
            nsExec::ExecToStack '"$INSTDIR\@DayZ\Installer\7zip\7z.exe" e $R2 -aoa -o"$INSTDIR\@DayZ\Addons"'
            Pop $0 # return value/error/timeout
            Pop $1
            StrCmp $0 "0" +3
                DetailPrint "Uncompress failed: $1"
                Abort
            Goto rarEnd
        rarNotFound:
            # find each TXT file and download it
            ${WordFind} $R2 ${TEXT_EXT} "E+1{" $R0
            IfErrors txtNotFound txtFound
            txtFound:
                # Downloading file
                DetailPrint "Download: $R2"
                inetc::get /CAPTION "$R2" /POPUP "" \
                           "$CdnSelected/$R2" $R2 \
                           /END
                Pop $R0
                StrCmp $R0 "OK" +3
                    DetailPrint "Download failed: $R0"
                    Abort
                SetDetailsPrint none
                CopyFiles $R2 "$INSTDIR\@DayZ\$R2"
                SetDetailsPrint lastused
                Goto txtEnd
            txtNotFound:
                ;
            txtEnd:
        rarEnd:
    ${Next}
    
    # Create desktop shortcut
    SetDetailsPrint none
    SetOutPath "$INSTDIR\@DayZ"
    File /oname=DayZ.ico "Graphics\Icons\Default.ico"
    SetDetailsPrint lastused
    CreateShortCut "$DESKTOP\$(^Name).lnk" "$GamePath\ArmA2OA.exe" "-mod=@DayZ -nosplah" "$INSTDIR\@DayZ\DayZ.ico"
SectionEnd

Function PageChooseMirror
    !insertmacro MUI_HEADER_TEXT "Choose Source Location" "Choose the mirror server closest to you"
    ReadINIStr $0 "$PLUGINSDIR\DayZMod.ini" "Mirrors" "Default"
    ReadINIStr $1 "$PLUGINSDIR\DayZMod.ini" "Mirrors" "List"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "DayZMod-PageSelectMirror.ini" "Field 1" "State" "$0"
    !insertmacro MUI_INSTALLOPTIONS_WRITE "DayZMod-PageSelectMirror.ini" "Field 1" "ListItems" "$1"
    !insertmacro MUI_INSTALLOPTIONS_DISPLAY "DayZMod-PageSelectMirror.ini"
FunctionEnd

Function PageLeaveChooseMirror
    !insertmacro MUI_INSTALLOPTIONS_READ $0 "DayZMod-PageSelectMirror.ini" "Field 1" "State"
    ;MessageBox MB_OK "DEBUG: $0"
    StrCpy $CdnSelected $0
FunctionEnd