#Region ;FUNCTION LIST IN FILE ORDER:

;===================================================================================================
; Function........:  Update()
;
; Parameter(s)....:  $hParent		- A handle to the parent window (optional).
;					 $bForceUpdate 	- Forces the update even if the current version is the newest.
;
; Description.....:  Checks for a newer version and updates if desired.
;===================================================================================================

#EndRegion

#include "Include.au3"

Func Update($hParent, $bForceUpdate = False)

	$VersionRef 	 = "http://guidedhacking.com/gh/inj"
	$g_NewestVersion = _INetGetSource($VersionRef)

	If ($g_NewestVersion OR $bForceUpdate) Then
		If (Number($g_CurrentVersion) < Number($g_NewestVersion) OR $bForceUpdate) Then
			$DownloadLink = "http://guidedhacking.com/gh/inj/V" & $g_NewestVersion & "/GH Injector.zip"

			$x = 250
			$y = 90
			Local $win_info = WinGetPos($hParent)
			If (NOT @error) Then
				$x = $win_info[0] + $win_info[2] / 2 - 125
				$y = $win_info[1] + $win_info[3] / 2 - 45
			EndIf

			$h_GUI_Update = GUICreate("New version available", 250, 90, $x, $y, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX), $WS_EX_TOPMOST, $hParent)
			$h_L_InfoText = GUICtrlCreateLabel("This version of the GH Injector is outdated." & @CRLF & "The newest version is V" & $g_NewestVersion & ".", 20, 10)
			$h_B_Update = GUICtrlCreateButton("Update", 20, 43, 87)
			$h_B_Cancel = GUICtrlCreateButton("Skip", 137, 43, 87)
			$h_C_Ignore = GUICtrlCreateCheckbox("Ignore future updates", 20, 70)

			GUISetState(@SW_SHOW, $h_GUI_Update)
			If ($hParent <> 0) Then
				GUISetState(@SW_DISABLE, $hParent)
			EndIf

			While (True)
				$Msg = GUIGetMsg()
				Select
					Case $Msg = $GUI_EVENT_CLOSE
						ExitLoop

					Case $Msg = $h_B_Cancel
						ExitLoop

					Case $Msg = $h_C_Ignore
						If (GUICtrlRead($h_C_Ignore) = $GUI_CHECKED) Then
							GUICtrlSetState($h_B_Update, $GUI_DISABLE)
							$g_IgnoreUpdates = True
						Else
							GUICtrlSetState($h_B_Update, $GUI_ENABLE)
							$g_IgnoreUpdates = False
						EndIf

					Case $Msg = $h_B_Update

						$h_GUI_Download = GUICreate("Update in progress (0%)", 250, 90, $x, $y, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX), $WS_EX_TOPMOST, $hParent)

						$h_Progress		= GUICtrlCreateProgress(5, 5, 240, 80)

						$h_LabelGUI = GUICreate("", 250, 90, 0, 0, $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_TRANSPARENT, $WS_EX_MDICHILD, $WS_EX_TOPMOST), $h_GUI_Download)
						GUISetBkColor(0x989898, $h_LabelGUI)

						$h_Label = GUICtrlCreateLabel("Downloading...", 0, 0, 250, 90, BitOR($SS_CENTER, $SS_CENTERIMAGE))
						GUICtrlSetFont($h_Label, 20, $FW_BOLD)
						GUICtrlSetBkColor($h_Label, $GUI_BKCOLOR_TRANSPARENT)

						_WinAPI_SetLayeredWindowAttributes($h_LabelGUI, 0x989898)

						GUISetState(@SW_HIDE, $h_GUI_Update)
						GUIDelete($h_GUI_Update)

						GUISetState(@SW_SHOW, $h_GUI_Download)
						GUISetState(@SW_SHOW, $h_LabelGUI)

						$Path = @TempDir & "\GH Injector V" & $g_NewestVersion & ".zip"
						If (_Zip_DllChk()) Then
							$Path = @ScriptDir & "\GH Injector V" & $g_NewestVersion & ".zip"
						EndIf

						$hDownload = InetGet($DownloadLink, $Path, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
						$bytes_max = 2236416

						While (InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE) = False)
							$bytes_read = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
							$percentage = Ceiling(($bytes_read / $bytes_max) * 100)
							WinSetTitle($h_GUI_Download, "", "Update in progress (" & $percentage & "%)")
							GUICtrlSetData($h_Progress, $percentage)
							Sleep(100)
						WEnd

						WinSetTitle($h_GUI_Download, "", "Update in progress (100%)")
						GUICtrlSetData($h_Progress, 100)

						If (InetGetInfo($hDownload, $INET_DOWNLOADSUCCESS) = False) Then

							GUISetState(@SW_HIDE, $h_LabelGUI)
							GUIDelete($h_LabelGUI)
							GUISetState(@SW_HIDE, $h_GUI_Download)
							GUIDelete($h_GUI_Download)
							If ($hParent) Then
								GUISetState(@SW_ENABLE, $hParent)
							EndIf
							MsgBox($MB_ICONERROR, "Error", "An error occured and the download couldn't be completed.")
							Return

						ElseIf (_Zip_DllChk()) Then

							GUISetState(@SW_HIDE, $h_LabelGUI)
							GUIDelete($h_LabelGUI)
							GUISetState(@SW_HIDE, $h_GUI_Download)
							GUIDelete($h_GUI_Download)
							If ($hParent) Then
								GUISetState(@SW_ENABLE, $hParent)
							EndIf
							ShellExecute(@ScriptDir)
							Return

						EndIf

						DllClose($g_hInjectionDll)

						If (@AutoItX64) Then
							FileMove(@ScriptDir & "\GH Injector - x64.exe", @ScriptDir & "\OLD.exe", $FC_OVERWRITE)
							FileDelete(@ScriptDir & "\GH Injector - x86.exe")
						Else
							FileMove(@ScriptDir & "\GH Injector - x86.exe", @ScriptDir & "\OLD.exe", $FC_OVERWRITE)
							FileDelete(@ScriptDir & "\GH Injector - x64.exe")
						EndIf

						FileDelete(@ScriptDir & "\GH Injector - x64.dll")
						FileDelete(@ScriptDir & "\GH Injector SWHEX - x64.exe")

						FileDelete(@ScriptDir & "\GH Injector - x86.dll")
						FileDelete(@ScriptDir & "\GH Injector SWHEX - x86.exe")

						FileDelete(@ScriptDir & "\GH Injector.exe")

						_Zip_UnzipAll($Path, @ScriptDir)

						FileDelete($Path)

						Run("GH Injector.exe")

						GUISetState(@SW_HIDE, $h_LabelGUI)
						GUIDelete($h_LabelGUI)
						GUISetState(@SW_HIDE, $h_GUI_Download)
						GUIDelete($h_GUI_Download)

						Exit
				EndSelect
			WEnd

			If ($hParent <> 0) Then
				GUISetState(@SW_ENABLE, $hParent)
			EndIf

			GUISetState(@SW_HIDE, $h_GUI_Update)
			GUIDelete($h_GUI_Update)
		EndIf
	EndIf

EndFunc   ;==>Update