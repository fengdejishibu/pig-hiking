# 任务：短信验证码 Mock 功能

> **优先级**: P0
> **预估工时**: 1h
> **负责人**: 待分配
> **目标**: 跑通 CI/CD 全流程验证

---

## 一、背景

Pig 框架已有完整的短信验证码基础设施，但短信服务（SmsBlend）未配置时会返回失败。需要实现 Mock 模式，使开发者可以通过日志获取验证码，完成登录验证闭环。

---

## 二、涉及文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `pig-upms-biz/.../service/impl/SysMobileServiceImpl.java` | 修改 | 添加 Mock 逻辑 |

**完整路径**：
```
D:\2_Study\coding\pig\pig-upms\pig-upms-biz\src\main\java\com\pig4cloud\pig\admin\service\impl\SysMobileServiceImpl.java
```

---

## 三、修改内容

### 3.1 定位代码

找到 `SysMobileServiceImpl.java` 第 85-93 行：

```java
// 集成短信服务发送验证码
SmsBlend smsBlend = SmsFactory.getSmsBlend();
if (Objects.isNull(smsBlend)) {
    return R.ok(Boolean.FALSE, MsgUtils.getMessage(ErrorCodes.SYS_SMS_BLEND_UNREGISTERED));
}

SmsResponse smsResponse = smsBlend.sendMessage(mobile, new LinkedHashMap<>(Map.of("code", code)));
log.debug("调用短信服务发送验证码结果:{}", smsResponse);
return R.ok(Boolean.TRUE);
```

### 3.2 修改为

```java
// 集成短信服务发送验证码
SmsBlend smsBlend = SmsFactory.getSmsBlend();
if (Objects.isNull(smsBlend)) {
    // Mock 模式：仅日志输出，返回成功
    log.info("========================================");
    log.info("[短信Mock] 手机号: {} | 验证码: {}", mobile, code);
    log.info("========================================");
    return R.ok(Boolean.TRUE);
}

SmsResponse smsResponse = smsBlend.sendMessage(mobile, new LinkedHashMap<>(Map.of("code", code)));
log.debug("调用短信服务发送验证码结果:{}", smsResponse);
return R.ok(Boolean.TRUE);
```

---

## 四、技术规格

### 4.1 已有基础设施（无需修改）

| 组件 | 说明 |
|------|------|
| `SysMobileController` | `GET /mobile/{mobile}` 发送验证码 |
| `ValidateCodeFilter` | 登录时校验验证码 |
| `CacheConstants.DEFAULT_CODE_KEY` | Redis Key 前缀 `"DEFAULT_CODE_KEY:"` |
| `SecurityConstants.CODE_TIME` | 验证码有效期 60 秒 |
| `SecurityConstants.CODE_SIZE` | 验证码长度 6 位 |

### 4.2 验证码存储

```
Redis Key: DEFAULT_CODE_KEY:{mobile}
Value: 6位数字验证码
TTL: 60秒
```

---

## 五、验收标准

### 5.1 功能验证

```bash
# 1. 启动服务后，调用发送验证码接口
curl http://localhost:9999/admin/mobile/13800138000

# 2. 预期响应
{"code":0,"msg":null,"data":true}

# 3. 查看控制台日志，应看到
# ========================================
# [短信Mock] 手机号: 13800138000 | 验证码: 642851
# ========================================

# 4. 验证 Redis 存储（可选）
docker exec hiking-redis redis-cli GET "DEFAULT_CODE_KEY:13800138000"
# 预期输出: "642851"（实际验证码）
```

### 5.2 CI/CD 验证

```bash
# 1. 推送代码
git add .
git commit -m "feat: 添加短信验证码 Mock 模式"
git push origin main

# 2. 等待流水线完成

# 3. 访问部署环境验证
curl http://8.135.20.173:8080/admin/mobile/13800138000

# 4. 预期响应
{"code":0,"msg":null,"data":true}
```

---

## 六、注意事项

1. **不要修改其他文件**，仅修改 `SysMobileServiceImpl.java`
2. Mock 日志使用 `log.info` 级别，确保生产环境可见
3. 后续接入真实短信服务时，只需配置 SmsFactory，无需修改业务代码

---

## 七、扩展说明（可选）

如需接入真实短信服务，参考 Pig 官方文档配置 `sms4j`：

```yaml
# application.yml
sms:
  alibaba:
    access-key-id: ${SMS_ACCESS_KEY}
    access-key-secret: ${SMS_SECRET_KEY}
    sign-name: 徒步社区
    template-id: SMS_XXXXXX
```

---

*文档版本: v1.0 | 创建日期: 2026-04-02*
