# Pig 微服务架构全貌学习指南

> **写给谁看**：只学过 C++ / Python 的同学，对 Java、微服务、注册中心、架构划分都不懂。
>
> **目标**：知其然，理解整个系统是怎么跑起来的。

---

## 第一章：核心概念对照表

> 💡 **学习方法**：用你已经熟悉的 C++ / Python 概念，来理解陌生的 Java 微服务概念。

| 你熟悉的概念 (C++/Python) | Java 微服务对应概念 | 说明 |
|---------------------------|-------------------|------|
| `#include` 或 `import` | Maven 依赖 (`pom.xml`) | 管理第三方库 |
| `class Student:` | `public class Student {}` | 类定义 |
| `__init__(self)` | 构造函数 `Student()` | 初始化对象 |
| 虚函数 / 抽象类 | `interface` + `implements` | 定义契约 |
| 全局变量 | Spring Bean (`@Component`) | 单例，全局可访问 |
| `requests.get()` | `RestTemplate` / Feign | HTTP 调用 |
| `threading.Thread` | `@Async` / `CompletableFuture` | 异步处理 |
| `.env` 文件 | `application.yml` | 配置文件 |
| Docker Compose | Nacos + Spring Cloud | 服务编排 |
| Nginx 反向代理 | Spring Cloud Gateway | API 网关 |
| Redis | Redis (相同) | 缓存 |
| MySQL | MySQL (相同) | 数据库 |

---

## 第二章：什么是微服务？（类比法）

### 2.1 传统单体 vs 微服务

想象你开了一家餐厅：

**单体架构** = 一个超级服务员
- 一个服务员负责：点菜、做饭、上菜、结账、打扫
- 优点：简单，一个人搞定
- 缺点：这个服务员病了，整个餐厅停业

**微服务架构** = 专业分工团队
- 点菜员：只负责点菜
- 厨师：只负责做饭
- 收银员：只负责结账
- 优点：厨师病了，点菜和收银还能正常工作
- 缺点：需要协调沟通

### 2.2 Pig 项目的服务分工

```
┌─────────────────────────────────────────────────────────────┐
│                      Pig 微服务全家桶                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ pig-gateway │    │  pig-auth   │    │  pig-upms   │     │
│  │   (网关)     │    │  (认证)     │    │ (用户权限)   │     │
│  │   端口:9999  │    │  端口:3000  │    │  端口:4000  │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            │                                │
│                     ┌──────▼──────┐                        │
│                     │    Nacos    │ ← 注册中心（电话簿）     │
│                     │  端口:8848  │                        │
│                     └─────────────┘                        │
│                            │                                │
│         ┌──────────────────┼──────────────────┐             │
│         │                  │                  │             │
│  ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐     │
│  │ pig-monitor │    │ pig-codegen │    │ pig-quartz  │     │
│  │   (监控)     │    │ (代码生成)   │    │ (定时任务)   │     │
│  │  端口:5001  │    │  端口:5002  │    │  端口:5007  │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 各服务职责

| 服务名 | C++/Python 类比 | 职责 |
|--------|----------------|------|
| **pig-register** | 服务发现 daemon | Nacos 注册中心，所有服务启动时来这里"签到" |
| **pig-gateway** | Nginx 反向代理 | 统一入口，路由转发，鉴权过滤 |
| **pig-auth** | OAuth2 服务 | 登录认证，颁发 Token |
| **pig-upms** | 用户管理后台 | 用户、角色、权限、菜单管理 |
| **pig-monitor** | 监控面板 | 查看各服务健康状态 |
| **pig-codegen** | 脚手架工具 | 根据数据库表自动生成 CRUD 代码 |
| **pig-quartz** | Cron 任务 | 定时任务调度 |

---

## 第三章：Nacos 注册中心（电话簿系统）

### 3.1 为什么需要 Nacos？

**问题场景**：
- 服务 A 想调用服务 B
- 但服务 B 可能有多个实例（B1, B2, B3）
- 而且 B 的 IP 地址可能会变

**类比理解**：
```
没有 Nacos：
  你想找张三，但你不知道他在哪
  你得记住张三的手机号、家庭住址
  如果张三搬家了，你就找不到他了

