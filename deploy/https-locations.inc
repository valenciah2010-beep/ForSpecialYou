root /www/wwwroot/default/dist;
client_max_body_size 20m;
location / { try_files $uri $uri/ /index.html; }
location /api/ {
    proxy_pass http://127.0.0.1:3002;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 65s;
}
