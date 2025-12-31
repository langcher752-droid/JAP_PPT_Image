# 分配静态IP并更新配置

## 当前状态
- ✅ 静态IP已创建：`34.19.16.87`（在us-west1区域）
- ✅ 实例：`instance-20251228-095410`（在us-west1-b区域）
- 需要将静态IP分配给实例

## 步骤1：分配静态IP给实例

```bash
# 查看实例的当前外部IP配置
gcloud compute instances describe instance-20251228-095410 \
    --zone us-west1-b \
    --format="get(networkInterfaces[0].accessConfigs[0].name,networkInterfaces[0].accessConfigs[0].natIP)"

# 删除临时外部IP配置
gcloud compute instances delete-access-config instance-20251228-095410 \
    --zone us-west1-b \
    --access-config-name "External NAT"

# 添加静态IP
gcloud compute instances add-access-config instance-20251228-095410 \
    --zone us-west1-b \
    --access-config-name "External NAT" \
    --address 34.19.16.87

# 验证静态IP已分配
gcloud compute instances describe instance-20251228-095410 \
    --zone us-west1-b \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

**注意：** 删除临时IP时，SSH连接可能会短暂断开。如果断开，等待2-3分钟后重新连接。

## 步骤2：在服务器上验证IP

SSH到服务器后运行：

```bash
# 验证IP已更改
curl ifconfig.me
# 应该返回: 34.19.16.87

# 或
curl ipinfo.io/ip
```

## 步骤3：更新Nginx配置

在服务器上运行：

```bash
# 更新Nginx配置中的IP地址
sudo sed -i 's/136.118.201.245/34.19.16.87/g' /etc/nginx/sites-available/ppt-enhancer

# 验证配置
sudo nginx -t

# 如果配置正确，重载Nginx
sudo systemctl reload nginx

# 测试
curl http://127.0.0.1/api/health
curl http://34.19.16.87/api/health
```

## 步骤4：更新DNS记录

**登录你的域名注册商/DNS服务商，更新A记录：**

- 主机名：`www`
- 类型：`A`
- 值：`34.19.16.87`（静态IP）
- TTL：3600

**如果还有根域名记录：**
- 主机名：`@` 或 `rancho.website`
- 类型：`A`
- 值：`34.19.16.87`
- TTL：3600

## 步骤5：验证修复

**在服务器上测试：**

```bash
# 测试本地
curl http://127.0.0.1/api/health

# 测试静态IP
curl http://34.19.16.87/api/health
```

**在本地电脑上测试（等待DNS传播后）：**

```bash
# 测试静态IP（立即生效）
curl http://34.19.16.87/api/health

# 检查DNS解析（等待传播）
dig www.rancho.website +short
# 应该返回: 34.19.16.87

# 测试域名（DNS传播后）
curl http://www.rancho.website/api/health
```

## 完整命令序列

### 在本地电脑上

```bash
# 1. 删除临时IP
gcloud compute instances delete-access-config instance-20251228-095410 \
    --zone us-west1-b \
    --access-config-name "External NAT"

# 2. 添加静态IP
gcloud compute instances add-access-config instance-20251228-095410 \
    --zone us-west1-b \
    --access-config-name "External NAT" \
    --address 34.19.16.87

# 3. 验证
gcloud compute instances describe instance-20251228-095410 \
    --zone us-west1-b \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

### 在服务器上（SSH重新连接后）

```bash
# 1. 验证IP
curl ifconfig.me

# 2. 更新Nginx配置
sudo sed -i 's/136.118.201.245/34.19.16.87/g' /etc/nginx/sites-available/ppt-enhancer

# 3. 验证并重载
sudo nginx -t && sudo systemctl reload nginx

# 4. 测试
curl http://34.19.16.87/api/health
```

## 注意事项

1. **SSH连接可能断开**：删除临时IP时，SSH连接可能会短暂断开。如果断开：
   - 等待2-3分钟让静态IP生效
   - 使用新IP重新连接：
     ```bash
     gcloud compute ssh instance-20251228-095410 --zone us-west1-b
     ```

2. **DNS传播时间**：DNS更新后，可能需要几分钟到几小时才能完全传播。

3. **防火墙规则**：静态IP使用相同的防火墙规则，不需要额外配置。

## 验证完成

完成后，应该能够：

1. ✅ 使用静态IP `34.19.16.87` 访问服务器
2. ✅ DNS指向静态IP
3. ✅ 网站可以正常访问
4. ✅ 重启实例后IP不会变化

## 完成！

配置静态IP后，IP地址将永久固定，不会因为实例重启而改变。




