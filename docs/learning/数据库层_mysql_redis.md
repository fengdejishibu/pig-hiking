# Pig 数据库与缓存设计文档

> **目标受众**：开发者、数据库管理员
> **目标**：理解 Pig 项目的数据库设计、Redis 缓存策略，以及企业级数据库管理实践

---

## 第一章：数据库概览

### 1.1 技术栈

| 组件 | 版本 | 用途 |
|------|------|------|
| MySQL | 8.0+ | 主数据库，存储业务数据 |
| Redis | 7.0+ | 缓存、会话、Token |
| MyBatis Plus | 3.5.15 | ORM 框架 |
| Druid | - | 数据库连接池（可选） |

### 1.2 数据库连接配置

```yaml
# application.yml
spring:
  datasource:
    type: com.zaxxer.hikari.HikariDataSource
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      minimum-idle: 10
      maximum-pool-size: 20
      idle-timeout: 30000
  data:
    dynamic: true
    druid:
      initial-size: 5
      min-idle: 5
      max-active: 20
      max-wait: 60000
```

---

## 第二章：核心数据表设计

### 2.1 用户权限模块

#### sys_user（用户表）

```sql
CREATE TABLE `sys_user` (
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `username` VARCHAR(50) COMMENT '用户名',
  `password` VARCHAR(100) COMMENT '密码',
  `salt` VARCHAR(100) COMMENT '随机盐',
  `phone` VARCHAR(20) COMMENT '手机号',
  `avatar` VARCHAR(255) COMMENT '头像',
  `dept_id` BIGINT COMMENT '部门ID',
  `lock_flag` CHAR(1) DEFAULT '0' COMMENT '锁定标记',
  `del_flag` CHAR(1) DEFAULT '0' COMMENT '删除标记',
  `create_by` VARCHAR(64) COMMENT '创建人',
  `update_by` VARCHAR(64) COMMENT '修改人',
  `create_time` DATETIME COMMENT '创建时间',
  `update_time` DATETIME COMMENT '修改时间',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_username` (`username`)
) COMMENT '用户表';
```

**字段说明**：
| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | BIGINT | 雪花算法生成的主键 |
| `salt` | VARCHAR(100) | 密码加密盐值 |
| `lock_flag` | CHAR(1) | 0=正常, 9=锁定 |
| `del_flag` | CHAR(1) | 0=正常, 1=删除（逻辑删除） |

#### sys_role（角色表）

```sql
CREATE TABLE `sys_role` (
  `role_id` BIGINT NOT NULL COMMENT '角色ID',
  `role_name` VARCHAR(50) COMMENT '角色名称',
  `role_code` VARCHAR(50) COMMENT '角色编码',
  `role_desc` VARCHAR(255) COMMENT '角色描述',
  `ds_type` CHAR(1) DEFAULT '0' COMMENT '数据权限类型',
  `del_flag` CHAR(1) DEFAULT '0' COMMENT '删除标记',
  `create_by` VARCHAR(64) COMMENT '创建人',
  `update_by` VARCHAR(64) COMMENT '修改人',
  `create_time` DATETIME COMMENT '创建时间',
  `update_time` DATETIME COMMENT '修改时间',
  PRIMARY KEY (`role_id`)
) COMMENT '角色表';
```

#### sys_menu（菜单权限表）

```sql
CREATE TABLE `sys_menu` (
  `menu_id` BIGINT NOT NULL COMMENT '菜单ID',
  `name` VARCHAR(50) COMMENT '菜单名称',
  `permission` VARCHAR(100) COMMENT '权限标识',
  `path` VARCHAR(255) COMMENT '路由路径',
  `parent_id` BIGINT COMMENT '父菜单ID',
  `icon` VARCHAR(100) COMMENT '图标',
  `sort_order` INT DEFAULT 0 COMMENT '排序',
  `type` CHAR(1) COMMENT '类型 0-菜单 1-按钮',
  `del_flag` CHAR(1) DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`menu_id`)
) COMMENT '菜单权限表';
```

### 2.2 关联关系表

#### sys_user_role（用户角色关联）

```sql
CREATE TABLE `sys_user_role` (
  `user_id` BIGINT NOT NULL COMMENT '用户ID',
  `role_id` BIGINT NOT NULL COMMENT '角色ID',
  PRIMARY KEY (`user_id`, `role_id`)
) COMMENT '用户角色关联表';
```

#### sys_role_menu（角色菜单关联）

```sql
CREATE TABLE `sys_role_menu` (
  `role_id` BIGINT NOT NULL COMMENT '角色ID',
  `menu_id` BIGINT NOT NULL COMMENT '菜单ID',
  PRIMARY KEY (`role_id`, `menu_id`)
) COMMENT '角色菜单关联表';
```

### 2.3 ER 图

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  sys_user    │         │ sys_user_role│         │  sys_role    │
│──────────────│         │──────────────│         │──────────────│
│ user_id (PK) │────────►│ user_id (FK)│◄────────│ role_id (PK) │
│ username     │         │ role_id (FK)│         │ role_name   │
│ password    │         └──────────────┘         │ role_code  │
│ dept_id     │                                   └───────┬──────┘
└───────┬──────┘                                           │
                                                            │
                                                            ▼
                                            ┌──────────────┐         ┌──────────────┐
                                            │sys_role_menu │         │  sys_menu    │
                                            │──────────────│         │──────────────│
                                            │ role_id (FK) │◄────────│ menu_id (PK) │
                                            │ menu_id (FK) │         │ name        │
                                            └──────────────┘         │ permission  │
                                                                     │ path        │
                                                                     └──────────────┘
```

