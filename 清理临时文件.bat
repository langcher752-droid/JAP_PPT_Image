@echo off
chcp 65001 >nul
echo ========================================
echo 清理pip临时文件
echo ========================================
echo.
echo 正在清理pip临时文件...
echo.

REM 清理用户临时目录中的pip文件
set TEMP_DIR=%TEMP%
if exist "%TEMP_DIR%\pip-*" (
    echo 发现临时文件，正在删除...
    del /f /q "%TEMP_DIR%\pip-*" 2>nul
    echo ✓ 临时文件已清理
) else (
    echo ✓ 没有需要清理的临时文件
)

echo.
echo 正在清理pip缓存...
python -m pip cache purge 2>nul
if %errorlevel% == 0 (
    echo ✓ pip缓存已清理
) else (
    echo ⚠ 无法清理pip缓存（可能pip未安装）
)

echo.
echo 完成！
echo.
pause

