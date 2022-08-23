#Region ;FUNCTION LIST IN FILE ORDER:

;===================================================================================================
; Function........:  InjectDll($DllPath, $PID, $hMainGUI)
;
; Description.....:  Calls the InjectW function in the injection library.
;
; Parameter(s)....:  $DllPath 	- The absolute path to the file.
;					 $PID		- The process identifier of the target process.
;					 $hMainGUI	- A handle to the main GUI to pass to MsgErr.
;===================================================================================================
; Function........:  Inject($hMainGUI)
;
; Description.....:  Wrapperfunction to call the InjectDll function. Does some checks then forwards
;						each path to the InjectDll function.
;
; Parameter(s)....:  $hMainGUI	- A handle to the main GUI to create the injection GUI on.
;===================================================================================================
; Function........:  PreInject($hMainGUI)
;
; Parameter(s)....:  $hMainGUI	- A handle to the main GUI to pass to MsgErr.
;
; Description.....:  Verifies stuff and executes delay before starting the injection process.
;
; Return Value(s).:  On Success - Returns true. Injection can continue.
;                    On Failure - Returns false. Injection can't continue.
;===================================================================================================

#EndRegion

#include "GUI.au3"

#Region Global Definitions

Global Const $INJECTIONDATAW = _
	"struct;									" & _
		"DWORD 		LastErrorCode;				" & _
		"WCHAR		szDllPath[520];				" & _
		"PTR		szTargetProcessExeFileName;	" & _
		"DWORD 		ProcessId;					" & _
		"DWORD 		InjectionMode;				" & _
		"DWORD 		LaunchMethod;				" & _
		"DWORD 		Flags;						" & _
		"DWORD		hHandleValue;				" & _
		"PTR	 	hDllOut;					" & _
	"endstruct									"

#EndRegion

Func InjectDll($DllPath, $PID, $hMainGUI)

	$Data 	= DllStructCreate($INJECTIONDATAW)
	$pData 	= DllStructGetPtr($Data)

	$Data.ProcessId 					= $PID
	$Data.szDllPath						= $DllPath
	$Data.szTargetProcessExeFileName 	= 0
	$Data.InjectionMode 				= $g_InjectionMethod
	$Data.LaunchMethod					= $g_LaunchMethod
	$Data.Flags							= $g_InjectionFlags
	$Data.LastErrorCode					= 0
	$Data.hHandleValue					= 0
	$Data.hDllOut						= 0

	Local $dllRet = DllCall($g_hInjectionDll, _
		"DWORD", "InjectW", _
			"STRUCT*", $pData _
	)
	If (IsArray($dllRet)) Then
		If ($dllRet[0] <> 0) Then
			MsgErr("Error 0x" & StringFormat("%08X", $dllRet[0]), "An error has occurred. For more information check the log file:" & @CRLF & @ScriptDir & "\GH_Inj_Log.txt", $hMainGUI)
		EndIf
	Else
		MsgErr("Error " & @error, "Can't call InjectW.", $hMainGUI)
	EndIf

EndFunc   ;==>InjectDll


Func Inject($hMainGUI)

	$DllCount = _GUICtrlListView_GetItemCount($g_hDllList)

	If ($DllCount <> 0) Then

		For $i = 0 To $DllCount - 1 Step 1
			If (NOT _GUICtrlListView_GetItemChecked($g_hDllList, $i)) Then
				ContinueLoop
			EndIf

			$Arch = _GUICtrlListView_GetItemText($g_hDllList, $i, 3)
			If ($Arch = $l_TargetProcessArchitecture OR ($l_TargetProcessArchitecture = "---" AND BitAND($g_InjectionFlags, $INJ_HIJACK_HANDLE))) Then
				InjectDll(_GUICtrlListView_GetItemText($g_hDllList, $i, 2), $g_PID, $hMainGUI)
			EndIf
		Next

		If ($g_AutoInjection) Then
			GUICtrlSetState($h_C_AutoI, $GUI_UNCHECKED)
			$g_AutoInjection = False
		EndIf

		If ($g_CloseAfterInjection) Then
			Return $GUI_EXIT
		EndIf
	EndIf

	Return $GUI_RETURN

EndFunc   ;==>Inject

Func PreInject($hMainGUI)

	If ($g_PID = 1337) Then
		MsgBox(0x36, "Critical KERNEL Error! Errorcode 0x" & StringFormat("%08X", Random(0, 0x7FFFFFFF, 1)), "The process you've specified is too dank.", 0, $hMainGUI)

		$pic 	= _INetGetSource("https://i.redd.it/u0n3m8o88c831.jpg", False)
		$file 	= FileOpen(@TempDir & "\u0n3m8o88c831.jpg",18)
		FileWrite($file, $pic)
		FileClose($file)

		Local $main_win_pos = WinGetPos($hMainGUI)

		$losergui = GUICreate("", 1077, 757, $main_win_pos[0] - 138, $main_win_pos[1] - 168, $WS_POPUP)
		GUISwitch($losergui)
		GUICtrlCreatePic(@TempDir & "\u0n3m8o88c831.jpg", 0, 0, 1077, 757)
		GUISetState(@SW_SHOW)

		$tmr = GetTickCount()
		While (GUIGetMsg($losergui) <> $GUI_EVENT_CLOSE)
			Sleep(50)
			If ($tmr < GetTickCount() - 5000) Then
				ExitLoop
			EndIf
		WEnd

		GUIDelete($losergui)
		GUISwitch($hMainGUI)

		Return False
	EndIf

	If (NOT ProcessExists(Number($g_PID))) Then
		If (NOT $g_AutoInjection) Then
			MsgErr("Error", "Invalid target process specified.", $hMainGUI)
		EndIf
		Return False
	EndIf

	$bDllSelected = False
	$Count = _GUICtrlListView_GetItemCount($g_hDllList)
	For $i = 0 To $Count - 1 Step 1
		If (_GUICtrlListView_GetItemChecked($g_hDllList, $i)) Then
			If (_GUICtrlListView_GetItemText($g_hDllList, $i, 3) = $l_TargetProcessArchitecture OR ($l_TargetProcessArchitecture = "---" AND BitAND($g_InjectionFlags, $INJ_HIJACK_HANDLE))) Then
				$bDllSelected = True
				ExitLoop
			EndIf
		EndIf
	Next

	If (NOT $bDllSelected) Then
		If (NOT $g_AutoInjection) Then
			MsgErr("Error", "No valid DLL selected.", $hMainGUI)
		EndIf
		Return False
	EndIf

	Sleep($g_InjectionDelay)

	Return True

EndFunc   ;==>PreInject