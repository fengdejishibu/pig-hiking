# Nacos 配置备份与恢复

此目录包含 Nacos 配置文件的备份，用于在新机器上快速恢复配置。

## 目录结构

```
nacos-backup/
├── README.md           # 本文件
├── import-nacos.sh    # Linux/Mac 导入脚本
├── import-nacos.bat   # Windows 导入脚本
├── application-dev.yml       # 主配置文件
├── pig-auth-dev.yml          # 认证服务配置
├── pig-gateway-dev.yml       # 网关配置
├── pig-upms-biz-dev.yml      # UPMS 服务配置
├── pig-codegen-dev.yml       # 代码生成服务配置
├── pig-monitor-dev.yml       # 监控服务配置
└── pig-quartz-dev.yml       # 定时任务服务配置
```

## 快速开始

### 方式一：使用启动脚本（推荐）

1. 确保 Docker 服务运行中
2. 启动后端服务：
   ```bash
   cd C:/Study/软工实训/Go_For_Walk/Platform
   docker-compose up -d
   ```
3. 等待约 30 秒让 Nacos 完全启动
4. 运行导入脚本：
   ```bash
   # Windows
   .\config\nacos-backup\import-nacos.bat

   # 或 Linux/Mac
   bash ./config/nacos-backup/import-nacos.sh
   ```
5. 验证：访问 http://localhost:8848/nacos ，账号 `nacos`/`nacos`

### 方式二：手动导入

1. 访问 http://localhost:8848/nacos
2. 进入「配置管理」→「配置列表」
3. 点击「+」按钮，逐个创建配置：
   - 选择对应的 dataId（如 `application-dev.yml`）
   - 选择类型 `yaml`
   - 复制对应文件内容粘贴

## 配置文件说明

| 配置文件 | 说明 | 关键内容 |
|----------|------|----------|
| application-dev.yml | 主配置文件 | 数据库连接、Redis、Mybatis-Plus |
| pig-auth-dev.yml | 认证服务配置 | OAuth2 密钥、允许的客户端 |
| pig-gateway-dev.yml | 网关配置 | 路由规则、限流配置 |
| pig-upms-biz-dev.yml | UPMS 服务配置 | 数据源、文件上传配置 |
| pig-codegen-dev.yml | 代码生成服务 | 数据源配置 |
| pig-monitor-dev.yml | 监控服务 | 安全配置 |
| pig-quartz-dev.yml | 定时任务服务 | 数据源配置 |

## 环境变量

配置文件中使用环境变量，允许通过 docker-compose 或系统环境覆盖：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| MYSQL_HOST | 127.0.0.1 | MySQL 主机 |
| MYSQL_PORT | 3306 | MySQL 端口 |
| MYSQL_DB | pig | 数据库名 |
| MYSQL_USERNAME | root | 数据库用户名 |
| MYSQL_PASSWORD | root | 数据库密码 |
| REDIS_HOST | 127.0.0.1 | Redis 主机 |
| REDIS_PORT | 6379 | Redis 端口 |
| REDIS_PASSWORD | (空) | Redis 密码 |
| REDIS_DATABASE | 0 | Redis 数据库编号 |

Docker Compose 中的设置：
```yaml
pig-upms:
  environment:
    MYSQL_HOST: pig-mysql
    REDIS_HOST: pig-redis
```

## 更新配置

当修改了 Nacos 配置后，需要同步更新此目录：

```bash
# 在 Windows PowerShell 中运行
$configs = @("application-dev.yml", "pig-auth-dev.yml", "pig-gateway-dev.yml", "pig-upms-biz-dev.yml", "pig-codegen-dev.yml", "pig-monitor-dev.yml", "pig-quartz-dev.yml")
foreach ($config in $configs) {
    curl -s "http://localhost:8848/nacos/v1/cs/configs?dataId=$config&group=DEFAULT_GROUP&username=nacos&password=nacos" -o ".\config\nacos-backup\$config"
}
```

## 故障排除

### 配置导入后服务仍无法连接数据库

1. 检查 MySQL 容器是否正常运行：
   ```bash
   docker ps | grep pig-mysql
   ```

2. 检查数据库是否初始化：
   ```bash
   docker exec pig-mysql mysql -uroot -proot -e "SHOW DATABASES;"
   ```

3. 确认 Nacos 配置中的数据库地址与 docker-compose 中的服务名一致

### 服务注册失败

1. 检查网络连通性：
   ```bash
   docker exec pig-upms ping pig-mysql
   docker exec pig-upms ping pig-redis
   docker exec pig-upms ping pig-register
   ```

2. 查看服务日志：
   ```bash
   docker logs pig-upms
   docker logs pig-auth
   docker logs pig-gateway
   ```
