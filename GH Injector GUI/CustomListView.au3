#include <Include.au3>

Dim $CLV_C_Listview[1] = [0]
Dim $CLV_H_Listview[1] = [0]
Dim $CLV_H_Listview_Header[1] = [0]
Dim $CLV_H_Listview_Header[1] = [0]

Dim $CLV_Color[1][5] = [[0, 0, 0, 0, 0]]

$CLV_Comctl32_DLL = 0
$CLV_hSubclassProc = 0
$CLV_pSubclassProc = 0

Func CLV_SubclassProc($hWnd, $uMsg, $wParam, $lParam, $iID, $pData)



	Return DllCall($h_Comctl32_DLL, "LRESULT", "DefSubclassProc", "HWND", $hWnd, "UINT", $uMsg, "WPARAM", $wParam, "LPARAM", $lParam)[0]

EndFunc

Func CreateListView($hOwner, $x, $y, $Width, $Height, $HeaderText, $ColWidth, $Colors, $Style = -1, $StyleEx = -1)

	If (NOT $CLV_Comctl32_DLL) Then
		$CLV_Comctl32_DLL = DllOpen("Comctl32.dll")
	EndIf

	If (NOT $CLV_pSubclassProc) Then
		$CLV_hSubclassProc = DllCallbackRegister("CLV_SubclassProc", "LRESULT", "HWND;UINT;WPARAM;LPARAM;UINT_PTR;DWORD_PTR")
		$CLV_pSubclassProc = DllCallbackGetPtr($CLV_hSubclassProc)
	EndIf

	$aSize = UBound($CLV_C_Listview)
	$index = -1

	For $i = 0 To $aSize - 1 Step 1
		If (NOT $CLV_C_Listview[$i]) Then
			$index = $i
			ExitLoop
		EndIf
	Next

	If ($index = -1) Then
		ReDim $CLV_C_Listview[UBound($CLV_C_Listview) + 1]
		ReDim $CLV_H_Listview[UBound($CLV_C_Listview) + 1]
		ReDim $CLV_H_Listview_Header[UBound($CLV_H_Listview_Header) + 1]
		ReDim $CLV_Color[UBound($CLV_Color) + 1][5]

		$index = UBound($CLV_C_Listview) - 1
	EndIf

	$cRet = GUICtrlCreateListView($HeaderText, $x, $y, $Width, $Height, $Style, $StyleEx)


EndFunc

Func DeleteListView($cListView)

	GUICtrlDelete($cListView)

	For $i = UBound($CLV_C_Listview) - 1 Step 1
		If ($CLV_C_Listview[$i] = $cListView) Then
			$CLV_C_Listview[$i] = 0
			$CLV_H_Listview[$i] = 0
			$CLV_H_Listview_Header[$i] = 0
		EndIf
	Next

EndFunc

Func CLV_OnExit()

	DllCallbackFree($CLV_hSubclassProc)
	DllClose($CLV_Comctl32_DLL)

EndFunc