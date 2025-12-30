@echo off
chcp 65001 >nul
echo ========================================
echo 简化安装脚本 - 逐步安装依赖
echo ========================================
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python未安装
    pause
    exit /b 1
)

echo 步骤1: 安装python-pptx
python -m pip install python-pptx -i https://pypi.tuna.tsinghua.edu.cn/simple --user
echo.

echo 步骤2: 安装requests
python -m pip install requests -i https://pypi.tuna.tsinghua.edu.cn/simple --user
echo.

echo 步骤3: 安装Pillow（尝试预编译版本）
python -m pip install --only-binary :all: Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple --user
if %errorlevel% neq 0 (
    echo 预编译版本失败，尝试最新版本...
    python -m pip install Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple --user --no-build-isolation
)
echo.

echo 验证安装...
python -c "import pptx; print('pptx OK')" 2>nul && python -c "import requests; print('requests OK')" 2>nul && python -c "from PIL import Image; print('Pillow OK')" 2>nul
if %errorlevel% == 0 (
    echo.
    echo 所有库安装成功！
) else (
    echo.
    echo 部分库可能未正确安装，请检查上面的错误信息
)

echo.
pause

