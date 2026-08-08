#!/bin/bash

read -p "請輸入要進入的 Docker 容器名稱或 ID: " container_name

if [ -z "$container_name" ]; then
    echo "名稱不可為空！"
    exit 1
fi

docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name"
docker exec -it "$container_name" bash 2>/dev/null || docker exec -it "$container_name" sh
