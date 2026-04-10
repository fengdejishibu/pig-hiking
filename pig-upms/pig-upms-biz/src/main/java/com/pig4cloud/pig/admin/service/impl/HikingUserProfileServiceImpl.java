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

package com.pig4cloud.pig.admin.service.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.pig4cloud.pig.admin.api.entity.HikingUserProfile;
import com.pig4cloud.pig.admin.mapper.HikingUserProfileMapper;
import com.pig4cloud.pig.admin.service.HikingUserProfileService;
import com.pig4cloud.pig.common.core.util.R;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 徒步用户扩展信息服务实现
 *
 * @author hiking
 * @date 2026-04-03
 */
@Slf4j
@Service
@AllArgsConstructor
public class HikingUserProfileServiceImpl extends ServiceImpl<HikingUserProfileMapper, HikingUserProfile>
		implements HikingUserProfileService {

	private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

	/**
	 * 获取用户扩展信息
	 */
	@Override
	public R<HikingUserProfile> getUserProfile(Long userId) {
		HikingUserProfile profile = this.getOne(
				Wrappers.<HikingUserProfile>lambdaQuery().eq(HikingUserProfile::getUserId, userId));

		if (profile == null) {
			// 如果不存在，返回默认值
			profile = new HikingUserProfile();
			profile.setUserId(userId);
			profile.setGender(0); // 默认保密
			profile.setSignature("这个人很神秘，什么都没有写"); // 默认签名
			profile.setIsLeader(0);
			profile.setIsVip(0);
			profile.setLevel(1);
			log.info("用户 {} 扩展信息不存在，返回默认信息", userId);
		}

		return R.ok(profile);
	}

	/**
	 * 授予/取消领队身份
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public R<Boolean> updateLeaderStatus(Long userId, Integer isLeader) {
		HikingUserProfile profile = getOrCreateProfile(userId);
		profile.setIsLeader(isLeader);
		this.updateById(profile);

		log.info("用户 {} 领队身份已更新为 {}", userId, isLeader == 1 ? "授予" : "取消");
		return R.ok(true, isLeader == 1 ? "授予领队身份成功" : "取消领队身份成功");
	}

	/**
	 * 授予/取消VIP身份
	 */
	@Override
	@Transactional(rollbackFor = Exception.class)
	public R<Boolean> updateVipStatus(Long userId, Integer isVip, String vipExpireTime) {
		HikingUserProfile profile = getOrCreateProfile(userId);
		profile.setIsVip(isVip);

		if (isVip == 1 && vipExpireTime != null && !vipExpireTime.isBlank()) {
			// 解析过期时间
			try {
				LocalDateTime expireDateTime = LocalDateTime.parse(vipExpireTime, DATE_TIME_FORMATTER);
				profile.setVipExpireTime(expireDateTime);
			}
			catch (Exception e) {
				log.warn("VIP过期时间格式错误: {}", vipExpireTime);
				return R.failed("VIP过期时间格式错误，请使用 yyyy-MM-dd HH:mm:ss 格式");
			}
		}
		else if (isVip == 0) {
			// 取消VIP时清空过期时间
			profile.setVipExpireTime(null);
		}

		this.updateById(profile);

		log.info("用户 {} VIP身份已更新为 {}", userId, isVip == 1 ? "授予" : "取消");
		return R.ok(true, isVip == 1 ? "授予VIP身份成功" : "取消VIP身份成功");
	}

	/**
	 * 获取或创建用户扩展信息
	 */
	@Override
	public HikingUserProfile getOrCreateProfile(Long userId) {
		HikingUserProfile profile = this.getOne(
				Wrappers.<HikingUserProfile>lambdaQuery().eq(HikingUserProfile::getUserId, userId));

		if (profile == null) {
			profile = new HikingUserProfile();
			profile.setUserId(userId);
			profile.setGender(0);
			profile.setSignature("这个人很神秘，什么都没有写");
			profile.setIsLeader(0);
			profile.setIsVip(0);
			profile.setLevel(1);
			this.save(profile);
			log.info("为用户 {} 创建扩展信息", userId);
		}

		return profile;
	}

}
