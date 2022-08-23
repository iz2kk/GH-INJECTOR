#Region ;FUNCTION LIST IN FILE ORDER:

;===================================================================================================
; Function........:  SetPrivilege($PrivilegeName, $bEnable)
;
; Description.....:  Enables/Disables a privilege for the current process.
;
; Parameter(s)....:  $PrivilegeName - Name of the privilege
;					 $bEnable		- True to enable and false to disable the privilege.
;===================================================================================================
; Function........:  GetTickCount()
;
; Description.....:  Calls GetTickCount (windows API) by using DllCall. For better perfomance a
;						global variable is used to store a handle (HINSTANCE) to kernel32.dll.
;
; Return Value(s).;  On Success - The return value of GetTickCount.
;					 On Failure - 0.
;===================================================================================================
; Function........:  GetSessionId($hTargetProcess)
;
; Description.....:  Retrieves the session identifier of the specified process.
;
; Parameter(s)....:  $hTargetProcess - Handle to the target process. This handle must have the
;										PROCESS_QUERY_LIMITED_INFORMATION access right.
;
; Return Value(s).;  On Success - The session identifier of the process.
;					 On Failure - -1 to indicate an invalid session identifier.
;===================================================================================================
; Function........:  GetProcessExePath($hProc)
;
; Description.....:  Retrieves the absolute path to the exe file on disk of a process.
;
; Parameter(s)....:  $hTargetProcess - Handle to the target process. This handle must have the
;										PROCESS_QUERY_LIMITED_INFORMATION access right.
;
; Return Value(s).;  On Success - A string containing the file path.
;					 On Failure - An empty string.
;===================================================================================================
; Function........:  ListProcesses($c_ProcessList, $ProcessList, $Mode, $CurrentSessionOnly, $Filter,
;						Processtype)
;
; Description.....:  Lists currently running processes in a list view using ProcessList.
;						(ExeIcon, ProcessId, ExeFileName, Architecture)
;
; Parameter(s)....:  $c_ProcessList 		- Handle to the listview control.
;					 $ProcessList			- An array returned by ProcessList().
;					 $Mode					- Defines the column used for sorting (1 - 3).
;					 $CurrentSessionOnly 	- If true processes from other sessions
;												are excluded from the list.
;					 $Filter				- A substring used to filter the list by ExeFileNames.
;					 $Processtype			- Used to filter processes by architecture. It has to be
;												one of the following values:
;													$PROCESS_TYPE_ALL (0)
;													$PROCESS_TYPE_X86 (1)
;													$PROCESS_TYPE_X64 (2)
;===================================================================================================
; Function........:  PL_WM_NOTIFY($hwnd, $uMsg, $wParam, $lParam)
;
; Description.....:  WM_NOTIFY wndProc of the ProcessList GUI. Handles doubleclicks on items
;						in the listview.
;
; Parameter(s)....:  default wndProc arguments
;
; Return Value(s).:  Forwards calls to the internal AutoIt/Windows handler(s)
;						by returning $GUI_RUNDEFMSG.
;===================================================================================================
; Function........:  PL_LV_SubclassProc($hWnd, $uMsg, $wParam, $lParam, $iID, $pData)
;
; Description.....:  A subclass procedure to catch VK_SPACE and VK_ENTER inputs to the listview.
;					 Also handles customdrawing when the GUI is set to dark mode.
;
; Parameter(s)....:  default SubClassProc arguments
;
; Return Value(s).:  By default calls are forwarded to DefSubclassProc using DllCall.
;					 	Exceptions (custom drawing when darkmode is enabled):
;							$uMsg = $WM_NOTIFY:
;								Code = $NM_CUSTOMDRAW and hWndFrom = handle to the listview header:
;									dwDrawStage = $CDDS_PREPAINT
;										Return $CDRF_NOTIFYITEMDRAW
;									dwDrawStage = $CDDS_ITEMPREPAINT
;										Return $CDRF_NOTIFYPOSTPAINT
;									dwDrawStage = $CDDS_ITEMPOSTPAINT
;										Return $CDRF_NEWFONT
;===================================================================================================
; Function........:  RGBToBGR($RGB)
;
; Description.....:  Converts a color value from RBG format to BGR format by bitwise functions.
;
; Paramter(s).....;	 $RGB	- The RGB value to convert.
;
; Return value(s).;	 The converted BGR value.
;===================================================================================================
; Function........:  CreateProcessList($hParent = 0, $bDarkTheme = False)
;
; Description.....:  Creates a GUI in which all currently running processes are listed.
;
; Parameter(s)....:  $hParent 		- A window handle (HWND) to a parent window (NULL by default).
;					 $bDarkTheme 	- A boolean which
;
; Return Value(s).;  On Success - The process identifier of the selected process.
;					 On Failure - -1 to imply an invalid process identifier.
;===================================================================================================
; Function........:  ProcessListCleanUp()
;
; Description.....:  Removes callbacks. Should be called when the process list is not needed
;						anymore or when the process exits.
;===================================================================================================

