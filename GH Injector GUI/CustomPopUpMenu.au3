;FUNCTION LIST IN FILE ORDER:

;===================================================================================================
; Function........:  _PopUpMenu_Create($hParent, $Width, $ItemHeight = 23, $bBorder = False)
;
; Description.....:  Creates a new popup menu which you then can add items to.
;
; Parameter(s)....:  $hParent		- A handle (HWND) to the parent window. This value can be NULL.
;					 $Width			- The width of the popup menu.
;					 $ItemHeight	- The height of the items of the menu. The default height is
;										23 pixels.
;					 $bBorder		- If true a thin border around the menu is created.
;
; Return Value(s).:  On Success - A handle (HWND) to the popup menu.
;                    On Failure - 0.
;===================================================================================================
; Function........:  _PopUpMenu_Delete($hMenu)
;
; Description.....:  Deletes a popup menu and frees the ressources. Call this function when the
;						menu isn't needed anymore.
;
; Parameter(s)....:  $hMenu		- A handle (HWND) to the menu.
;===================================================================================================
; Function........:  _PopUpMenu_AddOption($hMenu, $Text, $bEnabled = True,
;						$BackgroundColor_Default = 0xF2F2F2, $BackgroundColor_Hover = 0xA0FFFF,
;						$BackgroundColor_HoverDisabled = 0xE0E0E0, $TextColor_Default = 0x000000,
;						$TextColor_Hover = 0x000000, $TextColor_Disabled = 0x888888,
;						$IconFilepath = 0, $IconIndex = -1))
;
; Description.....:  Adds an item to a popup menu created with _PopUpMenu_Create.
;
; Parameter(s)....:  $hMenu							- A handle (HWND) to the popup menu.
;					 $Text							- The text to be displayed.
;					 $bEnabled						- If true the item is enabled, if false disabled.
;					 $BackgroundColor_Default		- The default background color of the item.
;					 $BackgroundColor_Hover			- The background color when the mouse is
;														hovering above the item.
;					 $BackgroundColor_HoverDisabled - The background color when the mouse is
;														hovering above the disabled item.
;					 $TextColor_Default				- The default color to display the text of the
;														item (by default the color is black).
;					 $TextColor_Hover				- The color of the text when the mouse is
;														hovering above the item (by default black).
;					 $TextColor_Disabled			- The color of the text when the item is disabled.
;					 $IconFilepath					- A path to a file containing one or multiple
;														icons which can be displayed on the left
;														 side of the item (optional).
;					 $IconIndex						- If the file specified by $IconFilepath
;														contains multiple items set this parameter
;														to the index of the desired item (default
;														index is 0 which is the first icon in
;														the file).
;
; Return Value(s).:  On Success - The id of the option.
;                    On Failure - -1.
;===================================================================================================
; Function........:  _PopUpMenu_Track($hMenu)
;
; Description.....:  Opens the specified popup menu and tracks the user input until the menu is
;						forced to close or an item was clicked.
;
; Parameter(s)....:  $hMenu		- A handle (HWND) to the popup menu.
;
; Return Value(s).:  On Success - The id of the option that was clicked. This id matches one of the
;									ids returned by _PopUpMenu_AddOption.
;                    On Failure - -1 (this means that the user didn't select any of the options).
;===================================================================================================

#include <Array.au3>
#include <GUIConstants.au3>
#include <GUIImageList.au3>
#include <WinAPI.au3>

#region INTERNAL USE ONLY - DON'T CHANGE OR I'LL FUCK YOU UP

Global $__g_PopUpMenu_Count = -1

Global Const $__g_PopUpMenu_ID_MAX 	= 12
Global Const $__g_PopUpMenu_OPT_MAX = 128

Global Const $__g_PopUpMenu_BorderOffset = 2

Global $__g_PopUpMenu_InternalData[1][$__g_PopUpMenu_OPT_MAX][$__g_PopUpMenu_ID_MAX]

;general menu info stored in $__g_PopUpMenu_InternalData[$menu_id][0][$n] with $n being on of the following values
Global Const $__g_PopUpMenu_ID_Menu_OptionCount			= 0
Global Const $__g_PopUpMenu_ID_Menu_Width				= 1
Global Const $__g_PopUpMenu_ID_Menu_ItemHeight			= 2
Global Const $__g_PopUpMenu_ID_Menu_ImageListHandle		= 3
Global Const $__g_PopUpMenu_ID_Menu_SubMenuLevel		= 4
Global Const $__g_PopUpMenu_ID_Menu_ParentMenuHandle	= 5
Global Const $__g_PopUpMenu_ID_Menu_ParentOptionID		= 6
Global Const $__g_PopUpMenu_ID_Menu_HasBorder			= 7

;option info stored in $__g_PopUpMenu_InternalData[$menu_id][$option_index][$n] with $n being on of the following values and $option_index being greater than 0
Global Const $__g_PopUpMenu_ID_OptionId						= 0
Global Const $__g_PopUpMenu_ID_ColorBackgroundDefault 		= 1
Global Const $__g_PopUpMenu_ID_ColorBackgroundHover			= 2
Global Const $__g_PopUpMenu_ID_ColorBackgroundHoverDisabled	= 3
Global Const $__g_PopUpMenu_ID_ColorTextDefault				= 4
Global Const $__g_PopUpMenu_ID_ColorTextHover				= 5
Global Const $__g_PopUpMenu_ID_ColorTextDisabled			= 6
Global Const $__g_PopUpMenu_ID_BackgroundLabel				= 7
Global Const $__g_PopUpMenu_ID_TextLabel					= 8
Global Const $__g_PopUpMenu_ID_Info							= 9
Global Const $__g_PopUpMenu_ID_SubMenuHandle				= 10
Global Const $__g_PopUpMenu_ID_SubMenuArrowLabel			= 11

Global Const $__g_PopUpMenu_Info_HasIcon 	= 0x00000001
Global Const $__g_PopUpMenu_Info_Enabled 	= 0x00000002
Global Const $__g_PopUpMenu_Info_HasSubmenu	= 0x00000004

#endregion

#region internal functions // INTERNAL USE ONLY

Func _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)

	$title_text = WinGetTitle($hMenu)
	If ($title_text = "") Then
		Return -1
	EndIf

	Return Number($title_text)

