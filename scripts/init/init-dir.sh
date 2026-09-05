#!/bin/sh
# =============================================================================
# 專案名稱: llm-ai-tools
# 檔案用途: 跨平台實體資料目錄與權限初始化自動修復腳本
# 說明: 自動檢測宿主作業系統 (Windows WSL / Linux / macOS) 並套用對應權限策略
# =============================================================================
set -e

echo "[init-dir] Starting directory initialization and cross-platform permission setup..."

# 1. 建立所有必要的 ./data 子目錄
#mkdir -p /data/n8n /data/ollama /data/vllm /data/open-webui /data/postgres /data/qdrant
mkdir -p /data/n8n /data/ollama /data/open-webui /data/postgres /data/qdrant

# 2. 檢測宿主機 OS 環境 (Linux / Windows WSL / macOS Docker Desktop)
KERNEL_INFO=$(uname -r 2>/dev/null || true)
PROC_VERSION=$(cat /proc/version 2>/dev/null || true)

if echo "$KERNEL_INFO $PROC_VERSION" | grep -qiE "WSL|microsoft"; then
    OS_TYPE="windows"
elif echo "$KERNEL_INFO $PROC_VERSION" | grep -qiE "linuxkit|lima|orbstack|darwin"; then
    OS_TYPE="mac"
else
    OS_TYPE="linux"
fi

echo "[init-dir] Detected host OS environment: ${OS_TYPE}"

# 3. 根據作業系統執行針對性修復策略
case "$OS_TYPE" in
    "windows")
        echo "[init-dir] Applying Windows (WSL2/NTFS) permission fix..."
        # Windows NTFS 存取不支援傳統 POSIX UID 映射，設定 777 寬鬆權限以確保相容
        chmod -R 777 /data/n8n 2>/dev/null || true
        chown -R 1000:1000 /data/n8n 2>/dev/null || true
        ;;
    "mac")
        echo "[init-dir] Applying macOS (virtiofs/gRPC-FUSE) permission fix..."
        # macOS Docker Desktop 具備自動 UID 映射層，設定 1000:1000 屬主與 775 權限
        chown -R 1000:1000 /data/n8n 2>/dev/null || true
        chmod -R 775 /data/n8n 2>/dev/null || true
        ;;
    "linux")
        echo "[init-dir] Applying Native Linux (POSIX) permission fix..."
        # 原生 Linux 採用嚴格 POSIX 權限，設定 node 專用屬主 1000:1000 與 775 權限
        chown -R 1000:1000 /data/n8n 2>/dev/null || true
        chmod -R 775 /data/n8n 2>/dev/null || true
        ;;
    *)
        echo "[init-dir] Applying default permission fix..."
        chown -R 1000:1000 /data/n8n 2>/dev/null || true
        chmod -R 777 /data/n8n 2>/dev/null || true
        ;;
esac

echo "[init-dir] Directory initialization and permission setup completed successfully!"