#EndRegion

#include "Include.au3"
#include "Misc.au3"
#include "Architecture.au3"

#Region Global Definitions
Global Const $ProcessSessionInformation = 24

Global Const $PROCESS_SESSION_INFORMATION = _
	"struct;				" & _
		"ULONG SessionId;	" & _
	"endstruct				"

Global $l_SortSense = [False, False, False]
Global Const $PROCESS_TYPE_ALL 		= 0
Global Const $PROCESS_TYPE_X86 		= 1
Global Const $PROCESS_TYPE_X64 		= 2

$PL_DoubleClickedIndex 	= -1
$PL_h_ImageList			= 0

$PL_h_GUI 				= 0
$PL_c_L_TitleBar		= 0
$PL_c_B_Close 			= 0
$PL_c_L_ProcessList 	= 0
$PL_h_L_ProcessList 	= 0
$PL_h_ProcessListHeader = 0
$PL_c_L_ProcFilter 		= 0
$PL_c_I_ProcFilter 		= 0
$PL_c_B_Select 			= 0
$PL_c_B_Refresh 		= 0
$PL_c_C_Processtype		= 0
$PL_c_C_Session 		= 0

$PL_Width 	= 300
$PL_Height 	= 405

$PL_HeaderText 		= "|PID|Name|Type"
$PL_HeaderTextSplit = _StringExplode($PL_HeaderText, "|")
Local $PL_ListViewColumnWidth[4] = [20, 45, 180, 38]
Local $PL_ListView_XY[2] 	= [0, 0]
$PL_ProcessList_X			= 0
$PL_ProcessList_Y 			= 0
$PL_ListView_PrevHoverIndex = -1
$PL_ProcessList_HoverHeader	= 0

$PL_RECT_Buffer			= 0

$PL_h_LV_SubclassProc 	= 0
$PL_ph_LV_SubclassProc	= 0

$PL_ProcessCount 	= 0

$PL_b_HoverClose = False
$PL_b_ClickClose = False

#EndRegion

Func SetPrivilege($PrivilegeName, $bEnable)

	Local $hToken = _Security__OpenProcessToken(_WinAPI_GetCurrentProcess(), $TOKEN_ALL_ACCESS)
	If NOT $hToken Then
		MsgErr("OpenProcessToken failed", "Couldn't enable debug privileges which might affect the functionality of the GH Injector.")
		Return
	EndIf

	If (NOT _Security__SetPrivilege($hToken, $SE_DEBUG_NAME, $bEnable)) Then
	    _WinAPI_CloseHandle($hToken)
		MsgErr($MB_ICONWARNING, "SetPrivilege failed", "Couldn't enable debug privileges which might affect the functionality of the GH Injector.")
	EndIf

	_WinAPI_CloseHandle($hToken)

EndFunc   ;==>SetPrivilege

Func GetTickCount()

	Local $dllRet = DllCall($g_kernel32_dll, "DWORD", 'GetTickCount')
	If (NOT IsArray($dllRet)) Then
		Return 0
	EndIf

	Return $dllRet[0]

EndFunc   ;==>_WinAPI_GetTickCount

Func GetSessionId($hTargetProcess)

	$psi 		= DllStructCreate($PROCESS_SESSION_INFORMATION)
	$ppsi 		= DllStructGetPtr($psi)
	$psi_size 	= DllStructGetSize($psi)

	$ntRet = DllCall("ntdll.dll", _
		"LONG", "NtQueryInformationProcess", _
			"HANDLE", 	$hTargetProcess, _
			"DWORD", 	$ProcessSessionInformation, _
			"STRUCT*", 	$ppsi, _
			"ULONG", 	$psi_size, _
			"ULONG*", 	0 _
	)

	If (NOT IsArray($ntRet) OR ($ntRet[0] < 0)) Then
		Return -1
	EndIf
	Return $psi.SessionId

EndFunc   ;==>GetSessionId

Func GetProcessExePath($hProc)

	$ret = DllCall($g_kernel32_dll, _
		"BOOL", "QueryFullProcessImageNameA", _
			"HANDLE", 	$hProc[0], _
			"DWORD", 	0, _
			"STR", 		"", _
			"DWORD*", 	260 _
	)

	Return $ret

EndFunc   ;==>GetProcessExePath

