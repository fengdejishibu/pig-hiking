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

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.pig4cloud.pig.admin.api.entity.HikingReport;
import com.pig4cloud.pig.admin.service.HikingReportService;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.log.annotation.SysLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

/**
 * 举报处理 Controller
 *
 * @author hiking
 * @date 2026-04-07
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/hiking/report")
@Tag(name = "举报处理管理")
public class HikingReportController {

	private final HikingReportService hikingReportService;

	/**
	 * 分页查询举报列表
	 */
	@GetMapping("/page")
	@Operation(summary = "举报分页", description = "分页查询举报列表，支持按处理状态筛选")
	@PreAuthorize("@pms.hasPermission('hiking_report_view')")
	public R getReportPage(Page page, @RequestParam(required = false) Integer status,
			@RequestParam(required = false) Integer targetType) {
		return R.ok(hikingReportService.lambdaQuery()
				.eq(status != null, HikingReport::getStatus, status)
				.eq(targetType != null, HikingReport::getTargetType, targetType)
				.orderByDesc(HikingReport::getCreateTime)
				.page(page));
	}

	/**
	 * 获取举报详情
	 */
	@GetMapping("/{id}")
	@Operation(summary = "获取举报详情")
	@PreAuthorize("@pms.hasPermission('hiking_report_view')")
	public R getById(@PathVariable Long id) {
		return R.ok(hikingReportService.getById(id));
	}

	/**
	 * 处理举报
	 * @param id 举报ID
	 * @param status 处理状态: 1-已处理 2-已驳回
	 * @param handleResult 处理结果
	 */
	@PostMapping("/handle/{id}")
	@Operation(summary = "处理举报")
	@PreAuthorize("@pms.hasPermission('hiking_report_handle')")
	@SysLog("处理举报")
	public R handle(@PathVariable Long id, @RequestParam Integer status,
			@RequestParam(required = false) String handleResult) {
		HikingReport report = new HikingReport();
		report.setId(id);
		report.setStatus(status);
		report.setHandlerId(1L); // TODO: 获取当前登录用户ID
		report.setHandleTime(LocalDateTime.now());
		report.setHandleResult(handleResult);
		return R.ok(hikingReportService.updateById(report));
	}

}
