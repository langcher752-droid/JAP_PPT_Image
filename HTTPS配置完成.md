# HTTPS配置完成 ✅

## 证书信息

- **证书路径：** `/etc/letsencrypt/live/www.rancho.website/fullchain.pem`
- **私钥路径：** `/etc/letsencrypt/live/www.rancho.website/privkey.pem`
- **有效期至：** 2026-03-30（90天）
- **自动续期：** 已配置 ✅

## 验证HTTPS

### 1. 测试API接口

```bash
curl https://www.rancho.website/api/health
```

应该返回JSON响应。

### 2. 在浏览器中访问

访问：`https://www.rancho.website`

应该看到：
- 🔒 浏览器地址栏显示锁图标
- 网站正常加载
- HTTP请求自动重定向到HTTPS

### 3. 检查SSL配置

使用SSL Labs测试（可选）：
访问：https://www.ssllabs.com/ssltest/analyze.html?d=www.rancho.website

## 更新前端API地址

如果你的前端部署在GitHub Pages或其他地方，需要更新API地址为HTTPS：

### 编辑 index.html

找到这一行：
```javascript
value="http://34.168.121.40"
```

改为：
```javascript
value="https://www.rancho.website"
```

或者如果前端也在同一服务器：
```javascript
value="https://www.rancho.website"
```

### 提交更新

```bash
git add index.html
git commit -m "Update API URL to HTTPS"
git push
```

## 证书自动续期

Certbot已经配置了自动续期任务。证书会在到期前自动续期。

### 查看续期任务

```bash
sudo systemctl status certbot.timer
```

### 手动测试续期

```bash
sudo certbot renew --dry-run
```

### 手动续期（如果需要）

```bash
sudo certbot renew
sudo systemctl reload nginx
```

## 完成 ✅

现在你的网站已经支持HTTPS了！

- ✅ HTTPS正常工作
- ✅ HTTP自动重定向到HTTPS
- ✅ 证书自动续期已配置
- ✅ 安全连接已启用

## 注意事项

1. **证书有效期：** 90天，会自动续期
2. **DNS配置：** 确保 `www.rancho.website` 的DNS记录指向 `34.168.121.40`
3. **防火墙：** 确保443端口开放
4. **前端更新：** 记得更新前端代码中的API地址为HTTPS

## 故障排查

如果HTTPS不工作：

1. **检查Nginx状态：**
   ```bash
   sudo systemctl status nginx
   ```

2. **检查Nginx配置：**
   ```bash
   sudo nginx -t
   ```

3. **查看Nginx错误日志：**
   ```bash
   sudo tail -n 50 /var/log/nginx/error.log
   ```

4. **检查证书文件：**
   ```bash
   sudo ls -la /etc/letsencrypt/live/www.rancho.website/
   ```

5. **检查443端口：**
   ```bash
   sudo netstat -tlnp | grep :443
   ```

