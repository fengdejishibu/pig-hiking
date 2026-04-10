#!/bin/bash
# Nacos 配置导入脚本
# 在 docker-compose up 后运行，将配置恢复到 Nacos
# 用法: ./import-nacos.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NACOS_URL="http://localhost:8848"
NACOS_USERNAME="nacos"
NACOS_PASSWORD="nacos"
GROUP="DEFAULT_GROUP"

echo "=========================================="
echo "  Nacos 配置导入脚本"
echo "=========================================="

# 等待 Nacos 服务就绪
echo "[1/5] 等待 Nacos 服务就绪..."
for i in {1..30}; do
    if curl -s "${NACOS_URL}/nacos/v1/console/health" > /dev/null 2>&1; then
        echo "      Nacos 服务已就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "      错误: Nacos 服务启动超时"
        exit 1
    fi
    echo "      等待中... ($i/30)"
    sleep 2
done

sleep 2

# 配置文件列表
CONFIG_FILES=(
    "application-dev.yml"
    "pig-auth-dev.yml"
    "pig-gateway-dev.yml"
    "pig-upms-biz-dev.yml"
    "pig-codegen-dev.yml"
    "pig-monitor-dev.yml"
    "pig-quartz-dev.yml"
)

echo "[2/5] 导入配置文件..."

for config_file in "${CONFIG_FILES[@]}"; do
    config_path="${SCRIPT_DIR}/${config_file}"
    if [ -f "$config_path" ]; then
        echo "      导入: ${config_file}"
        content=$(cat "$config_path" | sed 's/ /%20/g' | tr '\n' ' ' | sed 's/ /%0A/g' | sed 's/%0A$//')

        # URL 编码处理
        content=$(python3 -c "
import urllib.parse
import sys
content = open('$config_path', 'r', encoding='utf-8').read()
print(urllib.parse.quote(content, safe=''))
" 2>/dev/null) || content=$(cat "$config_path" | base64)

        curl -s -X POST "${NACOS_URL}/nacos/v1/cs/configs?dataId=${config_file}&group=${GROUP}&username=${NACOS_USERNAME}&password=${NACOS_PASSWORD}&type=yaml" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "content=${content}" > /dev/null

        if [ $? -eq 0 ]; then
            echo "      ✓ ${config_file} 导入成功"
        else
            echo "      ✗ ${config_file} 导入失败"
        fi
    else
        echo "      ! ${config_file} 不存在，跳过"
    fi
done

echo "[3/5] 验证配置..."
sleep 2

for config_file in "${CONFIG_FILES[@]}"; do
    result=$(curl -s "${NACOS_URL}/nacos/v1/cs/configs?dataId=${config_file}&group=${GROUP}&username=${NACOS_USERNAME}&password=${NACOS_PASSWORD}" 2>/dev/null)
    if [ -n "$result" ] && [ "$result" != "null" ]; then
        echo "      ✓ ${config_file} 验证通过"
    else
        echo "      ! ${config_file} 验证失败或为空"
    fi
done

echo ""
echo "[4/5] 等待服务注册..."
sleep 5

echo "[5/5] 检查服务状态..."
curl -s "${NACOS_URL}/nacos/v1/ns/instance/list?serviceName=pig-upms-biz" \
    -u "${NACOS_USERNAME}:${NACOS_PASSWORD}" 2>/dev/null | grep -q "ip" && \
    echo "      ✓ pig-upms-biz 已注册" || echo "      ! pig-upms-biz 未注册（等待中）"

curl -s "${NACOS_URL}/nacos/v1/ns/instance/list?serviceName=pig-auth" \
    -u "${NACOS_USERNAME}:${NACOS_PASSWORD}" 2>/dev/null | grep -q "ip" && \
    echo "      ✓ pig-auth 已注册" || echo "      ! pig-auth 未注册（等待中）"

curl -s "${NACOS_URL}/nacos/v1/ns/instance/list?serviceName=pig-gateway" \
    -u "${NACOS_USERNAME}:${NACOS_PASSWORD}" 2>/dev/null | grep -q "ip" && \
    echo "      ✓ pig-gateway 已注册" || echo "      ! pig-gateway 未注册（等待中）"

echo ""
echo "=========================================="
echo "  Nacos 配置导入完成！"
echo "=========================================="
echo ""
echo "  访问 Nacos 控制台: ${NACOS_URL}/nacos"
echo "  账号: ${NACOS_USERNAME} / ${NACOS_PASSWORD}"
echo ""
