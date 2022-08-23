#pragma once

#include <Windows.h>
#include <fstream>
#include <Psapi.h>
#include <vector>
#include <strsafe.h>

#pragma comment(lib, "Psapi.lib")

#ifdef _WIN64
#define FILENAME L"\\SWHEX64.txt"
#else
#define FILENAME L"\\SWHEX86.txt"
#endif

#define SWHEX_ERR_SUCCESS			0x00000000
#define SWHEX_ERR_INVALID_PATH		0x30000001
#define SWHEX_ERR_CANT_OPEN_FILE	0x30000002
#define SWHEX_ERR_EMPTY_FILE		0x30000003
#define SWHEX_ERR_INVALID_INFO		0x30000004
#define SWHEX_ERR_ENUM_WINDOWS_FAIL 0x30000005
#define SWHEX_ERR_NO_WINDOWS		0x30000006

struct HookData
{
	HHOOK	m_hHook;
	HWND	m_hWnd;
};

struct EnumWindowsCallback_Data
{
	std::vector<HookData>	m_HookData;
	DWORD					m_PID		= 0;
	HOOKPROC				m_pHook		= nullptr;
	HINSTANCE				m_hModule	= NULL;
};