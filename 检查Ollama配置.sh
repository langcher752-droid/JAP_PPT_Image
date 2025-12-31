#!/bin/bash
# 检查Ollama配置和状态

echo "=========================================="
echo "Ollama 配置检查"
echo "=========================================="

# 1. 检查Ollama是否安装
echo "[1] 检查Ollama安装..."
if command -v ollama &> /dev/null; then
    echo "✓ Ollama已安装: $(ollama --version)"
else
    echo "✗ Ollama未安装"
    exit 1
fi

# 2. 检查Ollama服务状态
echo ""
echo "[2] 检查Ollama服务状态..."
if sudo systemctl is-active --quiet ollama; then
    echo "✓ Ollama服务正在运行"
    sudo systemctl status ollama --no-pager -l | head -5
else
    echo "✗ Ollama服务未运行"
    echo "  启动命令: sudo systemctl start ollama"
fi

# 3. 检查模型
echo ""
echo "[3] 检查已安装的模型..."
ollama list

# 4. 测试API
echo ""
echo "[4] 测试Ollama API..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✓ Ollama API响应正常"
    echo "  模型列表:"
    curl -s http://localhost:11434/api/tags | python3 -m json.tool 2>/dev/null || curl -s http://localhost:11434/api/tags
else
    echo "✗ Ollama API无响应"
fi

# 5. 检查config.json
echo ""
echo "[5] 检查config.json配置..."
if [ -f "config.json" ]; then
    echo "✓ config.json存在"
    if grep -q "ollama_base_url" config.json; then
        echo "✓ Ollama配置已存在:"
        grep -A 1 "ollama" config.json | head -4
    else
        echo "✗ config.json中未找到Ollama配置"
        echo "  需要添加:"
        echo '  "ollama_base_url": "http://localhost:11434",'
        echo '  "ollama_model": "llama3.2"'
    fi
else
    echo "✗ config.json不存在"
    echo "  需要创建config.json文件"
fi

# 6. 检查应用代码
echo ""
echo "[6] 检查应用代码..."
if [ -f "main.py" ]; then
    if grep -q "optimize_search_keyword_with_ollama" main.py; then
        echo "✓ main.py包含Ollama支持"
    else
        echo "✗ main.py不包含Ollama支持"
        echo "  需要更新代码"
    fi
else
    echo "✗ main.py不存在"
fi

# 7. 检查环境变量
echo ""
echo "[7] 检查环境变量..."
if [ -f "/etc/systemd/system/ppt-enhancer.service" ]; then
    echo "检查服务文件中的环境变量:"
    grep -i ollama /etc/systemd/system/ppt-enhancer.service || echo "  未找到Ollama环境变量"
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="

