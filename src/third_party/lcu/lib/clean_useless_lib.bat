@echo off &title clean_lib &pushd %~dp0 &color 0A

for /r %%i in (*_demo) do @del "%%i"
for /r %%i in (*.exe) do @del "%%i"
for /r %%i in (*.pdb) do @del "%%i"

@echo bye bye...
