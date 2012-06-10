# DayZ Mod Setup Header functions
# Created with EclipseNSIS and NSIS
# @version 2012-06-10
# @author Arnaud Ligny <arnaud@ligny.org>

!define getItemVersionNumber "!insertmacro getItemVersionNumber"
!macro getItemVersionNumber File Item
    Push "${File}" ; md5checksums.txt
    Push "${Item}" ; dayz_code
    Call getItemVersionNumber
!macroend
Function getItemVersionNumber
    ClearErrors
    Exch $0
    Exch
    Exch $1
    Push $2
    ;
    ;MessageBox MB_OK "DEBUG: $0 / $1"
    ${LineSum} $1 $7
    ${ForEach} $9 1 $7 + 1
        ${LineRead} "$TEMP\${CHECKSUMS_FILENAME}" $9 $R1
        ${TrimNewLines} $R1 $R1
        ${WordFind2x} $R1 "$0_v" ".rar" "E+1" $R0
        IfErrors notFound found
        found:
            ;MessageBox MB_OK "DEBUG: $1 / $R0"
            Return
        notfound:
    ${Next}
    ;
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function detectArma2CO
    ReadRegStr $GamePath HKLM "$RegPath" "${REGKEYMAIN}"
    StrCmp $GamePath "" 0 +3
        MessageBox MB_OK|MB_ICONSTOP "Can't install DayZ Mod: Arma2 AO not found on your system!"
        Quit
FunctionEnd

Var /GLOBAL ModLastVersionNumber
Var /GLOBAL ModCurrentVersionNumber
Function detectDayZMod
    # Last version
    inetc::get /CAPTION "Downloading..." /BANNER "Check for update" \
               "${CDN_URL}/${CHECKSUMS_FILENAME}" "$TEMP\${CHECKSUMS_FILENAME}"
    ${getItemVersionNumber} "$TEMP\${CHECKSUMS_FILENAME}" "dayz_code"
    StrCpy $ModLastVersionNumber $R0
    StrCpy $R0 ""
    # Current version
    ${getItemVersionNumber} "$INSTDIR\@DayZ\Downloads\${CHECKSUMS_FILENAME}" "dayz_code"
    StrCpy $ModCurrentVersionNumber $R0
    # Compare
    StrCmp $R0 "" NotInstalled 0
    ;MessageBox MB_OK "DEBUG: compare '$ModLastVersionNumber' and '$ModCurrentVersionNumber'"
    ${VersionCompare} $ModLastVersionNumber $ModCurrentVersionNumber $R0
    StrCmp $R0 "0" 0 +3 ; =
        MessageBox MB_OK "Last version ($ModLastVersionNumber) of DayZ Mod already installed."
        Return
    StrCmp $R0 "1" 0 +3 ; <
        MessageBox MB_OK "New version of DayZ Mod ($ModLastVersionNumber) available."
        Return
    NotInstalled:
        ;MessageBox MB_OK "DayZ Mod not yet installed."
FunctionEnd
