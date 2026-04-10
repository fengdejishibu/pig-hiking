# Pig 项目 AI 开发指南

> **目标受众**：AI 助手（Claude、GPT 等）
> **目标**：确保 AI 在 Pig 项目中生成的代码符合项目规范和最佳实践

---

## 第一章：项目架构规范

### 1.1 模块结构

```
pig/
├── pig-common/                    # 公共模块（不要直接修改）
│   ├── pig-common-core/          # 核心工具类
│   ├── pig-common-feign/         # Feign 配置
│   ├── pig-common-security/      # 安全配置
│   ├── pig-common-mybatis/       # MyBatis 配置
│   └── pig-common-log/           # 日志配置
│
├── pig-upms/                      # 用户权限服务
│   ├── pig-upms-api/             # API 定义（Entity, DTO, Feign Client）
│   └── pig-upms-biz/             # 业务实现（Controller, Service, Mapper）
│
├── pig-auth/                      # 认证服务
├── pig-gateway/                   # 网关服务
└── pig-visual/                    # 可视化工具
```

### 1.2 模块职责边界

| 模块 | 允许的操作 | 禁止的操作 |
|------|-----------|-----------|
| `pig-upms-api` | 定义 Entity、DTO、VO、Feign Client | 写业务逻辑 |
| `pig-upms-biz` | 写 Controller、Service、Mapper | 定义新的 Entity |
| `pig-common-*` | 仅在必要时扩展 | 修改现有代码 |

---

## 第二章：代码命名规范

### 2.1 类命名规范

| 类型 | 命名规则 | 示例 |
|------|---------|------|
| Entity（实体类） | `Sys{业务名}` | `SysUser`, `SysRole` |
| DTO（数据传输对象） | `{业务名}DTO` | `UserDTO`, `RoleDTO` |
| VO（视图对象） | `{业务名}VO` | `UserExcelVO`, `TokenVo` |
| Controller | `Sys{业务名}Controller` | `SysUserController` |
| Service | `Sys{业务名}Service` | `SysUserService` |
| Mapper | `Sys{业务名}Mapper` | `SysUserMapper` |
| Feign Client | `Remote{业务名}Service` | `RemoteUserService` |

### 2.2 方法命名规范

| 操作类型 | Service 方法 | Controller 方法 |
|---------|-------------|-----------------|
| 分页查询 | `getPage()` / `get{Entity}Page()` | `get{Entity}Page()` |
| 单条查询 | `getById()` / `get{Entity}ById()` | `@GetMapping("/{id}")` |
| 新增 | `save()` / `save{Entity}()` | `@PostMapping` |
| 更新 | `update()` / `update{Entity}()` | `@PutMapping` |
| 删除 | `removeById()` / `remove{Entity}ByIds()` | `@DeleteMapping` |
| 内部调用 | 必须通过 Feign | `@Inner` |

### 2.3 变量命名规范

```java
// ✅ 正确
private Long userId;
private String userName;
private LocalDateTime createTime;

// ❌ 错误
private long user_id;      // 不要用下划线
private String UserName;   // 不要大写开头
private Date create_time;  // 使用 LocalDateTime
```

---

## 第三章：代码模板

### 3.1 Controller 模板