---

## 第三章：Redis 缓存设计

### 3.1 缓存 Key 命名规范

| Key 前缀 | 用途 | TTL | 示例 |
|---------|------|-----|------|
| `pig_oauth_access:` | OAuth2 Token | 根据配置 | `pig_oauth_access:eyJhbGc...` |
| `pig_oauth_refresh:` | 刷新 Token | 根据配置 | `pig_oauth_refresh:xxx` |
| `user_details:` | 用户详情缓存 | 30分钟 | `user_details:admin` |
| `sys_dept:` | 部门缓存 | 30分钟 | `sys_dept:1` |
| `sys_menu:` | 菜单缓存 | 30分钟 | `sys_menu:*` |

### 3.2 Token 存储结构

```
Key: pig_oauth_access:{access_token_value}
Value: OAuth2Authorization 序列化对象
TTL: access_token 有效期（默认 7200 秒）

存储内容：
{
  "id": "授权ID",
  "registeredClientId": "客户端ID",
  "principalName": "用户名",
  "accessToken": {
    "tokenValue": "xxx",
    "issuedAt": "2025-03-30T10:00:00",
    "expiresAt": "2025-03-30T12:00:00"
  }
}
```

### 3.3 用户信息缓存

```java
// 缓存 Key: user_details:{username}
// 缓存 Value: UserInfo 对象 JSON

@Cacheable(value = CacheConstants.USER_DETAILS, key = "#username")
public UserInfo getUserInfo(String username) {
    // 查询数据库
}

// 清除缓存
@CacheEvict(value = CacheConstants.USER_DETAILS, key = "#username")
public void updateUserInfo(UserDTO userDTO) {
    // 更新数据库
}
```

### 3.4 缓存常量定义

```java
// CacheConstants.java
public interface CacheConstants {
    String USER_DETAILS = "user_details";
    String SYS_MENU = "sys_menu";
    String SYS_DEPT = "sys_dept";
    String PROJECT_OAUTH_ACCESS = "pig_oauth_access";
    String PROJECT_OAUTH_REFRESH = "pig_oauth_refresh";
    String CAPTCHA_CODE_KEY = "captcha_code:";
}
```

---

## 第四章：企业级数据库管理实践

### 4.1 数据库连接池配置

#### HikariCP（推荐）

```yaml
spring:
  datasource:
    type: com.zaxxer.hikari.HikariDataSource
    hikari:
      # 最小空闲连接数
      minimum-idle: 10
      # 最大连接池大小
      maximum-pool-size: 20
      # 空闲连接超时时间（毫秒）
      idle-timeout: 30000
      # 连接超时时间（毫秒）
      connection-timeout: 30000
      # 连接最大存活时间（毫秒）
      max-lifetime: 1800000
      # 连接测试查询
      connection-test-query: SELECT 1
```