有 Nacos：
  你想找张三，查电话簿（Nacos）
  电话簿实时更新张三的联系方式
  即使张三搬家了，电话簿也会更新
```

### 3.2 服务注册流程

```python
# Python 伪代码理解 Nacos 原理

class Nacos:
    def __init__(self):
        self.service_registry = {}  # 服务注册表

    def register(self, service_name, ip, port):
        """服务启动时注册自己"""
        self.service_registry[service_name] = {
            'ip': ip,
            'port': port,
            'status': 'healthy',
            'last_heartbeat': time.now()
        }

    def discover(self, service_name):
        """其他服务发现目标服务"""
        return self.service_registry.get(service_name)

    def heartbeat(self, service_name):
        """心跳检测，每5秒发送一次"""
        if service_name in self.service_registry:
            self.service_registry[service_name]['last_heartbeat'] = time.now()

# 使用示例
nacos = Nacos()

# 服务 B 启动时注册
nacos.register('pig-upms', '192.168.1.100', 4000)

# 服务 A 想调用服务 B
b_info = nacos.discover('pig-upms')
# b_info = {'ip': '192.168.1.100', 'port': 4000}
```

### 3.3 Pig 中的配置

```yaml
# application.yml 中配置 Nacos
spring:
  cloud:
    nacos:
      discovery:
        server-addr: 127.0.0.1:8848  # Nacos 服务器地址
      config:
        server-addr: ${spring.cloud.nacos.discovery.server-addr}
