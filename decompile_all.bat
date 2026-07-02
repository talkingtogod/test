@echo off
mkdir decompiled 2>nul
for %%f in (bytecode_dump\*.luauc) do (
    echo Decompiling %%f...
    medal decompile "%%f" > "decompiled\%%~nf.luau" 2>&1
)
echo Done. Check the decompiled folder.
