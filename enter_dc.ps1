Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# 詢問使用者輸入 Docker 容器名稱或 ID
$containerName = Read-Host "請輸入要進入的 Docker 容器名稱或 ID"

# 檢查是否為空
if ([string]::IsNullOrWhiteSpace($containerName)) {
    Write-Host "名稱不可為空！"
    exit 1
}

# 顯示容器名稱與 IP
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $containerName

# 優先嘗試 bash，失敗則改用 sh
docker exec -it $containerName bash 2>$null

if ($LASTEXITCODE -ne 0) {
    docker exec -it $containerName sh
}