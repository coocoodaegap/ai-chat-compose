@echo off
chcp 65001 >nul
ping 180.76.76.76 -n 2 -w 2000 >nul 2>&1

if %errorlevel% neq 0 (
    echo 【错误】未联网，程序已停止。
    pause
    exit /b
)

docker-compose down

docker-compose up -d --build