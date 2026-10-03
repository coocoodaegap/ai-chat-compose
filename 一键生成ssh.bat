@echo off
chcp 65001 >nul
SET CONTAINER_NAME=astrbot
SET PUBKEY_PATH=%~dp0mayonnaise_pubkey.txt

echo ===================================================
echo.

:: 1. 检查容器是否运行
docker ps --filter "name=%CONTAINER_NAME%" --filter "status=running" | findstr %CONTAINER_NAME% >nul
if %errorlevel% NEQ 0 (
    echo [ERROR] 容器 "%CONTAINER_NAME%" 当前未运行！
    echo 请先在 E:\AI_Workstation 下执行: docker compose up -d
    echo.
    pause
    exit /b 1
)

echo [INFO] 检查到容器 "%CONTAINER_NAME%" 正在运行。

:: 2. 检查密钥是否已经存在（防止误操作覆写导致原密钥失效）
docker exec %CONTAINER_NAME% test -f /root/.ssh/id_ed25519_mayonnaise >nul 2>&1
if %errorlevel% EQU 0 (
    echo [INFO] 检测到 Bot 管家的专属密钥已存在，跳过生成步骤。
    goto :print_key
)

echo [INFO] 开始在容器命名卷中铸造Bot 管家的专属 SSH 钥匙...

:: 3. 强行建立目录并生成密钥（原生 0600 权限保护）
docker exec %CONTAINER_NAME% mkdir -p /root/.ssh
docker exec %CONTAINER_NAME% chmod 700 /root/.ssh
docker exec %CONTAINER_NAME% ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519_mayonnaise
if %errorlevel% NEQ 0 (
    echo [ERROR] 密钥生成失败！请检查容器状态。
    pause
    exit /b 1
)
echo [SUCCESS] 专属私钥已在容器内安全生成，权限已自动锁定为 0600。

:: 4. 预热 GitHub 域名指纹，防止第一次拉取时弹出 [yes/no] 交互导致死锁
echo [INFO] 正在预热 GitHub 域名指纹 (known_hosts)...
docker exec %CONTAINER_NAME% sh -c "ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null"
echo [SUCCESS] GitHub 已加入容器信任列表。

:print_key
:: 5. 将公钥从容器内拷贝到 Windows 宿主机的 data 目录下
echo [INFO] 正在导出公钥到宿主机...
docker cp %CONTAINER_NAME%:/root/.ssh/id_ed25519_mayonnaise.pub "%PUBKEY_PATH%" >nul
if %errorlevel% NEQ 0 (
    echo [ERROR] 导出公钥失败！
    pause
    exit /b 1
)

echo.
echo ===================================================
echo [SUCCESS] Bot 管家的公钥已导出到 Windows 宿主机 [5.1]：
echo %PUBKEY_PATH%
echo ---------------------------------------------------
echo 请复制以下框内的全部内容，并贴到Bot 管家的 GitHub 账号中：
echo ---------------------------------------------------
type "%PUBKEY_PATH%"
echo ===================================================
echo.
pause