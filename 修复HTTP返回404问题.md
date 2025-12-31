# 修复HTTP返回404问题

## 问题发现
- ✅ 后端服务正常
- ✅ location /api/ 配置存在
- ❌ HTTP server块（端口80）被Certbot配置为 `return 404;`

## 问题分析

查看配置发现：
```nginx
server {
    listen 80;
    server_name rancho.website www.rancho.website 136.118.201.245;
    return 404; # managed by Certbot  <-- 这里导致所有HTTP请求返回404
}
```

Certbot自动配置了HTTP到HTTPS的重定向，但配置有问题。

## 修复方案

### 方案1：修复HTTP server块（推荐）

编辑Nginx配置：

```bash
sudo nano /etc/nginx/sites-available/ppt-enhancer
```

**修改HTTP server块：**

```nginx
server {
    listen 80;
    server_name rancho.website www.rancho.website 136.118.201.245;

    client_max_body_size 100M;

    # API请求代理到后端
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    # 静态文件
    root /srv/jp-ppt;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**完整的配置文件应该是：**

```nginx
# HTTP server块
server {
    listen 80;
    server_name rancho.website www.rancho.website 136.118.201.245;

    client_max_body_size 100M;

    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    send_timeout 600s;

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    root /srv/jp-ppt;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}

# HTTPS server块
server {
    listen 443 ssl;
    server_name rancho.website www.rancho.website 136.118.201.245;

    ssl_certificate /etc/letsencrypt/live/www.rancho.website-0001/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.rancho.website-0001/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 100M;

    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    send_timeout 600s;

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    root /srv/jp-ppt;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 方案2：快速修复（使用sed）

```bash
# 备份配置
sudo cp /etc/nginx/sites-available/ppt-enhancer /etc/nginx/sites-available/ppt-enhancer.backup

# 删除return 404行并添加配置
sudo sed -i '/return 404; # managed by Certbot/d' /etc/nginx/sites-available/ppt-enhancer

# 在HTTP server块中添加location配置（如果还没有）
# 需要手动编辑，因为sed无法很好地处理多行插入
```

## 应用修复

```bash
# 1. 编辑配置
sudo nano /etc/nginx/sites-available/ppt-enhancer

# 2. 删除HTTP server块中的 return 404; 行
# 3. 确保HTTP server块有location /api/配置

# 4. 测试配置
sudo nginx -t

# 5. 重载Nginx
sudo systemctl reload nginx

# 6. 测试
curl http://127.0.0.1/api/health
curl http://136.118.201.245/api/health
```

## 验证修复

修复后，应该看到：

```bash
$ curl http://127.0.0.1/api/health
{"status":"ok","message":"PPT图片增强服务运行正常",...}

$ curl http://136.118.201.245/api/health
{"status":"ok","message":"PPT图片增强服务运行正常",...}
```

而不是404错误。

## 关于静态IP

注意：实例在 `us-west1-b`，但静态IP创建在 `europe-west2`。需要：

1. 删除错误的静态IP（如果在错误的区域）
2. 在正确的区域创建静态IP：`us-west1`

```bash
# 删除错误的静态IP
gcloud compute addresses delete ppt-enhancer-static-ip --region europe-west2

# 在正确区域创建静态IP
gcloud compute addresses create ppt-enhancer-static-ip --region us-west1

# 查看创建的IP
gcloud compute addresses list
```

## 完成

修复HTTP server块后，网站应该可以正常访问了！






