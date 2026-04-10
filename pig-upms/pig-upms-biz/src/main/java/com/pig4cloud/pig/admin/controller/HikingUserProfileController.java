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

package com.pig4cloud.pig.admin.controller;

import com.pig4cloud.pig.admin.api.entity.HikingUserProfile;
import com.pig4cloud.pig.admin.service.HikingUserProfileService;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.log.annotation.SysLog;
import com.pig4cloud.pig.common.security.annotation.HasPermission;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 徒步用户扩展信息控制器
 * 用户故事: US-06 身份标识, US-10 授予用户身份
 *
 * @author hiking
 * @date 2026-04-03
 */
@RestController
@AllArgsConstructor
@RequestMapping("/hiking/user")
@Tag(description = "hikingUser", name = "徒步用户扩展信息模块")
@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)
public class HikingUserProfileController {

	private final HikingUserProfileService hikingUserProfileService;

	/**
	 * 获取用户扩展信息
	 */
	@GetMapping("/profile/{userId}")
	@Operation(description = "获取用户扩展信息", summary = "获取用户的领队、VIP、等级等信息")
	public R<HikingUserProfile> getUserProfile(@PathVariable Long userId) {
		return hikingUserProfileService.getUserProfile(userId);
	}

	/**
	 * 授予/取消领队身份
	 */
	@PutMapping("/{userId}/leader")
	@SysLog("授予/取消领队身份")
	@HasPermission("sys_hiking_user_leader")
	@Operation(description = "授予/取消领队身份", summary = "授予或取消用户的领队身份")
	public R<Boolean> updateLeaderStatus(@PathVariable Long userId, @RequestBody Map<String, Integer> request) {
		Integer isLeader = request.get("isLeader");
		if (isLeader == null || (isLeader != 0 && isLeader != 1)) {
			return R.failed("isLeader 参数错误，必须为 0 或 1");
		}
		return hikingUserProfileService.updateLeaderStatus(userId, isLeader);
	}

	/**
	 * 授予/取消VIP身份
	 */
	@PutMapping("/{userId}/vip")
	@SysLog("授予/取消VIP身份")
	@HasPermission("sys_hiking_user_vip")
	@Operation(description = "授予/取消VIP身份", summary = "授予或取消用户的VIP身份")
	public R<Boolean> updateVipStatus(@PathVariable Long userId, @RequestBody Map<String, Object> request) {
		Integer isVip = (Integer) request.get("isVip");
		String vipExpireTime = (String) request.get("vipExpireTime");

		if (isVip == null || (isVip != 0 && isVip != 1)) {
			return R.failed("isVip 参数错误，必须为 0 或 1");
		}

		if (isVip == 1 && (vipExpireTime == null || vipExpireTime.isBlank())) {
			return R.failed("授予VIP时必须设置过期时间");
		}

		return hikingUserProfileService.updateVipStatus(userId, isVip, vipExpireTime);
	}

}
