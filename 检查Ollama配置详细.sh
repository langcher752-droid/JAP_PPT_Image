#!/bin/bash
# 详细检查Ollama配置

cd /srv/jp-ppt

echo "=========================================="
echo "详细检查Ollama配置"
echo "=========================================="

# 1. 检查config.json
echo "[1] 检查config.json..."
if [ -f "config.json" ]; then
    echo "✓ config.json存在"
    echo "  内容："
    cat config.json | python3 -m json.tool 2>/dev/null || cat config.json
    echo ""
    if grep -q "ollama_base_url" config.json; then
        echo "✓ 包含ollama_base_url"
        grep "ollama" config.json
    else
        echo "✗ 不包含ollama配置"
    fi
else
    echo "✗ config.json不存在"
fi

# 2. 检查代码中的load_config
echo ""
echo "[2] 检查load_config函数..."
if grep -A 5 "def load_config" main.py | head -10; then
    echo "✓ load_config函数存在"
fi

# 3. 使用虚拟环境测试导入
echo ""
echo "[3] 使用虚拟环境测试load_config..."
source venv/bin/activate
python3 <<'PYTHON'
import sys
sys.path.insert(0, '/srv/jp-ppt')
from main import load_config

print("调用load_config()...")
result = load_config()
print(f"返回值数量: {len(result)}")
if len(result) == 9:
    google_api_key, google_cse_id, google_ai_api_key, spark_api_key, spark_base_url, spark_model, ollama_base_url, ollama_model, bing_api_key = result
    print(f"✓ load_config返回9个值")
    print(f"  ollama_base_url: {ollama_base_url}")
    print(f"  ollama_model: {ollama_model}")
    if ollama_base_url:
        print("✓ Ollama配置已加载")
    else:
        print("✗ Ollama配置为空")
else:
    print(f"✗ 返回值数量错误: {len(result)}")
PYTHON
deactivate

# 4. 检查服务启动日志
echo ""
echo "[4] 检查服务启动日志（完整）..."
sudo journalctl -u ppt-enhancer --since "5 minutes ago" --no-pager | grep -E "(INFO|ollama|Ollama|OLLAMA)" || echo "未找到相关日志"

# 5. 检查应用初始化
echo ""
echo "[5] 检查应用初始化代码..."
if grep -q "Ollama本地模型已配置" main.py; then
    echo "✓ 代码包含Ollama日志输出"
    grep -B 2 -A 2 "Ollama本地模型已配置" main.py
else
    echo "✗ 代码不包含Ollama日志输出"
fi

# 6. 手动测试应用启动
echo ""
echo "[6] 手动测试应用初始化..."
source venv/bin/activate
python3 <<'PYTHON'
import sys
import os
sys.path.insert(0, '/srv/jp-ppt')

# 模拟web_app.py的初始化
from main import load_config

google_api_key, google_cse_id, google_ai_api_key, spark_api_key, spark_base_url, spark_model, ollama_base_url, ollama_model, bing_api_key = load_config()

# 检查环境变量
ollama_base_url = os.getenv('OLLAMA_BASE_URL', ollama_base_url)
ollama_model = os.getenv('OLLAMA_MODEL', ollama_model)

print(f"\n最终配置:")
print(f"  ollama_base_url: {ollama_base_url}")
print(f"  ollama_model: {ollama_model}")

if ollama_base_url:
    print("✓ Ollama配置存在")
else:
    print("✗ Ollama配置为空")
PYTHON
deactivate

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="

