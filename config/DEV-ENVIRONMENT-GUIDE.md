# 开发环境构建指南

> 徒步社区平台 - Sprint1
> 更新日期：2026-04-02
> 适用对象：新同学快速搭建开发环境

---

## 一、环境架构

```
┌─────────────────────────────────────────────────────────┐
│                    开发环境架构                          │
├─────────────────────────────────────────────────────────┤
│  MySQL (3306)     Redis (6379)    Nacos (8848)   Mongo (27017)  │
│  ├─ pig           └─ 缓存/会话     └─ 配置中心     └─ hiking_db    │
│  ├─ pig_config                                                        │
│  └─ hiking_db                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 二、前置条件

| 工具 | 版本 | 检查命令 |
|------|------|----------|
| Docker | 20.0+ | `docker --version` |
| Docker Compose | 2.0+ | `docker-compose --version` |
| Git | 2.0+ | `git --version` |

---

## 三、文件清单

```
db/
├── docker-compose.infra.yml   # 中间件编排（MySQL/Redis/Nacos/Mongo）
├── .cnb.yml                   # CI/CD 流水线配置
├── pig.sql                    # Pig框架业务表
├── pig_config.sql             # Nacos配置数据
├── init-v2.sql                # 徒步业务表
├── init-mongodb-v2.js         # MongoDB集合初始化
└── redis-keys-v2.md           # Redis Key设计参考
```

---

## 四、一键启动

```bash
cd db/
docker-compose -f docker-compose.infra.yml up -d
```

**执行顺序（自动）：**
```
01-pig.sql → 02-pig_config.sql → 03-hiking_db.sql
```

---

## 五、验证检查

### 5.1 容器状态

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**期望输出：**
```
hiking-mysql    Up (healthy)    0.0.0.0:3306->3306/tcp
hiking-redis    Up (healthy)    0.0.0.0:6379->6379/tcp
hiking-nacos    Up (healthy)    0.0.0.0:8848->8848/tcp
hiking-mongo    Up              0.0.0.0:27017->27017/tcp
```

### 5.2 数据库验证

```bash
# MySQL - 检查三个数据库
docker exec hiking-mysql mysql -uroot -proot -e "SHOW DATABASES;"

# 期望输出包含: pig, pig_config, hiking_db
```

```bash
# MongoDB - 检查集合
docker exec hiking-mongo mongosh --eval "db.getSiblingDB('hiking_db').user_profiles.getIndexes()"

# 期望输出包含: user_id 唯一索引
```

```bash
# Redis - 连通性
docker exec hiking-redis redis-cli ping

# 期望输出: PONG
```

```bash
# Nacos - 控制台
curl -s http://127.0.0.1:8848/nacos/ | head -5

# 期望输出: HTML内容（包含 Nacos 标题）
```

---

## 六、连接信息

| 服务 | 地址 | 用户名 | 密码 |
|------|------|--------|------|
| MySQL | localhost:3306 | root | root |
| Redis | localhost:6379 | - | - |
| Nacos | http://localhost:8848/nacos | nacos | nacos |
| MongoDB | mongodb://localhost:27017 | - | - |

---

## 七、应用配置

**application.yml 模板：**

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/hiking_db
    username: root
    password: root

  data:
    redis:
      host: localhost
      port: 6379

    mongodb:
      uri: mongodb://localhost:27017/hiking_db

  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
      config:
        server-addr: localhost:8848
```

---

## 八、CI/CD 部署

### 8.1 流水线配置

`.cnb.yml` 已配置：
- **镜像仓库**: 阿里云 ACR
- **部署目标**: 8.135.20.173:8080

### 8.2 触发构建

```bash
# 推送代码后自动触发
git push origin main
```

### 8.3 验证部署

```bash
# 外部访问
curl http://8.135.20.173:8080

# 服务器状态
ssh root@8.135.20.173 "docker ps | grep hiking-test"
```

---

## 九、常用命令

| 操作 | 命令 |
|------|------|
| 启动所有 | `docker-compose -f docker-compose.infra.yml up -d` |
| 停止所有 | `docker-compose -f docker-compose.infra.yml down` |
| 查看日志 | `docker-compose -f docker-compose.infra.yml logs -f` |
| 重置数据 | `docker-compose -f docker-compose.infra.yml down -v` |
| 进入MySQL | `docker exec -it hiking-mysql mysql -uroot -proot` |
| 进入Redis | `docker exec -it hiking-redis redis-cli` |
| 进入Mongo | `docker exec -it hiking-mongo mongosh` |

---

## 十、故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 容器启动失败 | 端口被占用 | `netstat -ano | findstr :3306` 检查端口 |
| Nacos 连接失败 | 依赖MySQL未就绪 | 等待MySQL健康检查通过 |
| 数据库不存在 | 初始化脚本未执行 | 检查 volumes 挂载路径 |
| Redis 连接超时 | 容器未启动 | `docker start hiking-redis` |

---

## 十一、数据库结构速查

### MySQL 数据库

| 数据库 | 表 | 用途 |
|--------|-----|------|
| pig | sys_user, sys_role, sys_menu | Pig框架核心 |
| pig_config | config_info | Nacos配置存储 |
| hiking_db | hiking_invite_code | 徒步业务 |

### MongoDB 集合

| 集合 | 字段 | 用途 |
|------|------|------|
| user_profiles | user_id, nickname, avatar, is_leader, is_vip, level | 用户扩展信息 |

### Redis Key

| Key | 用途 |
|-----|------|
| sms:code:{phone} | 验证码 (5min TTL) |
| login:fail:{phone} | 登录失败计数 (30min TTL) |

---

*文档版本: v1.0 | 适用于 Sprint1*
