#!/bin/bash
# 启动Web API服务器的脚本

echo "======================================"
echo "日语词汇PPT图片增强工具 - Web API"
echo "======================================"

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3，请先安装Python"
    exit 1
fi

# 检查虚拟环境是否存在
if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "检查依赖..."
pip install -q -r requirements-web.txt

# 检查配置文件
if [ ! -f "config.json" ]; then
    echo "警告: config.json 不存在，请先配置API密钥"
    echo "可以复制 config.json.example 并修改"
fi

# 启动服务器
echo ""
echo "启动Web API服务器..."
echo "访问地址: http://localhost:5000"
echo "按 Ctrl+C 停止服务器"
echo ""

# 使用gunicorn启动（生产环境）
if command -v gunicorn &> /dev/null; then
    gunicorn -w 4 -b 0.0.0.0:5000 web_app:app
else
    # 如果没有gunicorn，使用Flask开发服务器
    echo "提示: 建议安装gunicorn以获得更好的性能: pip install gunicorn"
    python web_app.py
fi