EndFunc

Func _PopUpMenu_Internal_OptionId_To_OptionIndex($MenuID, $OptionID)

	$option_count = $__g_PopUpMenu_InternalData[$MenuID][0][$__g_PopUpMenu_ID_Menu_OptionCount]
	$option_index = 0
	For $i = 1 To $option_count Step 1
		If ($__g_PopUpMenu_InternalData[$MenuID][$i][$__g_PopUpMenu_ID_OptionId] = $OptionID) Then
			$option_index = $i
			ExitLoop
		EndIf
	Next

	Return $option_index

EndFunc

Func _PopUpMenu_Internal_Generate_New_OptionId($MenuID)

	$option_count = $__g_PopUpMenu_InternalData[$MenuID][0][$__g_PopUpMenu_ID_Menu_OptionCount]
	$lowest_id = 1

	If ($option_count = 0) Then
		Return 0
	EndIf


	While (True)
		$bFoundInArray = False
		For $i = 1 To $option_count Step 1
			If ($__g_PopUpMenu_InternalData[$MenuID][$i][$__g_PopUpMenu_ID_OptionId] = $lowest_id) Then
				$bFoundInArray = True
				$lowest_id += 1
				ExitLoop
			EndIf
		Next

		If (NOT $bFoundInArray) Then
			ExitLoop
		EndIf
	WEnd

	Return $lowest_id

EndFunc

#EndRegion