```java
/*
 * Copyright (c) 2020 pig4cloud Authors. All Rights Reserved.
 *
 * [Apache License 2.0 header...]
 */
package com.pig4cloud.pig.admin.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pig4cloud.pig.admin.api.dto.{Entity}DTO;
import com.pig4cloud.pig.admin.api.entity.Sys{Entity};
import com.pig4cloud.pig.admin.service.Sys{Entity}Service;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.log.annotation.SysLog;
import com.pig4cloud.pig.common.security.annotation.HasPermission;
import com.pig4cloud.pig.common.security.annotation.Inner;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

/**
 * {业务名}管理控制器
 *
 * @author [作者]
 * @date [日期]
 */
@RestController
@AllArgsConstructor
@RequestMapping("/{path}")
@Tag(description = "{tag}", name = "{业务名}管理模块")
@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)
public class Sys{Entity}Controller {

    private final Sys{Entity}Service {entity}Service;

    /**
     * 分页查询
     * @param page 分页参数
     * @param {entity}DTO 查询条件
     * @return 分页结果
     */
    @GetMapping("/page")
    @Operation(summary = "分页查询", description = "分页查询")
    public R get{Entity}Page(@ParameterObject Page page, @ParameterObject {Entity}DTO {entity}DTO) {
        return R.ok({entity}Service.get{Entity}Page(page, {entity}DTO));
    }

    /**
     * 通过ID查询
     * @param id ID
     * @return 详情
     */
    @GetMapping("/{id}")
    @Operation(summary = "通过ID查询", description = "通过ID查询")
    public R getById(@PathVariable Long id) {
        return R.ok({entity}Service.getById(id));
    }

    /**
     * 新增
     * @param {entity}DTO 数据传输对象
     * @return 操作结果
     */
    @SysLog("新增{业务名}")
    @PostMapping
    @HasPermission("sys_{entity}_add")
    @Operation(summary = "新增", description = "新增")
    public R save(@RequestBody {Entity}DTO {entity}DTO) {
        return R.ok({entity}Service.save{Entity}({entity}DTO));
    }

    /**
     * 修改
     * @param {entity}DTO 数据传输对象
     * @return 操作结果
     */
    @SysLog("修改{业务名}")
    @PutMapping
    @HasPermission("sys_{entity}_edit")
    @Operation(summary = "修改", description = "修改")
    public R updateById(@RequestBody {Entity}DTO {entity}DTO) {
        return R.ok({entity}Service.update{Entity}({entity}DTO));
    }

    /**
     * 删除
     * @param ids ID数组
     * @return 操作结果
     */
    @SysLog("删除{业务名}")
    @DeleteMapping
    @HasPermission("sys_{entity}_del")
    @Operation(summary = "删除", description = "删除")
    public R removeById(@RequestBody Long[] ids) {
        return R.ok({entity}Service.removeByIds(ids));
    }
}
```

### 3.2 Service 模板

```java
package com.pig4cloud.pig.admin.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.pig4cloud.pig.admin.api.dto.{Entity}DTO;
import com.pig4cloud.pig.admin.api.entity.Sys{Entity};

/**
 * {业务名}服务接口
 *
 * @author [作者]
 * @date [日期]
 */
public interface Sys{Entity}Service extends IService<Sys{Entity}> {

    /**
     * 分页查询
     * @param page 分页参数
     * @param {entity}DTO 查询条件
     * @return 分页结果
     */
    Page get{Entity}Page(Page page, {Entity}DTO {entity}DTO);

    /**
     * 保存
     * @param {entity}DTO 数据传输对象
     * @return 是否成功
     */
    Boolean save{Entity}({Entity}DTO {entity}DTO);

    /**
     * 更新
     * @param {entity}DTO 数据传输对象
     * @return 是否成功
     */
    Boolean update{Entity}({Entity}DTO {entity}DTO);
}
```

### 3.3 ServiceImpl 模板

```java
package com.pig4cloud.pig.admin.service.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pig4cloud.pig.admin.api.dto.{Entity}DTO;
import com.pig4cloud.pig.admin.api.entity.Sys{Entity};
import com.pig4cloud.pig.admin.mapper.Sys{Entity}Mapper;
import com.pig4cloud.pig.admin.service.Sys{Entity}Service;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * {业务名}服务实现类
 *
 * @author [作者]
 * @date [日期]
 */
@Service
@AllArgsConstructor
public class Sys{Entity}ServiceImpl extends ServiceImpl<Sys{Entity}Mapper, Sys{Entity}>
        implements Sys{Entity}Service {

    @Override
    public Page get{Entity}Page(Page page, {Entity}DTO {entity}DTO) {
        return baseMapper.selectPageVo(page, {entity}DTO);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Boolean save{Entity}({Entity}DTO {entity}DTO) {
        Sys{Entity} {entity} = new Sys{Entity}();
        // 属性映射...
        return this.save({entity});
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Boolean update{Entity}({Entity}DTO {entity}DTO) {
        Sys{Entity} {entity} = new Sys{Entity}();
        // 属性映射...
        return this.updateById({entity});
    }
}
```

