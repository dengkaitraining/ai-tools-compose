@echo off
setlocal

set /p container_name=請輸入要進入的 Docker 容器名稱或 ID:

if "%container_name%"=="" (
    echo 名稱不可為空！
    exit /b 1
)

docker inspect -f "{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" "%container_name%"

:: 先嘗試 bash，失敗再改用 sh
docker exec -it "%container_name%" bash >nul 2>&1
if errorlevel 1 (
    docker exec -it "%container_name%" sh
) else (
    docker exec -it "%container_name%" bash
)

endlocal