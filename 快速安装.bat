@echo off
chcp 65001 >nul
echo ========================================
echo 快速安装 - 仅安装必需库
echo ========================================
echo.
echo 注意：此脚本只安装必需的库（不包含Pillow）
echo 因为代码中实际上不需要Pillow
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python未安装
    pause
    exit /b 1
)

echo 正在安装python-pptx和requests...
echo.

python -m pip install python-pptx==0.6.21 requests==2.31.0 -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60

if %errorlevel% == 0 (
    echo.
    echo 验证安装...
    python -c "import pptx; import requests; print('')" 2>nul
    if %errorlevel% == 0 (
        echo.
        echo ========================================
        echo 安装成功！
        echo ========================================
        echo.
        echo 现在可以运行程序了：
        echo   python main.py
        echo 或双击"运行程序.bat"
    ) else (
        echo.
        echo 安装可能有问题，请检查上面的错误信息
    )
) else (
    echo.
    echo 安装失败，请检查网络连接
)

echo.
pause

