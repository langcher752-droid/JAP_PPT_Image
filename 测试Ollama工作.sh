#!/bin/bash
# 测试Ollama是否正常工作

cd /srv/jp-ppt

echo "=========================================="
echo "测试Ollama配置和工作状态"
echo "=========================================="

# 1. 检查Ollama服务
echo "[1] 检查Ollama服务..."
if sudo systemctl is-active --quiet ollama; then
    echo "✓ Ollama服务运行中"
else
    echo "✗ Ollama服务未运行"
    exit 1
fi

# 2. 测试Ollama API
echo ""
echo "[2] 测试Ollama API..."
curl -s http://localhost:11434/api/tags | python3 -m json.tool | head -10

# 3. 测试Ollama生成（简单测试）
echo ""
echo "[3] 测试Ollama生成（简单测试）..."
curl -s http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Say hello",
  "stream": false
}' | python3 -c "import sys, json; data=json.load(sys.stdin); print('✓ Ollama响应:', data.get('response', '')[:50])" 2>/dev/null || echo "⚠ Ollama响应测试失败"

# 4. 检查应用配置加载
echo ""
echo "[4] 检查应用配置加载..."
source venv/bin/activate
python3 <<'PYTHON'
import sys
sys.path.insert(0, '/srv/jp-ppt')
from main import load_config

result = load_config()
if len(result) == 9:
    ollama_base_url = result[6]
    ollama_model = result[7]
    print(f"✓ 配置加载成功")
    print(f"  ollama_base_url: {ollama_base_url}")
    print(f"  ollama_model: {ollama_model}")
    
    # 测试PPTImageEnhancer初始化
    from main import PPTImageEnhancer
    import tempfile
    import os
    
    # 创建一个临时PPT文件用于测试
    try:
        from pptx import Presentation
        prs = Presentation()
        prs.slide_width = 9144000
        prs.slide_height = 6858000
        slide = prs.slides.add_slide(prs.slide_layouts[6])
        temp_ppt = tempfile.NamedTemporaryFile(suffix='.pptx', delete=False)
        prs.save(temp_ppt.name)
        temp_ppt.close()
        
        enhancer = PPTImageEnhancer(
            temp_ppt.name,
            ollama_base_url=ollama_base_url,
            ollama_model=ollama_model,
            verbose=True
        )
        print("✓ PPTImageEnhancer初始化成功")
        print(f"  enhancer.ollama_base_url: {enhancer.ollama_base_url}")
        print(f"  enhancer.ollama_model: {enhancer.ollama_model}")
        
        os.unlink(temp_ppt.name)
    except Exception as e:
        print(f"✗ 初始化失败: {e}")
        import traceback
        traceback.print_exc()
else:
    print(f"✗ 配置加载失败，返回值数量: {len(result)}")
PYTHON
deactivate

# 5. 检查服务日志中的错误
echo ""
echo "[5] 检查服务日志中的错误..."
sudo journalctl -u ppt-enhancer --since "5 minutes ago" --no-pager | grep -iE "(error|exception|traceback|failed)" | tail -20 || echo "未发现错误"

# 6. 测试API端点
echo ""
echo "[6] 测试API健康检查..."
curl -s http://localhost:5000/api/health | python3 -m json.tool 2>/dev/null || echo "API测试失败"

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="

