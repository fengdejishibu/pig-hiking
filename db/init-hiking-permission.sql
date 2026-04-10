-- ========================================
-- 徒步社区平台 - 菜单与角色权限初始化
-- 版本: v2.0
-- 日期: 2026-04-09
-- 目标库: pig
-- 说明: 与 pig 框架融合，复用 pig 菜单，仅新建徒步特有功能
-- ========================================

-- ========================================
-- 第一部分: 徒步业务菜单 (sys_menu)
-- menu_id 从 30000 开始
-- 与 pig 菜单 (1000-2999) 互不冲突
-- ========================================

-- ---- 顶层菜单：徒步业务 ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (30000, '徒步业务', '/hiking', -1, 'iconfont icon-luxian', 3, '0', '0');

-- ---- 运营管理（运营线） ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (30001, '运营管理', '/hiking/ops', 30000, 'el-icon-s-operation', 1, '0', '0');

-- 领队认证 - Sprint1 实现
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (10002, '领队认证', 'hiking_leader_view', '/hiking/leader/index', 30001, 'el-icon-medal', 1, '0', '0');
-- 领队认证按钮权限
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES
(10020, '审核通过', 'hiking_leader_audit', NULL, 10002, NULL, 1, '1', '0'),
(10021, '审核驳回', 'hiking_leader_audit', NULL, 10002, NULL, 2, '1', '0');

-- 运营子菜单 - 施工中 (del_flag='1')
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES
(30011, '内容审核', '/hiking/content', 30001, 'el-icon-document', 2, '0', '1'),
(30012, '举报处理', '/hiking/report', 30001, 'el-icon-warning', 3, '0', '1'),
(30013, '路线管理', '/hiking/route', 30001, 'el-icon-map-location', 4, '0', '1');

-- ---- 活动管理 - Sprint5 施工中 ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (30002, '活动管理', '/hiking/activity', 30000, 'el-icon-tickets', 2, '0', '1');

-- ---- 财务管理（财务线） ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (30003, '财务管理', '/hiking/finance', 30000, 'el-icon-money', 3, '0', '0');
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES
(30020, '订单管理', '/hiking/order', 30003, 'el-icon-s-order', 1, '0', '1'),
(30021, '提现审批', '/hiking/withdraw', 30003, 'el-icon-wallet', 2, '0', '1');

-- ---- 客服中心 - 施工中 ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (30004, '客服中心', '/hiking/service', 30000, 'el-icon-service', 4, '0', '1');

-- ---- 技术管理（技术线） ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (30005, '技术管理', '/hiking/tech', 30000, 'el-icon-setting', 5, '0', '0');
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES
(30040, '知识库管理', '/hiking/knowledge', 30005, 'el-icon-notebook-2', 1, '0', '1'),
(30041, 'AI配置', '/hiking/ai-config', 30005, 'el-icon-cpu', 2, '0', '1');

-- ---- 数据统计 - Sprint7 施工中 ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (30006, '数据统计', '/hiking/statistics', 30000, 'el-icon-data-analysis', 6, '0', '1');

-- ---- 恢复岗位管理（在 pig 权限管理下） ----
INSERT INTO sys_menu (menu_id, name, path, parent_id, icon, sort_order, menu_type, del_flag)
VALUES (1600, '岗位管理', '/admin/post/index', 1000, 'el-icon-postcard', 4, '0', '0');
-- 岗位管理按钮权限
INSERT INTO sys_menu (menu_id, name, permission, path, parent_id, sort_order, menu_type, del_flag)
VALUES
(1601, '岗位查看', 'sys_post_view', NULL, 1600, 1, '1', '0'),
(1602, '岗位新增', 'sys_post_add', NULL, 1600, 2, '1', '0'),
(1603, '岗位修改', 'sys_post_edit', NULL, 1600, 3, '1', '0'),
(1604, '岗位删除', 'sys_post_del', NULL, 1600, 4, '1', '0'),
(1605, '导入导出', 'sys_post_export', NULL, 1600, 5, '1', '0');


-- ========================================
-- 第二部分: 管理端角色 (sys_role)
-- role_id 从 100 开始
-- ========================================

INSERT INTO sys_role (role_id, role_name, role_code, role_desc, del_flag)
VALUES
(100, '超级管理员', 'SUPER_ADMIN', '系统最高权限', '0'),
(101, '运营总监', 'OPERATION_DIRECTOR', '运营决策层', '0'),
(102, '运营专员', 'OPERATION_STAFF', '日常运营执行', '0'),
(103, '内容审核', 'CONTENT_AUDITOR', '内容审核和举报处理', '0'),
(104, '客服', 'CUSTOMER_SERVICE', '用户服务和举报处理', '0'),
(105, '财务', 'FINANCE', '订单和财务管理', '0'),
(106, '数据分析', 'DATA_ANALYST', '数据分析和报表', '0');


-- ========================================
-- 第三部分: 角色菜单关联 (sys_role_menu)
-- ========================================

-- 超级管理员(100): 全部活跃菜单
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 100, menu_id FROM sys_menu WHERE del_flag = '0';

-- 运营总监(101): 徒步运营管理全部 + 系统管理（不含权限管理）
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 101, menu_id FROM sys_menu WHERE del_flag = '0'
AND menu_id IN (30000,30001,10002,10020,10021,30011,30012,30013,30002,30006,2000,2001,2100,2906);

-- 运营专员(102): 领队认证 + 路线管理 + 活动管理
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 102, menu_id FROM sys_menu WHERE del_flag = '0'
AND menu_id IN (30000,30001,10002,10020,10021,30013,30002);

-- 内容审核(103): 内容审核 + 举报处理
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 103, menu_id FROM sys_menu WHERE del_flag = '0'
AND menu_id IN (30000,30001,30011,30012);

-- 客服(104): 举报处理
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 104, menu_id FROM sys_menu WHERE del_flag = '0'
AND menu_id IN (30000,30001,30012);

-- 财务(105): 财务管理 + 数据统计
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 105, menu_id FROM sys_menu WHERE del_flag = '0'
AND menu_id IN (30000,30003,30020,30021,30006);

-- 数据分析(106): 数据统计
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT 106, menu_id FROM sys_menu WHERE del_flag = '0'
AND menu_id IN (30000,30006);


-- ========================================
-- 第四部分: admin 用户关联超管角色
-- ========================================

DELETE FROM sys_user_role WHERE user_id = 1;
INSERT INTO sys_user_role (user_id, role_id) VALUES (1, 100);
