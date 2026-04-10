// ========================================
// 徒步社区平台 - MongoDB 初始化脚本
// 版本: v3.0 (Sprint1 专用)
// 更新: 2026-04-02
// 说明: 严格按 Sprint1 用户故事设计
//
// 用户故事覆盖:
//   US-03 资料编辑 → user_profiles 集合
//   US-06 身份标识 → user_profiles 集合
//   US-10 授予身份 → user_profiles 集合
// ========================================

db = db.getSiblingDB('hiking_db');

// ------------------------------------
// 用户资料集合
// 用户故事: US-03 资料编辑, US-06 身份标识, US-10 授予身份
// ------------------------------------
db.createCollection('user_profiles');

// 创建索引
db.user_profiles.createIndex({ "user_id": 1 }, { unique: true });
db.user_profiles.createIndex({ "is_leader": 1 });
db.user_profiles.createIndex({ "is_vip": 1 });

// ------------------------------------
// 字段说明（文档结构）
// ------------------------------------
// {
//   _id: ObjectId,           // MongoDB 主键
//   user_id: NumberLong,     // 关联 sys_user.user_id -- US-03/US-06/US-10
//   nickname: String,        // 昵称 -- US-03
//   avatar: String,          // 头像URL -- US-03
//   gender: Number,          // 性别 0-保密 1-男 2-女 -- US-03
//   birthday: String,        // 出生年月 (格式: "1990-01") -- US-03
//   signature: String,       // 个性签名 -- US-03
//   is_leader: Number,       // 是否领队 0-否 1-是 -- US-06/US-10
//   is_vip: Number,          // 是否VIP 0-否 1-是 -- US-06/US-10
//   vip_expire: Date,        // VIP过期时间 -- US-10
//   level: Number,           // 徒步等级 -- US-06
//   created_at: Date,        // 创建时间
//   updated_at: Date         // 更新时间
// }

// 默认值示例
// 个性签名默认值: "这个人很神秘，什么都没有写" -- US-03
// 性别默认值: 0 (保密) -- US-03

print('MongoDB 初始化完成 - Sprint1');
