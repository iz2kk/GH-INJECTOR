#Region ;FUNCTION LIST IN FILE ORDER:

;===================================================================================================
; Function........:  SaveSettings()
;
; Description.....:  Saves the settings stored in the g_ variables to file.
;===================================================================================================
; Function........:  SaveFiles($h_DllList)
;
; Description.....:  Saves the dll files listed in $h_DllList to file.
;
; Parameter(s)....:  $h_DllList - Handle to the listview control containing the dll files.
;===================================================================================================
; Function........:  ResetSettings()
;
; Description.....:  Resets all injection settings. This does not include the dll file list.
;===================================================================================================
; Function........:  LoadSettings()
;
; Description.....:  Loads all injection settings. This does not include the dll file list.
;===================================================================================================
; Function........:  LoadFiles($h_DllList)
;
; Description.....:  Loads the dll file list from the settings file and passes them to the listview.
;
; Parameter(s)....:  $h_DllList - Handle to the listview control containing the dll files.
;===================================================================================================
; Function........:  MakeShort($hexVal, $shortStruct)
;
; Description.....:  Loads the dll file list from the settings file and passes them to the listview.
;
; Parameter(s)....:  $hexVal 		- The 16 bit value short to be properly converted.
;					 $shortStruct 	- A short structure created with $g_tagShort.
;===================================================================================================

#EndRegion

#include "Include.au3"

Func SaveSettings()

	IniWrite($g_ConfigPath, "CONFIG", "PROCESS", 		      ($g_Processname			))
	IniWrite($g_ConfigPath, "CONFIG", "PROCESSNAMELIST",      ($g_ProcessnameList		))
	IniWrite($g_ConfigPath, "CONFIG", "PID", 			Number($g_PID					))
	IniWrite($g_ConfigPath, "CONFIG", "PROCESSBYNAME", 	Number($g_ProcessByName			))
	IniWrite($g_ConfigPath, "CONFIG", "DELAY", 			Number($g_InjectionDelay		))
	IniWrite($g_ConfigPath, "CONFIG", "LASTDIR", 		      ($g_LastDirectory			))
	IniWrite($g_ConfigPath, "CONFIG", "AUTOINJ", 		Number($g_AutoInjection			))
	IniWrite($g_ConfigPath, "CONFIG", "CLOSEONINJ",		Number($g_CloseAfterInjection	))
	IniWrite($g_ConfigPath, "CONFIG", "METHOD", 		Number($g_InjectionMethod		))
	IniWrite($g_ConfigPath, "CONFIG", "LAUNCHMETHOD",	Number($g_LaunchMethod			))
	IniWrite($g_ConfigPath, "CONFIG", "FLAGS", 			Number($g_InjectionFlags		))
	IniWrite($g_ConfigPath, "CONFIG", "IGNOREUPDATES", 	Number($g_IgnoreUpdates			))
	IniWrite($g_ConfigPath, "CONFIG", "PROCNAMEFILTER", 	  ($g_ProcNameFilter		))
	IniWrite($g_ConfigPath, "CONFIG", "TOOLTIPSON",		Number($g_ToolTipsOn			))
	IniWrite($g_ConfigPath, "CONFIG", "CURRENTSESSION",	Number($g_CurrentSession		))
	IniWrite($g_ConfigPath, "CONFIG", "MAINGUIX", 		Number($g_MainGUI_X				))
	IniWrite($g_ConfigPath, "CONFIG", "MAINGUIY", 		Number($g_MainGUI_Y				))
	IniWrite($g_ConfigPath, "CONFIG", "DARKTHEME",		Number($g_DarkThemeEnabled		))
	IniWrite($g_ConfigPath, "CONFIG", "PROCESSTYPE",	Number($g_Processtype			))

EndFunc   ;==>SaveSettings

Func SaveFiles($h_DllList)

	IniWriteSection($g_ConfigPath, "FILES", "")

	$Count = _GUICtrlListView_GetItemCount($h_DllList)
	For $i = 0 To $Count - 1 Step 1
		$Path = _GUICtrlListView_GetItemText($h_DllList, $i, 2)
		$Path &= _GUICtrlListView_GetItemText($h_DllList, $i, 3)
		If (_GUICtrlListView_GetItemChecked($h_DllList, $i)) Then
			$Path &= "1"
		Else
			$Path &= "0"
		EndIf

		IniWrite($g_ConfigPath, "FILES", $i, $Path)
	Next

EndFunc   ;==>SaveFiles

Func ResetSettings()

	FileDelete($g_LogPath)

	IniDelete($g_ConfigPath, "CONFIG")

	$g_Processname 			= "Broihon.exe"
	$g_ProcessnameList		= "Broihon.exe"
	$g_PID					= 1337
	$g_ProcessByName		= True
	$g_InjectionDelay		= 0
	$g_LastDirectory		= @DesktopDir & "\"
	$g_AutoInjection 		= False
	$g_CloseAfterInjection 	= False
	$g_InjectionMethod		= 0
	$g_LaunchMethod			= False
	$g_InjectionFlags		= 0
	$g_IgnoreUpdates		= False
	$g_ProcNameFilter		= ""
	$g_ToolTipsOn			= True
	$g_CurrentSession		= True
	$g_MainGUI_X 			= 100
	$g_MainGUI_Y			= 100
	$g_DarkThemeEnabled		= True
	$g_Processtype			= 0

	SaveSettings()

