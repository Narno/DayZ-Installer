# DayZ Mod Setup Header functions
# Created with EclipseNSIS and NSIS
# @version 2012-06-23
# @author Arnaud Ligny <arnaud@ligny.org>

Var /GLOBAL Win32
Var /GLOBAL ModLastVersionNumber
Var /GLOBAL ModCurrentVersionNumber

# Macros
!include DayZMod-Macros.nsh

Function isWin32or64
    IfFileExists $WINDIR\SYSWOW64\*.* Is64bit Is32bit
    Is32bit:
        SetRegView 32
        StrCpy $Win32 "1"
        Goto End32Bitvs64BitCheck
    Is64bit:
        SetRegView 64
        StrCpy $Win32 "0"
    End32Bitvs64BitCheck:
FunctionEnd

Function .onVerifyInstDir
    IfFileExists "$INSTDIR\${ARMA2OA_EXE}" +2
        Abort
FunctionEnd

Function preDetect
    Call detectArma2
    Call detectArma2OA
    Call detectDayZMod
FunctionEnd

Function detectArma2
    StrCmp $Arma2Path "" 0 detected
        MessageBox MB_YESNO|MB_ICONQUESTION "ARMA II not found.$\n$\nDo you want to continue?" IDYES continue IDNO quit
        quit:
            Quit
        continue:
        detected:
FunctionEnd

Function detectArma2OA
    StrCmp $Arma2OAPath "" 0 detected
        MessageBox MB_YESNO|MB_ICONQUESTION "ARMA II Operation Arrowhead not found.$\n$\nDo you want to continue?" IDYES continue IDNO quit
        quit:
            Quit
        continue:
        detected:
FunctionEnd

Function detectDayZMod
    IfFileExists "$INSTDIR\@DayZ\Downloads\${CHECKSUMS_FILENAME}" isInstalled isNotInstalled
    isInstalled:
        Call checkForUpdates
        Return
    isNotInstalled:
        ;MessageBox MB_OK|MB_ICONINFORMATION "DayZ Mod not yet installed."
FunctionEnd

Function checkForUpdates
    Banner::show /set 76 "Check for updates" "Please wait..."
    # Get last version number (from default CDN)
    inetc::get /SILENT /CAPTION "Downloading..." /BANNER "Check for update" \
               "$CdnUrl/${CHECKSUMS_FILENAME}" "$TEMP\${CHECKSUMS_FILENAME}" \
               /END
    Pop $R0
    StrCmp $R0 "OK" OK
        Banner::destroy
        BringToFront
        MessageBox MB_OK|MB_ICONEXCLAMATION "Can't check for updates: Server unavailable"
        Abort
    OK:
    ${getItemVersionNumber} "$TEMP\${CHECKSUMS_FILENAME}" "dayz_code"
    StrCpy $ModLastVersionNumber $R0
    StrCpy $R0 ""
    # Get current (installed) version number
    ${getItemVersionNumber} "$INSTDIR\@DayZ\Downloads\${CHECKSUMS_FILENAME}" "dayz_code"
    StrCpy $ModCurrentVersionNumber $R0
    Banner::destroy
    BringToFront
    # Compare
    ;MessageBox MB_OK "DEBUG: compare '$ModLastVersionNumber' and '$ModCurrentVersionNumber'"
    ${VersionCompare} $ModLastVersionNumber $ModCurrentVersionNumber $R0
    StrCmp $R0 "0" 0 +3 ; =
        MessageBox MB_YESNO|MB_ICONQUESTION "Last version ($ModLastVersionNumber) of DayZ Mod is already installed.$\n$\nContinue?" IDYES yes IDNO no
        yes:
            Return
        no:
            Quit
    StrCmp $R0 "1" 0 +3 ; <
        MessageBox MB_OK "New version of DayZ Mod ($ModLastVersionNumber) available."
        Return
FunctionEnd

Function CreateDesktopShortcut
    ;CreateShortCut "$DESKTOP\$(^Name).lnk" "$Arma2OAPath\${ARMA2OA_EXE}" "-mod=@DayZ -nosplah" "$INSTDIR\@DayZ\DayZ.ico"
    CreateShortCut "$DESKTOP\$(^Name) - Steam.lnk" "$SteamPath\${STEAM_EXE}" "-applaunch 33930 -mod=$Arma2OAPath;EXPANSION;ca;@dayz -world=Chernarus -nosplah" "$INSTDIR\@DayZ\DayZ.ico"
FunctionEnd

;Function LaunchDayZModSteam
;    ExecShell "" "$SteamPath\${STEAM_EXE}" "-applaunch 33930 -mod=$Arma2OAPath;EXPANSION;ca;@dayz -world=Chernarus -nosplah"
;FunctionEnd