Func _PopUpMenu_Create($hParent, $Width, $ItemHeight = 23, $bBorder = False)

	$_width		= $Width
	$_height 	= $ItemHeight
	$_ws_border = 0

	If ($bBorder = True) Then
		$_width 	+= ($__g_PopUpMenu_BorderOffset * 2)
		$_height 	+= ($__g_PopUpMenu_BorderOffset * 2)
		$_ws_border = $WS_BORDER
	EndIf

	$hNewMenu = GUICreate($__g_PopUpMenu_Count + 1, $_width, $_height, Default, Default, BitOR($_ws_border, $WS_POPUP), Default, $hParent)
	If (NOT $hNewMenu) Then
		Return 0
	EndIf

	$__g_PopUpMenu_Count += 1

	ReDim $__g_PopUpMenu_InternalData[$__g_PopUpMenu_Count + 1][128][$__g_PopUpMenu_ID_MAX]

	$__g_PopUpMenu_InternalData[$__g_PopUpMenu_Count][0][$__g_PopUpMenu_ID_Menu_Width] 		= $Width
	$__g_PopUpMenu_InternalData[$__g_PopUpMenu_Count][0][$__g_PopUpMenu_ID_Menu_ItemHeight] = $ItemHeight

	If ($bBorder = True) Then
		$__g_PopUpMenu_InternalData[$__g_PopUpMenu_Count][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True
	Else
		$__g_PopUpMenu_InternalData[$__g_PopUpMenu_Count][0][$__g_PopUpMenu_ID_Menu_HasBorder] = False
	EndIf

	Return $hNewMenu

EndFunc

Func _PopUpMenu_Delete($hMenu)

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id < 0) Then
		Return -1
	EndIf

	$parent_menu_handle = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ParentMenuHandle]
	If ($parent_menu_handle) Then
		$parent_menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($parent_menu_handle)
		If ($menu_id < 0) Then
			Return -1
		EndIf

		$parent_option_id = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ParentOptionID]
		$parent_option_index = _PopUpMenu_Internal_OptionId_To_OptionIndex($parent_menu_id, $parent_option_id)

		$old_info = $__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_Info]
		$__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_Info] = BitXOR($old_info, $__g_PopUpMenu_Info_HasSubmenu)

		$__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_SubMenuHandle] = 0

		$h_parent_option_arrow_text_label = $__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_SubMenuArrowLabel]
		GUICtrlSetData($h_parent_option_arrow_text_label, " ")
	EndIf

	$hImageList = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ImageListHandle]
	If ($hImageList) Then
		_GUIImageList_Destroy($hImageList)
	EndIf

	$option_count = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount]
	For $i = 1 To $option_count Step 1
		$submenu_handle = $__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_SubMenuHandle]
		If ($submenu_handle) Then
			_PopUpMenu_Delete($submenu_handle)
		EndIf
	Next

	GUIDelete($hMenu)
	_ArrayDelete($__g_PopUpMenu_InternalData, $menu_id)

	$__g_PopUpMenu_Count -= 1

EndFunc

Func _PopUpMenu_CreateSubMenu($hParentMenu, $ParentOptionId, $Width, $ItemHeight = 23)

	$parent_menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hParentMenu)
	If ($parent_menu_id < 0) Then
		Return -1
	EndIf

	$parent_option_index = _PopUpMenu_Internal_OptionId_To_OptionIndex($parent_menu_id, $ParentOptionId)
	If (NOT $parent_option_index) Then
		Return 0
	EndIf

	$old_info = $__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_Info]
	If (BitAND($old_info, $__g_PopUpMenu_Info_HasSubmenu)) Then
		Return 0
	EndIf

	$hNewSubMenu = _PopUpMenu_Create($hParentMenu, $Width, $ItemHeight)
	If (NOT $hNewSubMenu) Then
		Return 0
	EndIf

	$submenu_title_text = WinGetTitle($hNewSubMenu)
	If ($submenu_title_text = "") Then
		GUIDelete($hNewSubMenu)
		$__g_PopUpMenu_Count -= 1
		Return 0
	EndIf

	$submenu_id = Number($submenu_title_text)

	$parent_submenu_level = $__g_PopUpMenu_InternalData[$parent_menu_id][0][$__g_PopUpMenu_ID_Menu_SubMenuLevel]

	$__g_PopUpMenu_InternalData[$submenu_id][0][$__g_PopUpMenu_ID_Menu_ParentMenuHandle] 	= $hParentMenu
	$__g_PopUpMenu_InternalData[$submenu_id][0][$__g_PopUpMenu_ID_Menu_ParentOptionID]		= $ParentOptionId
	$__g_PopUpMenu_InternalData[$submenu_id][0][$__g_PopUpMenu_ID_Menu_SubMenuLevel]		= $parent_submenu_level + 1

	$__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_Info] 			= BitOR($old_info, $__g_PopUpMenu_Info_HasSubmenu)
	$__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_SubMenuHandle] = $hNewSubMenu

	$h_parent_option_arrow_text_label = $__g_PopUpMenu_InternalData[$parent_menu_id][$parent_option_index][$__g_PopUpMenu_ID_SubMenuArrowLabel]
	GUICtrlSetData($h_parent_option_arrow_text_label, "❯")

	Return $hNewSubMenu

