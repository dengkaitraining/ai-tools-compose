# `LLM-AI-Tools` 跨平台一站式微服務容器化方案

![GitHub repo size](https://img.shields.io/github/repo-size/dengkaitraining/llm-ai-tools)
![GitHub language count](https://img.shields.io/github/languages/count/dengkaitraining/llm-ai-tools)
![GitHub top language](https://img.shields.io/github/languages/top/dengkaitraining/llm-ai-tools)
![GitHub last commit](https://img.shields.io/github/last-commit/dengkaitraining/llm-ai-tools?color=red)
![Docker Compose V2](https://img.shields.io/badge/Docker--Compose-V2-blue?logo=docker)
![License](https://img.shields.io/badge/License-MIT-green)

「**`LLM-AI-Tools` 跨平台一站式微服務容器化方案**」 是一個整合 `Ollama`（本地 `LLM`）、`Qdrant`（向量資料庫）、`n8n`（工作流引擎）與 `Apache Tika`（文件解析），打造 100% 地端部署與完全資料隱私之 `AI` 自動化堆疊；支援 `Linux`、`Windows WSL2` 及 `macOS` 跨平台部署，實現企業級 `RAG` 與自動化工作流。

---

## 1. 專案簡介 (Description)

本專案整合 6 大核心微服務與 1 個自動初始化修復服務：
- **init-dir**: 自動化資料目錄建立與跨平台權限修復服務（於 Compose 啟動時自動判斷 Windows / Linux / macOS 並修復權限）。
- **Ollama**: 本地大語言模型 (LLM) 推理引擎，支援 Llama 3, Qwen, Mistral 等模型。
- **Qdrant**: 高效能向量資料庫 (Vector Database)，提供 RAG 語意檢索與向量檢索功能。
- **Open WebUI**: 現代化 Web 聊天圖形介面，整合 Ollama 模型、Qdrant 向量庫與 Tika 文件解析。
- **PostgreSQL 18**: 關聯式資料庫，作為 n8n 工作流引擎之核心資料儲存庫。
- **n8n**: 流程自動化與 AI Agent 流程編排平台，支援節點式串接與自動化任務執行。
- **Apache Tika**: 文件文本擷取伺服器，自動解析 PDF、Word 等格式並優化 RAG 前處理。

---

### 1.1 系統架構圖 (System Architecture)

```mermaid
graph TD
    subgraph Host ["宿主機 (Host System)"]
        subgraph BridgeNet ["Docker Bridge 網路: web-app-bridge"]
            
            subgraph Init_Container ["初始化與權限修復"]
                InitDir["init-dir 容器<br/>(自動辨識 OS 套用修復)"]
            end

            subgraph WebUI_Container ["Open WebUI 容器"]
                OpenWebUI["Open WebUI<br/>(Port 3000 -> 8080)"]
            end
            
            subgraph AI_Core ["AI 推理與向量核心"]
                Ollama["Ollama 推理引擎<br/>(Port 11434)"]
                Qdrant["Qdrant 向量庫<br/>(Port 6333 / 6334)"]
                Tika["Apache Tika 伺服器<br/>(Port 9998)"]
            end
            
            subgraph Automation_Stack ["工作流與資料庫"]
                n8n["n8n 工作流平台<br/>(Port 5678)"]
                Postgres["PostgreSQL 18 資料庫<br/>(Port 5432)"]
            end
            
        end

        subgraph LocalData ["專案本地實體資料目錄 (./data/)"]
            DataOllama["./data/ollama"]
            DataQdrant["./data/qdrant"]
            DataWebUI["./data/open-webui"]
            DataPostgres["./data/postgres"]
            DataN8n["./data/n8n"]
        end
    end

    %% 初始化順序
    InitDir -->|"完成權限修復"| n8n
    InitDir -->|"自動建立目錄"| LocalData

    %% 連線關係
    OpenWebUI -->|"LLM API"| Ollama
    OpenWebUI -->|"Vector Query"| Qdrant
    OpenWebUI -->|"Doc Parse"| Tika
    
    n8n -->|"DB Connection"| Postgres
    n8n -->|"AI Node Call"| Ollama

    %% 資料掛載
    Ollama -.->|"Volume Bind"| DataOllama
    Qdrant -.->|"Volume Bind"| DataQdrant
    OpenWebUI -.->|"Volume Bind"| DataWebUI
    Postgres -.->|"Volume Bind"| DataPostgres
    n8n -.->|"Volume Bind"| DataN8n
```

---

### 1.2 系統流程圖 (System Flowchart)

```mermaid
flowchart TD
    Start[執行 docker compose up -d] --> A[啟動 init-dir 容器]
    A --> B{檢測宿主機作業系統}
    B -->|Linux| C[套用 Native POSIX 權限 1000:1000 & 775]
    B -->|Windows WSL2| D[套用 NTFS 777 存取權限與設定]
    B -->|macOS| E[套用 virtioFS 自動映射 1000:1000 & 775]
    C --> F[init-dir 成功退出 Exit 0]
    D --> F
    E --> F
    F --> G[啟動微服務堆疊: Ollama, Qdrant, Postgres, n8n, Open WebUI, Tika]
    G --> H[Open WebUI 執行 /api/version 健康檢查並呈綠燈]
```

---

### 1.3 系統時序圖 (Sequence Diagram)

```mermaid
sequenceDiagram
    autonumber
    actor User as 使用者
    participant Init as init-dir 服務
    participant WebUI as Open WebUI (Frontend/Backend)
    participant Tika as Apache Tika
    participant Qdrant as Qdrant 向量庫
    participant Ollama as Ollama 推理引擎
    participant n8n as n8n 自動化平台
    participant DB as PostgreSQL 18

    %% 初始化階段
    Init->>Init: 1. 自動檢測宿主 OS (Linux/Windows/macOS) 並修復 ./data/n8n 權限
    Init-->>n8n: 2. 權限修復完成，釋放啟動依賴

    %% RAG 知識庫上傳與對話
    User->>WebUI: 3. 上傳文件檔 (PDF/DOCX) 建立知識庫
    WebUI->>Tika: 4. 傳送文件進行內文文字抽離 (no_ocr 模式)
    Tika-->>WebUI: 5. 回傳抽離之純文字內容
    WebUI->>Qdrant: 6. 計算 Embedding 並寫入向量索引
    Qdrant-->>WebUI: 7. 確認向量儲存完成

    User->>WebUI: 8. 發送對話問題 Prompt
    WebUI->>Qdrant: 9. 搜尋相關 Context 向量
    Qdrant-->>WebUI: 10. 回傳最相符內容區段
    WebUI->>Ollama: 11. 發送 Prompt + Context 請求模型生成
    Ollama-->>WebUI: 12. 串流 (Stream) 回傳 AI 生成解答
    WebUI-->>User: 13. 網頁呈現最終回答

    %% 工作流觸發
    User->>n8n: 14. 觸發 Webhook 或自動化工作流程
    n8n->>DB: 15. 讀寫工作流程與狀態紀錄
    DB-->>n8n: 16. 回傳查詢資料
    n8n->>Ollama: 17. 呼叫 LLM 進行自動化處理
    Ollama-->>n8n: 18. 回傳 AI 處理結果
```

---

## 2. 安裝與建置指南 (Installation and Setup)

### 2.1 系統環境需求
在安裝本專案前，請確保系統已安裝以下軟體：
- **Docker Desktop** (Windows / macOS) 或 **Docker Engine** 20.10+ (Linux)
- **Docker Compose** V2 (`docker compose` 指令)
- **Git**

### 2.2 專案複製與初始化
1. **複製專案庫**:
   ```bash
   git clone https://github.com/dengkaitraining/llm-ai-tools.git
   cd llm-ai-tools
   ```

2. **建立環境變數設定檔**:
   複製 `.env.example` 為 `.env`，並根據部署需求調整自訂金鑰與密碼：
   ```bash
   cp .env.example .env
   ```

---

## 3. 設定說明 (Configuration)

### 3.1 環境變數 (`.env`)
專案提供完整簡潔之 `.env` 變數設定，主要參數如下：

| 分類 | 變數名稱 | 預設值 / 建議值 | 說明 |
| :--- | :--- | :--- | :--- |
| **Global** | `DATA_DIR` | `./data` | 資料儲存根目錄 |
| | `GENERIC_TIMEZONE` | `Asia/Taipei` | 系統與排程運作時區 |
| **Ollama** | `OLLAMA_DOCKER_TAG` | `latest` | Ollama 容器映像檔版本 |
| | `OLLAMA_BASE_URL` | `http://llm-ai-ollama:11434` | Open WebUI 連接 Ollama 之內部網址 |
| **Open WebUI** | `WEBUI_DOCKER_TAG` | `main` | Open WebUI 容器映像檔版本 |
| | `WEBUI_SECRET_KEY` | `(隨機密碼)` | 用於 Session/Cookie 加密之金鑰 |
| | `ENABLE_SIGNUP` | `False` | 是否開放新使用者自由註冊 |
| **Qdrant** | `VECTOR_DB` | `qdrant` | 指定向量資料庫類型 |
| | `QDRANT_URI` | `http://llm-ai-qdrant:6333` | Qdrant 內部 REST API 位址 |
| | `QDRANT_API_KEY` | `(自訂密碼)` | Qdrant 管理者 API 金鑰 |
| **Tika** | `TIKA_SERVER_URL` | `http://llm-ai-tika:9998` | Tika 文件解析伺服器內部網址 |
| **PostgreSQL** | `POSTGRES_USER` | `root` | PostgreSQL 管理者帳號 |
| | `POSTGRES_PASSWORD` | `(自訂密碼)` | PostgreSQL 管理者密碼 |
| | `POSTGRES_DB` | `n8n` | 預設建立之資料庫名稱 |
| **n8n** | `N8N_DOMAIN_NAME` | `localhost` | n8n 服務網域名稱 |
| | `N8N_WEBHOOK_URL` | `https://your-domain.com/` | n8n 外部 Webhook 呼叫位址 |

### 3.2 實體目錄資料持久化 (Volume Persistence)
所有微服務容器資料均掛載至專案內部的實體相對目錄 `./data/`：
- `./data/ollama`: 儲存下載之 Ollama LLM 模型與快取。
- `./data/qdrant`: 儲存 Qdrant 向量索引與資料庫檔。
- `./data/open-webui`: 儲存 Open WebUI 使用者設定與 SQLite 庫。
- `./data/postgres`: 儲存 PostgreSQL 18 資料庫檔案。
- `./data/n8n`: 儲存 n8n 工作流程、金鑰與憑證。

### 3.3 跨平台相容性處理 (Linux & Windows & macOS)
- **`init-dir` 自動修復服務**: [init-dir.sh](file:///home/dengkai/projects/ai-tools-compose/init-dir.sh) 在容器啟動時自動解析 `/proc/version` 與 `uname -r` 判斷宿主作業系統：
  - **Linux**: 設定屬主 `1000:1000` (n8n node 使用者) 與 `775` 權限。
  - **Windows (WSL2 / NTFS)**: 設定 `777` 存取權限並搭配 `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false` 避免 POSIX 語法崩潰。
  - **macOS (virtioFS / Docker Desktop)**: 設定屬主 `1000:1000` 與 `775` 權限。
- **`.gitattributes`**: 設定 `*.sh text eol=lf`，確保 Shell 腳本 (`init-data.sh`, `init-dir.sh`) 在 Windows clone 時維持 Unix LF 格式，避免 `/bin/bash` 報錯 `\r: command not found`。
- **Open WebUI 健康檢查修正**: 將容器健康檢查端點覆寫為 `/api/version` (`curl -sf http://localhost:8080/api/version`)，解決原生 `/health` 回傳 HTML 導致 `jq` 解析失敗報錯 `unhealthy` 的問題。

### 3.4 程式與服務設定檔功能描述

| 檔案名稱 | 檔案類型 | 詳細說明與功能描述 |
| :--- | :--- | :--- |
| [docker-compose.yaml](docker-compose.yaml) | YAML | 微服務編排主檔。定義 `init-dir` 權限修復服務、6 大 AI 服務容器、`web-app-bridge` 外部橋接網路與健康檢查設定。 |
| [.env.example](.env.example) | ENV | 環境變數範本檔。提供預設範例值與豐富的欄位說明註解，包含 PostgreSQL 密碼、Qdrant API 金鑰、Open WebUI 密鑰與 n8n 時區。 |
| [init-dir.sh](/scripts/init/init-dir.sh) | Shell | **跨平台自動修復腳本**。自動判斷 Linux / Windows (WSL2) / macOS 並修正 `./data/n8n` 等 Volume 掛載權限。 |
| [init-data.sh](/scripts/init/init-data.sh) | Shell | **PostgreSQL 初始化腳本**。在 Postgres 容器首次啟動時自動建立 n8n 專用非 root 資料庫使用者與權限。 |
| [tika-config.xml](/tika-config.xml/tika-config.xml) | XML | Apache Tika 配置文件。停用高耗能的 Tesseract OCR，優化大批次 PDF/DOCX 文字萃取效能。 |
| [.gitattributes](.gitattributes) | Config | 跨平台 Git 換行符強制設定檔。確保所有 `*.sh` Shell 腳本強制保持 Unix LF 格式。 |

---

## 4. 執行與啟動本地服務 (Usage / Getting Started)

### 4.1 啟動容器服務
使用以下指令在背景啟動所有微服務：
```bash
docker compose up -d
```

### 4.2 檢查容器運作狀態
```bash
docker compose ps
```

### 4.3 檢視服務即時日誌 (Logs)
```bash
docker compose logs -f [service_name]
```

### 4.4 停止與關閉服務
```bash
docker compose down
```

### 4.5 服務存取端點 (Endpoints)
容器啟動完成後，可透過瀏覽器存取以下服務：

| 服務名稱 | 存取網址 / 端點 | 預設說明 |
| :--- | :--- | :--- |
| **Open WebUI** | [http://localhost:3000](http://localhost:3000) | 圖形化對話與 RAG 管理介面 |
| **n8n 工作流** | [http://localhost:5678](http://localhost:5678) | 工作流自動化與 AI Agent 編輯器 |
| **Qdrant Dashboard** | [http://localhost:6333/dashboard](http://localhost:6333/dashboard) | 向量資料庫控制台 |
| **Ollama API** | [http://localhost:11434](http://localhost:11434) | Ollama REST API 端點 |
| **Apache Tika** | [http://localhost:9998](http://localhost:9998) | Tika 文件萃取 REST Server |
| **PostgreSQL 18** | `localhost:5432` | 關聯式資料庫服務端點 |

---

## 5. 資料夾結構與架構簡述 (Project Structure)

```
llm-ai-tools/
├── data/                         # 容器實體資料持久化目錄
│   ├── n8n/                      # n8n 工作流與設定
│   ├── ollama/                   # Ollama 大模型檔與快取
│   ├── open-webui/               # Open WebUI 帳號與對話庫
│   ├── postgres/                 # PostgreSQL 資料庫檔案
│   └── qdrant/                   # Qdrant 向量庫檔案
├── docs/                         # 專案相關文件與參考說明
├── local-files/                  # n8n 容器共用本機檔案交換目錄
├── scripts/                      # 專案腳本程式
│   ├── init/                     # 專案初始化腳本程式
│   │   ├── init-data.sh          # PostgreSQL 初始化非 Root 使用
│   │   └── init-dir.sh           # 跨平台資料目錄自動建立與權限修
│   └── man/                      # 專案手動腳本程式
│       ├── enter_dc.bat          # 快速進入 Docker 容器之互動式輔助腳本 (batch)
│       ├── enter_dc.ps1          # 快速進入 Docker 容器之互動式輔助腳本 (powershell)
│       ├── enter_dc.sh           # 快速進入 Docker 容器之互動式輔助腳本 (shell script)
│       ├── ip_dc_all.ps1         # 快速查詢 Docker Compose 所有容器之 IP 位址 (powershell)
│       ├── ip_dc_all.sh          # 快速查詢 Docker Compose 所有容器之 IP 位址 (shell script)
│       ├── ip_dc.ps1             # 快速查詢單一 Docker 容器之 IP 位址 (powershell)
│       └── ip_dc.sh              # 快速查詢單一 Docker 容器之 IP 位址 (shell script)
├── tika-config.xml/              # Apache Tika 自訂設定檔目錄
│   └── tika-config.xml           # PDF 停用 OCR 效能設定檔
├── .env.example                  # 環境變數範本檔
├── .gitattributes                # Git 跨平台換行符規則設定檔
├── .gitignore                    # Git 忽略檔案設定
├── docker-compose.yaml           # Docker Compose 微服務編排主設定檔
└── README.md                     # 專案說明文件
```

---

## 6. 系統測試與驗證 (System Testing and Verification)

### 6.1 Compose 語法驗證
執行以下指令驗證 `docker-compose.yaml` 與 `.env` 變數解析是否無誤：
```bash
docker compose config
```

### 6.2 服務健康檢查測試
- **PostgreSQL 18**:
  ```bash
  docker compose exec postgres pg_isready -h localhost -U root -d n8n
  ```
- **Open WebUI (API 健康端點)**:
  ```bash
  curl -sf http://localhost:8080/api/version
  ```
- **Ollama API**:
  ```bash
  curl http://localhost:11434/api/tags
  ```

---

## 7. 貢獻與授權 (Contributing and License)

### 貢獻指南
歡迎提出 Issue 或發起 Pull Request！改善內容可包含服務升級、新 AI 模組整合或文件優化。

### 授權條款 (License)
本專案採用 [MIT License](LICENSE) 授權釋出。