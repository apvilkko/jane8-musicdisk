python .\tools\readmod.py D:\Audio\Modules\new\jane8-0002_test.it intermediate/0002.bin
C:\apps\vasm\vasm6502_oldstyle_win32.exe .\src\c64\j8md.asm -chklabels -L "build\out.txt" -Fbin -o "out\j8md.prg"
if not "%errorlevel%"=="0" goto fail
C:\apps\GTK3VICE-3.5-win64\bin\x64sc.exe -autostartprgmode 1 .\out\j8md.prg
REM c:\apps\c64debugger\C64Debugger.exe .\out\j8md.prg
:fail
