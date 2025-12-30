@echo off
chcp 65001 >nul
echo ========================================
echo 日语词汇PPT图片增强工具 - GUI版本
echo ========================================
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python未安装或未添加到PATH
    echo 请先安装Python
    pause
    exit /b 1
)

python gui.py

if %errorlevel% neq 0 (
    echo.
    echo 运行失败，可能的原因：
    echo 1. 缺少依赖库，请运行"安装GUI依赖.bat"
    echo 2. 如果只是拖拽功能不可用，可以忽略
    echo.
    pause
)