#### Druid（带监控）

```yaml
spring:
  datasource:
    type: com.alibaba.druid.pool.DruidDataSource
    druid:
      initial-size: 5
      min-idle: 5
      max-active: 20
      max-wait: 60000
      # 监控配置
      stat-view-servlet:
        enabled: true
        url-pattern: /druid/*
```

### 4.2 多数据源配置

```java
// 动态数据源配置
@Configuration
public class DynamicDataSourceConfig {

    @Bean
    @ConfigurationProperties("spring.datasource.dynamic")
    public DataSourceProperties dynamicDataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean
    @Primary
    public DataSource dynamicDataSource() {
        return dynamicDataSourceProperties()
            .initializeDataSourceBuilder()
            .build();
    }
}
```

### 4.3 读写分离配置

```yaml
# 主库配置
spring:
  datasource:
    master:
      url: jdbc:mysql://master-host:3306/pig
      username: root
      password: password
    slave:
      url: jdbc:mysql://slave-host:3306/pig
      username: root
      password: password
```

```java
// 读写分离路由
@Component
public class ReadWriteRouting extends AbstractRoutingDataSource {
    @Override
    protected Object determineCurrentLookupKey() {
        // 根据操作类型选择数据源
        return TransactionSynchronizationManager.isCurrentTransactionReadOnly()
            ? "slave"
            : "master";
    }
}
```

---

## 第五章：数据库管理前端实践

### 5.1 常用数据库管理工具

| 工具 | 用途 | 访问方式 |
|------|------|---------|
| Navicat | 数据库可视化管理 | 客户端软件 |
| DBeaver | 开源数据库工具 | 客户端软件 |
| phpMyAdmin | MySQL Web 管理 | 浏览器访问 |
| Adminer | 轻量级数据库管理 | 浏览器访问 |

### 5.2 Redis 管理工具

| 工具 | 用途 | 特点 |
|------|------|------|
| RedisInsight | Redis 官方可视化 | 图形化界面 |
| RedisDesktopManager | 桌面管理工具 | 跨平台 |
| Redis Commander | Web 管理界面 | 开源免费 |
| redis-cli | 命令行工具 | 官方内置 |

### 5.3 监控指标

```yaml
# Actuator 监控配置
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,env
  endpoint:
    health:
      show-details: always
    metrics:
      enabled: true
```

### 5.4 健康检查

```java
// 数据库健康检查
@Component
public class DatabaseHealthIndicator implements HealthIndicator {

    @Autowired
    private DataSource dataSource;

    @Override
    public Health health() {
        try (Connection conn = dataSource.getConnection()) {
            if (conn.isValid(1)) {
                return Health.up().withDetail("database", "MySQL").build();
            }
        } catch (SQLException e) {
            return Health.down(e);
        }
        return Health.unknown();
    }
}

// Redis 健康检查
@Component
public class RedisHealthIndicator implements HealthIndicator {

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Override
    public Health health() {
        try {
            String pong = redisTemplate.getConnectionFactory()
                .getConnection()
                .ping();
            return Health.up().withDetail("redis", pong).build();
        } catch (Exception e) {
            return Health.down(e);
        }
    }
}
```

---

## 第六章：性能优化

### 6.1 索引优化

```sql
-- 用户名索引（已存在）
CREATE UNIQUE INDEX uk_username ON sys_user(username);

-- 部门查询优化
CREATE INDEX idx_dept_parent ON sys_dept(parent_id);

-- 日志查询优化
CREATE INDEX idx_log_create_time ON sys_log(create_time);
CREATE INDEX idx_log_type ON sys_log(type);

-- 角色菜单查询优化
CREATE INDEX idx_role_menu ON sys_role_menu(role_id, menu_id);
```

### 6.2 分区表设计

