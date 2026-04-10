-- ========================================
-- hiking_user_profile 徒步用户扩展信息表
-- Sprint2: 小程序用户系统对接
-- ========================================

CREATE TABLE IF NOT EXISTS `hiking_user_profile` (
  `id` bigint NOT NULL COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '关联 sys_user.user_id',
  `nickname` varchar(64) DEFAULT NULL COMMENT '昵称',
  `avatar` varchar(255) DEFAULT NULL COMMENT '头像URL',
  `gender` int DEFAULT 0 COMMENT '性别 0-保密 1-男 2-女',
  `birthday` varchar(32) DEFAULT NULL COMMENT '出生年月 (格式: 1990-01)',
  `signature` varchar(255) DEFAULT NULL COMMENT '个性签名',
  `is_leader` int DEFAULT 0 COMMENT '是否领队 0-否 1-是',
  `is_vip` int DEFAULT 0 COMMENT '是否VIP 0-否 1-是',
  `vip_expire_time` datetime DEFAULT NULL COMMENT 'VIP过期时间',
  `level` int DEFAULT 1 COMMENT '徒步等级',
  `total_distance` decimal(10,2) DEFAULT 0.00 COMMENT '累计徒步公里数',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `idx_level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='徒步用户扩展信息表';
