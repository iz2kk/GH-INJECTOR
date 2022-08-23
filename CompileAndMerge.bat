rd "GH Injector" /q /s
mkdir "GH Injector"

"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2Exe.exe" /in ".\GH Injector GUI\Main.au3" /out ".\GH Injector\GH Injector.exe" /icon ".\GH Injector GUI\GH Icon.ico" /x86
"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2Exe.exe" /in ".\GH Injector GUI\Injector.au3" /out ".\GH Injector GUI\GH Injector - x86.exe" /icon ".\GH Injector GUI\GH Icon.ico" /x86
"C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2Exe.exe" /in ".\GH Injector GUI\Injector.au3" /out ".\GH Injector GUI\GH Injector - x64.exe" /icon ".\GH Injector GUI\GH Icon.ico" /x64

copy "GH Injector GUI\GH Injector - x64.exe" "GH Injector" /y
copy "GH Injector GUI\GH Injector - x86.exe" "GH Injector" /y
copy "GH Injector GUI\GH Injector.exe" "GH Injector" /y

copy "GH Injector Library\Release\x64\GH Injector - x64.dll" "GH Injector" /y
copy "GH Injector Library\Release\x86\GH Injector - x86.dll" "GH Injector" /y
copy "GH Injector Library\Release\x64\GH Injector SWHEX - x64.exe" "GH Injector" /y
copy "GH Injector Library\Release\x86\GH Injector SWHEX - x86.exe" "GH Injector" /y