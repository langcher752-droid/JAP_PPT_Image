@echo off
REM Windows启动脚本

echo ======================================
echo 日语词汇PPT图片增强工具 - Web API
echo ======================================

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到Python，请先安装Python
    pause
    exit /b 1
)

REM 检查虚拟环境是否存在
if not exist "venv" (
    echo 创建虚拟环境...
    python -m venv venv
)

REM 激活虚拟环境
echo 激活虚拟环境...
call venv\Scripts\activate.bat

REM 安装依赖
echo 检查依赖...
pip install -q -r requirements-web.txt

REM 检查配置文件
if not exist "config.json" (
    echo 警告: config.json 不存在，请先配置API密钥
    echo 可以复制 config.json.example 并修改
)

REM 启动服务器
echo.
echo 启动Web API服务器...
echo 访问地址: http://localhost:5000
echo 按 Ctrl+C 停止服务器
echo.

python web_app.py

pause