Func ListProcesses($c_ProcessList, $ProcessList, $Mode, $CurrentSessionOnly, $Filter, $Processtype)

	Local $ProcessData[256][4]
	$Count = 0

	$OwnSession = GetSessionId(-1)

	For $i = 1 To $ProcessList[0][0] Step 1
		$ProcessData[$Count][0] = $ProcessList[$i][1]
		$ProcessData[$Count][1] = $ProcessList[$i][0]
		$ProcessData[$Count][2] = "---"

		If (StringCompare($Filter, "")) Then
			If (StringInStr($ProcessData[$Count][1], $Filter, $STR_NOCASESENSE, 1, 1, StringLen($ProcessData[$Count][1]) - 4) = 0) Then
				ContinueLoop
			EndIf
		EndIf

		If ($ProcessData[$Count][0] == @AutoItPID OR NOT $ProcessData[$Count][0]) Then
			ContinueLoop
		EndIf

		$hProc_info = DllCall($g_kernel32_dll, _
			"HANDLE", "OpenProcess", _
				"DWORD", 	$PROCESS_QUERY_LIMITED_INFORMATION, _
				"INT", 		0, _
				"DWORD", 	$ProcessData[$Count][0] _
		)

		If (NOT IsArray($hProc_info) OR ($hProc_info[0] = 0)) Then
			If ($Processtype = $PROCESS_TYPE_ALL) Then
				$Count += 1
			EndIf
			ContinueLoop
		EndIf

		$bArch = Is64BitProcess($hProc_info[0])

		If ($bArch = 0 AND $Processtype = $PROCESS_TYPE_X64) Then
			ContinueLoop
		ElseIf ($bArch = 1 AND $Processtype = $PROCESS_TYPE_X86) Then
			ContinueLoop
		ElseIf ($bArch = -1 AND $Processtype <> $PROCESS_TYPE_ALL) Then
			ContinueLoop
		EndIf

		If ($bArch = 0) Then
			$ProcessData[$Count][2] = "x86"
		ElseIf ($bArch = 1) Then
			$ProcessData[$Count][2] = "x64"
		Else
			DllCall($g_kernel32_dll, _
				"BOOL", "CloseHandle", _
					"HANDLE", $hProc_info[0] _
			)
			$Count += 1
			ContinueLoop
		EndIf

		If ($CurrentSessionOnly = True) Then
			If (GetSessionId($hProc_info[0]) <> $OwnSession) Then
				DllCall($g_kernel32_dll, _
					"BOOL", "CloseHandle", _
						"HANDLE", $hProc_info[0] _
				)
				ContinueLoop
			EndIf
		EndIf

		$dllRet = GetProcessExePath($hProc_info)

		DllCall($g_kernel32_dll, _
			"BOOL", "CloseHandle", _
				"HANDLE", $hProc_info[0] _
		)

		If (IsArray($dllRet) AND ($dllRet[0] <> 0)) Then
			$ProcessData[$Count][3] = $dllRet[3]
		Else
			$ProcessData[$Count][3] = 0
		EndIf

		$Count += 1
	Next

	If ($Count > 1) Then
		$CurrentSortSense = $l_SortSense[$Mode]
		_ArraySort($ProcessData, $l_SortSense[$Mode], 0, $Count - 1, $Mode)

		$l_SortSense[0] = False
		$l_SortSense[1] = False
		$l_SortSense[2] = False

		If ($CurrentSortSense = False) Then
			$l_SortSense[$Mode] = True
		EndIf
	EndIf

	_GUIImageList_Destroy($PL_h_ImageList)

	$wnd_list = WinList()
	$PL_h_ImageList = _GUIImageList_Create(16, 16, 5, 1)
	For $i = 0 To $Count - 1 Step 1
		If (IsString($ProcessData[$i][3])) Then
			If (_GUIImageList_AddIcon($PL_h_ImageList, $ProcessData[$i][3], 0) <> - 1) Then
				ContinueLoop
			EndIf
		EndIf

		$bConsole = False

		For $j = 1 To $wnd_list[0][0] Step 1
			If (WinGetProcess($wnd_list[$j][1]) = $ProcessData[$i][0]) Then
				If (NOT StringCompare("ConsoleWindowClass", _WinAPI_GetClassName($wnd_list[$j][1]))) Then
					_GUIImageList_AddIcon($PL_h_ImageList, @SystemDir & "\cmd.exe", 0)
					$bConsole = True
					ExitLoop
				EndIf
			EndIf
		Next

		If (NOT $bConsole) Then
			_GUIImageList_AddIcon($PL_h_ImageList, @SystemDir & "\imageres.dll", 11)
		EndIf

	Next

	_GUICtrlListView_BeginUpdate($c_ProcessList)

	_GUICtrlListView_SetImageList($c_ProcessList, $PL_h_ImageList, 1)

	$cur_item_count = _GUICtrlListView_GetItemCount($c_ProcessList)

	For $i = 0 To $Count - 1 Step 1
		If ($i >= $cur_item_count) Then
			_GUICtrlListView_AddItem($c_ProcessList, "", $i)
		EndIf

		_GUICtrlListView_SetItem($c_ProcessList, $ProcessData[$i][0], $i, 1)
		_GUICtrlListView_SetItem($c_ProcessList, $ProcessData[$i][1], $i, 2)
		_GUICtrlListView_SetItem($c_ProcessList, $ProcessData[$i][2], $i, 3)
	Next

	If ($Count < $cur_item_count) Then
		For $i = $Count To $cur_item_count - 1 Step 1
			_GUICtrlListView_DeleteItem($c_ProcessList, $Count)
		Next
	EndIf

	_GUICtrlListView_EndUpdate($c_ProcessList)

	Return $Count

