#!/bin/bash

# set -e: 脚本中任何命令执行失败，就立刻停止执行
set -e

# --- 1. 定义变量 ---
CONTAINER_NAME="my-postgis-container"
IMAGE_NAME="my-postgis-image:latest"
NETWORK_NAME="postgis_net"


# --- 2. 清理旧的容器 ---
echo "INFO: Checking for and removing old container named '$CONTAINER_NAME'..."
# `docker ps -a -q` 列出所有容器ID，`-f name=` 进行过滤
if [ "$(docker ps -a -q -f name=$CONTAINER_NAME)" ]; then
    echo "INFO: Old container found, stopping and removing..."
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    echo "INFO: Old container removed."
else
    echo "INFO: No old container found."
fi


# --- 3. 准备数据目录 ---
echo "INFO: Resetting data and log directories..."
# 使用 sudo 是因为目录可能已被容器内的用户(999)拥有
sudo rm -rf ./postgres_data
sudo rm -rf ./postgres_logs

mkdir ./postgres_data
mkdir ./postgres_logs

echo "INFO: Setting correct ownership for directories..."
# 这一步对于 Docker 来说同样重要，可以避免权限问题
sudo chown -R 999:999 ./postgres_data
sudo chown -R 999:999 ./postgres_logs
echo "INFO: Directories are ready."


# --- 4. 构建镜像 ---
echo "INFO: Building container image '$IMAGE_NAME' from Dockerfile..."
docker build -t "$IMAGE_NAME" .


# --- 5. 准备网络 ---
# Docker 的网络管理非常直接，不会有 rootless 的问题
echo "INFO: Checking for network '$NETWORK_NAME'..."
# `docker network ls -q` 列出网络ID
if [ -z "$(docker network ls -q -f name=$NETWORK_NAME)" ]; then
    echo "INFO: Network not found. Creating network '$NETWORK_NAME'..."
    docker network create "$NETWORK_NAME"
    echo "INFO: Network created."
else
    echo "INFO: Network already exists."
fi


# --- 6. 运行新容器 ---
echo "INFO: Starting new container '$CONTAINER_NAME'..."
docker run \
    -d \
    --name "$CONTAINER_NAME" \
    --network "$NETWORK_NAME" \
    -p 35432:5432 \
    -e "POSTGRES_PASSWORD=ds123456" \
    -v "$(pwd)/postgres_data:/var/lib/postgresql/data:z" \
    -v "$(pwd)/postgres_logs:/var/lib/postgresql/logs:z" \
    -v "$(pwd)/postgresql.conf:/etc/postgresql/postgresql.conf:z" \
    --restart=always \
    "$IMAGE_NAME" \
    -c config_file=/etc/postgresql/postgresql.conf

# 等待一小会儿，给容器一点启动时间
sleep 5

# --- 7. 显示最终状态 ---
echo ""
echo "SUCCESS: Deployment finished!"
echo "--------------------------------------------------"
docker ps -f "name=$CONTAINER_NAME"
echo "--------------------------------------------------"
echo "You can check logs with: docker logs -f $CONTAINER_NAME"
echo "You can connect to the database via port 35432."
echo "--------------------------------------------------"
