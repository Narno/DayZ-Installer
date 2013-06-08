# DayZ Mod Setup Header functions
# Created with EclipseNSIS and NSIS
# @version 2012-07-01
# @author Arnaud Ligny <arnaud@ligny.org>

Var /GLOBAL Win32
Var /GLOBAL ModLastVersionNumber
Var /GLOBAL ModCurrentVersionNumber

# Macros
!include DayZMod-Macros.nsh

# Run on Windows 32 or 64 bits?
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

# Verify ARMA II OA install dir
Function .onVerifyInstDir
    IfFileExists "$INSTDIR\${ARMA2OA_EXE}" +2
        Abort
FunctionEnd

Function DirectoryLeave
    Call detectArma2OABeta
FunctionEnd

# Detects if ARMA II is installed
Function detectArma2
    StrCmp $Arma2Path "" 0 detected
        MessageBox MB_YESNO|MB_ICONQUESTION "ARMA II not found.$\n$\nDo you want to continue?" IDYES continue IDNO quit
        quit:
            Quit
        continue:
        detected:
        Call detectArma2OA
FunctionEnd

# Detects if ARMA II Operation Arrowhead is installed
Function detectArma2OA
    StrCmp $Arma2OAPath "" 0 detected
        MessageBox MB_YESNO|MB_ICONQUESTION "ARMA II Operation Arrowhead not found.$\n$\nDo you want to continue?" IDYES continue IDNO quit
        quit:
            Quit
        continue:
        detected:
FunctionEnd

# Detects if ARMA II OA beta is installed
Function detectArma2OABeta
    IfFileExists "$INSTDIR\${ARMA2OA_BETA_PATH}\${ARMA2OA_BETA_EXE}" isBeta isNotBeta
    isBeta:
        ; beta installed: nothing to say
        StrCpy $Arma2OAisBeta "1"
        Return
    isNotBeta:
        MessageBox MB_OK|MB_ICONINFORMATION "$(^Name) requires ARMA 2 beta patch"
        ExecShell "open" "http://www.arma2.com/beta-patch.php"
        MessageBox MB_ABORTRETRYIGNORE|MB_ICONINFORMATION|MB_DEFBUTTON2 "- Click 'Retry' to check beta patch installation$\n$\n- Click 'Abort' to exit installer$\n$\n- Click 'Ignore' to ignore beta patch installation" IDABORT abort IDRETRY retry
        Goto ignore
        abort:
            Quit
        retry:
            Call detectArma2OABeta
        ignore:
FunctionEnd

# Detects if the DayZ Mod is installed
Function detectDayZMod
    IfFileExists "$INSTDIR\@DayZ\Downloads\${CHECKSUMS_FILENAME}" isInstalled isNotInstalled
    isInstalled:
        Call checkForUpdates
        Return
    isNotInstalled:
        ;MessageBox MB_OK|MB_ICONINFORMATION "DayZ Mod not yet installed."
FunctionEnd

# Check for updates
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
    StrCmp $R0 "0" 0 NewVersion ; =
        MessageBox MB_YESNO|MB_ICONQUESTION "Last version ($ModLastVersionNumber) of DayZ Mod is already installed.$\n$\nContinue?" IDYES yes IDNO no
        yes:
            Return
        no:
            Quit
    NewVersion:
    StrCmp $R0 "1" 0 +3 ; <
        MessageBox MB_OK "New version of DayZ Mod ($ModLastVersionNumber) available."
        Return
FunctionEnd

# Create a desktop shortcut
Function CreateDesktopShortcut
    # Classic shortcut
    ;CreateShortCut "$DESKTOP\$(^Name).lnk" "$INSTDIR\${ARMA2OA_EXE}" "-mod=@DayZ -nosplah -skipintro" "$INSTDIR\@DayZ\DayZ.ico"
    StrCmp $SteamPath "" 0 createSteamShortcut
        # Beta shortcut
        CreateShortCut "$DESKTOP\$(^Name).lnk" "$INSTDIR\${ARMA2OA_BETA_PATH}\${ARMA2OA_EXE}" '"-mod=$Arma2Path;Expansion;ca;Expansion\beta;Expansion\beta\Expansion;@dayz" -nosplash -skipintro -world=Chernarus' "$INSTDIR\@DayZ\DayZ.ico"
    createSteamShortcut:
        # Beta shortcut (with Steam, need to copy exe from beta directory to the root)
        CreateShortCut "$DESKTOP\$(^Name).lnk" "$SteamPath\${STEAM_EXE}" '-applaunch 33930 "-mod=$Arma2Path;Expansion;ca;Expansion\beta;Expansion\beta\Expansion;@dayz" -nosplash -skipintro -world=Chernarus' "$INSTDIR\@DayZ\DayZ.ico"
FunctionEnd

# DayZ launcher
;Function LaunchDayZModSteam
;    ExecShell "" "$SteamPath\${STEAM_EXE}" "-applaunch 33930 -mod=$Arma2OAPath;EXPANSION;ca;@dayz -world=Chernarus -nosplah"
;FunctionEnd