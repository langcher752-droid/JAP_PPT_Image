#!/bin/bash
# 快速在GCP服务器上安装和配置Ollama

set -e

echo "=========================================="
echo "Ollama 安装和配置脚本"
echo "=========================================="

# 1. 安装Ollama
echo "[1/6] 安装Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# 2. 验证安装
echo "[2/6] 验证安装..."
if ! command -v ollama &> /dev/null; then
    echo "错误: Ollama安装失败"
    exit 1
fi
echo "✓ Ollama已安装: $(ollama --version)"

# 3. 下载模型
echo "[3/6] 下载llama3.2模型（这可能需要几分钟）..."
ollama pull llama3.2

# 4. 验证模型
echo "[4/6] 验证模型..."
ollama list

# 5. 配置systemd服务
echo "[5/6] 配置systemd服务..."
sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="OLLAMA_HOST=0.0.0.0:11434"

[Install]
WantedBy=default.target
EOF

# 创建ollama用户
sudo useradd -r -s /bin/false ollama 2>/dev/null || true

# 重新加载systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl enable ollama
sudo systemctl start ollama

# 等待服务启动
sleep 3

# 6. 测试服务
echo "[6/6] 测试Ollama服务..."
if sudo systemctl is-active --quiet ollama; then
    echo "✓ Ollama服务运行正常"
    
    # 测试API
    if curl -s http://localhost:11434/api/tags > /dev/null; then
        echo "✓ Ollama API响应正常"
    else
        echo "⚠ Ollama API测试失败，但服务已启动"
    fi
else
    echo "✗ Ollama服务启动失败"
    echo "查看日志: sudo journalctl -u ollama -n 50"
    exit 1
fi

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 更新config.json，添加："
echo '   "ollama_base_url": "http://localhost:11434"'
echo '   "ollama_model": "llama3.2"'
echo ""
echo "2. 重启应用服务："
echo "   sudo systemctl restart ppt-enhancer"
echo ""
echo "3. 查看服务状态："
echo "   sudo systemctl status ollama"
echo "   sudo journalctl -u ppt-enhancer -f"
echo ""