EndFunc   ;==>ListProcesses

Func PL_WM_NOTIFY($hWnd, $uMsg, $wParam, $lParam)

	$tNMHDR = DllStructCreate($tagNMHDR, $lParam)

	If (HWnd($tNMHDR.hWndFrom) = $PL_h_L_ProcessList) Then
		If ($tNMHDR.Code = $NM_DBLCLK) Then
			$tInfo = DllStructCreate($tagNMITEMACTIVATE, $lParam)
			$PL_DoubleClickedIndex = $tInfo.Index
	    ElseIf ($tNMHDR.Code = $NM_CUSTOMDRAW) Then
			For $i = 0 To _GUICtrlListView_GetColumnCount($PL_c_L_ProcessList) - 1 Step 1
				If (_GUICtrlListView_GetColumnWidth($PL_c_L_ProcessList, $i) <> $PL_ListViewColumnWidth[$i]) Then
					_GUICtrlListView_SetColumnWidth($PL_c_L_ProcessList, $i, $PL_ListViewColumnWidth[$i])
				EndIf
			Next
		EndIf
	EndIf

	Return $GUI_RUNDEFMSG

EndFunc   ;==>PL_WM_NOTIFY

Func PL_LV_SubclassProc($hWnd, $uMsg, $wParam, $lParam, $iID, $pData)

	If ($uMsg = $WM_GETDLGCODE) Then
		If ($wParam = $VK_RETURN OR $wParam = $VK_SPACE) Then
			$sel_index = _GUICtrlListView_GetSelectedIndices($PL_h_L_ProcessList, True)
			If (UBound($sel_index) AND ($sel_index[0] <> 0)) Then
			   $PL_DoubleClickedIndex = $sel_index[1]
			EndIf
		EndIf
	ElseIf ($g_DarkThemeEnabled AND $uMsg = $WM_NOTIFY) Then
		$tNMHDR = DllStructCreate($tagNMHDR, $lParam)
		If ($tNMHDR.Code = $NM_CUSTOMDRAW AND $tNMHDR.hWndFrom = $PL_h_ProcessListHeader) Then
			Local $NMLVCD = DllStructCreate($tagNMLVCUSTOMDRAW, $lParam)

			Switch $NMLVCD.dwDrawStage
				Case $CDDS_PREPAINT
					Return $CDRF_NOTIFYITEMDRAW

				Case $CDDS_ITEMPREPAINT
					Return $CDRF_NOTIFYPOSTPAINT

				Case $CDDS_ITEMPOSTPAINT
					Local $hDC 		= $NMLVCD.hdc
					Local $index 	= $NMLVCD.dwItemSpec

					_WinAPI_SelectObject($hDC, $G_HFONT_LV_Font)
					_WinAPI_SetBkMode($hDC, $TRANSPARENT)
					_WinAPI_SetTextColor($hDC, $C_GUI_Text[1])

					$curr_total_col_width = 0
					For $i = 0 To $index - 1 Step 1
						$curr_total_col_width += $PL_ListViewColumnWidth[$i]
					Next

					$PL_RECT_Buffer.Left 	= $NMLVCD.Left
					$PL_RECT_Buffer.Top 	= $NMLVCD.Top
					$PL_RECT_Buffer.Right 	= $NMLVCD.Right
					$PL_RECT_Buffer.Bottom 	= $NMLVCD.Bottom

					If ($index = 0) Then
						_WinAPI_FillRect($hDC, $PL_RECT_Buffer, $G_HBRUSH_Dark)
						Return $CDRF_NEWFONT
					EndIf

					If ($NMLVCD.uItemState = $CDIS_SELECTED) Then
						_WinAPI_FillRect($hDC, $PL_RECT_Buffer, $G_HBRUSH_Light)
						If (BitAND($PL_ProcessList_HoverHeader, 2 ^ $index)) Then
							$PL_ProcessList_HoverHeader = 0
						EndIf
					Else
						Local $info = MouseGetPos()
						$info[0] -= $PL_ProcessList_X + $PL_ListView_XY[0]
						$info[1] -= $PL_ProcessList_Y + $PL_ListView_XY[1]

						If ($info[0] >= $PL_RECT_Buffer.Left AND $info[0] <= $PL_RECT_Buffer.Right AND $info[1] >= $PL_RECT_Buffer.Top AND $info[1] <= $PL_RECT_Buffer.Bottom) Then
							_WinAPI_FillRect($hDC, $PL_RECT_Buffer, $G_HBRUSH_SemiDark)
							$PL_ProcessList_HoverHeader = BitOR($PL_ProcessList_HoverHeader, 2 ^ $index)
						Else
							_WinAPI_FillRect($hDC, $PL_RECT_Buffer, $G_HBRUSH_Dark)
							If (BitAND($PL_ProcessList_HoverHeader, 2 ^ $index)) Then
								$PL_ProcessList_HoverHeader = 0
							EndIf
						EndIf
					EndIf

					If ($index < UBound($PL_ListViewColumnWidth)) Then
						$PL_RECT_Buffer.Right 	= $PL_RECT_Buffer.Left + 2
						$PL_RECT_Buffer.Top 	+= 2
						$PL_RECT_Buffer.Bottom	-= 2
						_WinAPI_FillRect($hDC, $PL_RECT_Buffer, $G_HBRUSH_SuperDark)
					EndIf

					$PL_RECT_Buffer.Left	= $curr_total_col_width
					$PL_RECT_Buffer.Right 	= $PL_ListViewColumnWidth[$index] + $curr_total_col_width
					$PL_RECT_Buffer.Top 	= $NMLVCD.Top + 4
					$PL_RECT_Buffer.Bottom 	= $NMLVCD.Bottom
					_WinAPI_DrawText($hDC, "  " & $PL_HeaderTextSplit[$index], $PL_RECT_Buffer, $DT_VCENTER)

					Return $CDRF_NEWFONT
			EndSwitch
		EndIf
	EndIf

	Return DllCall("Comctl32.dll", "LRESULT", "DefSubclassProc", "HWND", $hWnd, "UINT", $uMsg, "WPARAM", $wParam, "LPARAM", $lParam)[0]

