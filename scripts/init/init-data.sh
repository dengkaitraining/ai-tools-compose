#!/bin/bash
# =============================================================================
# 專案名稱: ai-tools-compose
# 檔案用途: PostgreSQL 資料庫初始化指令腳本 (init-data.sh)
# 執行時機: postgres 容器首次啟動且 `/var/lib/postgresql/data` 為空時自動執行
# 掛載位置: `/docker-entrypoint-initdb.d/init-data.sh`
# 功能說明:
#   1. 檢查系統環境變數 POSTGRES_NON_ROOT_USER 與 POSTGRES_NON_ROOT_PASSWORD
#   2. 使用超級管理員 (POSTGRES_USER) 登入 PostgreSQL 資料庫 (POSTGRES_DB)
#   3. 自動創建非 Root 之專用帳號，並授予對應資料庫的完整管理與 Schema 建立權限
# =============================================================================

set -e;

# 檢查非 Root 使用者帳號與密碼變數是否已正確設定
if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
	echo "PostgreSQL 初始化: 正在建立非 Root 使用者 [${POSTGRES_NON_ROOT_USER}] 及賦予資料庫 [${POSTGRES_DB}] 存取權限..."
	
	# 透過 psql 執行 SQL 語法
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		-- 建立指定名稱與密碼的資料庫使用者
		CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
		-- 授予該使用者對目標資料庫的所有權限
		GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_NON_ROOT_USER};
		-- 授予在 public Schema 下建立資料表的權限
		GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
	EOSQL

	echo "PostgreSQL 初始化成功: 使用者 [${POSTGRES_NON_ROOT_USER}] 設定完成。"
else
	echo "SETUP INFO: 未偵測到 POSTGRES_NON_ROOT_USER / POSTGRES_NON_ROOT_PASSWORD 環境變數，跳過非 Root 使用者建立作業。"
fi