### 3.4 Entity 模板

```java
/*
 * Copyright (c) 2018-2025, lengleng All rights reserved.
 * [License header...]
 */
package com.pig4cloud.pig.admin.api.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * {业务名}表
 *
 * @author [作者]
 * @date [日期]
 */
@Data
@Schema(description = "{业务名}")
@TableName("sys_{table}")
public class Sys{Entity} implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    @TableId(value = "{entity}_id", type = IdType.ASSIGN_ID)
    @Schema(description = "主键id")
    private Long {entity}Id;

    /**
     * 名称
     */
    @Schema(description = "名称")
    private String name;

    /**
     * 创建人
     */
    @TableField(fill = FieldFill.INSERT)
    @Schema(description = "创建人")
    private String createBy;

    /**
     * 修改人
     */
    @TableField(fill = FieldFill.UPDATE)
    @Schema(description = "修改人")
    private String updateBy;

    /**
     * 创建时间
     */
    @TableField(fill = FieldFill.INSERT)
    @Schema(description = "创建时间")
    private LocalDateTime createTime;

    /**
     * 修改时间
     */
    @TableField(fill = FieldFill.UPDATE)
    @Schema(description = "修改时间")
    private LocalDateTime updateTime;

    /**
     * 删除标记 0-正常 1-删除
     */
    @TableLogic
    @TableField(fill = FieldFill.INSERT)
    @Schema(description = "删除标记")
    private String delFlag;
}
```

### 3.5 Feign Client 模板

```java
package com.pig4cloud.pig.admin.api.feign;

import com.pig4cloud.pig.admin.api.dto.{Entity}DTO;
import com.pig4cloud.pig.common.core.constant.SecurityConstants;
import com.pig4cloud.pig.common.core.constant.ServiceNameConstants;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.security.annotation.Inner;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

/**
 * {业务名}远程调用服务
 *
 * @author [作者]
 * @date [日期]
 */
@FeignClient(contextId = "remote{Entity}Service", value = ServiceNameConstants.UPMS_SERVICE)
public interface Remote{Entity}Service {

    /**
     * 通过ID查询
     * @param id ID
     * @param from 内部调用标识
     * @return 结果
     */
    @Inner
    @GetMapping("/{entity}/{id}")
    R<{Entity}DTO> getById(@PathVariable("id") Long id,
                           @RequestHeader(SecurityConstants.FROM) String from);

    /**
     * 保存
     * @param {entity}DTO 数据传输对象
     * @param from 内部调用标识
     * @return 结果
     */
    @Inner
    @PostMapping("/{entity}")
    R<Boolean> save(@RequestBody {Entity}DTO {entity}DTO,
                    @RequestHeader(SecurityConstants.FROM) String from);
}
```

---

## 第四章：注解使用规范

### 4.1 必须使用的注解

| 场景 | 注解 | 说明 |
|------|------|------|
| Controller 类 | `@RestController`, `@AllArgsConstructor`, `@Tag` | REST 控制器 |
| 分页接口 | `@ParameterObject` | 参数对象 |
| 操作日志 | `@SysLog("操作描述")` | 记录操作日志 |
| 权限控制 | `@HasPermission("sys_xxx_xxx")` | 权限校验 |
| 内部接口 | `@Inner` | 仅允许内部调用 |
| 接口文档 | `@Operation(summary, description)` | Swagger 文档 |
| 事务 | `@Transactional(rollbackFor = Exception.class)` | 事务管理 |