EndFunc   ;==>WndProc_ProcessList

Func RGBToBGR($RGB)

	$R = BitShift(BitAND($RGB, 0xFF0000), 16)
	$G = BitAND($RGB, 0x00FF00)
	$B = BitShift(BitAND($RGB, 0x0000FF), -16)

	Return BitOR($B, $G, $R)

EndFunc   ;==>RGBToBGR

Func CreateProcessList($hParent = 0, $bDarkTheme = False)

	If (NOT $PL_h_GUI) Then

		$PL_ProcessList_X = -1
		$PL_ProcessList_Y = -1

		If ($hParent <> 0) Then
			Local $pos = WinGetPos($hParent)
			If (NOT @error) Then
				$PL_ProcessList_X = $pos[0] + ($pos[2] - $PL_Width) / 2
				$PL_ProcessList_Y = $pos[1] + ($pos[3] - $PL_Height) / 2
			EndIf
		EndIf

		$PL_h_GUI = GUICreate("", $PL_Width, $PL_Height, $PL_ProcessList_X, $PL_ProcessList_Y, $WS_POPUP + $WS_BORDER, $WS_EX_TOPMOST, $hParent)

		$PL_c_L_TitleBar 	= GUICtrlCreateLabel(" Select a process (0)", 0, 2, $PL_Width - 20, 20, Default, $GUI_WS_EX_PARENTDRAG)
		$PL_c_B_Close 		= GUICtrlCreateLabel("×", $PL_Width - 17, 0, 17, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
			GUICtrlSetFont($PL_c_B_Close, 12, $FW_BOLD)

		$PL_c_L_ProcessList = GUICtrlCreateListView($PL_HeaderText, 0, 20, $PL_Width, $PL_Height - 100, $LVS_REPORT, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_SUBITEMIMAGES))
			$PL_ListView_XY[0] = 0
			$PL_ListView_XY[1] = 20

			$PL_h_L_ProcessList = GUICtrlGetHandle($PL_c_L_ProcessList)
			$PL_h_ProcessListHeader = _GUICtrlListView_GetHeader($PL_c_L_ProcessList)
				$PL_RECT_Buffer = DllStructCreate($tagRECT)

		For $i = 0 To _GUICtrlListView_GetColumnCount($PL_c_L_ProcessList) - 1 Step 1
			_GUICtrlListView_SetColumnWidth($PL_c_L_ProcessList, $i, $PL_ListViewColumnWidth[$i])
		Next

		$PL_c_L_ProcFilter 	= GUICtrlCreateLabel("Filter process list:", 6, $PL_Height - 74, 80, 15)
		$PL_c_I_ProcFilter 	= GUICtrlCreateInput($g_ProcNameFilter, 90, $PL_Height - 76, $PL_Width - 96, 17)
		$PL_c_B_Select 		= GUICtrlCreateButton("Select", 5, $PL_Height - 55, $PL_Width / 2 - 8, 27)
		$PL_c_B_Refresh 	= GUICtrlCreateButton("Refresh", $PL_Width / 2 + 3, $PL_Height - 55, $PL_Width / 2 - 8, 27)
		$PL_c_C_Processtype	= GUICtrlCreateCombo("", 7, $PL_Height - 24, $PL_Width / 2 - 12, 20, $CBS_DROPDOWNLIST)
			GUICtrlSetData($PL_c_C_Processtype, "All processes|x86 processes only|x64 processes only", "All processes")
			If (NOT @AutoItX64) Then
				GUICtrlSetState($PL_c_C_Processtype, $GUI_DISABLE)
				_GUICtrlComboBox_SetCurSel($PL_c_C_Processtype, $PROCESS_TYPE_X86)
				$g_Processtype = 1
			Else
				_GUICtrlComboBox_SetCurSel($PL_c_C_Processtype, $g_Processtype)
			EndIf
		$PL_c_C_Session 	= GUICtrlCreateCheckbox("Current session only", $PL_Width / 2 + 5, $PL_Height - 23, $PL_Width / 2 - 8, 20)
			If ($g_CurrentSession = True) Then
				GUICtrlSetState($PL_c_C_Session, $GUI_CHECKED)
			EndIf

		$PL_h_LV_SubclassProc 	= DllCallbackRegister("PL_LV_SubclassProc", "LRESULT", "HWND;UINT;WPARAM;LPARAM;UINT_PTR;DWORD_PTR")
		$PL_ph_LV_SubclassProc 	= DllCallbackGetPtr($PL_h_LV_SubclassProc)
		_WinAPI_SetWindowSubclass(GUICtrlGetHandle($PL_c_L_ProcessList), $PL_ph_LV_SubclassProc, 2, 0)

	EndIf

	If $bDarkTheme Then
		DllCall("UxTheme.dll", "int", "SetWindowTheme", "HWND", GUICtrlGetHandle($PL_c_C_Session), "wstr", "", "wstr", "")
	Else
		_WinAPI_SetWindowTheme(GUICtrlGetHandle($PL_c_C_Session), "Explorer")
	EndIf

	GUISetBkColor($C_GUI[$bDarkTheme], $PL_h_GUI)

	GUICtrlSetBkColor	($PL_c_L_ProcessList, $C_GUI_Ctrl_Listview[$bDarkTheme])
	GUICtrlSetColor		($PL_c_L_ProcessList, $C_GUI_Text[$bDarkTheme])

	GUICtrlSetBkColor	($PL_c_L_TitleBar, 	$C_GUI[$bDarkTheme])
	GUICtrlSetColor		($PL_c_L_TitleBar, 	$C_GUI_Text[$bDarkTheme])

	GUICtrlSetBkColor	($PL_c_B_Close, 	$C_GUI[$bDarkTheme])
	GUICtrlSetColor		($PL_c_B_Close, 	$C_GUI_Text[$bDarkTheme])

	GUICtrlSetBkColor	($PL_c_L_ProcFilter, $C_GUI_Ctrl_Label[$bDarkTheme])
	GUICtrlSetColor		($PL_c_L_ProcFilter, $C_GUI_Text[$bDarkTheme])
	GUICtrlSetBkColor	($PL_c_I_ProcFilter, $C_GUI_Ctrl_Input[$bDarkTheme])
	GUICtrlSetColor		($PL_c_I_ProcFilter, $C_GUI_Text[$bDarkTheme])
	GUICtrlSetBkColor	($PL_c_B_Select, 	 $C_GUI_Ctrl_Button[$bDarkTheme])
	GUICtrlSetColor		($PL_c_B_Select, 	 $C_GUI_Text[$bDarkTheme])
	GUICtrlSetBkColor	($PL_c_C_Session, 	 $C_GUI_Ctrl_Checkbox[$bDarkTheme])
	GUICtrlSetColor		($PL_c_C_Session, 	 $C_GUI_Text[$bDarkTheme])
	GUICtrlSetBkColor	($PL_c_B_Refresh, 	 $C_GUI_Ctrl_Button[$bDarkTheme])
	GUICtrlSetColor		($PL_c_B_Refresh, 	 $C_GUI_Text[$bDarkTheme])

	If ($bDarkTheme) Then
		DllCall("UxTheme.dll", "int", "SetWindowTheme", "HWND", GUICtrlGetHandle($PL_c_C_Processtype), "wstr", "", "wstr", "")
	Else
		_WinAPI_SetWindowTheme(GUICtrlGetHandle($PL_c_C_Processtype), "Explorer")
	EndIf

	GUICtrlSetBkColor	($PL_c_C_Processtype, $C_GUI_Ctrl_Combo[$g_DarkThemeEnabled])
	GUICtrlSetColor		($PL_c_C_Processtype, $C_GUI_Text[$g_DarkThemeEnabled])

	GUICtrlSetData($PL_c_I_ProcFilter, $g_ProcNameFilter)

	Local $ProcessList 	= ProcessList()
	$ProcessCount = ListProcesses($PL_c_L_ProcessList, $ProcessList, 1, $g_CurrentSession, $g_ProcNameFilter, $g_Processtype)
	GUICtrlSetData($PL_c_L_TitleBar, " Select a process (" & $ProcessCount & ")")

	If ($hParent) Then
		GUISetState(@SW_DISABLE, $hParent)
	EndIf
	GUISetState(@SW_SHOW, $PL_h_GUI)

	$lPID 				= -1
	$lProcArch 			= ""
	$UpdateListFromMask = False
	$TempPrcoNameFilter = $g_ProcNameFilter

	_WinAPI_SetFocus(GUICtrlGetHandle($PL_c_I_ProcFilter))
	ControlSend($PL_h_GUI, "", $PL_c_I_ProcFilter, "{END}")

	While (True)
		Sleep(5)

		$TempPrcoNameFilter = GUICtrlRead($PL_c_I_ProcFilter)
		If (StringCompare($TempPrcoNameFilter, $g_ProcNameFilter)) Then
			$UpdateListFromMask = True
		EndIf

		$info = GUIGetCursorInfo($PL_h_GUI)
		If ($info[4] = $PL_c_B_Close) Then
			If ($info[2] AND NOT $PL_b_ClickClose) Then
				$PL_b_ClickClose = True
				GUICtrlSetColor($PL_c_B_Close, 0xFFFFFF)
				GUICtrlSetBkColor($PL_c_B_Close, 0xF1707A)

				While ($info[4] = $PL_c_B_Close AND $info[2])
					$info = GUIGetCursorInfo($PL_h_GUI)
					Sleep(20)
				WEnd

				If (NOT $info[2]) Then
					$lPID = -1
					ExitLoop
				Else
					$PL_b_HoverClose = False
					$PL_b_ClickClose = False
					GUICtrlSetColor($PL_c_B_Close, $C_GUI_Text[$bDarkTheme])
					GUICtrlSetBkColor($PL_c_B_Close, $C_GUI[$bDarkTheme])
				EndIf
			ElseIf NOT $PL_b_HoverClose Then
				$PL_b_HoverClose = True
				$PL_b_ClickClose = False
				GUICtrlSetColor($PL_c_B_Close, 0xFFFFFF)
				GUICtrlSetBkColor($PL_c_B_Close, 0xE81123)
			EndIf
		ElseIf ($PL_b_HoverClose OR $PL_b_ClickClose) Then
			$PL_b_HoverClose = False
			$PL_b_ClickClose = False
			GUICtrlSetColor($PL_c_B_Close, $C_GUI_Text[$bDarkTheme])
			GUICtrlSetBkColor($PL_c_B_Close, $C_GUI[$bDarkTheme])
		EndIf

		If ($PL_ProcessList_HoverHeader <> 0) Then
			_WinAPI_RedrawWindow($PL_h_ProcessListHeader)
		EndIf


		$Msg = GUIGetMsg($PL_h_GUI)
		Select
			Case $Msg = $GUI_EVENT_CLOSE
				$lPID = -1
				ExitLoop

			Case $PL_DoubleClickedIndex <> -1
				$lPID 		= _GUICtrlListView_GetItemText($PL_c_L_ProcessList, $PL_DoubleClickedIndex, 1)
				$lProcArch 	= _GUICtrlListView_GetItemText($PL_c_L_ProcessList, $PL_DoubleClickedIndex, 3)
				$PL_DoubleClickedIndex = -1

				If (NOT StringCompare($lProcArch, "---")) Then
					$mbRet = MsgBox(BitOR($MB_ICONWARNING, $MB_TOPMOST , $MB_YESNO), "Warning", "Cannot attach to the selected process. Do you want to select this process anyway?", 0, $PL_h_GUI)
					If ($mbRet = $IDNO) Then
						ContinueLoop
					EndIf
				EndIf

				ExitLoop

			Case $Msg = $PL_c_B_Select
				Local $Index = _GUICtrlListView_GetSelectedIndices($PL_c_L_ProcessList, True)
				If ($Index[0] = 0) Then
					MsgErr("Error", "Please select a process first.", $PL_h_GUI)
					ContinueLoop
				EndIf

				$lPID 		= _GUICtrlListView_GetItemText($PL_c_L_ProcessList, $Index[1], 1)
				$lProcArch 	= _GUICtrlListView_GetItemText($PL_c_L_ProcessList, $Index[1], 3)
				If ($lProcArch = "---") Then
					$mbRet = MsgBox(BitOR($MB_ICONWARNING, $MB_TOPMOST , $MB_YESNO), "Warning", "Cannot attach to the selected process. Do you want to select this process anyway?", 0, $PL_h_GUI)
					If ($mbRet = $IDNO) Then
						ContinueLoop
					EndIf
				EndIf

				ExitLoop

			Case $Msg = $PL_c_L_ProcessList
				$ClickedCol = GUICtrlGetState($PL_c_L_ProcessList)
				If ($ClickedCol <> 0) Then
					$ProcessCount = ListProcesses($PL_c_L_ProcessList, $ProcessList, $ClickedCol - 1, $g_CurrentSession, $g_ProcNameFilter, $g_Processtype)
					GUICtrlSetData($PL_c_L_TitleBar, " Select a process (" & $ProcessCount & ")")
				EndIf

			Case $Msg = $PL_c_B_Refresh
				$l_SortSense[1] = False
				$ProcessList 	= ProcessList()
				$ProcessCount 	= ListProcesses($PL_c_L_ProcessList, $ProcessList, 1, $g_CurrentSession, $g_ProcNameFilter, $g_Processtype)
				GUICtrlSetData($PL_c_L_TitleBar, " Select a process (" & $ProcessCount & ")")

			Case $Msg = $PL_c_C_Processtype
				$g_Processtype = _GUICtrlComboBox_GetCurSel($PL_c_C_Processtype)

				$l_SortSense[1] = False
				$ProcessList 	= ProcessList()
				$ProcessCount 	= ListProcesses($PL_c_L_ProcessList, $ProcessList, 1, $g_CurrentSession, $g_ProcNameFilter, $g_Processtype)
				GUICtrlSetData($PL_c_L_TitleBar, " Select a process (" & $ProcessCount & ")")

			Case $Msg = $PL_c_C_Session
				$g_CurrentSession = BitAND(GUICtrlRead($PL_c_C_Session), $GUI_CHECKED) <> 0

				$l_SortSense[1] = False
				$ProcessList 	= ProcessList()
				$ProcessCount 	= ListProcesses($PL_c_L_ProcessList, $ProcessList, 1, $g_CurrentSession, $g_ProcNameFilter, $g_Processtype)
				GUICtrlSetData($PL_c_L_TitleBar, " Select a process (" & $ProcessCount & ")")

			Case $UpdateListFromMask = True
				$UpdateListFromMask = False
				$g_ProcNameFilter 	= GUICtrlRead($PL_c_I_ProcFilter)
				$l_SortSense[1] = False
				$ProcessList 	= ProcessList()
				$ProcessCount 	= ListProcesses($PL_c_L_ProcessList, $ProcessList, 1, $g_CurrentSession, $g_ProcNameFilter, $g_Processtype)
				GUICtrlSetData($PL_c_L_TitleBar, " Select a process (" & $ProcessCount & ")")

		 EndSelect
	WEnd

	_GUIImageList_Destroy($PL_h_ImageList)

	If ($hParent) Then
		GUISetState(@SW_ENABLE, $hParent)
	EndIf

	GUISetState(@SW_HIDE, $PL_h_GUI)

	$l_SortSense[1] = False

	Return $lPID

EndFunc   ;==>CreateProcessList

Func ProcessListCleanUp()

	If (NOT $PL_h_GUI) Then
		Return
	EndIf

	_WinAPI_RemoveWindowSubclass(GUICtrlGetHandle($PL_c_L_ProcessList), $PL_ph_LV_SubclassProc, 2)
	DllCallbackFree($PL_h_LV_SubclassProc)

	GUIDelete($PL_h_GUI)

EndFunc   ;==>ProcessListCleanUp