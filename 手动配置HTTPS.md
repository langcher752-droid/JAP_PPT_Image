# 手动配置HTTPS（Certbot自动配置失败时的解决方案）

## 问题
Certbot自动配置失败，出现 `AttributeError: can't set attribute` 错误。

## 解决方案：手动配置SSL

### 步骤1：获取SSL证书（使用standalone模式）

```bash
# 停止Nginx（Certbot需要临时使用80端口）
sudo systemctl stop nginx

# 使用standalone模式获取证书（不需要修改Nginx配置）
sudo certbot certonly --standalone -d www.rancho.website

# 启动Nginx
sudo systemctl start nginx
```

### 步骤2：手动配置Nginx支持HTTPS

编辑Nginx配置文件：
```bash
sudo nano /etc/nginx/sites-available/ppt-enhancer
```

**完整的配置示例：**

```nginx
# HTTP重定向到HTTPS
server {
    listen 80;
    server_name www.rancho.website rancho.website 34.168.121.40;
    return 301 https://www.rancho.website$request_uri;
}

# HTTPS配置
server {
    listen 443 ssl http2;
    server_name www.rancho.website;

    # SSL证书路径（Certbot会自动创建）
    ssl_certificate /etc/letsencrypt/live/www.rancho.website/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.rancho.website/privkey.pem;
    
    # SSL配置（使用Certbot推荐的配置）
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    client_max_body_size 100M;

    # 静态文件
    root /srv/jp-ppt;
    index index.html;

    # API请求代理到Gunicorn
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
    }

    # 前端页面
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 步骤3：测试配置

```bash
# 测试Nginx配置
sudo nginx -t

# 如果测试通过，重载Nginx
sudo systemctl reload nginx
```

### 步骤4：验证HTTPS

```bash
# 测试HTTPS连接
curl https://www.rancho.website/api/health

# 在浏览器中访问
# https://www.rancho.website
```

### 步骤5：配置自动续期

编辑续期脚本：
```bash
sudo nano /etc/letsencrypt/renewal/www.rancho.website.conf
```

确保配置正确：
```ini
[renewalparams]
account = YOUR_ACCOUNT_ID
authenticator = standalone
server = https://acme-v02.api.letsencrypt.org/directory
```

测试续期：
```bash
sudo certbot renew --dry-run
```

## 如果standalone模式也失败

### 使用DNS验证（最可靠的方法）

```bash
# 使用DNS验证模式
sudo certbot certonly --manual --preferred-challenges dns -d www.rancho.website
```

Certbot会提示你添加DNS TXT记录，按照提示操作即可。

## 检查证书

```bash
# 查看证书信息
sudo certbot certificates

# 查看证书文件
sudo ls -la /etc/letsencrypt/live/www.rancho.website/
```

应该看到：
- `cert.pem` - 证书
- `chain.pem` - 证书链
- `fullchain.pem` - 完整证书链（Nginx使用这个）
- `privkey.pem` - 私钥

## 常见问题

### 问题1：证书文件不存在

如果证书文件不存在，检查：
```bash
sudo ls -la /etc/letsencrypt/live/
```

如果没有 `www.rancho.website` 目录，说明证书获取失败。

### 问题2：Nginx启动失败

检查错误日志：
```bash
sudo tail -n 50 /var/log/nginx/error.log
```

### 问题3：SSL证书过期

证书有效期90天，自动续期应该已经配置。手动续期：
```bash
sudo certbot renew
sudo systemctl reload nginx
```

## 完成

配置完成后，你的网站就可以通过HTTPS访问了！

访问：`https://www.rancho.website`

