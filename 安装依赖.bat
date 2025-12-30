@echo off
chcp 65001 >nul
echo ========================================
echo 日语词汇PPT图片增强工具 - 依赖安装
echo ========================================
echo.

echo 正在检查Python环境...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ Python未安装或未添加到PATH
    echo.
    echo 请先运行"检查Python安装.bat"来诊断问题
    echo 或查看"Python安装指南.txt"了解详细安装步骤
    echo.
    pause
    exit /b 1
)

echo ✓ Python已安装
python --version
echo.
echo 正在安装所需的Python库...
echo 提示：使用国内镜像源以加快下载速度
echo.

REM 先升级pip
echo [步骤1/2] 升级pip...
python -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60 >nul 2>&1

REM 尝试使用python -m pip（更可靠），使用国内镜像源
echo [步骤2/2] 安装依赖库（使用清华镜像源）...
python -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60

if %errorlevel% == 0 (
    echo.
    echo ✓ 安装成功！
    echo.
    echo 现在可以运行程序了：
    echo python main.py
    echo 或双击"运行程序.bat"
) else (
    echo.
    echo ✗ 安装失败，可能的原因：
    echo   1. 网络连接问题
    echo   2. pip需要更新：python -m pip install --upgrade pip
    echo   3. 防火墙或代理设置阻止了下载
    echo.
    echo 请查看"Python安装指南.txt"获取更多帮助
)

echo.
pause