### 4.2 注解组合示例

```java
// 标准的删除接口
@SysLog("删除用户")                    // 1. 操作日志
@DeleteMapping                        // 2. HTTP 方法
@HasPermission("sys_user_del")        // 3. 权限检查
@Operation(summary = "删除用户", description = "根据ID删除用户")  // 4. 文档
public R removeById(@RequestBody Long[] ids) {
    return R.ok(userService.removeByIds(ids));
}

// 内部调用接口
@Inner                                // 1. 内部调用标识
@GetMapping("/info/query")            // 2. HTTP 方法
@Operation(summary = "查询用户信息")   // 3. 文档
public R info(UserDTO userDTO) {
    return userService.getUserInfo(userDTO);
}
```

---

## 第五章：Debug 排查路径

### 5.1 请求 401/403 问题

```
排查路径：
1. 检查请求头是否携带 Token
   → Authorization: Bearer xxx

2. 检查 Token 是否过期
   → Redis: GET pig_oauth_access::{token}

3. 检查用户是否被锁定
   → 数据库: SELECT lock_flag FROM sys_user WHERE username = 'xxx'

4. 检查权限标识是否正确
   → 数据库: SELECT * FROM sys_menu WHERE permission = 'xxx'
   → 检查用户角色是否关联该菜单
```

### 5.2 服务调用失败

```
排查路径：
1. 检查服务是否注册
   → Nacos 控制台查看服务列表

2. 检查 Feign Client 定义是否正确
   → @FeignClient(name = "服务名") 必须与注册名一致

3. 检查内部调用是否添加 from 头
   → @Inner 接口需要 SecurityConstants.FROM = "Y"

4. 检查网关路由配置
   → application.yml 中的 spring.cloud.gateway.routes
```

### 5.3 数据库操作问题

```
排查路径：
1. 检查 MyBatis Mapper XML 是否正确
   → namespace 必须与 Mapper 接口全限定名一致

2. 检查字段映射
   → Entity 中的 @TableField 注解

3. 检查逻辑删除
   → del_flag 字段，@TableLogic 注解

4. 检查自动填充
   → create_by, create_time 等字段
   → @TableField(fill = FieldFill.INSERT)
```

### 5.4 常见错误代码

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `Invalid bearer token` | Token 无效或过期 | 重新登录获取 Token |
| `Access Denied` | 无权限 | 检查 @HasPermission 标识 |
| `Service Unavailable` | 服务未注册 | 检查 Nacos 注册状态 |
| `Feign$xxx` | Feign 调用失败 | 检查服务名和接口定义 |

---

## 第六章：数据库操作规范

### 6.1 SQL 命名规范

```sql
-- 表名：sys_{业务名}
CREATE TABLE sys_user (
    user_id BIGINT PRIMARY KEY COMMENT '主键',
    username VARCHAR(50) COMMENT '用户名',
    ...
);

-- 字段名：下划线分隔
user_id, user_name, create_time, del_flag

-- 索引名：idx_{表名}_{字段名}
CREATE INDEX idx_sys_user_username ON sys_user(username);

-- 唯一索引：uk_{表名}_{字段名}
CREATE UNIQUE INDEX uk_sys_user_username ON sys_user(username);
```

### 6.2 通用字段要求

所有业务表必须包含以下字段：

```sql
-- 必须字段
`create_by` VARCHAR(64) COMMENT '创建人',
`update_by` VARCHAR(64) COMMENT '修改人',
`create_time` DATETIME COMMENT '创建时间',
`update_time` DATETIME COMMENT '修改时间',
`del_flag` CHAR(1) DEFAULT '0' COMMENT '删除标记 0-正常 1-删除'
```

### 6.3 MyBatis Plus 使用规范

