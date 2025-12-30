# 修复HTTPS配置问题

## 问题
`rancho.website` 域名没有有效的DNS A记录，导致Let's Encrypt验证失败。

## 解决方案

### 方案1：只为 www.rancho.website 申请证书（推荐）

```bash
sudo certbot --nginx -d www.rancho.website
```

这样只会为 `www.rancho.website` 申请证书，`rancho.website` 会通过Nginx重定向到 `www.rancho.website`。

### 方案2：配置DNS记录后再申请

如果你想让 `rancho.website` 也能直接访问，需要先配置DNS：

1. **登录你的域名注册商/DNS服务商**
2. **添加A记录：**
   - 主机名：`rancho.website`（或 `@`）
   - 类型：A
   - 值：`34.168.121.40`
   - TTL：3600（或默认）

3. **等待DNS传播（通常几分钟到几小时）**

4. **验证DNS解析：**
   ```bash
   dig rancho.website
   # 或
   nslookup rancho.website
   ```
   
   应该返回 `34.168.121.40`

5. **然后重新申请证书：**
   ```bash
   sudo certbot --nginx -d www.rancho.website -d rancho.website
   ```

## 推荐操作（方案1）

```bash
# 只为www.rancho.website申请证书
sudo certbot --nginx -d www.rancho.website

# 配置Nginx，让rancho.website重定向到www.rancho.website
sudo nano /etc/nginx/sites-available/ppt-enhancer
```

在配置文件中添加HTTP重定向（在HTTPS server块之前）：

```nginx
# HTTP重定向：rancho.website -> www.rancho.website
server {
    listen 80;
    server_name rancho.website;
    return 301 https://www.rancho.website$request_uri;
}

# HTTPS主配置
server {
    listen 443 ssl;
    server_name www.rancho.website;

    ssl_certificate /etc/letsencrypt/live/www.rancho.website/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.rancho.website/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 100M;

    root /srv/jp-ppt;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}

# HTTP重定向：www.rancho.website -> HTTPS
server {
    if ($host = www.rancho.website) {
        return 301 https://$host$request_uri;
    }
    
    listen 80;
    server_name www.rancho.website;
    return 404;
}
```

测试并重载：
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 验证

访问：
- `https://www.rancho.website` - 应该正常显示
- `http://rancho.website` - 应该重定向到 `https://www.rancho.website`
- `http://www.rancho.website` - 应该重定向到 `https://www.rancho.website`

## 检查DNS配置

如果你想检查DNS配置是否正确：

```bash
# 检查www.rancho.website
dig www.rancho.website +short
# 应该返回: 34.168.121.40

# 检查rancho.website
dig rancho.website +short
# 如果返回空或不是34.168.121.40，说明DNS未配置
```

