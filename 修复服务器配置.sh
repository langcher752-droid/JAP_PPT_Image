#!/bin/bash
# 修复服务器配置

set -e

cd /srv/jp-ppt

echo "=========================================="
echo "修复服务器配置"
echo "=========================================="

# 1. 检查并创建config.json
echo "[1] 检查config.json..."
if [ ! -f "config.json" ]; then
    echo "✗ config.json不存在，创建默认配置..."
    cat > config.json <<'EOF'
{
  "google_api_key": "",
  "google_cse_id": "",
  "google_ai_api_key": "",
  "spark_api_key": "",
  "spark_base_url": "https://spark-api-open.xf-yun.com/v2",
  "spark_model": "spark-x",
  "ollama_base_url": "http://localhost:11434",
  "ollama_model": "llama3.2",
  "bing_api_key": ""
}
EOF
    echo "✓ 已创建config.json"
else
    echo "✓ config.json存在"
    # 检查是否包含Ollama配置
    if ! grep -q "ollama_base_url" config.json; then
        echo "  添加Ollama配置..."
        # 使用python添加配置（更安全）
        python3 <<'PYTHON'
import json
import sys

try:
    with open('config.json', 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    if 'ollama_base_url' not in config:
        config['ollama_base_url'] = 'http://localhost:11434'
    if 'ollama_model' not in config:
        config['ollama_model'] = 'llama3.2'
    if 'bing_api_key' not in config:
        config['bing_api_key'] = ''
    
    with open('config.json', 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    print("✓ 已更新config.json")
except Exception as e:
    print(f"✗ 更新config.json失败: {e}")
    sys.exit(1)
PYTHON
    else
        echo "✓ Ollama配置已存在"
    fi
fi

# 2. 检查代码语法
echo ""
echo "[2] 检查代码语法..."
if python3 -m py_compile main.py 2>&1; then
    echo "✓ main.py语法正确"
else
    echo "✗ main.py有语法错误"
    exit 1
fi

if python3 -m py_compile web_app.py 2>&1; then
    echo "✓ web_app.py语法正确"
else
    echo "✗ web_app.py有语法错误"
    exit 1
fi

# 3. 测试导入
echo ""
echo "[3] 测试模块导入..."
if python3 -c "from main import load_config; print('✓ load_config导入成功')" 2>&1; then
    echo "✓ 模块导入成功"
else
    echo "✗ 模块导入失败"
    exit 1
fi

# 4. 测试load_config返回值
echo ""
echo "[4] 测试load_config返回值..."
python3 <<'PYTHON'
from main import load_config
result = load_config()
if len(result) == 9:
    print(f"✓ load_config返回9个值: {len(result)}")
    print(f"  返回值: google_api_key, google_cse_id, google_ai_api_key, spark_api_key, spark_base_url, spark_model, ollama_base_url, ollama_model, bing_api_key")
else:
    print(f"✗ load_config返回值数量错误: {len(result)} (应该是9)")
    exit(1)
PYTHON

# 5. 检查服务配置
echo ""
echo "[5] 检查服务配置..."
if [ -f "/etc/systemd/system/ppt-enhancer.service" ]; then
    echo "✓ 服务文件存在"
    echo "  工作目录:"
    grep -i "workingdirectory\|WorkingDirectory" /etc/systemd/system/ppt-enhancer.service || echo "  未设置工作目录"
else
    echo "✗ 服务文件不存在"
fi

echo ""
echo "=========================================="
echo "配置检查完成"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 编辑config.json添加API密钥（如果需要）"
echo "2. 重启服务: sudo systemctl restart ppt-enhancer"
echo "3. 查看日志: sudo journalctl -u ppt-enhancer -f"
echo ""