```java
// ✅ 正确：使用 Wrappers 构建条件
List<SysUser> users = userMapper.selectList(
    Wrappers.<SysUser>lambdaQuery()
        .eq(SysUser::getDelFlag, "0")
        .like(StringUtils.hasText(username), SysUser::getUsername, username)
);

// ❌ 错误：直接拼接 SQL
@Select("SELECT * FROM sys_user WHERE username = '" + username + "'")
```

---

## 第七章：安全规范

### 7.1 密码处理

```java
// ✅ 正确：使用 BCrypt 加密
String encodedPassword = passwordEncoder.encode(rawPassword);

// ❌ 错误：明文存储
user.setPassword(rawPassword);
```

### 7.2 SQL 注入防护

```java
// ✅ 正确：使用参数化查询
@Select("SELECT * FROM sys_user WHERE username = #{username}")
SysUser selectByUsername(@Param("username") String username);

// ❌ 错误：字符串拼接
@Select("SELECT * FROM sys_user WHERE username = '" + username + "'")
```

### 7.3 敏感信息处理

```java
// ✅ 正确：使用 @JsonIgnore 排除敏感字段
@JsonIgnore
@Schema(description = "密码")
private String password;

@JsonIgnore
@Schema(description = "随机盐")
private String salt;
```

---

## 第八章：Git 提交规范

### 8.1 Commit Message 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 8.2 Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(user): 新增用户导出功能` |
| `fix` | 修复 Bug | `fix(auth): 修复 Token 过期时间计算错误` |
| `docs` | 文档更新 | `docs(readme): 更新部署文档` |
| `style` | 代码格式 | `style(user): 格式化代码` |
| `refactor` | 重构 | `refactor(user): 重构用户查询逻辑` |
| `test` | 测试 | `test(user): 添加用户服务单元测试` |
| `chore` | 构建/工具 | `chore(pom): 升级依赖版本` |

### 8.3 示例

```
feat(user): 新增用户批量导入功能

- 支持Excel导入用户数据
- 添加数据校验
- 支持错误数据导出

Closes #123
```

---

## 第九章：性能优化规范

### 9.1 分页查询

```java
// ✅ 正确：使用分页
@GetMapping("/page")
public R<Page> getPage(Page page, UserDTO userDTO) {
    return R.ok(userService.getPage(page, userDTO));
}

// ❌ 错误：查询全部再分页
@GetMapping("/page")
public R<Page> getPage(int current, int size) {
    List<User> all = userService.list();  // 全量查询
    // 手动分页...
}
```

### 9.2 缓存使用

```java
// ✅ 正确：使用缓存
@Cacheable(value = CacheConstants.USER_DETAILS, key = "#username")
public UserInfo getUserInfo(String username) {
    // ...
}

// 清除缓存
@CacheEvict(value = CacheConstants.USER_DETAILS, key = "#username")
public void updateUser(String username, UserDTO userDTO) {
    // ...
}
```

### 9.3 批量操作

```java
// ✅ 正确：批量插入
userService.saveBatch(userList);

// ❌ 错误：循环单条插入
for (User user : userList) {
    userService.save(user);
}
```

---

## 第十章：检查清单

### 10.1 新增功能检查

- [ ] Entity 类是否包含通用字段
- [ ] Controller 是否添加 `@Tag`、`@Operation` 注解
- [ ] 是否添加 `@SysLog` 操作日志
- [ ] 是否添加 `@HasPermission` 权限控制
- [ ] Service 方法是否添加 `@Transactional`
- [ ] 内部调用接口是否添加 `@Inner`
- [ ] 敏感字段是否添加 `@JsonIgnore`

### 10.2 代码审查检查

- [ ] 命名是否符合规范
- [ ] 是否有硬编码
- [ ] 是否有 SQL 注入风险
- [ ] 是否有性能问题（N+1 查询等）
- [ ] 异常处理是否完善
- [ ] 日志是否完整

---

*文档版本：v1.0*
*生成时间：2025-03-30*
*适用项目：pig-4.x*