EndFunc

Func _PopUpMenu_GetItemHeight($hMenu)

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id < 0) Then
		Return -1
	EndIf

	Return $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ItemHeight]

EndFunc

Func _PopUpMenu_GetOptionCount($hMenu)

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id < 0) Then
		Return -1
	EndIf

	Return $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount]

EndFunc

Func _PopUpMenu_AddOption($hMenu, $Text, $bEnabled = True, $BackgroundColor_Default = 0xF2F2F2, $BackgroundColor_Hover = 0xA0FFFF, $BackgroundColor_HoverDisabled = 0xE0E0E0, _
	$TextColor_Default = 0x000000, $TextColor_Hover = 0x000000, $TextColor_Disabled = 0x888888, $IconFilepath = 0, $IconIndex = -1)

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id < 0) Then
		Return -1
	EndIf

	$option_count 	= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount]
	$MenuWidth 		= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_Width]
	$ItemHeight		= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ItemHeight]

	If ($option_count = $__g_PopUpMenu_OPT_MAX) Then
		Return -1
	EndIf

	$option_index = $option_count + 1
	$option_id = _PopUpMenu_Internal_Generate_New_OptionId($menu_id)

	$MenuHeight	= $ItemHeight * ($option_count + 1)
	$y_offset = ($option_index - 1) * $ItemHeight
	$x_offset = 0
	If ($__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True) Then
		$MenuWidth += ($__g_PopUpMenu_BorderOffset * 2)
		$MenuHeight += ($__g_PopUpMenu_BorderOffset * 2)
		$y_offset += $__g_PopUpMenu_BorderOffset
		$x_offset = $__g_PopUpMenu_BorderOffset
		If ($option_index = 1) Then
			$y_offset = 0
		EndIf
	EndIf

	WinMove($hMenu, 0, 0, 0, $MenuWidth, $MenuHeight)

	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_OptionId] = $option_id

	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorBackgroundDefault] 			= $BackgroundColor_Default
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorBackgroundHover] 			= $BackgroundColor_Hover
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorBackgroundHoverDisabled] 	= $BackgroundColor_HoverDisabled
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorTextDefault] 				= $TextColor_Default
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorTextHover] 					= $TextColor_Hover
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorTextDisabled] 				= $TextColor_Disabled

	$h_old_gui = GUISwitch($hMenu)

	$background_label = 0
	If ($option_index = 1) Then
		$background_label = GUICtrlCreateLabel("", 0, 0, $MenuWidth, $ItemHeight + $__g_PopUpMenu_BorderOffset)
	Else
		$background_label = GUICtrlCreateLabel("", 0, $y_offset, $MenuWidth, $ItemHeight)
	EndIf
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_BackgroundLabel] = $background_label
	GUICtrlSetResizing($background_label, $GUI_DOCKALL)
	GUICtrlSetBkColor($background_label, $BackgroundColor_Default)

	$text_label = GUICtrlCreateLabel(" " & $Text, $ItemHeight + $x_offset, $y_offset, $MenuWidth - $ItemHeight, $ItemHeight, $SS_CENTERIMAGE)
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_TextLabel] = $text_label
	GUICtrlSetBkColor($text_label, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetResizing($text_label, $GUI_DOCKALL)
	If ($bEnabled = True) Then
		GUICtrlSetColor($text_label, $TextColor_Default)
		$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info] = $__g_PopUpMenu_Info_Enabled
	Else
		GUICtrlSetColor($text_label, $TextColor_Disabled)
		$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info] = 0
	EndIf
