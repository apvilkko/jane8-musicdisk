@echo off
md build
md out
del out\j8md.nes
del build\j8md-%1.txt
%2\vasm\vasm6502_oldstyle_win32.exe src/%1/j8md.asm -chklabels -L "build\j8md-%1.txt" -DBuildNES=1 -Fbin -o "out\j8md.nes"
if not "%errorlevel%"=="0" goto fail
dir out
rem %2\nosnes\NO$NES.exe  "%cd%\out\j8md.nes"
%2\nestopia\nestopia.exe  "%cd%\out\j8md.nes"
exit
:fail
