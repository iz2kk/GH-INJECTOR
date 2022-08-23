#NoTrayIcon
#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=GH Icon.ico
#AutoIt3Wrapper_Outfile=GH Injector - x86.exe
#AutoIt3Wrapper_Outfile_x64=GH Injector - x64.exe
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compile_Both=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Region ;FUNCTION LIST IN FILE ORDER:

;===================================================================================================
; Function........:  Main()
;
; Description.....:  Main function of the injector GUI.
;===================================================================================================

#EndRegion

#include "Update.au3"
#include "Injection.au3"

Func Main()

	$g_InjectionDll_Name = "GH Injector - "
	$OsArch = @OSArch

	If ($OsArch = "X64" AND NOT @AutoItX64) Then
		$g_RunNative = False
		$g_InjectionDll_Name = $g_InjectionDll_Name & "x86.dll"

		$mb_ret = MsgBox(BitOR($MB_ICONWARNING, $MB_YESNO), "Warning", "Since you're using a 64-bit version of Windows it's recommended to use the 64-bit version of the injector." & @CRLF & _
			"Do you want to switch to the 64-bit version?")
		If ($mb_ret = $IDYES) Then
			If (NOT FileExists("GH Injector - x64.exe")) Then
				MsgBox($MB_ICONERROR, "Error", '"GH Injector - x64.exe" is missing.')
				Exit
			EndIf
			ShellExecute("GH Injector - x64.exe")
			Exit
		EndIf
	Else
		$g_InjectionDll_Name = "GH Injector - " & StringLower($OsArch) & ".dll"
	EndIf

	If (NOT FileExists($g_InjectionDll_Name)) Then
		MsgBox($MB_ICONERROR, "Error", $g_InjectionDll_Name & " is missing.")
		Exit
	EndIf

	$g_hInjectionDll = DllOpen($g_InjectionDll_Name)
	If ($g_hInjectionDll = -1) Then
		MsgBox($MB_ICONERROR, "Error", "Can't load " & $g_InjectionDll_Name & "." & @CRLF & "Errorcode: " & @error)
		Exit
	EndIf

	SetPrivilege($SE_DEBUG_NAME, True)

	LoadSettings()

	If (NOT $g_IgnoreUpdates) Then
		Update(0)
	EndIf

	$hGUI = CreateGUI()

	$GUI_MSG = $GUI_RETURN
	While ($GUI_MSG <> $GUI_EXIT)
		$GUI_MSG = UpdateGUI()

		If ($GUI_MSG = $GUI_RESET) Then
			ResetSettings()
			ResetGUI()
			$GUI_MSG = UpdateGUI()

		ElseIf ($GUI_MSG = $GUI_INJECT OR $g_AutoInjection) Then
			$injection_state = PreInject($hGUI)
			If ($injection_state = True) Then
				If (Inject($hGUI) = $GUI_EXIT) Then
					ExitLoop
				EndIf
			EndIf

		ElseIf ($GUI_MSG = $GUI_UPDATE) Then
			Update($hGUI)
		ElseIf ($GUI_MSG = $GUI_FORCE_UPDATE) Then
			Update($hGUI, True)
		EndIf

		Sleep(30)
	WEnd

	DllClose($g_hInjectionDll)

	SaveFiles($g_hDllList)

	SaveSettings()

	ProcessListCleanUp()
	CloseGUI()

	Exit

EndFunc   ;==>Main

If (FileExists("OLD.exe")) Then
	ProcessClose("OLD.exe")
	FileDelete("OLD.exe")
EndIf

Main()