#cs
	$submenu_arrow_label = GUICtrlCreateLabel(" ", $MenuWidth - $ItemHeight + $x_offset, $y_offset, $ItemHeight, $ItemHeight, $SS_CENTERIMAGE)
	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_SubMenuArrowLabel] = $submenu_arrow_label
	GUICtrlSetBkColor($submenu_arrow_label, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetResizing($submenu_arrow_label, $GUI_DOCKALL)
#ce
	GUISwitch($h_old_gui)

	$hImageList = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ImageListHandle]
	If ($option_index = 1) Then
		$hImageList = _GUIImageList_Create($ItemHeight - 2, $ItemHeight - 2, 5, 1)
		$__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ImageListHandle] = $hImageList
	EndIf

	If (FileExists($IconFilepath)) Then
		If (_GUIImageList_AddIcon($hImageList, $IconFilepath, $IconIndex, True) = -1) Then
			_GUIImageList_AddIcon($hImageList, @SystemDir & "\shell32.dll", 131, True)
		EndIf
		$info = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info]
		$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info] = BitOR($info, $__g_PopUpMenu_Info_HasIcon)
	Else
		$hDC = _WinAPI_GetDC($hMenu)
		$dummy_bmp = _WinAPI_CreateSolidBitmap($hMenu, 0xFFFFFF, 16, 16)
		_GUIImageList_Add($hImageList, $dummy_bmp)
		_WinAPI_DeleteObject($dummy_bmp)
		_WinAPI_ReleaseDC($hMenu, $hDC)
	EndIf

	$__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount] += 1

	Return $option_id

EndFunc

Func _PopUpMenu_DeleteOption($hMenu, $OptionId)

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id < 0) Then
		Return -1
	EndIf

	$ItemHeight	= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ItemHeight]
	$MenuWidth	= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_Width]

	$option_count = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount]
	$option_index = _PopUpMenu_Internal_OptionId_To_OptionIndex($menu_id, $OptionId)
	If (NOT $option_index) Then
		Return -1
	EndIf

	$hImageList = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ImageListHandle]
	If ($hImageList) Then
		_GUIImageList_Remove($hImageList, $option_index - 1)
	EndIf

	For $i = $option_index To $option_count - 1 Step 1
		For $j = 0 To $__g_PopUpMenu_ID_MAX - 1 Step 1
			$__g_PopUpMenu_InternalData[$menu_id][$i][$j] = $__g_PopUpMenu_InternalData[$menu_id][$i + 1][$j]
		Next

		$y_offset = ($i - 1) * $ItemHeight
		$x_offset = 0
		If ($__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True) Then
			$y_offset += $__g_PopUpMenu_BorderOffset
			$x_offset = $__g_PopUpMenu_BorderOffset
		EndIf
		GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_BackgroundLabel], $x_offset, $y_offset, $MenuWidth, $ItemHeight)
		GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_TextLabel], $ItemHeight + $x_offset, $y_offset, $MenuWidth - $ItemHeight, $ItemHeight)
	Next

	$option_count -= 1
	$__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount] = $option_count

	WinMove($hMenu, "", 0, 0, $MenuWidth, $option_count * $ItemHeight)

	If ($option_count = 0) Then
		If ($hImageList) Then
			_GUIImageList_Destroy($hImageList)
		EndIf
	EndIf

	Return $option_count

EndFunc

Func _PopUpMenu_OptionGetIndex($hMenu, $OptionId)

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id < 0) Then
		Return -1
	EndIf

	Return _PopUpMenu_Internal_OptionId_To_OptionIndex($menu_id, $OptionId)

EndFunc

