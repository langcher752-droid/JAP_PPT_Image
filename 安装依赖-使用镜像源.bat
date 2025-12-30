@echo off
chcp 65001 >nul
echo ========================================
echo 日语词汇PPT图片增强工具 - 依赖安装（使用国内镜像源）
echo ========================================
echo.
echo 此脚本使用清华大学镜像源，下载速度更快
echo.

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ Python未安装或未添加到PATH
    echo 请先运行"检查Python安装.bat"
    pause
    exit /b 1
)

echo ✓ Python已安装
python --version
echo.

REM 清理可能存在的临时文件
echo 正在清理临时文件...
if exist "%TEMP%\pip-*" (
    echo 发现临时文件，正在清理...
    timeout /t 2 /nobreak >nul
)

echo.
echo 正在升级pip（使用清华镜像源）...
python -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60
echo.

echo 正在安装依赖库（使用清华镜像源，超时时间60秒）...
echo.
echo 提示：如果Pillow安装失败，将尝试使用预编译版本...
echo.

REM 先尝试安装python-pptx和requests
python -m pip install python-pptx==0.6.21 requests==2.31.0 -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60

REM 然后尝试安装Pillow，使用预编译的wheel文件
echo.
echo 正在安装Pillow（图像处理库）...
python -m pip install --only-binary :all: Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60

if %errorlevel% neq 0 (
    echo.
    echo Pillow预编译版本安装失败，尝试安装最新版本...
    python -m pip install Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60 --no-build-isolation
)

if %errorlevel% == 0 (
    echo.
    echo 正在验证安装...
    python -c "import pptx; import requests; print('✓ 核心库安装成功')" 2>nul
    if %errorlevel% == 0 (
        echo.
        echo ========================================
        echo ✓ 所有依赖安装成功！
        echo ========================================
    ) else (
        echo.
        echo ⚠ 请检查上面的错误信息
    )
) else (
    echo.
    echo ========================================
    echo ✗ 安装失败
    echo ========================================
    echo.
    echo 如果遇到"文件被占用"错误：
    echo   1. 关闭所有Python相关程序
    echo   2. 等待10秒
    echo   3. 重新运行此脚本
    echo.
    echo 如果遇到网络超时：
    echo   1. 检查网络连接
    echo   2. 稍后重试
    echo   3. 或尝试使用手机热点
)

echo.
pause

