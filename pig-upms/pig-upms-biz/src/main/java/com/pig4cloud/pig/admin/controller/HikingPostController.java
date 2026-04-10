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
import com.pig4cloud.pig.admin.api.entity.HikingPost;
import com.pig4cloud.pig.admin.service.HikingPostService;
import com.pig4cloud.pig.common.core.util.R;
import com.pig4cloud.pig.common.log.annotation.SysLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

/**
 * 帖子审核 Controller
 *
 * @author hiking
 * @date 2026-04-07
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/hiking/post")
@Tag(name = "帖子审核管理")
public class HikingPostController {

	private final HikingPostService hikingPostService;

	/**
	 * 分页查询帖子列表
	 */
	@GetMapping("/page")
	@Operation(summary = "帖子分页", description = "分页查询帖子列表，支持按审核状态筛选")
	@PreAuthorize("@pms.hasPermission('hiking_post_view')")
	public R getPostPage(Page page, @RequestParam(required = false) Integer auditStatus) {
		return R.ok(hikingPostService.lambdaQuery()
				.eq(auditStatus != null, HikingPost::getAuditStatus, auditStatus)
				.orderByDesc(HikingPost::getCreateTime)
				.page(page));
	}

	/**
	 * 获取帖子详情
	 */
	@GetMapping("/{id}")
	@Operation(summary = "获取帖子详情")
	@PreAuthorize("@pms.hasPermission('hiking_post_view')")
	public R getById(@PathVariable Long id) {
		return R.ok(hikingPostService.getById(id));
	}

	/**
	 * 审核帖子
	 * @param id 帖子ID
	 * @param auditStatus 审核状态: 1-通过 2-驳回
	 * @param auditReason 驳回原因
	 */
	@PostMapping("/audit/{id}")
	@Operation(summary = "审核帖子")
	@PreAuthorize("@pms.hasPermission('hiking_post_audit')")
	@SysLog("审核帖子")
	public R audit(@PathVariable Long id, @RequestParam Integer auditStatus,
			@RequestParam(required = false) String auditReason) {
		HikingPost post = new HikingPost();
		post.setId(id);
		post.setAuditStatus(auditStatus);
		post.setAuditorId(1L); // TODO: 获取当前登录用户ID
		post.setAuditTime(LocalDateTime.now());
		if (auditStatus == 2) {
			post.setAuditReason(auditReason);
		}
		return R.ok(hikingPostService.updateById(post));
	}

	/**
	 * 下架帖子
	 * @param id 帖子ID
	 */
	@PostMapping("/hide/{id}")
	@Operation(summary = "下架帖子")
	@PreAuthorize("@pms.hasPermission('hiking_post_audit')")
	@SysLog("下架帖子")
	public R hide(@PathVariable Long id) {
		HikingPost post = new HikingPost();
		post.setId(id);
		post.setStatus(1); // 隐藏
		return R.ok(hikingPostService.updateById(post));
	}

}
