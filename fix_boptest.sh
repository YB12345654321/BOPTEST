#!/bin/bash
# BOPTEST 诊断和修复脚本

echo "=========================================="
echo "🔧 BOPTEST 诊断和修复工具"
echo "=========================================="
echo ""

echo "=== 1. 检查 worker 日志 ==="
docker logs project1-boptest-worker-1 --tail 30 2>&1
echo ""

echo "=== 2. 检查 Redis 队列 ==="
docker exec project1-boptest-redis-1 redis-cli KEYS "*" 2>&1 | head -20
echo ""

echo "=== 3. 清空 Redis 队列 ==="
docker exec project1-boptest-redis-1 redis-cli FLUSHALL 2>&1
echo "✅ Redis 已清空"
echo ""

echo "=== 4. 重启 worker 容器 ==="
docker restart project1-boptest-worker-1 project1-boptest-worker-2 2>&1
echo "✅ Worker 已重启"
echo ""

echo "=== 5. 检查并重启 web 服务 ==="
if [ "$(docker ps -a --filter 'name=project1-boptest-web-1' --format '{{.Status}}')" != *"Up"* ]; then
    docker start project1-boptest-web-1 2>&1
    echo "✅ Web 服务已启动"
else
    echo "✅ Web 服务已在运行"
fi
echo ""

echo "=== 6. 等待服务启动 (5秒) ==="
sleep 5
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|boptest"
echo ""

echo "=== 7. 测试 select 请求 ==="
curl -X POST http://localhost/testcases/bestest_air/select \
     -H "Content-Type: application/json" \
     -d '{}' \
     --max-time 90 2>&1 | tail -5
echo ""

echo "=========================================="
echo "✅ 修复完成！现在可以重新运行训练代码了"
echo "=========================================="

