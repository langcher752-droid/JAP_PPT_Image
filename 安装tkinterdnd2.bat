@echo off
chcp 65001 >nul
echo ========================================
echo 安装tkinterdnd2（拖拽功能）
echo ========================================
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python未安装
    pause
    exit /b 1
)

echo 正在安装tkinterdnd2（使用清华镜像源）...
echo.

python -m pip install tkinterdnd2 -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60

if %errorlevel% == 0 (
    echo.
    echo ========================================
    echo ✓ 安装成功！
    echo ========================================
    echo.
    echo 现在GUI版本可以使用拖拽功能了
) else (
    echo.
    echo ✗ 安装失败，请检查网络连接
    echo.
    echo 提示：即使安装失败，GUI版本仍可使用
    echo 只是无法使用拖拽功能，需要通过按钮选择文件
)

echo.
pause

