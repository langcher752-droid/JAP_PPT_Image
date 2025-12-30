@echo off
chcp 65001 >nul
echo ========================================
echo 安装GUI版本所需依赖
echo ========================================
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python未安装
    pause
    exit /b 1
)

echo 正在安装依赖库（使用清华镜像源）...
echo.

echo 正在安装tkinterdnd2（拖拽功能）...
python -m pip install tkinterdnd2 -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60
echo.

echo 正在安装其他依赖库...
python -m pip install -r requirements-gui.txt -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60

if %errorlevel% == 0 (
    echo.
    echo ========================================
    echo ✓ 安装成功！
    echo ========================================
    echo.
    echo 现在可以运行GUI版本了：
    echo   python gui.py
    echo 或双击"运行GUI.bat"
) else (
    echo.
    echo ✗ 安装失败，请检查网络连接
)

echo.
pause