Func _PopUpMenu_OptionSetIndex($hMenu, $OptionId, $NewIndex)

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id < 0) Then
		Return -1
	EndIf

	$ItemHeight	= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ItemHeight]
	$MenuWidth	= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_Width]

	$option_count = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount]
	If ($option_count < $NewIndex) Then
		$NewIndex = $option_count
	ElseIf ($NewIndex < 1) Then
		$NewIndex = 1
	EndIf

	$option_index = _PopUpMenu_Internal_OptionId_To_OptionIndex($menu_id, $OptionId)
	If (NOT $option_index) Then
		Return False
	ElseIf ($option_index = $NewIndex) Then
		Return True
	EndIf

	Local $data_saved[$__g_PopUpMenu_ID_MAX]
	For $i = 0 To $__g_PopUpMenu_ID_MAX - 1 Step 1
		$data_saved[$i] = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$i]
	Next

	If ($option_index < $NewIndex) Then
		For $i = $option_index To $NewIndex - 1 Step 1
			For $j = 0 To $__g_PopUpMenu_ID_MAX - 1 Step 1
				$__g_PopUpMenu_InternalData[$menu_id][$i][$j] = $__g_PopUpMenu_InternalData[$menu_id][$i + 1][$j]
			Next

			$y_offset = ($i - 1) * $ItemHeight
			$x_offset = 0
			If ($__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True) Then
				$y_offset += $__g_PopUpMenu_BorderOffset
				$x_offset = $__g_PopUpMenu_BorderOffset
			EndIf
			GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_BackgroundLabel], $x_offset, $y_offset, $MenuWidth, $ItemHeight)
			GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_TextLabel], $ItemHeight + $x_offset, $y_offset, $MenuWidth - $ItemHeight, $ItemHeight)
		Next
	Else
		For $i = $option_index To $NewIndex + 1 Step -1
			For $j = 0 To $__g_PopUpMenu_ID_MAX - 1 Step 1
				$__g_PopUpMenu_InternalData[$menu_id][$i][$j] = $__g_PopUpMenu_InternalData[$menu_id][$i - 1][$j]
			Next

			$y_offset = ($i - 1) * $ItemHeight
			$x_offset = 0
			If ($__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True) Then
				$y_offset += $__g_PopUpMenu_BorderOffset
				$x_offset = $__g_PopUpMenu_BorderOffset
			EndIf
			GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_BackgroundLabel], $x_offset, $y_offset, $MenuWidth, $ItemHeight)
			GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_TextLabel], $ItemHeight + $x_offset, $y_offset, $MenuWidth - $ItemHeight, $ItemHeight)
		Next
	EndIf

	For $i = 0 To $__g_PopUpMenu_ID_MAX - 1 Step 1
		$__g_PopUpMenu_InternalData[$menu_id][$NewIndex][$i] = $data_saved[$i]
	Next

	$y_offset = ($NewIndex - 1) * $ItemHeight
	$x_offset = 0
	If ($__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True) Then
		$y_offset += $__g_PopUpMenu_BorderOffset
		$x_offset = $__g_PopUpMenu_BorderOffset
	EndIf
	GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$NewIndex][$__g_PopUpMenu_ID_BackgroundLabel], $x_offset, $y_offset, $MenuWidth, $ItemHeight)
	GUICtrlSetPos($__g_PopUpMenu_InternalData[$menu_id][$NewIndex][$__g_PopUpMenu_ID_TextLabel], $ItemHeight + $x_offset, $y_offset, $MenuWidth - $ItemHeight, $ItemHeight)

	Return True

EndFunc

Func _PopUpMenu_OptionGetState($hMenu, $OptionId)

	$title_text = WinGetTitle($hMenu)
	If ($title_text = "") Then
		Return False
	EndIf

	$menu_id = Number(WinGetTitle($hMenu))

	$option_index = _PopUpMenu_Internal_OptionId_To_OptionIndex($menu_id, $OptionId)
	If (NOT $option_index) Then
		Return False
	EndIf


	If (BitAND($__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info], $__g_PopUpMenu_Info_Enabled)) Then
		Return True
	EndIf

	Return False

EndFunc

Func _PopUpMenu_OptionSetState($hMenu, $OptionId, $bEnable = True)

	$title_text = WinGetTitle($hMenu)
	If ($title_text = "") Then
		Return False
	EndIf

	$menu_id = Number(WinGetTitle($hMenu))

	$option_index = _PopUpMenu_Internal_OptionId_To_OptionIndex($menu_id, $OptionId)
	If (NOT $option_index) Then
		Return False
	EndIf

	$id_background 	= $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_BackgroundLabel]
	$id_text		= $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_TextLabel]
	$info 			= $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info]

	$info_res = BitAND($info, $__g_PopUpMenu_Info_Enabled)
	If ($info_res AND $bEnable OR NOT $info_res AND NOT $bEnable) Then
		Return True
	EndIf

	If ($bEnable) Then
		GUICtrlSetColor($id_text, $__g_PopUpMenu_InternalData[$menu_id][$OptionId][$__g_PopUpMenu_ID_ColorTextDefault])
		$info = BitOR($info, $__g_PopUpMenu_Info_Enabled)
	Else
		GUICtrlSetColor($id_text, $__g_PopUpMenu_InternalData[$menu_id][$OptionId][$__g_PopUpMenu_ID_ColorTextDisabled])
		$info = BitXOR($info, $__g_PopUpMenu_Info_Enabled)
	EndIf

	$__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info] = $info

	Return True

EndFunc

