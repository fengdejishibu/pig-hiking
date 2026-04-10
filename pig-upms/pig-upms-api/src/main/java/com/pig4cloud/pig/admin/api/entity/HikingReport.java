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
 * 举报表
 *
 * @author hiking
 * @date 2026-04-07
 */
@Data
@Schema(description = "举报")
@EqualsAndHashCode(callSuper = true)
@TableName("hiking_report")
public class HikingReport extends Model<HikingReport> {

	private static final long serialVersionUID = 1L;

	/**
	 * 举报ID
	 */
	@TableId(type = IdType.ASSIGN_ID)
	@Schema(description = "举报ID")
	private Long id;

	/**
	 * 举报人ID
	 */
	@Schema(description = "举报人ID", required = true)
	private Long reporterId;

	/**
	 * 目标类型: 1-帖子 2-评论 3-用户
	 */
	@Schema(description = "目标类型: 1-帖子 2-评论 3-用户", required = true)
	private Integer targetType;

	/**
	 * 目标ID
	 */
	@Schema(description = "目标ID", required = true)
	private Long targetId;

	/**
	 * 举报原因
	 */
	@Schema(description = "举报原因", required = true)
	private String reason;

	/**
	 * 证据图片URLs
	 */
	@Schema(description = "证据图片URLs")
	private String evidenceUrls;

	/**
	 * 处理状态: 0-待处理 1-已处理 2-已驳回
	 */
	@Schema(description = "处理状态: 0-待处理 1-已处理 2-已驳回")
	private Integer status;

	/**
	 * 处理人ID
	 */
	@Schema(description = "处理人ID")
	private Long handlerId;

	/**
	 * 处理结果
	 */
	@Schema(description = "处理结果")
	private String handleResult;

	/**
	 * 处理时间
	 */
	@Schema(description = "处理时间")
	private LocalDateTime handleTime;

	/**
	 * 举报时间
	 */
	@TableField(fill = FieldFill.INSERT)
	@Schema(description = "举报时间")
	private LocalDateTime createTime;

	/**
	 * 更新时间
	 */
	@TableField(fill = FieldFill.INSERT_UPDATE)
	@Schema(description = "更新时间")
	private LocalDateTime updateTime;

	/**
	 * 删除标记: 0-正常 1-删除
	 */
	@TableLogic
	@TableField(fill = FieldFill.INSERT)
	@Schema(description = "删除标记")
	private String delFlag;

}
