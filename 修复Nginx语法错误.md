# 修复Nginx语法错误

## 问题
Nginx配置语法错误：`unexpected "}" in /etc/nginx/sites-enabled/ppt-enhancer:46`

## 修复步骤

### 1. 查看配置文件

```bash
# 查看配置文件内容
sudo cat /etc/nginx/sites-available/ppt-enhancer

# 查看第46行附近的内容
sudo sed -n '40,50p' /etc/nginx/sites-available/ppt-enhancer
```

### 2. 检查配置语法

```bash
# 测试配置语法
sudo nginx -t

# 查看详细错误
sudo nginx -T 2>&1 | grep -A 5 -B 5 "error"
```

### 3. 修复配置

最可能的问题是：
- 多余的 `}`
- 缺少 `}`
- server块结构不正确

**正确的完整配置应该是：**

```bash
sudo nano /etc/nginx/sites-available/ppt-enhancer
```

**完整配置内容：**

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

### 4. 验证并应用

```bash
# 测试配置
sudo nginx -t

# 如果测试通过，重载Nginx
sudo systemctl reload nginx

# 如果重载失败，重启Nginx
sudo systemctl restart nginx

# 检查状态
sudo systemctl status nginx

# 测试
curl http://127.0.0.1/api/health
curl http://136.118.201.245/api/health
```

## 快速修复脚本

如果配置文件很乱，可以重新创建：

```bash
# 1. 备份原配置
sudo cp /etc/nginx/sites-available/ppt-enhancer /etc/nginx/sites-available/ppt-enhancer.backup.$(date +%Y%m%d_%H%M%S)

# 2. 创建新配置
sudo tee /etc/nginx/sites-available/ppt-enhancer > /dev/null << 'EOF'
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
EOF

# 3. 测试配置
sudo nginx -t

# 4. 如果测试通过，重载
sudo systemctl reload nginx

# 5. 测试
curl http://127.0.0.1/api/health
```

## 检查常见错误

```bash
# 检查括号匹配
sudo grep -o '[{}]' /etc/nginx/sites-available/ppt-enhancer | sort | uniq -c

# 应该看到相同数量的 { 和 }

# 检查server块
sudo grep -c "server {" /etc/nginx/sites-available/ppt-enhancer
sudo grep -c "^}" /etc/nginx/sites-available/ppt-enhancer
```

## 验证修复

修复后，应该看到：

```bash
$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

$ curl http://127.0.0.1/api/health
{"status":"ok","message":"PPT图片增强服务运行正常",...}
```




