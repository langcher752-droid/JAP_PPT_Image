#!/bin/bash
# 更新服务器代码并配置Ollama

set -e

echo "=========================================="
echo "更新服务器代码"
echo "=========================================="

# 切换到应用目录
cd /srv/jp-ppt || { echo "错误: /srv/jp-ppt 目录不存在"; exit 1; }

echo "[1] 当前目录: $(pwd)"
echo "[2] 检查git状态..."
git status

echo ""
echo "[3] 检查config.json..."
if [ -f "config.json" ]; then
    echo "✓ config.json存在"
    if grep -q "ollama_base_url" config.json; then
        echo "✓ Ollama配置已存在"
        grep -A 1 "ollama" config.json
    else
        echo "✗ 需要添加Ollama配置"
        echo "  编辑config.json添加："
        echo '  "ollama_base_url": "http://localhost:11434",'
        echo '  "ollama_model": "llama3.2"'
    fi
else
    echo "✗ config.json不存在"
fi

echo ""
echo "[4] 检查代码是否包含Ollama支持..."
if [ -f "main.py" ]; then
    if grep -q "optimize_search_keyword_with_ollama" main.py; then
        echo "✓ main.py包含Ollama支持"
    else
        echo "✗ main.py不包含Ollama支持，需要更新代码"
    fi
else
    echo "✗ main.py不存在"
fi

echo ""
echo "[5] 检查Ollama服务..."
if sudo systemctl is-active --quiet ollama; then
    echo "✓ Ollama服务正在运行"
else
    echo "✗ Ollama服务未运行"
fi

echo ""
echo "=========================================="
echo "下一步操作："
echo "=========================================="
echo "1. 如果代码需要更新，执行: git pull"
echo "2. 如果config.json需要更新，编辑: nano config.json"
echo "3. 重启应用服务: sudo systemctl restart ppt-enhancer"
echo ""

