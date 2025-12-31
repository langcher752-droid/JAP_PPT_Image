# 检查GCP防火墙并测试连接

## 当前状态
✅ 端口80和443正在监听（0.0.0.0，监听所有接口）
✅ 端口5000正在监听（127.0.0.1，本地）
✅ Nginx正在运行
⚠️ UFW未安装（GCP使用自己的防火墙，这是正常的）

## 问题诊断

### 1. 测试本地连接（完整测试）

```bash
# 测试HTTP
curl -v http://127.0.0.1/ 2>&1 | head -20

# 测试API
curl -v http://127.0.0.1/api/health 2>&1 | head -20

# 测试HTTPS（如果已配置）
curl -v https://127.0.0.1/ -k 2>&1 | head -20
```

### 2. 检查GCP防火墙规则（最重要）

**在GCP控制台操作：**

1. 进入 **VPC网络 > 防火墙规则**
2. 查找以下规则：
   - `default-allow-http` - 允许 tcp:80
   - `default-allow-https` - 允许 tcp:443
   - `allow-http` - 允许 tcp:80
   - `allow-https` - 允许 tcp:443

**如果没有找到，需要创建规则：**

**方法1：通过GCP控制台**
1. VPC网络 > 防火墙规则 > 创建防火墙规则
2. 名称：`allow-http`
3. 目标：所有实例
4. 来源IP范围：`0.0.0.0/0`
5. 协议和端口：选择"指定的协议和端口"，勾选"tcp"，输入"80"
6. 创建
7. 重复创建 `allow-https`，端口改为 `443`

**方法2：通过gcloud CLI（在本地电脑上）**

```bash
# 创建HTTP规则
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --target-tags http-server \
    --description "Allow HTTP traffic"

# 创建HTTPS规则
gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --target-tags https-server \
    --description "Allow HTTPS traffic"
```

**方法3：创建不带标签的规则（推荐）**

```bash
# 创建HTTP规则（应用到所有实例）
gcloud compute firewall-rules create allow-http-all \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP traffic to all instances"

# 创建HTTPS规则（应用到所有实例）
gcloud compute firewall-rules create allow-https-all \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTPS traffic to all instances"
```

### 3. 检查实例的网络标签

**在GCP控制台：**
1. 计算引擎 > VM实例
2. 点击你的实例名称
3. 查看"网络标签"部分
4. 如果使用了标签规则，确保实例有 `http-server` 和 `https-server` 标签

### 4. 测试公网IP访问

**在本地电脑上运行：**

```bash
# 测试HTTP（使用IP地址，绕过DNS）
curl -v http://34.142.75.113/ 2>&1 | head -20

# 测试API
curl -v http://34.142.75.113/api/health 2>&1 | head -20

# 如果超时，说明是防火墙问题
# 如果可以访问，说明是DNS问题
```

### 5. 检查DNS解析

**在本地电脑上运行：**

```bash
# Mac/Linux
dig www.rancho.website +short
nslookup www.rancho.website

# Windows (PowerShell)
nslookup www.rancho.website
```

**应该返回：** `34.142.75.113`（新服务器）或 `34.168.121.40`（旧服务器）

### 6. 检查Nginx配置

**在服务器上运行：**

```bash
# 查看Nginx配置
sudo cat /etc/nginx/sites-available/ppt-enhancer

# 检查配置语法
sudo nginx -t

# 查看访问日志（实时）
sudo tail -f /var/log/nginx/access.log
```

## 快速修复命令

### 如果使用gcloud CLI（在本地电脑上）

```bash
# 列出当前防火墙规则
gcloud compute firewall-rules list

# 创建HTTP规则
gcloud compute firewall-rules create allow-http-all \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP traffic"

# 创建HTTPS规则
gcloud compute firewall-rules create allow-https-all \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTPS traffic"

# 验证规则已创建
gcloud compute firewall-rules list | grep -E 'allow-http|allow-https'
```

### 在服务器上测试

```bash
# 1. 测试本地连接
curl -v http://127.0.0.1/api/health

# 2. 检查Nginx访问日志（看是否有外部请求）
sudo tail -20 /var/log/nginx/access.log

# 3. 检查Nginx错误日志
sudo tail -20 /var/log/nginx/error.log
```

## 验证修复

创建防火墙规则后，在本地电脑上测试：

```bash
# 1. 测试IP地址（绕过DNS）
curl -I http://34.142.75.113/
curl http://34.142.75.113/api/health

# 2. 测试域名（如果DNS已传播）
curl -I http://www.rancho.website/
curl http://www.rancho.website/api/health

# 3. 测试HTTPS
curl -I https://www.rancho.website/
curl https://www.rancho.website/api/health
```

## 常见问题

### 问题1：GCP防火墙规则已存在但仍无法访问

**可能原因：**
- 规则的目标标签与实例不匹配
- 规则被其他规则覆盖
- 实例在错误的网络/VPC中

**解决：**
```bash
# 查看所有防火墙规则
gcloud compute firewall-rules list

# 查看规则的详细信息
gcloud compute firewall-rules describe allow-http-all

# 检查规则的优先级（数字越小优先级越高）
```

### 问题2：DNS未传播

**症状：** IP可以访问，但域名无法访问

**解决：**
- 等待DNS传播（可能需要几分钟到几小时）
- 检查DNS配置是否正确
- 使用 `dig` 或 `nslookup` 验证

### 问题3：SSL证书问题

**症状：** HTTP可以访问，但HTTPS无法访问

**解决：**
```bash
# 在服务器上重新申请证书
sudo certbot --nginx -d www.rancho.website
```

## 下一步

1. **最重要：** 检查并创建GCP防火墙规则
2. 测试IP地址访问（绕过DNS）
3. 如果IP可以访问，等待DNS传播
4. 如果IP也无法访问，检查防火墙规则配置






