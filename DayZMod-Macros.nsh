# DayZ Mod Setup Macros
# Created with EclipseNSIS and NSIS
# @version 2012-06-22
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
        ${LineRead} $1 $9 $R1
        ${TrimNewLines} $R1 $R1
        ${WordFind2x} $R1 "$0_v" ".rar" "E+1" $R0
        IfErrors notFound found
        found:
            ;MessageBox MB_OK "DEBUG: $1 / $R0"
            Return
        notfound:
            ;StrCpy $R0 ""
    ${Next}
    ;
    Pop $2
    Pop $1
    Pop $0
FunctionEnd