# Bing Image Search API 配置指南

## 什么是Bing Image Search API？

Bing Image Search API是微软提供的图片搜索服务，可以搜索高质量的图片，通常返回更多JPEG/PNG格式的图片（而不是WEBP），非常适合用于PPT图片增强。

## 配置步骤

### 步骤1：创建Azure账号和资源

1. **访问Azure Portal**
   - 打开：https://portal.azure.com/
   - 如果没有账号，点击"免费开始"注册（新用户有$200免费额度）

2. **创建资源组（可选）**
   - 在Azure Portal中，点击"资源组" → "创建"
   - 输入资源组名称（如：`ppt-enhancer-resources`）
   - 选择区域（建议选择离你服务器近的区域，如：`East US`）
   - 点击"创建"

3. **创建Bing Search资源**
   - 在Azure Portal中，点击左上角"创建资源"（+号）
   - 在搜索框中输入：`Bing Search v7`
   - 选择"Bing Search v7"（由Microsoft提供）
   - 点击"创建"

4. **配置Bing Search资源**
   - **订阅**：选择你的Azure订阅
   - **资源组**：选择刚才创建的资源组（或使用现有资源组）
   - **名称**：输入资源名称（如：`ppt-enhancer-bing-search`）
   - **定价层**：选择"F1 - 免费"（每月3000次免费请求）
     - 如果免费层不够，可以选择"S1 - 标准"（按使用量付费）
   - **区域**：选择离你服务器近的区域
   - 点击"查看 + 创建" → "创建"

### 步骤2：获取API密钥

1. **等待资源创建完成**（通常几秒钟）

2. **进入资源页面**
   - 在Azure Portal中，点击"转到资源"
   - 或者从"所有资源"中找到你刚创建的资源

3. **获取密钥**
   - 在左侧菜单中，点击"密钥和终结点"
   - 你会看到两个密钥（Key1和Key2），**任意使用一个即可**
   - 点击密钥旁边的"复制"图标，复制密钥

### 步骤3：配置到服务器

#### 方法1：通过config.json配置（推荐）

在服务器上编辑配置文件：

```bash
cd /srv/jp-ppt
nano config.json
```

添加或更新 `bing_api_key` 字段：

```json
{
  "google_api_key": "你的Google API密钥",
  "google_cse_id": "你的Google CSE ID",
  "google_ai_api_key": "你的Gemini API密钥",
  "spark_api_key": "你的Spark API密钥",
  "spark_base_url": "https://spark-api-open.xf-yun.com/v2",
  "spark_model": "spark-x",
  "ollama_base_url": "http://localhost:11434",
  "ollama_model": "llama3.2",
  "bing_api_key": "你的Bing API密钥"
}
```

保存文件（Ctrl+O, Enter, Ctrl+X）

#### 方法2：通过环境变量配置

编辑systemd服务文件：

```bash
sudo nano /etc/systemd/system/ppt-enhancer.service
```

在 `[Service]` 部分添加：

```ini
Environment="BING_API_KEY=你的Bing API密钥"
```

然后重新加载并重启：

```bash
sudo systemctl daemon-reload
sudo systemctl restart ppt-enhancer
```

### 步骤4：验证配置

重启服务后，查看日志确认Bing API已配置：

```bash
sudo systemctl restart ppt-enhancer
sudo journalctl -u ppt-enhancer -n 50 --no-pager | grep -i bing
```

应该看到：
```
[INFO] Bing Image Search API已配置
```

## 测试Bing API

可以手动测试Bing API是否工作：

```bash
# 在服务器上执行
curl -H "Ocp-Apim-Subscription-Key: 你的Bing API密钥" \
  "https://api.bing.microsoft.com/v7.0/images/search?q=cat&count=2" | python3 -m json.tool
```

如果返回JSON数据，说明API配置成功。

## 定价信息

### 免费层（F1）
- **每月3000次请求**
- 适合：小规模使用
- 超出后需要升级到付费层

### 标准层（S1）
- **按使用量付费**
- 前1000次请求：$4/1000次
- 之后：$3/1000次
- 适合：大规模使用

## 优势

1. **更多JPEG/PNG格式**：Bing通常返回更多非WEBP格式的图片
2. **高质量图片**：搜索结果质量高
3. **免费额度**：每月3000次免费请求
4. **稳定可靠**：微软Azure服务，稳定性好

## 注意事项

1. **API密钥安全**：
   - 不要将API密钥提交到Git仓库
   - 不要在前端代码中暴露密钥
   - 定期轮换密钥（在Azure Portal中可以重新生成）

2. **配额限制**：
   - 免费层每月3000次请求
   - 超出后API会返回429错误
   - 可以升级到付费层或等待下个月重置

3. **区域选择**：
   - 选择离你服务器近的区域可以减少延迟
   - 如果服务器在美国，选择"East US"或"West US"

## 故障排查

### 问题1：API返回401错误
- **原因**：API密钥错误或未设置
- **解决**：检查config.json中的`bing_api_key`是否正确

### 问题2：API返回429错误
- **原因**：超出免费配额（每月3000次）
- **解决**：等待下个月重置，或升级到付费层

### 问题3：找不到图片
- **原因**：搜索关键词不合适
- **解决**：Ollama会自动优化关键词，通常能解决

## 完整配置示例

```json
{
  "google_api_key": "AIzaSy...",
  "google_cse_id": "0123456789:abcdefghijk",
  "google_ai_api_key": "AIzaSy...",
  "spark_api_key": "",
  "spark_base_url": "https://spark-api-open.xf-yun.com/v2",
  "spark_model": "spark-x",
  "ollama_base_url": "http://localhost:11434",
  "ollama_model": "llama3.2",
  "bing_api_key": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
}
```

## 总结

配置Bing API后，系统会：
1. **优先使用Bing搜索**（如果配置了）
2. **自动过滤WEBP格式**
3. **获得更多高质量图片**

配置完成后，重启服务即可使用！

