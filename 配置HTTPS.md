# 配置HTTPS（使用Let's Encrypt免费SSL证书）

## 前提条件

1. 你的域名已经解析到服务器IP（34.168.121.40）
2. 服务器上已安装Nginx
3. 服务器可以访问外网（Let's Encrypt需要验证域名）

## 步骤

### 1. 安装Certbot

```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

### 2. 配置Nginx（确保域名正确）

编辑Nginx配置文件：
```bash
sudo nano /etc/nginx/sites-available/ppt-enhancer
```

确保server_name包含你的域名：
```nginx
server {
    listen 80;
    server_name www.rancho.website rancho.website 34.168.121.40;

    client_max_body_size 100M;

    # 静态文件（如果有）
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

测试配置：
```bash
sudo nginx -t
```

如果测试通过，重载Nginx：
```bash
sudo systemctl reload nginx
```

### 3. 获取SSL证书

运行Certbot：
```bash
sudo certbot --nginx -d www.rancho.website -d rancho.website
```

**注意：** 如果你只想为一个域名配置HTTPS，可以只指定一个：
```bash
sudo certbot --nginx -d www.rancho.website
```

Certbot会：
1. 自动验证域名所有权
2. 获取SSL证书
3. 自动修改Nginx配置，添加HTTPS支持
4. 设置自动续期

### 4. 验证HTTPS配置

Certbot会自动修改Nginx配置，添加类似这样的配置：

```nginx
server {
    listen 443 ssl;
    server_name www.rancho.website rancho.website;

    ssl_certificate /etc/letsencrypt/live/www.rancho.website/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.rancho.website/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # ... 其他配置 ...
}

server {
    if ($host = www.rancho.website) {
        return 301 https://$host$request_uri;
    }
    
    listen 80;
    server_name www.rancho.website rancho.website;
    return 404;
}
```

### 5. 测试HTTPS

访问你的网站：
```bash
curl https://www.rancho.website/api/health
```

或者在浏览器中访问：
```
https://www.rancho.website
```

### 6. 自动续期

Let's Encrypt证书有效期90天，Certbot会自动设置续期任务。

测试续期：
```bash
sudo certbot renew --dry-run
```

查看续期任务：
```bash
sudo systemctl status certbot.timer
```

### 7. 更新前端API地址

如果你的前端部署在GitHub Pages或其他地方，需要更新API地址为HTTPS：

编辑 `index.html`，找到：
```javascript
value="http://34.168.121.40"
```

改为：
```javascript
value="https://www.rancho.website"
```

## 常见问题

### 问题1：Certbot验证失败

**原因：** 域名未正确解析到服务器IP

**解决：**
```bash
# 检查DNS解析
dig www.rancho.website
# 或
nslookup www.rancho.website
```

确保返回的IP是 `34.168.121.40`

### 问题2：端口80被占用

**解决：** 确保Nginx正在运行并监听80端口：
```bash
sudo netstat -tlnp | grep :80
sudo systemctl status nginx
```

### 问题3：防火墙阻止

**解决：** 确保防火墙允许80和443端口：
```bash
# Ubuntu/Debian
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 或者如果使用iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### 问题4：需要强制HTTPS重定向

Certbot通常会自动配置，但如果需要手动添加，在HTTP server块中添加：

```nginx
server {
    listen 80;
    server_name www.rancho.website rancho.website;
    return 301 https://$server_name$request_uri;
}
```

## 验证SSL配置

使用SSL Labs测试：
访问 https://www.ssllabs.com/ssltest/analyze.html?d=www.rancho.website

## 完成

配置完成后，你的网站就可以通过HTTPS访问了！

