@echo off
md build
md out
del out\j8md.nes
del build\j8md-%1.txt
c:\apps\vasm\vasm6502_oldstyle_win32.exe src/%1/j8md.asm -chklabels -L "build\j8md-%1.txt" -DBuildNES=1 -Fbin -o "out\j8md.nes"
dir out
if not "%errorlevel%"=="0" goto fail
c:\apps\nestopia\nestopia.exe  out/j8md.nes
exit
:fail
