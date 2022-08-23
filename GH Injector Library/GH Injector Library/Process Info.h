#pragma once

#include "Tools.h"

//Wrapper class which relies on information from NtQuerySystemInformation and NtQueryInformationProcess

//Used to enumerate threads, retrieve PEBs, etc...

//Honestly, too lazy to document

class ProcessInfo
{
	SYSTEM_PROCESS_INFORMATION	* m_pCurrentProcess = nullptr;
	SYSTEM_PROCESS_INFORMATION	* m_pFirstProcess	= nullptr;
	SYSTEM_THREAD_INFORMATION	* m_pCurrentThread	= nullptr;

	ULONG m_BufferSize = 0;

	HANDLE m_hCurrentProcess = nullptr;

	f_NtQueryInformationProcess m_pNtQueryInformationProcess	= nullptr;
	f_NtQuerySystemInformation	m_pNtQuerySystemInformation		= nullptr;

	PEB						* GetPEB_Native();
	LDR_DATA_TABLE_ENTRY	* GetLdrEntry_Native(HINSTANCE hMod);

public:

	ProcessInfo();
	~ProcessInfo();

	bool SetProcess(HANDLE hTargetProc);
	bool SetThread(DWORD TID);
	bool NextThread();

	bool RefreshInformation();

	PEB						* GetPEB();
	LDR_DATA_TABLE_ENTRY	* GetLdrEntry(HINSTANCE hMod);

	DWORD GetPID();

	bool IsNative();

	void * GetEntrypoint();

	DWORD GetTID();
	DWORD GetThreadId();
	bool GetThreadState(THREAD_STATE & state, KWAIT_REASON & reason);
	bool GetThreadStartAddress(void * & start_address);

	const SYSTEM_PROCESS_INFORMATION	* GetProcessInfo();
	const SYSTEM_THREAD_INFORMATION		* GetThreadInfo();

#ifdef _WIN64

	PEB32					* GetPEB_WOW64();
	LDR_DATA_TABLE_ENTRY32	* GetLdrEntry_WOW64(HINSTANCE hMod);

#endif
};