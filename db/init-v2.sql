-- ========================================
-- 徒步社区平台 - MySQL 初始化脚本
-- 版本: v6.1 (完整业务表设计)
-- 更新: 2026-04-09
-- 说明: 包含完整Sprint1-Sprint7所有业务表
--
-- 用户故事覆盖:
--   Sprint1: US-03,US-04,US-05,US-06,US-07,US-08,US-10
--   Sprint2: 帖子、评论、举报
--   Sprint3: 路线库、攻略库
--   Sprint5: 活动、报名、订单、财务
--   Sprint7: 数据统计
--
-- 技术栈:
--   MySQL 8.0+ → 业务数据（所有表均存储在MySQL）
--   Redis 6.0+ → 验证码、登录失败计数
-- ========================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS hiking_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- ========================================
-- 步骤1: 执行 Pig 框架表初始化（如果需要）
-- 注意: 如果 pig.sql 已执行，可跳过此部分
-- ========================================

-- USE pig;  -- 如果需要初始化 pig 库，请先执行 pig.sql

-- ========================================
-- 步骤2: 切换到 hiking_db 创建业务表
-- ========================================

USE hiking_db;

-- ========================================
-- Sprint1 业务表
-- ========================================

-- 用户扩展信息表（MySQL存储，非MongoDB）
CREATE TABLE IF NOT EXISTS hiking_user_profile (
    id BIGINT NOT NULL COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID，关联sys_user.user_id',
    nickname VARCHAR(50) COMMENT '昵称',
    avatar VARCHAR(255) COMMENT '头像URL',
    gender INT DEFAULT 0 COMMENT '性别: 0-保密 1-男 2-女',
    birthday VARCHAR(20) COMMENT '出生年月',
    signature VARCHAR(255) COMMENT '个性签名',
    is_leader INT DEFAULT 0 COMMENT '是否领队: 0-否 1-是',
    is_vip INT DEFAULT 0 COMMENT '是否VIP: 0-否 1-是',
    vip_expire_time DATETIME COMMENT 'VIP过期时间',
    level INT DEFAULT 1 COMMENT '徒步等级',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='徒步用户扩展信息表';

-- 领队认证申请表
CREATE TABLE IF NOT EXISTS hiking_leader_apply (
    id BIGINT NOT NULL COMMENT '申请ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    real_name VARCHAR(50) NOT NULL COMMENT '真实姓名',
    phone VARCHAR(20) NOT NULL COMMENT '联系电话',
    emergency_contact VARCHAR(50) COMMENT '紧急联系人',
    emergency_phone VARCHAR(20) COMMENT '紧急联系电话',
    hiking_experience TEXT COMMENT '徒步经验描述',
    certificate_urls VARCHAR(1000) COMMENT '资质证书图片URLs，逗号分隔',
    status TINYINT DEFAULT 0 COMMENT '状态: 0-待审核 1-已通过 2-已驳回',
    reject_reason VARCHAR(500) COMMENT '驳回原因',
    reviewer_id BIGINT COMMENT '审核人ID',
    review_time DATETIME COMMENT '审核时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='领队认证申请表';

-- ========================================
-- Sprint2 业务表 - 内容管理
-- ========================================

-- 帖子表
CREATE TABLE IF NOT EXISTS hiking_post (
    id BIGINT NOT NULL COMMENT '帖子ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    content TEXT NOT NULL COMMENT '帖子内容',
    image_urls VARCHAR(2000) COMMENT '图片URLs，逗号分隔',
    location_name VARCHAR(100) COMMENT '位置名称',
    latitude DECIMAL(10,6) COMMENT '纬度',
    longitude DECIMAL(10,6) COMMENT '经度',
    like_count INT DEFAULT 0 COMMENT '点赞数',
    comment_count INT DEFAULT 0 COMMENT '评论数',
    share_count INT DEFAULT 0 COMMENT '分享数',
    status TINYINT DEFAULT 0 COMMENT '状态: 0-正常 1-隐藏 2-删除',
    audit_status TINYINT DEFAULT 1 COMMENT '审核状态: 0-待审核 1-已通过 2-已驳回',
    audit_reason VARCHAR(500) COMMENT '审核驳回原因',
    auditor_id BIGINT COMMENT '审核人ID',
    audit_time DATETIME COMMENT '审核时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    INDEX idx_user_id (user_id),
    INDEX idx_audit_status (audit_status),
    INDEX idx_status (status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子表';

-- 举报表
CREATE TABLE IF NOT EXISTS hiking_report (
    id BIGINT NOT NULL COMMENT '举报ID',
    reporter_id BIGINT NOT NULL COMMENT '举报人ID',
    target_type TINYINT NOT NULL COMMENT '目标类型: 1-帖子 2-评论 3-用户',
    target_id BIGINT NOT NULL COMMENT '目标ID',
    reason VARCHAR(500) NOT NULL COMMENT '举报原因',
    evidence_urls VARCHAR(2000) COMMENT '证据图片URLs',
    status TINYINT DEFAULT 0 COMMENT '处理状态: 0-待处理 1-已处理 2-已驳回',
    handler_id BIGINT COMMENT '处理人ID',
    handle_result VARCHAR(500) COMMENT '处理结果',
    handle_time DATETIME COMMENT '处理时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '举报时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    INDEX idx_reporter_id (reporter_id),
    INDEX idx_target (target_type, target_id),
    INDEX idx_status (status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='举报表';

-- ========================================
-- Sprint2 业务表 - 评论模块
-- ========================================

-- 评论表
CREATE TABLE IF NOT EXISTS hiking_comment (
    id BIGINT NOT NULL COMMENT '评论ID',
    post_id BIGINT NOT NULL COMMENT '帖子ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    parent_id BIGINT DEFAULT 0 COMMENT '父评论ID，0表示顶级评论',
    content TEXT NOT NULL COMMENT '评论内容',
    like_count INT DEFAULT 0 COMMENT '点赞数',
    reply_count INT DEFAULT 0 COMMENT '回复数',
    status TINYINT DEFAULT 0 COMMENT '状态: 0-正常 1-隐藏 2-删除',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    INDEX idx_post_id (post_id),
    INDEX idx_user_id (user_id),
    INDEX idx_parent_id (parent_id),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论表';

-- ========================================
-- Sprint3 业务表 - 路线与攻略
-- ========================================

-- 路线表
CREATE TABLE IF NOT EXISTS hiking_route (
    id BIGINT NOT NULL COMMENT '路线ID',
    name VARCHAR(100) NOT NULL COMMENT '路线名称',
    cover_image VARCHAR(500) COMMENT '封面图片',
    description TEXT COMMENT '路线描述',
    difficulty TINYINT DEFAULT 1 COMMENT '难度等级: 1-简单 2-中等 3-困难 4-极难',
    distance DECIMAL(10,2) COMMENT '距离（公里）',
    elevation_gain INT COMMENT '爬升高度（米）',
    estimated_duration INT COMMENT '预计时长（分钟）',
    route_type TINYINT DEFAULT 1 COMMENT '路线类型: 1-徒步 2-登山 3-溯溪 4-穿越',
    start_point VARCHAR(200) COMMENT '起点',
    end_point VARCHAR(200) COMMENT '终点',
    waypoints TEXT COMMENT '途经点，JSON格式',
    route_data TEXT COMMENT '路线轨迹数据',
    tags VARCHAR(200) COMMENT '标签，逗号分隔',
    is_featured TINYINT DEFAULT 0 COMMENT '是否推荐: 0-否 1-是',
    is_public TINYINT DEFAULT 1 COMMENT '是否公开: 0-否 1-是',
    view_count INT DEFAULT 0 COMMENT '浏览数',
    favorite_count INT DEFAULT 0 COMMENT '收藏数',
    status TINYINT DEFAULT 0 COMMENT '状态: 0-待审核 1-已通过 2-已驳回',
    audit_status TINYINT DEFAULT 1 COMMENT '审核状态: 0-待审核 1-已通过 2-已驳回',
    auditor_id BIGINT COMMENT '审核人ID',
    audit_time DATETIME COMMENT '审核时间',
    create_by BIGINT COMMENT '创建人ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    INDEX idx_difficulty (difficulty),
    INDEX idx_distance (distance),
    INDEX idx_route_type (route_type),
    INDEX idx_is_featured (is_featured),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='徒步路线表';

-- 攻略表
CREATE TABLE IF NOT EXISTS hiking_guide (
    id BIGINT NOT NULL COMMENT '攻略ID',
    user_id BIGINT NOT NULL COMMENT '作者ID',
    route_id BIGINT COMMENT '关联路线ID',
    title VARCHAR(200) NOT NULL COMMENT '攻略标题',
    summary VARCHAR(500) COMMENT '攻略摘要',
    content TEXT NOT NULL COMMENT '攻略正文内容',
    cover_images VARCHAR(1000) COMMENT '封面图片，逗号分隔',
    tags VARCHAR(200) COMMENT '标签，逗号分隔',
    view_count INT DEFAULT 0 COMMENT '浏览数',
    like_count INT DEFAULT 0 COMMENT '点赞数',
    favorite_count INT DEFAULT 0 COMMENT '收藏数',
    comment_count INT DEFAULT 0 COMMENT '评论数',
    status TINYINT DEFAULT 0 COMMENT '状态: 0-待审核 1-已发布 2-草稿 3-下架',
    audit_status TINYINT DEFAULT 0 COMMENT '审核状态: 0-待审核 1-已通过 2-已驳回',
    auditor_id BIGINT COMMENT '审核人ID',
    audit_time DATETIME COMMENT '审核时间',
    publish_time DATETIME COMMENT '发布时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    INDEX idx_user_id (user_id),
    INDEX idx_route_id (route_id),
    INDEX idx_status (status),
    INDEX idx_audit_status (audit_status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='徒步攻略表';

-- ========================================
-- Sprint5 业务表 - 活动与报名
-- ========================================

-- 活动表
CREATE TABLE IF NOT EXISTS hiking_activity (
    id BIGINT NOT NULL COMMENT '活动ID',
    title VARCHAR(200) NOT NULL COMMENT '活动标题',
    cover_image VARCHAR(500) COMMENT '封面图片',
    description TEXT COMMENT '活动描述',
    route_id BIGINT NOT NULL COMMENT '关联路线ID',
    leader_id BIGINT NOT NULL COMMENT '领队用户ID',
    activity_type TINYINT DEFAULT 1 COMMENT '活动类型: 1-日常徒步 2-主题活动 3-挑战赛 4-团建',
    max_participants INT NOT NULL COMMENT '最大参与人数',
    current_participants INT DEFAULT 0 COMMENT '当前报名人数',
    signup_start_time DATETIME NOT NULL COMMENT '报名开始时间',
    signup_end_time DATETIME NOT NULL COMMENT '报名截止时间',
    activity_start_time DATETIME NOT NULL COMMENT '活动开始时间',
    activity_end_time DATETIME NOT NULL COMMENT '活动结束时间',
    meeting_point VARCHAR(200) COMMENT '集合地点',
    meeting_latitude DECIMAL(10,6) COMMENT '集合点纬度',
    meeting_longitude DECIMAL(10,6) COMMENT '集合点经度',
    estimated_duration INT COMMENT '预计时长（分钟）',
    fee DECIMAL(10,2) DEFAULT 0 COMMENT '费用（元）',
    fee_includes VARCHAR(500) COMMENT '费用包含说明',
    equipment_require TEXT COMMENT '装备要求',
    attention_items TEXT COMMENT '注意事项',
    risk_assessment TEXT COMMENT '风险评估',
    status TINYINT DEFAULT 0 COMMENT '状态: 0-待审核 1-报名中 2-报名截止 3-活动进行中 4-已结束 5-已取消',
    audit_status TINYINT DEFAULT 0 COMMENT '审核状态: 0-待审核 1-已通过 2-已驳回',
    audit_reason VARCHAR(500) COMMENT '审核驳回原因',
    auditor_id BIGINT COMMENT '审核人ID',
    audit_time DATETIME COMMENT '审核时间',
    cancellation_reason VARCHAR(500) COMMENT '取消原因',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    INDEX idx_route_id (route_id),
    INDEX idx_leader_id (leader_id),
    INDEX idx_activity_type (activity_type),
    INDEX idx_status (status),
    INDEX idx_activity_start_time (activity_start_time),
    INDEX idx_audit_status (audit_status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='徒步活动表';

-- 活动报名表
CREATE TABLE IF NOT EXISTS hiking_signup (
    id BIGINT NOT NULL COMMENT '报名ID',
    activity_id BIGINT NOT NULL COMMENT '活动ID',
    user_id BIGINT NOT NULL COMMENT '报名用户ID',
    real_name VARCHAR(50) NOT NULL COMMENT '真实姓名',
    phone VARCHAR(20) NOT NULL COMMENT '联系电话',
    gender TINYINT COMMENT '性别: 1-男 2-女',
    emergency_contact VARCHAR(50) COMMENT '紧急联系人',
    emergency_phone VARCHAR(20) COMMENT '紧急联系电话',
    health_condition VARCHAR(200) COMMENT '健康状况备注',
    hiking_experience TINYINT DEFAULT 1 COMMENT '徒步经验: 1-新手 2-有经验 3-丰富',
    equipment_status TINYINT DEFAULT 0 COMMENT '装备状态: 0-无装备 1-自备 2-需要租借',
    signup_status TINYINT DEFAULT 1 COMMENT '报名状态: 0-取消报名 1-已报名 2-已确认 3-已签到 4-已退出',
    cancel_reason VARCHAR(500) COMMENT '取消原因',
    sign_time DATETIME COMMENT '签到时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '报名时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    UNIQUE KEY uk_activity_user (activity_id, user_id),
    INDEX idx_activity_id (activity_id),
    INDEX idx_user_id (user_id),
    INDEX idx_signup_status (signup_status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='活动报名表';

-- ========================================
-- Sprint5 业务表 - 订单与财务
-- ========================================

-- 订单表
CREATE TABLE IF NOT EXISTS hiking_order (
    id BIGINT NOT NULL COMMENT '订单ID',
    order_no VARCHAR(32) NOT NULL COMMENT '订单号',
    activity_id BIGINT COMMENT '关联活动ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    leader_id BIGINT COMMENT '领队用户ID（收入归属）',
    total_amount DECIMAL(10,2) NOT NULL COMMENT '订单总金额',
    discount_amount DECIMAL(10,2) DEFAULT 0 COMMENT '优惠金额',
    actual_amount DECIMAL(10,2) NOT NULL COMMENT '实付金额',
    order_type TINYINT NOT NULL COMMENT '订单类型: 1-活动报名费 2-装备租赁 3-商品购买',
    pay_type TINYINT COMMENT '支付方式: 1-微信 2-支付宝 3-余额',
    pay_status TINYINT DEFAULT 0 COMMENT '支付状态: 0-待支付 1-已支付 2-已退款 3-已关闭',
    pay_time DATETIME COMMENT '支付时间',
    transaction_id VARCHAR(64) COMMENT '支付流水号',
    refund_amount DECIMAL(10,2) DEFAULT 0 COMMENT '退款金额',
    refund_time DATETIME COMMENT '退款时间',
    refund_reason VARCHAR(500) COMMENT '退款原因',
    remark VARCHAR(500) COMMENT '订单备注',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    UNIQUE KEY uk_order_no (order_no),
    INDEX idx_activity_id (activity_id),
    INDEX idx_user_id (user_id),
    INDEX idx_leader_id (leader_id),
    INDEX idx_pay_status (pay_status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单表';

-- 提现申请表
CREATE TABLE IF NOT EXISTS hiking_withdraw (
    id BIGINT NOT NULL COMMENT '提现ID',
    withdraw_no VARCHAR(32) NOT NULL COMMENT '提现单号',
    user_id BIGINT NOT NULL COMMENT '申请人ID（领队）',
    bank_name VARCHAR(100) COMMENT '银行名称',
    bank_account VARCHAR(50) COMMENT '银行账号',
    account_name VARCHAR(50) COMMENT '开户名',
    amount DECIMAL(10,2) NOT NULL COMMENT '提现金额',
    fee DECIMAL(10,2) DEFAULT 0 COMMENT '手续费',
    actual_amount DECIMAL(10,2) NOT NULL COMMENT '实际到账金额',
    status TINYINT DEFAULT 0 COMMENT '状态: 0-待审核 1-待打款 2-已打款 3-已拒绝 4-已取消',
    reject_reason VARCHAR(500) COMMENT '拒绝原因',
    reviewer_id BIGINT COMMENT '审核人ID',
    review_time DATETIME COMMENT '审核时间',
    pay_time DATETIME COMMENT '打款时间',
    pay_remark VARCHAR(500) COMMENT '打款备注',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    UNIQUE KEY uk_withdraw_no (withdraw_no),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='提现申请表';

-- 退款申请表
CREATE TABLE IF NOT EXISTS hiking_refund (
    id BIGINT NOT NULL COMMENT '退款ID',
    refund_no VARCHAR(32) NOT NULL COMMENT '退款单号',
    order_id BIGINT NOT NULL COMMENT '原订单ID',
    order_no VARCHAR(32) NOT NULL COMMENT '原订单号',
    user_id BIGINT NOT NULL COMMENT '申请人ID',
    activity_id BIGINT COMMENT '关联活动ID',
    refund_type TINYINT NOT NULL COMMENT '退款类型: 1-用户取消 2-活动取消 3-部分退款',
    amount DECIMAL(10,2) NOT NULL COMMENT '退款金额',
    refund_reason VARCHAR(500) NOT NULL COMMENT '退款原因',
    refund_status TINYINT DEFAULT 0 COMMENT '退款状态: 0-待审核 1-待退款 2-已退款 3-已拒绝',
    reviewer_id BIGINT COMMENT '审核人ID',
    review_time DATETIME COMMENT '审核时间',
    review_remark VARCHAR(500) COMMENT '审核备注',
    refund_time DATETIME COMMENT '退款时间',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    del_flag CHAR(1) DEFAULT '0' COMMENT '删除标记: 0-正常 1-删除',
    PRIMARY KEY (id),
    UNIQUE KEY uk_refund_no (refund_no),
    INDEX idx_order_id (order_id),
    INDEX idx_user_id (user_id),
    INDEX idx_activity_id (activity_id),
    INDEX idx_refund_status (refund_status),
    INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='退款申请表';

-- ========================================
-- 步骤3: 初始化管理端岗位数据
-- 目标库: pig
-- 说明: 岗位体系用于管理端用户职位划分
-- ========================================
USE pig;

-- 岗位初始化（避免与现有数据冲突，post_id 从 1001 开始）
INSERT INTO sys_post (post_id, post_code, post_name, post_sort, remark, del_flag, create_time) VALUES
(1001, 'POST_OP_JUNIOR', '初级运营', 1, '路线筛选、异常标注', '0', NOW()),
(1002, 'POST_OP_SENIOR', '高级运营', 2, '内容审核、领队审核、举报处理', '0', NOW()),
(1003, 'POST_OP_DIRECTOR', '运营总监', 3, '审批决策、数据分析、团队管理', '0', NOW()),
(1004, 'POST_FIN_STAFF', '财务专员', 4, '对账、发起提现/退款申请', '0', NOW()),
(1005, 'POST_FIN_MANAGER', '财务主管', 5, '审批提现/退款、财务报表', '0', NOW()),
(1006, 'POST_CS_STAFF', '客服专员', 6, '用户咨询、投诉处理、SOS响应', '0', NOW()),
(1007, 'POST_TECH_OPS', '技术运营', 7, '知识库管理、AI配置', '0', NOW()),
(1008, 'POST_SUPER_ADMIN', '超级管理员', 99, '系统配置、全部权限', '0', NOW())
ON DUPLICATE KEY UPDATE post_name = VALUES(post_name);

-- ========================================
-- 步骤4: 初始化管理端角色数据
-- 目标库: pig
-- 说明: 角色体系用于管理端权限控制（已在 pig.sql 中定义了 ROLE_ADMIN(1), GENERAL_USER(2)，此处新增 2001-2008）
-- ========================================

INSERT INTO sys_role (role_id, role_code, role_name, role_desc, del_flag, create_time) VALUES
(2001, 'ROLE_OP_JUNIOR', '初级运营角色', '路线管理权限', '0', NOW()),
(2002, 'ROLE_OP_SENIOR', '高级运营角色', '内容审核+领队审核权限', '0', NOW()),
(2003, 'ROLE_OP_DIRECTOR', '运营总监角色', '运营全部权限+数据统计', '0', NOW()),
(2004, 'ROLE_FIN_STAFF', '财务专员角色', '财务查看+发起申请', '0', NOW()),
(2005, 'ROLE_FIN_MANAGER', '财务主管角色', '财务审批权限', '0', NOW()),
(2006, 'ROLE_CS_STAFF', '客服角色', '用户查看+举报处理', '0', NOW()),
(2007, 'ROLE_TECH_OPS', '技术运营角色', '知识库+AI配置', '0', NOW()),
(2008, 'ROLE_SUPER_ADMIN', '超级管理员', '全部权限', '0', NOW())
ON DUPLICATE KEY UPDATE role_name = VALUES(role_name);

-- ========================================
-- 步骤5: 初始化管理端菜单数据
-- 目标库: pig
-- 说明: 菜单体系用于管理端导航和权限标识
-- 注意: menu_id 从 3000 开始，避免与现有菜单冲突（现有最大 9064）
-- ========================================

-- 一级菜单：首页
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, keep_alive, del_flag, create_time) VALUES
(3000, '首页', 'hiking_home', '/home', -1, 'iconfont icon-shouye', 0, '0', '0', '0', '0', NOW());

-- 一级菜单：用户中心
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, keep_alive, del_flag, create_time) VALUES
(3100, '用户中心', '', '/user', -1, 'iconfont icon-yonghu', 1, '0', '0', '0', '0', NOW());

-- 二级菜单
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, del_flag, create_time) VALUES
(3101, '用户管理', 'hiking_user_view', '/hiking/user/index', 3100, 'ele-User', 1, '0', '0', '0', NOW()),
(3102, '领队认证', 'hiking_leader_view', '/hiking/leader/index', 3100, 'ele-Medal', 2, '0', '0', '0', NOW()),
(3103, '角色管理', 'sys_role_view', '/admin/role/index', 3100, 'ele-UserFilled', 3, '0', '0', '0', NOW());

-- 按钮权限：用户管理
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, sort_order, menu_type, del_flag, create_time) VALUES
(310101, '用户新增', 'hiking_user_add', NULL, 3101, 1, '1', '0', NOW()),
(310102, '用户修改', 'hiking_user_edit', NULL, 3101, 2, '1', '0', NOW()),
(310103, '用户删除', 'hiking_user_del', NULL, 3101, 3, '1', '0', NOW()),
(310104, '用户导出', 'hiking_user_export', NULL, 3101, 4, '1', '0', NOW());

-- 按钮权限：领队认证
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, sort_order, menu_type, del_flag, create_time) VALUES
(310201, '领队审核', 'hiking_leader_audit', NULL, 3102, 1, '1', '0', NOW()),
(310202, '领队导出', 'hiking_leader_export', NULL, 3102, 2, '1', '0', NOW());

-- 一级菜单：内容管理（Sprint2，预留）
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, del_flag, create_time) VALUES
(3200, '内容管理', '', '/content', -1, 'iconfont icon-wenzhang', 2, '0', '0', '0', NOW()),
(3201, '帖子审核', 'hiking_post_view', '/hiking/content/post', 3200, 'ele-Document', 1, '0', '0', '0', NOW()),
(3202, '评论管理', 'hiking_comment_view', '/hiking/content/comment', 3200, 'ele-ChatDotRound', 2, '0', '0', '0', NOW()),
(3203, '举报处理', 'hiking_report_view', '/hiking/content/report', 3200, 'ele-Warning', 3, '0', '0', '0', NOW());

-- 一级菜单：路线管理（Sprint3，预留）
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, del_flag, create_time) VALUES
(3300, '路线管理', '', '/route', -1, 'iconfont icon-luxian', 3, '0', '0', '0', NOW()),
(3301, '路线库', 'hiking_route_view', '/hiking/route/library', 3300, 'ele-MapLocation', 1, '0', '0', '0', NOW()),
(3302, '攻略库', 'hiking_guide_view', '/hiking/route/guide', 3300, 'ele-Notebook', 2, '0', '0', '0', NOW());

-- 一级菜单：活动管理（Sprint5，预留）
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, del_flag, create_time) VALUES
(3400, '活动管理', '', '/activity', -1, 'iconfont icon-huodong', 4, '0', '0', '0', NOW()),
(3401, '活动列表', 'hiking_activity_view', '/hiking/activity/list', 3400, 'ele-Tickets', 1, '0', '0', '0', NOW()),
(3402, '报名管理', 'hiking_signup_view', '/hiking/activity/signup', 3400, 'ele-List', 2, '0', '0', '0', NOW());

-- 一级菜单：财务管理（Sprint5，预留）
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, del_flag, create_time) VALUES
(3500, '财务管理', '', '/finance', -1, 'iconfont icon-caiwu', 5, '0', '0', '0', NOW()),
(3501, '订单管理', 'hiking_order_view', '/hiking/finance/order', 3500, 'ele-Money', 1, '0', '0', '0', NOW()),
(3502, '提现审批', 'hiking_withdraw_view', '/hiking/finance/withdraw', 3500, 'ele-Wallet', 2, '0', '0', '0', NOW()),
(3503, '退款管理', 'hiking_refund_view', '/hiking/finance/refund', 3500, 'ele-RefreshLeft', 3, '0', '0', '0', NOW());

-- 一级菜单：数据统计（Sprint7，预留）
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, del_flag, create_time) VALUES
(3600, '数据统计', '', '/dashboard', -1, 'iconfont icon-shujutongji', 6, '0', '0', '0', NOW()),
(3601, '运营看板', 'hiking_dashboard_view', '/hiking/dashboard/index', 3600, 'ele-DataAnalysis', 1, '0', '0', '0', NOW());

-- 一级菜单：AI 运营（Sprint3，预留）
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, visible, del_flag, create_time) VALUES
(3800, 'AI 运营', '', '/ai', -1, 'iconfont icon-robot', 8, '0', '0', '0', NOW()),
(3801, '知识库管理', 'hiking_knowledge_view', '/hiking/ai/knowledge', 3800, 'ele-Collection', 1, '0', '0', '0', NOW()),
(3802, 'AI 配置', 'hiking_ai_config', '/hiking/ai/config', 3800, 'ele-Setting', 2, '0', '0', '0', NOW());

-- ========================================
-- 步骤6: 初始化角色菜单关联
-- 目标库: pig
-- 说明: 为新增角色分配菜单权限
-- ========================================

-- 运营总监(2003)：用户中心 + 内容管理 + 路线管理 + 活动管理 + 数据统计
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2003, menu_id FROM sys_menu
WHERE menu_id IN (
    3000, 3100, 3101, 3102, 3103, 310101, 310102, 310103, 310104, 310201, 310202,
    3200, 3201, 3202, 3203,
    3300, 3301, 3302,
    3400, 3401, 3402,
    3600, 3601
) AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2003 AND menu_id = sys_menu.menu_id);

-- 高级运营(2002)：用户管理 + 领队认证 + 内容管理
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2002, menu_id FROM sys_menu
WHERE menu_id IN (
    3000, 3100, 3101, 3102, 310101, 310102, 310201,
    3200, 3201, 3202, 3203
) AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2002 AND menu_id = sys_menu.menu_id);

-- 初级运营(2001)：路线管理 + 活动管理（查看）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2001, menu_id FROM sys_menu
WHERE menu_id IN (
    3000, 3100, 3101,
    3300, 3301, 3302,
    3400, 3401, 3402
) AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2001 AND menu_id = sys_menu.menu_id);

-- 财务主管(2005)：财务管理 + 数据统计
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2005, menu_id FROM sys_menu
WHERE menu_id IN (
    3000, 3500, 3501, 3502, 3503, 3600, 3601
) AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2005 AND menu_id = sys_menu.menu_id);

-- 财务专员(2004)：订单管理（只读）+ 发起申请
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2004, menu_id FROM sys_menu
WHERE menu_id IN (
    3000, 3500, 3501, 3600, 3601
) AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2004 AND menu_id = sys_menu.menu_id);

-- 客服(2006)：用户管理（只读）+ 举报处理
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2006, menu_id FROM sys_menu
WHERE menu_id IN (
    3000, 3100, 3101, 3200, 3203
) AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2006 AND menu_id = sys_menu.menu_id);

-- 技术运营(2007)：AI 运营 + 数据统计
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2007, menu_id FROM sys_menu
WHERE menu_id IN (
    3000, 3800, 3801, 3802, 3600, 3601
) AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2007 AND menu_id = sys_menu.menu_id);

-- ========================================
-- 步骤7: 给超级管理员(2008)角色分配全部菜单
-- 说明: 超级管理员拥有全部菜单权限
-- ========================================

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 2008, menu_id FROM sys_menu WHERE menu_id >= 3000
AND NOT EXISTS (SELECT 1 FROM sys_role_menu WHERE role_id = 2008 AND menu_id = sys_menu.menu_id);

-- ========================================
-- 步骤8: 将超级管理员(2008)角色分配给 admin 用户
-- 说明: 超级管理员拥有全部菜单权限
-- ========================================

INSERT INTO sys_user_role (user_id, role_id) VALUES (1, 2008)
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);

-- ========================================
-- 初始化完成
-- ========================================
