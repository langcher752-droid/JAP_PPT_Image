# 服务器Ollama配置指南

## 在GCP服务器上安装和配置Ollama

### 1. SSH连接到服务器

```bash
gcloud compute ssh --zone "us-west1-b" "instance-20251228-095410" --project "project-c9bc7311-141d-4b19-8bb"
```

### 2. 安装Ollama

```bash
# 下载并安装Ollama
curl -fsSL https://ollama.com/install.sh | sh

# 验证安装
ollama --version
```

### 3. 下载模型

```bash
# 下载llama3.2模型（约2GB，根据服务器配置选择）
ollama pull llama3.2

# 或者下载更小的模型（如果内存有限）
# ollama pull llama3.2:1b  # 1B参数版本，约700MB
# ollama pull qwen2:0.5b   # 更小的模型

# 验证模型已下载
ollama list
```

### 4. 配置Ollama服务（作为systemd服务运行）

创建systemd服务文件：

```bash
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

# 创建ollama用户（如果不存在）
sudo useradd -r -s /bin/false ollama || true

# 重新加载systemd
sudo systemctl daemon-reload

# 启动Ollama服务
sudo systemctl enable ollama
sudo systemctl start ollama

# 检查服务状态
sudo systemctl status ollama
```

### 5. 测试Ollama API

```bash
# 测试本地连接
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Say hello in Japanese",
  "stream": false
}'
```

### 6. 配置防火墙（如果需要从外部访问）

如果Ollama只在本机使用（推荐），跳过此步骤。

如果需要在服务器内部其他服务访问，确保本地防火墙允许：

```bash
# 检查防火墙状态
sudo ufw status

# 如果需要，允许本地访问（默认应该已经允许）
# sudo ufw allow from 127.0.0.1 to any port 11434
```

### 7. 更新应用配置

编辑服务器上的 `config.json`：

```bash
# 在服务器上编辑配置文件
nano config.json
```

添加或更新以下配置：

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

### 8. 重启应用服务

```bash
# 如果使用systemd服务运行
sudo systemctl restart ppt-enhancer

# 或者如果使用gunicorn
sudo systemctl restart gunicorn
```

### 9. 验证配置

查看应用日志，确认Ollama已配置：

```bash
sudo journalctl -u ppt-enhancer -n 50 --no-pager | grep -i ollama
```

应该看到类似输出：
```
[INFO] Ollama本地模型已配置: http://localhost:11434 (模型: llama3.2)
```

### 10. 性能优化建议

#### 内存优化
如果服务器内存有限（如16GB），可以考虑：

```bash
# 使用更小的模型
ollama pull llama3.2:1b

# 或者限制Ollama使用的GPU/CPU
# 编辑 /etc/systemd/system/ollama.service
# 添加：Environment="OLLAMA_NUM_GPU=0"  # 如果只有CPU
```

#### 模型选择建议
- **llama3.2** (2GB): 推荐，平衡性能和准确性
- **llama3.2:1b** (700MB): 内存受限时使用
- **qwen2:0.5b** (300MB): 最小模型，快速但准确性较低

### 11. 故障排查

#### 检查Ollama是否运行
```bash
sudo systemctl status ollama
```

#### 查看Ollama日志
```bash
sudo journalctl -u ollama -n 100 --no-pager
```

#### 测试API连接
```bash
# 测试本地连接
curl http://localhost:11434/api/tags

# 应该返回已安装的模型列表
```

#### 如果Ollama无法启动
```bash
# 检查端口是否被占用
sudo netstat -tlnp | grep 11434

# 手动启动测试
ollama serve
```

### 12. 更新代码到服务器

如果代码在本地，需要上传到服务器：

```bash
# 在本地执行（从项目目录）
gcloud compute scp --zone "us-west1-b" \
  main.py web_app.py config.json.example \
  instance-20251228-095410:~/ppt-enhancer/
```

### 13. 环境变量配置（可选）

如果使用环境变量而不是config.json：

```bash
# 编辑服务文件
sudo nano /etc/systemd/system/ppt-enhancer.service

# 在[Service]部分添加：
Environment="OLLAMA_BASE_URL=http://localhost:11434"
Environment="OLLAMA_MODEL=llama3.2"
```

然后重启服务：
```bash
sudo systemctl daemon-reload
sudo systemctl restart ppt-enhancer
```

## 注意事项

1. **安全性**：Ollama默认只监听localhost，这是安全的。不要将其暴露到公网。

2. **性能**：首次调用模型会较慢（需要加载模型到内存），后续调用会快很多。

3. **内存使用**：llama3.2模型需要约2-4GB内存。确保服务器有足够内存。

4. **并发**：Ollama可以处理多个并发请求，但会共享模型内存。

## 验证完整流程

1. 确认Ollama服务运行：`sudo systemctl status ollama`
2. 确认模型已下载：`ollama list`
3. 测试API：`curl http://localhost:11434/api/tags`
4. 查看应用日志：`sudo journalctl -u ppt-enhancer -f`
5. 提交一个PPT处理请求，观察日志中是否有Ollama调用

如果一切正常，应该看到类似日志：
```
[DEBUG] 调用Ollama本地模型优化关键词: 電車
[DEBUG] Ollama API请求URL: http://localhost:11434/api/generate
[DEBUG] Ollama优化后的关键词: train
```

