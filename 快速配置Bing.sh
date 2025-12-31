#!/bin/bash
# 快速配置Bing API的辅助脚本

echo "=========================================="
echo "Bing API 配置助手"
echo "=========================================="

cd /srv/jp-ppt

# 检查config.json是否存在
if [ ! -f "config.json" ]; then
    echo "创建config.json..."
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
fi

# 读取当前配置
echo ""
echo "当前Bing API配置："
if grep -q "bing_api_key" config.json; then
    bing_key=$(grep "bing_api_key" config.json | cut -d'"' -f4)
    if [ -z "$bing_key" ] || [ "$bing_key" == "" ]; then
        echo "  ✗ 未配置（为空）"
    else
        echo "  ✓ 已配置: ${bing_key:0:10}..."
    fi
else
    echo "  ✗ 配置项不存在"
fi

echo ""
echo "=========================================="
echo "配置步骤："
echo "=========================================="
echo ""
echo "1. 访问 Azure Portal: https://portal.azure.com/"
echo "2. 创建 'Bing Search v7' 资源"
echo "3. 选择 'F1 - 免费' 定价层（每月3000次免费）"
echo "4. 在资源页面 → '密钥和终结点' → 复制密钥"
echo ""
echo "5. 编辑config.json添加密钥："
echo "   nano config.json"
echo ""
echo "6. 将密钥添加到 'bing_api_key' 字段"
echo ""
echo "7. 重启服务："
echo "   sudo systemctl restart ppt-enhancer"
echo ""
echo "详细说明请查看: BingAPI配置指南.md"
echo ""

