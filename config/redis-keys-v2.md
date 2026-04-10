# Redis Key 设计

> 版本: v3.0 (Sprint1 专用)
> 更新: 2026-04-02
> 说明: 严格按 Sprint1 用户故事设计

---

## 用户故事覆盖

| Key 模式 | 用户故事 | 用途 |
|----------|----------|------|
| `sms:code:{phone}` | US-04, US-05 | 短信验证码存储 |
| `login:fail:{phone}` | US-05 | 登录失败计数 |

---

## Key 详细设计

### 1. 短信验证码

**用户故事**: US-04 手机号注册, US-05 账号登录

```
Key:    sms:code:{phone}
Value:  {code}
TTL:    300 秒 (5分钟)
```

**示例**:
```bash
# 发送验证码
SET sms:code:13800138000 "123456"
EXPIRE sms:code:13800138000 300

# 验证
GET sms:code:13800138000
# 返回 "123456" 或 nil

# 验证后删除（一次性使用）
DEL sms:code:13800138000
```

---

### 2. 登录失败计数

**用户故事**: US-05 账号登录

```
Key:    login:fail:{phone}
Value:  {count}
TTL:    1800 秒 (30分钟)
```

**逻辑**:
- 每次登录失败: `INCR login:fail:{phone}`
- 计数达到 5: 拒绝登录，提示"登录失败次数过多，请 30 分钟后再试"
- 登录成功: `DEL login:fail:{phone}`
- 30分钟无操作自动过期

**示例**:
```bash
# 登录失败
INCR login:fail:13800138000
# 返回 1, 2, 3, 4, 5...

# 检查是否锁定
GET login:fail:13800138000
# 返回 "5" 表示已锁定

# 设置过期时间（首次失败时）
EXPIRE login:fail:13800138000 1800

# 登录成功，清除计数
DEL login:fail:13800138000
```

---

## Java 代码示例

### 验证码服务

```java
@Service
public class SmsCodeService {
    
    @Autowired
    private StringRedisTemplate redisTemplate;
    
    // 发送验证码 - US-04/US-05
    public void sendCode(String phone) {
        String code = RandomStringUtils.randomNumeric(6);
        String key = "sms:code:" + phone;
        redisTemplate.opsForValue().set(key, code, 5, TimeUnit.MINUTES);
        // TODO: 调用短信服务发送
    }
    
    // 验证验证码 - US-04/US-05
    public boolean verifyCode(String phone, String code) {
        String key = "sms:code:" + phone;
        String stored = redisTemplate.opsForValue().get(key);
        if (code.equals(stored)) {
            redisTemplate.delete(key); // 一次性使用
            return true;
        }
        return false;
    }
}
```

### 登录失败计数服务

```java
@Service
public class LoginFailService {
    
    private static final int MAX_FAIL_COUNT = 5;
    private static final int LOCK_MINUTES = 30;
    
    @Autowired
    private StringRedisTemplate redisTemplate;
    
    // 检查是否锁定 - US-05
    public boolean isLocked(String phone) {
        String key = "login:fail:" + phone;
        String count = redisTemplate.opsForValue().get(key);
        return count != null && Integer.parseInt(count) >= MAX_FAIL_COUNT;
    }
    
    // 记录失败 - US-05
    public void recordFail(String phone) {
        String key = "login:fail:" + phone;
        Long count = redisTemplate.opsForValue().increment(key);
        if (count != null && count == 1) {
            redisTemplate.expire(key, LOCK_MINUTES, TimeUnit.MINUTES);
        }
    }
    
    // 清除计数（登录成功） - US-05
    public void clearFail(String phone) {
        redisTemplate.delete("login:fail:" + phone);
    }
}
```

---

## 初始化检查清单

- [ ] Redis 服务已启动 (6379 端口)
- [ ] 应用配置了 Redis 连接
- [ ] 验证码发送功能已实现
- [ ] 登录失败锁定功能已实现