Func _PopUpMenu_Track($hMenu)

	Local $ret_val[2] = [0, 0]

	$menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($hMenu)
	If ($menu_id = -1) Then
		Return $ret_val
	EndIf

	$submenu_level = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_SubMenuLevel]
	ReDim $ret_val[$submenu_level + 2]
	$ret_val[0] = $submenu_level + 1
	$ret_val[$submenu_level + 1] = -1

	Local $pos[2] = [0, 0]
	$screen_width 		= _WinAPI_GetSystemMetrics($SM_CXVIRTUALSCREEN)
	$screen_height 		= _WinAPI_GetSystemMetrics($SM_CYVIRTUALSCREEN)
	Local $menu_window_info = WinGetPos($hMenu)

	If (NOT $submenu_level) Then
		Local $cursor_info 	= MouseGetPos()
		If (@error) Then
			Return $ret_val
		EndIf

		If ($cursor_info[0] + $menu_window_info[2] > $screen_width) Then
			$cursor_info[0] = $screen_width - $menu_window_info[2]
		EndIf
		If ($cursor_info[1] + $menu_window_info[3] > $screen_height) Then
			$cursor_info[1] = $screen_height - $menu_window_info[3]
		EndIf

		$pos[0] = $cursor_info[0]
		$pos[1] = $cursor_info[1]
	Else
		$parent_menu_handle = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ParentMenuHandle]
		$parent_option_id 	= $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ParentOptionID]

		Local $parent_menu_info = WinGetPos($parent_menu_handle)
		If (@error) Then
			Return $ret_val
		EndIf

		$parent_menu_id = _PopUpMenu_Internal_Menu_Handle_To_MenuId($parent_menu_handle)
		If ($parent_menu_id = -1) Then
			Return $ret_val
		EndIf

		$parent_menu_width 			= $parent_menu_info[2]
		$parent_menu_item_height 	= $__g_PopUpMenu_InternalData[$parent_menu_id][0][$__g_PopUpMenu_ID_Menu_ItemHeight]
		$parent_option_index 		= _PopUpMenu_Internal_OptionId_To_OptionIndex($parent_menu_info, $parent_option_id)

		$x_offset = $parent_menu_width
		$y_offset = ($parent_option_index - 1) * $parent_menu_item_height

		$parent_menu_info[0] += $x_offset
		$parent_menu_info[1] += $y_offset

		If ($parent_menu_info[0] + $menu_window_info[2] > $screen_width) Then
			$parent_menu_info[0] = $screen_width - $menu_window_info[2] - $parent_menu_width
		EndIf
		If ($parent_menu_info[1] + $menu_window_info[3] > $screen_height) Then
			$parent_menu_info[1] -= $menu_window_info[3] - $parent_menu_item_height
		EndIf

		$pos[0] = $parent_menu_info[0]
		$pos[1] = $parent_menu_info[1]
	EndIf

	WinMove($hMenu, "", $pos[0], $pos[1])

	$OptionCount = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_OptionCount]
	If (NOT $OptionCount) Then
		Return $ret_val
	EndIf

	$ItemHeight = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ItemHeight]

	GUISetState(@SW_SHOW, $hMenu)

	$x_offset = 0
	$y_offset = 0
	If ($__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True) Then
		$x_offset = $__g_PopUpMenu_BorderOffset
		$y_offset = $__g_PopUpMenu_BorderOffset
	EndIf

	$hDC = _WinAPI_GetDC($hMenu)
	$hImageList = $__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_ImageListHandle]
	For $i = 1 To $OptionCount Step 1
		If (BitAND($__g_PopUpMenu_InternalData[$menu_id][$i][$__g_PopUpMenu_ID_Info], $__g_PopUpMenu_Info_HasIcon)) Then
			_GUIImageList_Draw($hImageList, $i - 1, $hDC, 1 + $x_offset, ($i - 1) * $ItemHeight + 1 + $y_offset)
		EndIf
	Next

	While (True)

		Sleep(10)

		If (_WinAPI_GetForegroundWindow() <> $hMenu) Then
			ExitLoop
		EndIf

		Local $cursor_info = GUIGetCursorInfo($hMenu)
		If (@error) Then
			ContinueLoop
		EndIf

		$hover_id = $cursor_info[4]
		If (NOT $hover_id) Then
			ContinueLoop
		EndIf

		If ($__g_PopUpMenu_InternalData[$menu_id][0][$__g_PopUpMenu_ID_Menu_HasBorder] = True) Then
			;$cursor_info[1] -= $__g_PopUpMenu_BorderOffset
		EndIf

		$option_index = Int($cursor_info[1] / $ItemHeight) + 1
		$option_info = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info]

		$is_enabled 	= BitAND($option_info, $__g_PopUpMenu_Info_Enabled)
		$has_SubMenu 	= BitAND($option_info, $__g_PopUpMenu_Info_HasSubmenu)
		$has_icon 		= BitAND($option_info, $__g_PopUpMenu_Info_HasIcon)

		$hover_id_background 	= $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_BackgroundLabel]
		$hover_id_text		 	= $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_TextLabel]
		$hover_id_submenu_label = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_SubMenuArrowLabel]

		If ($is_enabled) Then
			$bk_color = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorBackgroundHover]
			GUICtrlSetBkColor($hover_id_background, $bk_color)
			$txt_color = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorTextHover]
			GUICtrlSetColor($hover_id_text, $txt_color)
		Else
			$bk_color = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorBackgroundHoverDisabled]
			GUICtrlSetBkColor($hover_id_background, $bk_color)
		EndIf

		If ($has_SubMenu) Then
			$txt_color = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorTextHover]
			GUICtrlSetColor($hover_id_submenu_label, $txt_color)
		EndIf

		If ($has_icon) Then
			_GUIImageList_Draw($hImageList, $option_index - 1, $hDC, 1 + $x_offset, ($option_index - 1) * $ItemHeight + 1 + $y_offset)
		EndIf

		$bClicked = False
		$bTimer = False
		$hTimer = 0
		While ($is_enabled AND $hover_id_text = $cursor_info[4] OR $hover_id_background = $cursor_info[4] OR ($has_SubMenu AND $hover_id_submenu_label = $cursor_info[4]))
			$cursor_info = GUIGetCursorInfo($hMenu)
			If (@error) Then
				ExitLoop
			EndIf
