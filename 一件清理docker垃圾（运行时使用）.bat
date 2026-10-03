# 执行此脚本前，请确保你的工作站容器（AstrBot、NapCat、llama-brain）正处于运行状态
echo "=== 开始清理 Docker 垃圾 ==="

# 1. 强力清除 BuildKit 编译残留 (最吃盘)
docker builder prune -af

# 2. 清除所有未使用的镜像（不单是悬空镜像，只要现在没容器在跑的镜像都清掉，但保留你的拉取记录）
docker image prune -af

# 3. 强力清除已退出的僵尸容器
docker container prune -f

echo "=== 清理完成！ ==="
# 查看清理后的 Docker 磁盘占用情况
docker system df