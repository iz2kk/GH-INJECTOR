#include-once

#include <Array.au3>
#include <ColorConstants.au3>
#include <ComboConstants.au3>
#include <CustomPopUpMenu.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <FontConstants.au3>
#include <GUIComboBox.au3>
#include <GUIConstantsEx.au3>
#include <GUIImageList.au3>
#include <GUIListView.au3>
#include <GUIMenu.au3>
#include <GUIScrollBars.au3>
#include <GUIToolTip.au3>
#include <Inet.au3>
#include <InetConstants.au3>
#include <Process.au3>
#include <StaticConstants.au3>
#include <String.au3>
#include <WinAPI.au3>
#include <WinAPIEx.au3>
#include <WinAPIvkeysConstants.au3>
#include <WindowsConstants.au3>
#include <Zip.au3>

#Region Global Definitions

Global Const 	$g_CurrentVersion 		= "3.3"
Global 			$g_NewestVersion 		= ""
Global Const 	$g_ConfigPath 			= @ScriptDir & "\GH Injector Config.ini"
Global Const 	$g_LogPath				= @ScriptDir & "\GH_Inj_Log.txt"
Global			$g_RunNative			= True
Global			$g_InjectionDll_Name	= ""
Global			$g_hInjectionDll 		= 0

Global $g_Processname 			= "Broihon.exe"
Global $g_ProcessnameList		= "Broihon.exe"
Global $g_PID					= 1337
Global $g_ProcessByName			= True
Global $g_InjectionDelay		= 0
Global $g_LastDirectory			= @DesktopDir & "\"
Global $g_AutoInjection 		= False
Global $g_CloseAfterInjection 	= False
Global $g_LaunchMethod			= 0
Global $g_InjectionMethod		= 0
Global $g_InjectionFlags		= 0
Global $g_IgnoreUpdates			= False
Global $g_ProcNameFilter		= ""
Global $g_ToolTipsOn			= True
Global $g_CurrentSession		= True
Global $g_MainGUI_X 			= 100
Global $g_MainGUI_Y				= 100
Global $g_hDllList				= 0
Global $g_DarkThemeEnabled		= True
Global $g_Processtype			= 0

Global Const $INJ_ERASE_HEADER			= 0x0001
Global Const $INJ_FAKE_HEADER			= 0x0002
Global Const $INJ_UNLINK_FROM_PEB		= 0x0004
Global Const $INJ_SHIFT_MODULE			= 0x0008
Global Const $INJ_CLEAN_DATA_DIR		= 0x0010
Global Const $INJ_THREAD_CREATE_CLOAKED	= 0x0020
Global Const $INJ_SCRAMBLE_DLL_NAME 	= 0x0040
Global Const $INJ_LOAD_DLL_COPY 		= 0x0080
Global Const $INJ_HIJACK_HANDLE			= 0x0100

Global Const $GUI_EXIT  		= 0
Global Const $GUI_RETURN 		= 1
Global Const $GUI_RESET 		= 2
Global Const $GUI_INJECT		= 3
Global Const $GUI_UPDATE		= 4
Global Const $GUI_FORCE_UPDATE 	= 5

Global Const $C_GUI[2] = [0xF0F0F0, 0x555555]
Global Const $C_GUI_Ctrl_Button[2] 		= [0xE0E0E0, 	0x777777]
Global Const $C_GUI_Ctrl_Label[2] 		= [$C_GUI[0], 	$C_GUI[1]]
Global Const $C_GUI_Ctrl_Radio[2] 		= [$C_GUI[0], 	$C_GUI[1]]
Global Const $C_GUI_Ctrl_Combo[2] 		= [$C_GUI[0], 	$C_GUI[1]]
Global Const $C_GUI_Ctrl_Input[2] 		= [$C_GUI[0], 	$C_GUI[1]]
Global Const $C_GUI_Ctrl_Checkbox[2]	= [$C_GUI[0], 	$C_GUI[1]]
Global Const $C_GUI_Ctrl_Listview[2]	= [$C_GUI[0], 	0x444444]
Global Const $C_GUI_ProcIconList[2]		= [$C_GUI[0], 	$C_GUI[1]]
Global Const $C_GUI_Text[2] 			= [0x000000, 0xF4F4F4]
Global Const $C_GUI_Border[2]			= [0xB0B0B0, 0x666666]
Global Const $C_GUI_Version_Label		= [0xCCCCAA, 0x999999]
Global Const $C_GUI_Ctrl_PopUpMenuBgDef[2]	= [0xE0E0E0, 0x666666]
Global Const $C_GUI_Ctrl_PopUpMenuBgHov[2]	= [0xA0FFFF, 0x808080]
Global Const $C_GUI_Ctrl_PopUpMenuTxDef[2]	= [0x000000, 0xFFFFFF]
Global Const $C_GUI_Ctrl_PopUpMenuTxHov[2]	= [0x000000, 0xFFFFFF]
Global $G_HBRUSH_SuperDark		= 0
Global $G_HBRUSH_Dark			= 0
Global $G_HBRUSH_SemiDark		= 0
Global $G_HBRUSH_Light			= 0
Global $G_HFONT_LV_Font			= 0

Global Const $g_tagShort = "SHORT short;"
Global $g_ShortStruct = 0

Global $g_kernel32_dll = 0

#EndRegion

;===================================================================================================
; Function........:  MsgErr($Title, $Text, $hParent = 0)
;
; Description.....:  Wrapper function to call MsgBox with $MB_ICONERROR and 0 as timeout.
;
; Parameter(s)....:  $Title 	- The title of the message box.
;					 $Text		- The text to display.
;					 $hParent	- A handle to the parent window (optional).
;
; Return value(s).:	 Returned value of MsgBox.
;===================================================================================================

Func MsgErr($Title, $Text, $hParent = 0)
	Return MsgBox($MB_ICONERROR, $Title, $Text, 0, $hParent)
EndFunc