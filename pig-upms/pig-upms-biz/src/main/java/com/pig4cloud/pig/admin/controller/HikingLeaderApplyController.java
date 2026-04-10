/*
 *    Copyright (c) 2018-2025, lengleng All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided to the following conditions are met:
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

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pig4cloud.pig.admin.api.entity.HikingLeaderApply;
import com.pig4cloud.pig.admin.service.HikingLeaderApplyService;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.log.annotation.SysLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * 领队认证申请 Controller
 *
 * @author hiking
 * @date 2026-04-07
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/hiking/leader")
@Tag(name = "领队认证管理")
public class HikingLeaderApplyController {

	private final HikingLeaderApplyService hikingLeaderApplyService;

	/**
	 * 分页查询领队认证申请
	 */
	@GetMapping("/page")
	@Operation(summary = "领队认证申请分页", description = "分页查询领队认证申请列表")
	@PreAuthorize("@pms.hasPermission('hiking_leader_view')")
	public R getLeaderApplyPage(Page page) {
		return R.ok(hikingLeaderApplyService.page(page));
	}

	/**
	 * 获取领队认证申请详情
	 */
	@GetMapping("/{id}")
	@Operation(summary = "获取领队认证申请详情")
	@PreAuthorize("@pms.hasPermission('hiking_leader_view')")
	public R getById(@PathVariable Long id) {
		return R.ok(hikingLeaderApplyService.getById(id));
	}

	/**
	 * 审核领队认证申请
	 * @param id 申请ID
	 * @param status 审核状态: 1-通过 2-驳回
	 * @param rejectReason 驳回原因
	 */
	@PostMapping("/audit/{id}")
	@Operation(summary = "审核领队认证申请")
	@PreAuthorize("@pms.hasPermission('hiking_leader_audit')")
	@SysLog("审核领队认证申请")
	public R audit(@PathVariable Long id, @RequestParam Integer status,
			@RequestParam(required = false) String rejectReason) {
		HikingLeaderApply apply = new HikingLeaderApply();
		apply.setId(id);
		apply.setStatus(status);
		if (status == 2) {
			apply.setRejectReason(rejectReason);
		}
		return R.ok(hikingLeaderApplyService.updateById(apply));
	}

}