EndFunc   ;==>ResetSettings

Func LoadSettings()

	If (NOT FileExists($g_ConfigPath)) Then
		ResetSettings()
		Return
	EndIf

	$g_Processname 			= 		(IniRead($g_ConfigPath, "CONFIG", "PROCESS", 		      ($g_Processname			)))
	$g_ProcessnameList 		= 		(IniRead($g_ConfigPath, "CONFIG", "PROCESSNAMELIST",      ($g_ProcessnameList		)))
	$g_PID 					= Number(IniRead($g_ConfigPath, "CONFIG", "PID", 			Number($g_PID					)))
	$g_ProcessByName	 	= Number(IniRead($g_ConfigPath, "CONFIG", "PROCESSBYNAME", 	Number($g_ProcessByName			)))
	$g_InjectionDelay		= Number(IniRead($g_ConfigPath, "CONFIG", "DELAY", 			Number($g_InjectionDelay		)))
	$g_LastDirectory 		= 		(IniRead($g_ConfigPath, "CONFIG", "LASTDIR", 			  ($g_LastDirectory			)))
	$g_AutoInjection 		= Number(IniRead($g_ConfigPath, "CONFIG", "AUTOINJ", 		Number($g_AutoInjection			)))
	$g_CloseAfterInjection 	= Number(IniRead($g_ConfigPath, "CONFIG", "CLOSEONINJ", 	Number($g_CloseAfterInjection	)))
	$g_InjectionMethod 		= Number(IniRead($g_ConfigPath, "CONFIG", "METHOD", 		Number($g_InjectionMethod		)))
	$g_LaunchMethod		 	= Number(IniRead($g_ConfigPath, "CONFIG", "LAUNCHMETHOD",	Number($g_LaunchMethod			)))
	$g_InjectionFlags 		= Number(IniRead($g_ConfigPath, "CONFIG", "FLAGS", 			Number($g_InjectionFlags		)))
	$g_IgnoreUpdates 		= Number(IniRead($g_ConfigPath, "CONFIG", "IGNOREUPDATES", 	Number($g_IgnoreUpdates			)))
	$g_ProcNameFilter 		= 		(IniRead($g_ConfigPath, "CONFIG", "PROCNAMEFILTER", 	  ($g_ProcNameFilter		)))
	$g_ToolTipsOn 			= Number(IniRead($g_ConfigPath, "CONFIG", "TOOLTIPSON", 	Number($g_ToolTipsOn			)))
	$g_CurrentSession		= Number(IniRead($g_ConfigPath, "CONFIG", "CURRENTSESSION", Number($g_CurrentSession		)))
	$g_MainGUI_X			= Number(IniRead($g_ConfigPath, "CONFIG", "MAINGUIX",		Number($g_MainGUI_X				)))
	$g_MainGUI_Y			= Number(IniRead($g_ConfigPath, "CONFIG", "MAINGUIY",		Number($g_MainGUI_Y				)))
	$g_DarkThemeEnabled		= Number(IniRead($g_ConfigPath, "CONFIG", "DARKTHEME",		Number($g_DarkThemeEnabled		)))
	$g_Processtype			= Number(IniRead($g_ConfigPath, "CONFIG", "PROCESSTYPE",	Number($g_Processtype			)))

EndFunc   ;==>LoadSettings

Func LoadFiles($h_DllList)

	Local $Files = IniReadSection($g_ConfigPath, "FILES")
	If (@error) Then
		Return
	EndIf

	For $i = 0 To $Files[0][0] - 1 Step 1

		$Path 		= StringTrimRight($Files[$i + 1][1], 4)
		$FileData	= StringTrimLeft($Files[$i + 1][1], StringLen($Files[$i + 1][1]) - 4)
		$FileArch	= StringTrimRight($FileData, 1)
		$FileTicked	= StringTrimLeft($FileData, 3)

		If (FileExists($Path)) Then
			Local $Split = StringSplit($Path, "\")
			_GUICtrlListView_AddItem($h_DllList, "", $i)
			_GUICtrlListView_AddSubItem($h_DllList, $i, $Split[$Split[0]], 1)
			_GUICtrlListView_AddSubItem($h_DllList, $i, $Path, 2)
			_GUICtrlListView_AddSubItem($h_DllList, $i, $FileArch, 3)
			_GUICtrlListView_AddSubItem($h_DllList, $i, 0, 4)

			If ($FileTicked = 1) Then
				_GUICtrlListView_SetItemChecked($h_DllList, $i)
				_GUICtrlListView_AddSubItem($h_DllList, $i, 1, 4)
			EndIf
		EndIf
	Next

EndFunc   ;==>LoadFiles

Func MakeShort($hexVal, $shortStruct)
	$shortStruct.short = $hexVal
	Return $shortStruct.short
EndFunc   ;==>MakeShort