```

---

## 第四章：请求生命周期（一次登录的全过程）

### 4.1 登录请求流程图

```
用户浏览器
    │
    │ POST /auth/oauth2/token
    │ Body: username=admin&password=123456
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      pig-gateway (9999)                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ PigRequestGlobalFilter                              │    │
│  │ 1. 清洗请求头（移除 from 参数）                       │    │
│  │ 2. 添加请求开始时间                                   │    │
│  │ 3. 重写 URL 路径（去掉前缀）                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 路由规则匹配                                         │    │
│  │ /auth/** → lb://pig-auth                            │    │
│  │ (lb 表示 load balance，负载均衡)                      │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       pig-auth (3000)                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 1. 验证用户名密码                                     │    │
│  │    - 调用 pig-upms 查询用户信息                       │    │
│  │    - 验证密码（BCrypt 加密比对）                      │    │
│  │                                                       │    │
│  │ 2. 生成 OAuth2 Token                                 │    │
│  │    - Access Token（有效期2小时）                      │    │
│  │    - Refresh Token（有效期7天）                       │    │
│  │                                                       │    │
│  │ 3. 存储到 Redis                                       │    │
│  │    - Key: pig_oauth_access::{token}                  │    │
│  │    - Value: 用户信息 JSON                             │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       pig-upms (4000)                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ RemoteUserService.getUserInfo(username)              │    │
│  │                                                       │    │
│  │ SELECT * FROM sys_user WHERE username = 'admin'     │    │
│  │ SELECT * FROM sys_role WHERE role_id IN (...)       │    │
│  │ SELECT * FROM sys_menu WHERE menu_id IN (...)       │    │
│  │                                                       │    │
│  │ 返回：用户信息 + 角色列表 + 权限列表                   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                    返回 Token 给用户
```

### 4.2 后续请求（携带 Token）

```
用户浏览器
    │
    │ GET /admin/user/page
    │ Header: Authorization: Bearer eyJhbGciOiJ...
    ▼
┌─────────────────────────────────────────────────────────────┐
│                      pig-gateway (9999)                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 1. 解析 Token                                        │    │
│  │ 2. 验证 Token 有效性（查询 Redis）                    │    │
│  │ 3. 提取用户信息放入请求头                             │    │
│  │ 4. 路由到 pig-upms                                   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                       pig-upms (4000)                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ SysUserController.getUserPage()                      │    │
│  │                                                       │    │
│  │ @HasPermission("sys_user_view")  // 权限检查         │    │
│  │ public R getUserPage(Page page, UserDTO userDTO) {  │    │
│  │     return R.ok(userService.getUsersWithRolePage());│    │
│  │ }                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 第五章：服务间通信（Feign）

### 5.1 什么是 Feign？

**类比理解**：
```python
# Python 中调用另一个服务的 HTTP 接口
import requests

def get_user(user_id):
    # 需要硬编码服务地址
    response = requests.get(f'http://192.168.1.100:4000/user/{user_id}')
    return response.json()
```

```java
// Java + Feign 调用另一个服务
@FeignClient(name = "pig-upms")  // 只需要服务名，不需要知道IP和端口
public interface RemoteUserService {
    @GetMapping("/user/{id}")
    R<UserDTO> getUser(@PathVariable("id") Long id);
}

// 使用时像调用本地方法一样
@Autowired
private RemoteUserService remoteUserService;

public void doSomething() {
    R<UserDTO> result = remoteUserService.getUser(1L);  // 自动负载均衡
}
```

### 5.2 Feign 工作原理

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   服务 A      │      │    Nacos     │      │   服务 B      │
│              │      │              │      │              │
│ remoteUser   │      │  注册表:      │      │  /user/{id}  │
│ .getUser(1)  │      │  pig-upms:   │      │              │
│      │       │      │  192.168.1.100│      │              │
│      ▼       │      │  192.168.1.101│      │              │
│ ┌────────┐   │      │  192.168.1.102│      │              │
│ │ Feign  │───┼─────►│  查询服务地址 │      │              │
│ │ 代理   │   │      │      │       │      │              │
│ └────────┘   │      │      ▼       │      │              │
│      │       │      │  返回地址列表 │      │              │
│      │       │      └──────────────┘      │              │
│      │       │              │              │              │
│      │       │              ▼              │              │
│      │       │      负载均衡选择一个        │              │
│      │       │      (轮询/随机)           │              │
│      │       │              │              │              │
│      └──────────────────────┼─────────────►│              │
│                  HTTP GET /user/1         │              │
│                           │              │              │
│                           └──────────────│─── 返回结果   │
└──────────────┘                           └──────────────┘
```

### 5.3 Pig 中的 Feign 拦截器

```java
// PigFeignInnerRequestInterceptor.java
// 作用：在 Feign 调用时自动添加内部调用标识

public class PigFeignInnerRequestInterceptor implements RequestInterceptor {
    @Override
    public void apply(RequestTemplate template) {
        // 添加 from 请求头，表示这是内部服务调用
        template.header(SecurityConstants.FROM, SecurityConstants.FROM_IN);
    }
}

// PigFeignLanguageInterceptor.java
// 作用：透传语言环境（国际化支持）

public class PigFeignLanguageInterceptor implements RequestInterceptor {
    @Override
    public void apply(RequestTemplate template) {
        HttpServletRequest request = WebUtils.getRequest().orElse(null);
        if (request == null) return;

        String language = request.getHeader(HttpHeaders.ACCEPT_LANGUAGE);
        if (StringUtils.hasText(language)) {
            template.header(HttpHeaders.ACCEPT_LANGUAGE, language);
        }
    }
}
```

---

## 第六章：权限控制（RBAC 模型）

### 6.1 RBAC 是什么？

**RBAC** = Role-Based Access Control（基于角色的访问控制）

**类比理解**：
```
公司组织架构：

张三（用户）
   │
   └──► 技术经理（角色）
          │
          ├──► 查看员工信息（权限）
          ├──► 审批请假（权限）
          └──► 查看报表（权限）
```

### 6.2 Pig 中的权限表结构

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   sys_user  │       │sys_user_role│       │   sys_role  │
│─────────────│       │─────────────│       │─────────────│
│ user_id(PK) │◄──────│ user_id(FK) │       │ role_id(PK) │
│ username    │       │ role_id(FK) │──────►│ role_name   │
│ password    │       └─────────────┘       │ role_code   │
│ dept_id     │                             └─────────────┘
└─────────────┘                                   │
                                                  │
                                      ┌───────────┴───────────┐
                                      │    sys_role_menu      │
                                      │───────────────────────│
                                      │ role_id(FK)           │
                                      │ menu_id(FK)           │
                                      └───────────┬───────────┘
                                                  │
                                      ┌───────────▼───────────┐
                                      │      sys_menu         │
                                      │───────────────────────│
                                      │ menu_id(PK)           │
                                      │ menu_name             │
                                      │ permission (权限标识)  │
                                      │ path (前端路由)        │
                                      └───────────────────────┘
```

### 6.3 权限注解使用

```java
@RestController
@RequestMapping("/user")
public class SysUserController {

    // 需要 sys_user_add 权限才能访问
    @PostMapping
    @HasPermission("sys_user_add")
    public R saveUser(@RequestBody UserDTO userDto) {
        return R.ok(userService.saveUser(userDto));
    }

    // 只有内部服务才能调用
    @Inner
    @GetMapping("/info/query")
    public R info(UserDTO userDTO) {
        return userService.getUserInfo(userDTO);
    }
}
```

---

## 第七章：公共模块（pig-common）

### 7.1 模块结构

```
pig-common/
├── pig-common-bom          # 依赖版本管理（类似 requirements.txt）
├── pig-common-core         # 核心工具类
│   ├── R.java              # 统一响应包装器
│   ├── RedisUtils.java     # Redis 工具类
│   └── WebUtils.java       # Web 工具类
├── pig-common-security     # 安全认证
│   ├── @Inner              # 内部调用注解
│   └── @HasPermission      # 权限注解
├── pig-common-feign        # 服务间通信
│   └── PigFeignAutoConfiguration.java
├── pig-common-mybatis      # 数据库 ORM
│   └── MyBatisPlusConfig.java
├── pig-common-log          # 日志
│   └── @SysLog             # 操作日志注解
├── pig-common-datasource   # 动态数据源
└── pig-common-swagger      # API 文档
```

### 7.2 统一响应格式 R

```java
// 所有接口返回统一格式
public class R<T> {
    private int code;       // 状态码：0=成功，1=失败
    private String msg;     // 提示信息
    private T data;         // 数据内容

    // 成功响应
    public static <T> R<T> ok(T data) {
        R<T> r = new R<>();
        r.setCode(0);
        r.setMsg("success");
        r.setData(data);
        return r;
    }

    // 失败响应
    public static <T> R<T> failed(String msg) {
        R<T> r = new R<>();
        r.setCode(1);
        r.setMsg(msg);
        return r;
    }
}
```

**类比 Python**：
```python
# 类似于 FastAPI 的响应模型
from pydantic import BaseModel
from typing import Generic, TypeVar, Optional

T = TypeVar('T')

class R(BaseModel, Generic[T]):
    code: int = 0
    msg: str = "success"
    data: Optional[T] = None
```

---

## 第八章：项目启动流程

### 8.1 启动顺序

```
1. 启动基础设施
   ┌─────────────────────────────────────┐
   │ MySQL (3306)  - 数据库              │
   │ Redis (6379)  - 缓存                │
   │ Nacos (8848)  - 注册中心/配置中心    │
   └─────────────────────────────────────┘

2. 启动核心服务
   ┌─────────────────────────────────────┐
   │ pig-upms (4000)   - 用户权限服务     │
   │ pig-auth (3000)   - 认证服务         │
   │ pig-gateway (9999) - 网关            │
   └─────────────────────────────────────┘

3. 启动扩展服务（可选）
   ┌─────────────────────────────────────┐
   │ pig-monitor (5001) - 监控            │
   │ pig-codegen (5002) - 代码生成        │
   │ pig-quartz (5007)  - 定时任务        │
   └─────────────────────────────────────┘
```

### 8.2 服务启动时的自动注册

```java
@SpringBootApplication
@EnableDiscoveryClient  // 启用服务注册发现
public class PigAuthApplication {
    public static void main(String[] args) {
        SpringApplication.run(PigAuthApplication.class, args);
        // 启动后自动向 Nacos 注册
        // 注册信息：服务名=pig-auth, IP=xxx, Port=3000
    }
}
```

---

## 第九章：常见问题 FAQ

### Q1: Nacos 和 Eureka 有什么区别？

| 特性 | Nacos | Eureka |
|------|-------|--------|
| 配置中心 | 支持 | 不支持 |
| 健康检查 | TCP/HTTP/MySQL | HTTP |
| 负载均衡 | 权重 | 轮询 |
| 社区活跃度 | 阿里维护，活跃 | Netflix 停止维护 |

### Q2: Gateway 和 Nginx 有什么区别？

| 特性 | Spring Cloud Gateway | Nginx |
|------|---------------------|-------|
| 语言 | Java | C |
| 动态路由 | 代码级别配置 | 需重启/重载 |
| 鉴权 | 与 Spring Security 无缝集成 | 需要额外模块 |
| 性能 | 较高 | 非常高 |

### Q3: 为什么要用 Redis 存储 Token？

1. **性能**：Redis 是内存数据库，读取速度极快
2. **过期**：Redis 支持 TTL，Token 过期自动删除
3. **分布式**：多个服务实例可以共享 Token 状态

### Q4: @Inner 注解是什么意思？

```java
@Inner  // 表示这个接口只允许内部服务调用
@GetMapping("/info/query")
public R info(UserDTO userDTO) {
    return userService.getUserInfo(userDTO);
}
```

- 外部请求（浏览器）不能直接调用
- 只有 Feign 内部调用（带有 from=Y 请求头）才能访问
- 防止外部直接绕过网关调用内部接口

### Q5: 如何调试一个请求？

1. 在 Gateway 的 `PigRequestGlobalFilter` 打断点
2. 在目标 Controller 打断点
3. 查看请求头中的 `Authorization: Bearer xxx`
4. 用 Redis CLI 查看 Token：`GET pig_oauth_access::{token}`

---

## 第十章：动手实践

### 实验 1：查看 Nacos 注册的服务

```bash
# 访问 Nacos 控制台
http://localhost:8848/nacos

# 默认账号：nacos / nacos

# 在"服务管理" -> "服务列表"中可以看到所有注册的服务
```

### 实验 2：手动调用登录接口

```bash
# 获取 Token
curl -X POST "http://localhost:9999/auth/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=123456&grant_type=password&client_id=pig&client_secret=pig"

# 返回结果
{
  "access_token": "eyJhbGciOiJ...",
  "token_type": "Bearer",
  "expires_in": 7200
}

# 使用 Token 访问接口
curl -X GET "http://localhost:9999/admin/user/page" \
  -H "Authorization: Bearer eyJhbGciOiJ..."
```

### 实验 3：查看 Redis 中的 Token

```bash
redis-cli

# 查看所有 Token
KEYS pig_oauth_access:*

# 查看某个 Token 的详细信息
GET pig_oauth_access:eyJhbGciOiJ...
```

---

## 总结：核心概念速记卡

| 概念 | 一句话总结 |
|------|-----------|
| **Nacos** | 服务电话簿，所有服务启动时来这登记 |
| **Gateway** | 统一大门，所有请求先经过这里 |
| **Feign** | 远程调用，像调本地方法一样调其他服务 |
| **OAuth2** | 身份证系统，登录后颁发 Token |
| **RBAC** | 权限模型，用户→角色→权限 |
| **Redis** | 内存数据库，存 Token 和缓存 |
| **@Inner** | 内部接口，外部不能直接访问 |
| **R** | 统一响应格式 `{code, msg, data}` |

---

*文档版本：v1.0*
*生成时间：2025-03-30*
*适用项目：pig-4.x*
