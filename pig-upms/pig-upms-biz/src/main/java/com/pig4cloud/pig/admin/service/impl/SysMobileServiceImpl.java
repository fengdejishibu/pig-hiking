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

import cn.hutool.core.collection.CollUtil;
import cn.hutool.core.util.RandomUtil;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.pig4cloud.pig.admin.api.entity.SysUser;
import com.pig4cloud.pig.admin.mapper.SysUserMapper;
import com.pig4cloud.pig.admin.service.SysMobileService;
import com.pig4cloud.pig.common.core.constant.CacheConstants;
import com.pig4cloud.pig.common.core.constant.SecurityConstants;
import com.pig4cloud.pig.common.core.exception.ErrorCodes;
import com.pig4cloud.pig.common.core.util.MsgUtils;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.core.util.RedisUtils;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.dromara.sms4j.api.SmsBlend;
import org.dromara.sms4j.api.entity.SmsResponse;
import org.dromara.sms4j.core.factory.SmsFactory;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

/**
 * 手机登录相关业务实现类
 *
 * @author lengleng
 * @date 2025/05/30
 */
@Slf4j
@Service
@AllArgsConstructor
public class SysMobileServiceImpl implements SysMobileService {

	private final SysUserMapper userMapper;

	private static final String SMS_DAILY_KEY = "sms:daily:";

	private static final int DAILY_LIMIT = 10;

	/**
	 * 发送手机验证码（登录场景，需校验手机号已注册）
	 * @param mobile 手机号码
	 * @return 返回操作结果，包含验证码发送状态及验证码信息
	 */
	@Override
	public R<Boolean> sendSmsCode(String mobile) {
		List<SysUser> userList = userMapper
			.selectList(Wrappers.<SysUser>query().lambda().eq(SysUser::getPhone, mobile));

		if (CollUtil.isEmpty(userList)) {
			log.info("手机号未注册:{}", mobile);
			return R.ok(Boolean.FALSE, MsgUtils.getMessage(ErrorCodes.SYS_APP_PHONE_UNREGISTERED, mobile));
		}

		return doSendSmsCode(mobile);
	}

	/**
	 * 发送注册验证码（注册场景，校验手机号未注册）
	 * @param mobile 手机号码
	 * @return 发送结果
	 */
	@Override
	public R<Boolean> sendRegisterSmsCode(String mobile) {
		List<SysUser> userList = userMapper
			.selectList(Wrappers.<SysUser>query().lambda().eq(SysUser::getPhone, mobile));

		if (CollUtil.isNotEmpty(userList)) {
			log.info("手机号已注册:{}", mobile);
			return R.ok(Boolean.FALSE, "该手机号已注册");
		}

		return doSendSmsCode(mobile);
	}

	/**
	 * 实际发送验证码逻辑
	 */
	private R<Boolean> doSendSmsCode(String mobile) {
		// 每日发送限制
		String dailyKey = SMS_DAILY_KEY + mobile;
		String dailyCount = RedisUtils.get(dailyKey);
		if (dailyCount != null && Integer.parseInt(dailyCount) >= DAILY_LIMIT) {
			log.info("手机号每日发送上限:{}，已发送{}次", mobile, dailyCount);
			return R.ok(Boolean.FALSE, "今日验证码发送次数已达上限");
		}

		// 60秒内不可重发
		String cacheKey = CacheConstants.DEFAULT_CODE_KEY + mobile;
		String codeObj = RedisUtils.get(cacheKey);

		if (codeObj != null) {
			log.info("手机号验证码未过期:{}，{}", mobile, codeObj);
			return R.ok(Boolean.FALSE, MsgUtils.getMessage(ErrorCodes.SYS_APP_SMS_OFTEN));
		}

		String code = RandomUtil.randomNumbers(Integer.parseInt(SecurityConstants.CODE_SIZE));
		log.info("手机号生成验证码成功:{},{}", mobile, code);
		RedisUtils.set(cacheKey, code, SecurityConstants.CODE_TIME, TimeUnit.SECONDS);

		// 每日计数+1，key 到当天 23:59:59 过期
		long secondsUntilMidnight = Duration.between(LocalDateTime.now(),
				LocalDateTime.now().toLocalDate().atTime(LocalTime.MAX)).getSeconds();
		if (dailyCount == null) {
			RedisUtils.set(dailyKey, "1", secondsUntilMidnight, TimeUnit.SECONDS);
		}
		else {
			RedisUtils.set(dailyKey, String.valueOf(Integer.parseInt(dailyCount) + 1), secondsUntilMidnight,
					TimeUnit.SECONDS);
		}

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
	}

}
