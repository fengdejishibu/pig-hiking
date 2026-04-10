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

package com.pig4cloud.pig.admin.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.pig4cloud.pig.admin.api.entity.HikingUserProfile;
import com.pig4cloud.pig.common.core.util.R;

/**
 * 徒步用户扩展信息服务接口
 *
 * @author hiking
 * @date 2026-04-03
 */
public interface HikingUserProfileService extends IService<HikingUserProfile> {

	/**
	 * 获取用户扩展信息
	 * @param userId 用户ID
	 * @return 用户扩展信息
	 */
	R<HikingUserProfile> getUserProfile(Long userId);

	/**
	 * 授予/取消领队身份
	 * @param userId 用户ID
	 * @param isLeader 是否领队 1-授予 0-取消
	 * @return 操作结果
	 */
	R<Boolean> updateLeaderStatus(Long userId, Integer isLeader);

	/**
	 * 授予/取消VIP身份
	 * @param userId 用户ID
	 * @param isVip 是否VIP 1-授予 0-取消
	 * @param vipExpireTime VIP过期时间（授予时必填）
	 * @return 操作结果
	 */
	R<Boolean> updateVipStatus(Long userId, Integer isVip, String vipExpireTime);

	/**
	 * 获取或创建用户扩展信息
	 * @param userId 用户ID
	 * @return 用户扩展信息
	 */
	HikingUserProfile getOrCreateProfile(Long userId);

}
