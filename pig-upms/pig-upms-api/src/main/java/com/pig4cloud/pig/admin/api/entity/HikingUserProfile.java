/*
 *    Copyright (c) 2018-2025, lengleng All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * Neither the name of the pig4cloud.com developer nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * Author: lengleng (wangiegie@gmail.com)
 */

package com.pig4cloud.pig.admin.api.entity;

import com.baomidou.mybatisplus.annotation.*;
import com.baomidou.mybatisplus.extension.activerecord.Model;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 徒步用户扩展信息表
 * 用户故事: US-03 资料编辑, US-06 身份标识, US-10 授予身份
 *
 * @author hiking
 * @date 2026-04-03
 */
@Data
@Schema(description = "徒步用户扩展信息")
@EqualsAndHashCode(callSuper = true)
@TableName("hiking_user_profile")
public class HikingUserProfile extends Model<HikingUserProfile> {

	private static final long serialVersionUID = 1L;

	/**
	 * 主键ID
	 */
	@TableId(type = IdType.ASSIGN_ID)
	@Schema(description = "主键ID")
	private Long id;

	/**
	 * 关联 sys_user.user_id
	 */
	@Schema(description = "用户ID", required = true)
	private Long userId;

	/**
	 * 昵称
	 */
	@Schema(description = "昵称")
	private String nickname;

	/**
	 * 头像URL
	 */
	@Schema(description = "头像URL")
	private String avatar;

	/**
	 * 性别 0-保密 1-男 2-女
	 */
	@Schema(description = "性别 0-保密 1-男 2-女")
	private Integer gender;

	/**
	 * 出生年月 (格式: "1990-01")
	 */
	@Schema(description = "出生年月")
	private String birthday;

	/**
	 * 个性签名
	 */
	@Schema(description = "个性签名")
	private String signature;

	/**
	 * 是否领队 0-否 1-是
	 */
	@Schema(description = "是否领队 0-否 1-是")
	private Integer isLeader;

	/**
	 * 是否VIP 0-否 1-是
	 */
	@Schema(description = "是否VIP 0-否 1-是")
	private Integer isVip;

	/**
	 * VIP过期时间
	 */
	@Schema(description = "VIP过期时间")
	private LocalDateTime vipExpireTime;

	/**
	 * 徒步等级
	 */
	@Schema(description = "徒步等级")
	private Integer level;

	/**
	 * 创建时间
	 */
	@TableField(fill = FieldFill.INSERT)
	@Schema(description = "创建时间")
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	@TableField(fill = FieldFill.INSERT_UPDATE)
	@Schema(description = "更新时间")
	private LocalDateTime updateTime;

}
