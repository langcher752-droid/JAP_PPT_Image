# 修复Nginx配置IP地址

## 问题
Nginx配置中的server_name包含旧IP地址 `34.168.121.40`，但新服务器IP是 `34.142.75.113`。

## 修复步骤

### 1. 更新Nginx配置

在服务器上运行：

```bash
# 编辑Nginx配置
sudo nano /etc/nginx/sites-available/ppt-enhancer
```

**修改server_name行：**
```nginx
# 将旧IP替换为新IP
server_name rancho.website www.rancho.website 34.142.75.113;
```

**完整的配置应该是：**
```nginx
# HTTP重定向到HTTPS（如果有SSL）
server {
    listen 80;
    server_name rancho.website www.rancho.website 34.142.75.113;
    
    # 如果有SSL，重定向到HTTPS
    # return 301 https://$server_name$request_uri;
    
    # 如果没有SSL，直接服务
    client_max_body_size 100M;
    
    root /srv/jp-ppt;
    index index.html;
    
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
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# HTTPS配置（如果已配置SSL）
server {
    listen 443 ssl;
    server_name rancho.website www.rancho.website 34.142.75.113;
    
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
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 2. 测试配置

```bash
# 测试Nginx配置语法
sudo nginx -t
```

### 3. 重载Nginx

```bash
# 重载Nginx配置
sudo systemctl reload nginx

# 或重启Nginx
sudo systemctl restart nginx

# 检查状态
sudo systemctl status nginx
```

### 4. 验证修复

```bash
# 在服务器上测试
curl -I http://127.0.0.1/
curl http://127.0.0.1/api/health

# 测试外部IP（从服务器内部）
curl -I http://34.142.75.113/
curl http://34.142.75.113/api/health
```

### 5. 在本地电脑上测试

```bash
# 测试IP地址
curl -I http://34.142.75.113/
curl http://34.142.75.113/api/health

# 测试域名
curl -I http://www.rancho.website/
curl http://www.rancho.website/api/health
```

## 快速修复命令

```bash
# 1. 备份原配置
sudo cp /etc/nginx/sites-available/ppt-enhancer /etc/nginx/sites-available/ppt-enhancer.backup

# 2. 替换IP地址
sudo sed -i 's/34.168.121.40/34.142.75.113/g' /etc/nginx/sites-available/ppt-enhancer

# 3. 验证配置
sudo nginx -t

# 4. 重载Nginx
sudo systemctl reload nginx

# 5. 测试
curl http://127.0.0.1/api/health
curl http://34.142.75.113/api/health
```

## 如果仍然超时

### 检查1：确认外部IP是否正确

```bash
# 在服务器上查看实际的外部IP
curl ifconfig.me
# 或
curl ipinfo.io/ip

# 应该返回: 34.142.75.113
```

### 检查2：检查Nginx是否监听所有接口

```bash
# 检查端口监听
sudo netstat -tlnp | grep -E ':(80|443)'

# 应该看到 0.0.0.0:80 和 0.0.0.0:443
# 如果是 127.0.0.1:80，说明只监听本地，需要修改配置
```

### 检查3：检查防火墙规则是否生效

```bash
# 在GCP控制台检查防火墙规则
# 确保 allow-http 和 allow-https 规则已创建并启用
```

## 完成

修复后，网站应该可以正常访问了！




