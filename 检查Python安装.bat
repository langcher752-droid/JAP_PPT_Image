@echo off
chcp 65001 >nul
echo ========================================
echo Python环境检查工具
echo ========================================
echo.

echo 正在检查Python安装...
echo.

python --version >nul 2>&1
if %errorlevel% == 0 (
    echo ✓ Python已安装
    python --version
    echo.
    echo 正在检查pip...
    python -m pip --version >nul 2>&1
    if %errorlevel% == 0 (
        echo ✓ pip可用
        python -m pip --version
        echo.
        echo 正在安装依赖库...
        echo.
        echo 提示：如果遇到网络超时，请稍后重试
        echo 如果遇到文件占用错误，请关闭其他程序后重试
        echo.
        
        REM 先升级pip，使用国内镜像源加速
        echo [1/3] 升级pip...
        python -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple --user
        echo.
        
        REM 安装依赖，使用国内镜像源和--user选项
        echo [2/3] 安装依赖库（使用清华镜像源，速度更快）...
        python -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple --user --timeout 60
        
        if %errorlevel% == 0 (
            echo.
            echo [3/3] 验证安装...
            python -c "import pptx; import requests; from PIL import Image; print('✓ 所有依赖库已成功安装！')" 2>nul
            if %errorlevel% == 0 (
                echo.
                echo ========================================
                echo ✓ 所有依赖安装成功！
                echo ========================================
                echo.
                echo 现在可以运行程序了：
                echo   python main.py
                echo 或双击"运行程序.bat"
            ) else (
                echo.
                echo ⚠ 安装可能不完整，请检查上面的错误信息
            )
        ) else (
            echo.
            echo ========================================
            echo ✗ 依赖安装失败
            echo ========================================
            echo.
            echo 可能的原因和解决方案：
            echo.
            echo 1. 网络连接超时
            echo    解决方案：检查网络连接，稍后重试
            echo    或使用手机热点尝试
            echo.
            echo 2. 文件被占用（WinError 32）
            echo    解决方案：
            echo    - 关闭所有Python程序
            echo    - 关闭IDE（如VS Code、PyCharm等）
            echo    - 等待几秒后重试
            echo.
            echo 3. 权限问题
            echo    解决方案：以管理员身份运行此脚本
            echo.
            echo 4. 临时文件问题
            echo    解决方案：手动删除以下文件夹后重试：
            echo    C:\Users\%USERNAME%\AppData\Local\Temp\pip-*
            echo.
            echo 如果问题持续，可以尝试：
            echo   python -m pip install --user python-pptx requests Pillow
        )
    ) else (
        echo ✗ pip不可用
        echo.
        echo 请尝试重新安装Python，并确保勾选"Add Python to PATH"选项
    )
) else (
    echo ✗ Python未安装或未添加到系统PATH
    echo.
    echo 请按照以下步骤安装Python：
    echo.
    echo 1. 访问 https://www.python.org/downloads/
    echo 2. 下载最新版本的Python（推荐Python 3.11或3.12）
    echo 3. 运行安装程序时，务必勾选 "Add Python to PATH" 选项
    echo 4. 安装完成后，重新运行此脚本
    echo.
    echo 或者，如果您已经安装了Python但未添加到PATH：
    echo 请手动将Python安装目录添加到系统环境变量PATH中
)

echo.
pause

