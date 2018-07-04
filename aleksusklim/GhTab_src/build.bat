for %%i in (*.rc) do brcc32 -r %%i
for %%i in (*.dpr) do dcc32 -U.\shl\ %%i
pause
del *.res