#cs
			If ($has_SubMenu) Then
				If (NOT $bTimer) Then
					$bTimer = True
					$hTimer = TimerInit()
				EndIf

				If (TimerDiff($hTimer) > 350) Then
					$ret_val = _PopUpMenu_Track($__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_SubMenuHandle])
					If ($ret_val[0]) Then
						$ret_val[$submenu_level + 1] = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_OptionId]
					EndIf
					ExitLoop
				EndIf

			EndIf
#ce
			If (NOT $bClicked AND $cursor_info[2] AND NOT $has_SubMenu) Then
				$bClicked = True
			EndIf
#cs
			ElseIf (NOT $bClicked AND $cursor_info[2] AND $has_SubMenu) Then
				$ret_val = _PopUpMenu_Track($__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_SubMenuHandle])
				If ($ret_val[0]) Then
					$ret_val[$submenu_level + 1] = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_OptionId]
				EndIf
				ExitLoop
			EndIf
#ce
			If (NOT $cursor_info[2] AND $bClicked) Then
				$ret_val[$submenu_level + 1] = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_OptionId]
				ExitLoop
			EndIf

			Sleep(10)
		WEnd

		If ($is_enabled) Then
			$bk_color = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorBackgroundDefault]
			GUICtrlSetBkColor($hover_id_background, $bk_color)
			$txt_color = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorTextDefault]
			GUICtrlSetColor($hover_id_text, $txt_color)
			If ($has_SubMenu) Then
				GUICtrlSetColor($hover_id_submenu_label, $txt_color)
			EndIf
		Else
			$bk_color = $__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_ColorBackgroundDefault]
			GUICtrlSetBkColor($hover_id_background, $bk_color)
		EndIf

		If (BitAND($__g_PopUpMenu_InternalData[$menu_id][$option_index][$__g_PopUpMenu_ID_Info], $__g_PopUpMenu_Info_HasIcon)) Then
			_GUIImageList_Draw($hImageList, $option_index - 1, $hDC, 1 + $x_offset, ($option_index - 1) * $ItemHeight + 1 + $y_offset)
		EndIf

		If ($ret_val[$submenu_level + 1] <> -1) Then
			ExitLoop
		EndIf

	WEnd

	GUISetState(@SW_HIDE, $hMenu)

	_WinAPI_ReleaseDC($hMenu, $hDC)

	Return $ret_val

EndFunc