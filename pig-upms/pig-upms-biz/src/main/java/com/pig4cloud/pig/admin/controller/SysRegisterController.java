package com.pig4cloud.pig.admin.controller;

import com.pig4cloud.pig.admin.api.dto.RegisterUserDTO;
import com.pig4cloud.pig.admin.service.SysUserService;
import com.pig4cloud.pig.common.core.constant.CacheConstants;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.core.util.RedisUtils;
import com.pig4cloud.pig.common.log.annotation.SysLog;
import com.pig4cloud.pig.common.security.annotation.Inner;

import cn.hutool.core.util.StrUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户注册控制器：提供用户注册功能
 *
 * @author lengleng
 * @date 2025/05/30
 */
@RestController
@RequestMapping("/register")
@RequiredArgsConstructor
@Tag(description = "register", name = "注册用户管理模块")
@ConditionalOnProperty(name = "register.user", matchIfMissing = true)
public class SysRegisterController {

	private final SysUserService userService;

	/**
	 * 注册用户（强制校验短信验证码）
	 * @param registerUserDTO 注册用户信息DTO
	 * @return 注册结果封装对象
	 */
	@Inner(value = false)
	@SysLog("注册用户")
	@PostMapping("/user")
	@Operation(summary = "注册用户", description = "注册用户")
	public R<Boolean> registerUser(@RequestBody RegisterUserDTO registerUserDTO) {
		// 强制校验手机号
		if (StrUtil.isBlank(registerUserDTO.getPhone())) {
			return R.failed("手机号不能为空");
		}
		// 强制校验验证码
		if (StrUtil.isBlank(registerUserDTO.getCode())) {
			return R.failed("验证码不能为空");
		}
		// 校验验证码是否正确
		String cacheKey = CacheConstants.DEFAULT_CODE_KEY + registerUserDTO.getPhone();
		String savedCode = RedisUtils.get(cacheKey);
		if (savedCode == null || !savedCode.equals(registerUserDTO.getCode())) {
			return R.failed("验证码错误或已过期");
		}
		// 验证通过后删除验证码
		RedisUtils.delete(cacheKey);

		// 如果用户名为空，使用手机号作为用户名
		if (StrUtil.isBlank(registerUserDTO.getUsername())) {
			registerUserDTO.setUsername(registerUserDTO.getPhone());
		}

		return userService.registerUser(registerUserDTO);
	}

}
