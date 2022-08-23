#NoTrayIcon
#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=GH Icon.ico
#AutoIt3Wrapper_Outfile=GH Injector.exe
#AutoIt3Wrapper_UseUpx=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "MsgBoxConstants.au3"

If (@OSArch = "X86") Then
	If NOT (FileExists("GH Injector - x86.exe")) Then
		ShellExecute($MB_ICONERROR, "Error", "GH Injector - x86.exe is missing.")
	Else
		Run("GH Injector - x86.exe")
	EndIf
ElseIf (@OSArch = "X64") Then
	If NOT (FileExists("GH Injector - x64.exe")) Then
		MsgBox($MB_ICONERROR, "Error", "GH Injector - x64.exe is missing.")
	Else
		ShellExecute("GH Injector - x64.exe")
	EndIf
Else
	MsgBox($MB_ICONERROR, "Error", "This operating system architecture is not supported.")
EndIf

If (FileExists("OLD.exe")) Then
	ProcessClose("OLD.exe")
	FileDelete("OLD.exe")
EndIf