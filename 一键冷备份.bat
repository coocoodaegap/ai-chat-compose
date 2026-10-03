@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 1. 环境准备：定义备份存放路径（放在父目录，完美避开套娃）
set "BACKUP_ROOT=..\AI_Backups"
if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%"

set "TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "OUT_FILE=%BACKUP_ROOT%\Butler_Full_Snapshot_%TIMESTAMP%.zip"

echo [!] 启动全量冷备份模式...

:: 2. 停机释放文件锁
echo [^>] 正在执行: docker-compose stop
docker-compose stop

:: 3. 暴力打包：直接打包当前目录下所有项 (.)
echo [^>] 正在创建全量快照: %OUT_FILE%

:: 这里 "." 代表当前目录全部内容
tar -acf "%OUT_FILE%" .

if %ERRORLEVEL% equ 0 (
    echo [+] 全量备份成功: %OUT_FILE%
) else (
    echo [x] 错误：打包失败。
)

:: 4. 重启服务
echo [^>] 正在重启 Bot 管家...
docker-compose start

echo [OK] 任务完成。
pause