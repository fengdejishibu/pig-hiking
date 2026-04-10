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

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 帖子表
 *
 * @author hiking
 * @date 2026-04-07
 */
@Data
@Schema(description = "帖子")
@EqualsAndHashCode(callSuper = true)
@TableName("hiking_post")
public class HikingPost extends Model<HikingPost> {

	private static final long serialVersionUID = 1L;

	/**
	 * 帖子ID
	 */
	@TableId(type = IdType.ASSIGN_ID)
	@Schema(description = "帖子ID")
	private Long id;

	/**
	 * 用户ID
	 */
	@Schema(description = "用户ID", required = true)
	private Long userId;

	/**
	 * 帖子内容
	 */
	@Schema(description = "帖子内容", required = true)
	private String content;

	/**
	 * 图片URLs，逗号分隔
	 */
	@Schema(description = "图片URLs")
	private String imageUrls;

	/**
	 * 位置名称
	 */
	@Schema(description = "位置名称")
	private String locationName;

	/**
	 * 纬度
	 */
	@Schema(description = "纬度")
	private BigDecimal latitude;

	/**
	 * 经度
	 */
	@Schema(description = "经度")
	private BigDecimal longitude;

	/**
	 * 点赞数
	 */
	@Schema(description = "点赞数")
	private Integer likeCount;

	/**
	 * 评论数
	 */
	@Schema(description = "评论数")
	private Integer commentCount;

	/**
	 * 分享数
	 */
	@Schema(description = "分享数")
	private Integer shareCount;

	/**
	 * 状态: 0-正常 1-隐藏 2-删除
	 */
	@Schema(description = "状态: 0-正常 1-隐藏 2-删除")
	private Integer status;

	/**
	 * 审核状态: 0-待审核 1-已通过 2-已驳回
	 */
	@Schema(description = "审核状态: 0-待审核 1-已通过 2-已驳回")
	private Integer auditStatus;

	/**
	 * 审核驳回原因
	 */
	@Schema(description = "审核驳回原因")
	private String auditReason;

	/**
	 * 审核人ID
	 */
	@Schema(description = "审核人ID")
	private Long auditorId;

	/**
	 * 审核时间
	 */
	@Schema(description = "审核时间")
	private LocalDateTime auditTime;

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

	/**
	 * 删除标记: 0-正常 1-删除
	 */
	@TableLogic
	@TableField(fill = FieldFill.INSERT)
	@Schema(description = "删除标记")
	private String delFlag;

}