```sql
-- 日志表按时间分区
CREATE TABLE sys_log_2025_03 PARTITION OF sys_log
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- 自动创建分区
CREATE OR REPLACE FUNCTION create_log_partition()
RETURNS void AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    start_date := DATE_TRUNC('month', CURRENT_DATE);
    end_date := start_date + INTERVAL '1 month';
    partition_name := 'sys_log_' || TO_CHAR(start_date, 'YYYY_MM');

    EXECUTE format('CREATE TABLE IF NOT EXISTS %s PARTITION OF sys_log
        FOR VALUES FROM (%L) TO (%L)',
        partition_name, start_date, end_date);
END;
$$ LANGUAGE plpgsql;
```

### 6.3 查询优化

```java
// ✅ 使用索引覆盖
@Select("SELECT user_id, username FROM sys_user WHERE username = #{username}")
SysUser selectUsernameIndex(@Param("username") String username);

// ✅ 批量查询
List<SysUser> users = userMapper.selectBatchIds(userIds);

// ❌ 避免 N+1 查询
// 错误：循环中查询
for (Long roleId : roleIds) {
    Role role = roleMapper.selectById(roleId);  // 每次查询一条
}

// 正确：一次性查询
List<Role> roles = roleMapper.selectBatchIds(roleIds);
```

---

## 第七章：数据迁移

### 7.1 Flyway 配置

```yaml
spring:
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true
    validate-on-migrate: true
```

### 7.2 迁移脚本命名

```
db/migration/
├── V1.0.0__init_schema.sql          # 初始化表结构
├── V1.0.2__add_user_table.sql      # 添加用户表
├── V1.1.0__add_menu_permission.sql  # 添加菜单权限
└── V2.0.0__refactor_dept_tree.sql   # 重构部门树结构
```

### 7.3 迁移脚本示例

```sql
-- V1.0.1__add_user_nickname.sql
-- 添加用户昵称字段

ALTER TABLE sys_user ADD COLUMN nickname VARCHAR(100) COMMENT '昵称' AFTER username;

-- 创建索引
CREATE INDEX idx_user_nickname ON sys_user(nickname);
```

---

## 第八章：备份与恢复

### 8.1 MySQL 备份策略

```bash
#!/bin/bash
# MySQL 自动备份脚本

BACKUP_DIR="/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="pig"

# 全量备份
mysqldump -h localhost -u root -p${MYSQL_ROOT_PASSWORD} \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    ${DB_NAME} > ${BACKUP_DIR}/${DB_NAME}_${DATE}.sql

# 压缩
gzip ${BACKUP_DIR}/${DB_NAME}_${DATE}.sql

# 删除 7 天前的备份
find ${BACKUP_DIR} -name "*.gz" -mtime +7 -delete
```

### 8.2 Redis 备份

```bash
# Redis RDB 备份
redis-cli BGSAVE

# AOF 备份（实时）
# redis.conf
appendonly yes
appendfsync everysec
```

### 8.3 恢复流程

```bash
# MySQL 恢复
mysql -u root -p pig < backup_20250330.sql

# Redis 恢复
# 1. 停止 Redis
systemctl stop redis

# 2. 复制 RDB 文件
cp /backup/redis/dump.rdb /var/lib/redis/

# 3. 启动 Redis
systemctl start redis
```

---

## 第九章：安全配置

### 9.1 数据库用户权限

```sql
-- 创建应用用户（最小权限原则）
CREATE USER 'pig_app'@'%' IDENTIFIED BY 'secure_password';

-- 授予必要权限
GRANT SELECT, INSERT, UPDATE, DELETE ON pig.* TO 'pig_app'@'%';

-- 禁止 DROP, ALTER, CREATE
REVOKE DROP, ALTER, CREATE ON pig.* FROM 'pig_app'@'%';
```

### 9.2 Redis 安全

```conf
# redis.conf

# 绑定内网地址
bind 127.0.0.1 10.0.0.1

# 设置密码
requirepass your_secure_password

# 禁用危险命令
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command KEYS ""
```

### 9.3 连接加密

```yaml
# MySQL SSL 连接
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/pig?useSSL=true&requireSSL=true

# Redis TLS 连接
spring:
  redis:
    ssl: true
```

---

*文档版本：v1.0*
*生成时间：2025-03-30*
*适用项目：pig-4.x*
