# 徒步社区平台 - 后端服务

基于 Pig 微服务框架的徒步社区管理后台。

## 技术栈

- **后端**: Spring Boot 3.4 + Spring Cloud 2024 + MyBatis Plus
- **前端**: Vue 3 + Element Plus + TypeScript (pig-ui)
- **数据库**: MySQL 8.0 + Redis 7
- **服务发现**: Nacos 2.2.3
- **容器化**: Docker Compose

## 快速开始

### 方式一：一键部署（推荐）

双击运行 `start-all.bat`，自动完成：Docker 启动 → 数据库初始化 → Nacos 配置导入 → 服务就绪检查。

部署完成后启动前端：

```bash
cd ../pig-ui
npm install
npm run dev
```

访问 http://localhost:8888，使用 `admin` / `123456` 登录。

### 方式二：手动步骤

#### 1. 环境要求

- Docker Desktop
- Node.js 18+

#### 2. 启动服务

```bash
docker compose up -d --build
```

首次启动时 `db/Dockerfile` 会自动导入所有 SQL（框架表 + 业务表 + 菜单权限 + 菜单清理）。

等待约 2 分钟，确认 6 个容器全部 `Up`：pig-mysql, pig-redis, pig-register, pig-gateway, pig-auth, pig-upms

#### 3. 手动导入数据（仅非首次启动需要）

如果容器已有历史数据（非全新部署），需手动导入业务数据：

```powershell
# PowerShell
docker cp db\init-hiking-permission.sql pig-mysql:/tmp/init.sql
docker exec pig-mysql mysql -uroot -proot pig -e "source /tmp/init.sql"

docker cp db\cleanup-menus.sql pig-mysql:/tmp/cleanup.sql
docker exec pig-mysql mysql -uroot -proot pig -e "source /tmp/cleanup.sql"
```

#### 4. 验证

双击 `verify-backend.bat` 或手动测试：

```bash
curl -s -X POST "http://localhost:9999/auth/oauth2/token" -H "Authorization: Basic cGlnOnBpZw==" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=password&username=admin&password=YehdBPev&scope=server"
```

返回 `access_token` 即正常。

#### 5. 启动前端

```bash
cd ../pig-ui
npm install
npm run dev
```

访问 http://localhost:8888，使用 `admin` / `123456` 登录。

## 服务端口

| 服务 | 宿主端口 | 容器端口 | 说明 |
|------|---------|---------|------|
| MySQL | 33306 | 3306 | 数据库 |
| Redis | 36379 | 6379 | 缓存 |
| Nacos | 8848 | 8848 | 服务发现 / 配置中心 |
| Gateway | 9999 | 9999 | API 网关（前端代理目标） |
| Auth | - | 3000 | 认证服务（内部） |
| UPMS | - | 4000 | 用户权限服务（内部） |
| pig-ui | 8888 | - | 前端开发服务器 |

## 目录结构

```
pig/
├── db/                            # 数据库脚本
│   ├── Dockerfile                 # MySQL 镜像（自动导入全部 SQL）
│   ├── pig.sql                    # Pig 框架基础表
│   ├── pig_config.sql             # Nacos 配置数据
│   ├── init-v2.sql                # 徒步业务表（v6.0）
│   ├── init-hiking-permission.sql # 菜单/角色/权限初始化
│   └── cleanup-menus.sql          # 非业务菜单清理
├── config/nacos-backup/           # Nacos 配置备份
├── docker-compose.yml             # 完整服务编排
├── start-all.bat                  # 一键部署脚本
├── verify-backend.bat             # 一键健康检查
├── stop-all.bat                   # 停止所有服务
├── pig-gateway/                   # 网关服务
├── pig-auth/                      # 认证服务
├── pig-register/                  # Nacos 注册中心
└── pig-upms/                      # 用户权限服务
```

## Sprint1 功能状态

| ID | 功能 | 状态 |
|----|------|------|
| S1-001 | 基础设施启动与验证 | PASS |
| S1-002 | 数据库字段对齐验证 | PASS |
| S1-003 | 菜单数据初始化 (sys_menu) | PASS |
| S1-004 | 角色数据初始化 (sys_role) | PASS |
| S1-005 | 后端服务 admin 登录验证 | PASS |
| S1-006 | 前端 pig-ui 连接后端 | PASS |
| S1-007 | 超管创建用户并分配角色 | PASS |
| S1-008 | 角色菜单权限闭环验证 | PASS |
| S1-009 | 非业务内容清理 | PASS |

## 登录账号

| 账号 | 密码 | 角色 | 说明 |
|------|------|------|------|
| admin | 123456 | 超级管理员 | 拥有全部菜单权限 |
| ops001 | 123456 | 运营专员 | 仅用户中心权限 |

## 常见问题

### 容器启动失败

```bash
docker info                          # 检查 Docker 状态
docker logs pig-mysql                # 查看 MySQL 日志
docker logs pig-register             # 查看 Nacos 日志
```

### 数据库连接

```bash
docker exec pig-mysql mysql -uroot -proot -e "SHOW DATABASES"
docker exec pig-mysql mysql -uroot -proot pig -e "SELECT menu_id, name FROM sys_menu WHERE parent_id = -1"
```

### Nacos 连接失败

确保 pig-register 容器先启动，其他服务依赖 Nacos：

```powershell
docker compose up -d pig-register
# 等待 30 秒
docker compose up -d
```

### 重置数据库

删除 MySQL 数据卷重新初始化：

```powershell
docker compose down
rd /s /q data\mysql
docker compose up -d --build
```

## 相关项目

- **pig-ui**: `../pig-ui/` - 管理后台前端（Vue 3 + Element Plus）
