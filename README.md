# GuidedHacking Injector
Fully Featured DLL Injector made by [Broihon](https://guidedhacking.com/members/broihon.49430/) for Guided Hacking

**This is our old v3.3 source code, the new v4.4+ repo is here: [Broihon - GH-Injector-Library](https://github.com/Broihon/GH-Injector-Library)**

Release Downloads: [Register & Download DLL Injector Here ](https://guidedhacking.com/resources/guided-hacking-dll-injector.4/)

![](https://i.gyazo.com/23b497942ade7bc6a13b2d7029567c6b.png)

**Injection Methods:**
* LoadLibrary
* LdrLoadDll Stub
* Manual Mapping

**Launch Methods:**
* NtCreateThreadEx
* Thread Hijacking
* SetWindowsHookEx
* QueueUserAPC

**Bug Reports:**

Post all bug reports & issues on the forum [here](https://guidedhacking.com/threads/guidedhacking-dll-injector.8417/)

**Requirements**

Windows 10 1809 or above

**Description**

* Compatible with both 32-bit and 64-bit programs
* Settings of the GUI are saved to a local ini file
* Processes can be selected by name or process ID and by the fancy process picker.

# GH Injector Library

Since GH Injector V3.0 the actual injector has been converted in to a library

To use it in your applications you can either use InjectA (ansi) or 
InjectW (unicode) which are the two functions exported by the "GH 
Injector - x86.dll" and "GH Injector - x64.dll".

These functions take a pointer to a INJECTIONDATAA/INJECTIONDATAW structure. For more the 
struct definition / enums / flags check "Injection.h".

How To Use GH Injector & Source Code Review: https://youtu.be/zhA9kSCY3Ec

# FAQ
* It's not a virus, it is packed with UPX and uses Autoit, according to most antivirus software that means it's a virus.
* It connects to the internet to check for updates


# How to Build from Source

Compile "GH Injector Library\GH Injector Library.sln" with these steps:
1. Open the project
2. Click "Build" in the menubar
3. Click "Batch Build"
4. Tick all 4 release builds (Configuration = Release)
5. Click "Build"
6. Done

Install AutoIt - It is Required to compile GUI - https://www.autoitscript.com/site/autoit/downloads/


Run CompileAndMerge.bat

It will compile the AutoIt files and merge all the required files into "GH Injector\".

To run the GH Injector simply open "GH Injector\GH Injector.exe".

# Credits

For the Manual Mapping a lot of credits go to [Joachim Bauch](https://www.joachim-bauch.de/tutorials/loading-a-dll-from-memory/).  I highly recommend you to go there and take a look if you're interested in Manual Mapping and the PE format itself.

The windows structures I use for the unlinking process are mostly inspired by [this site](https://sandsprite.com/CodeStuff/Understanding_the_Peb_Loader_Data_List.html) which is also a very interesting read.

I also want to credit Anton Bruckner and Dmitri Shostakovich because most of the time coding this I listened to their fantastic music which is probably one of the reasons why this took me way too long.
