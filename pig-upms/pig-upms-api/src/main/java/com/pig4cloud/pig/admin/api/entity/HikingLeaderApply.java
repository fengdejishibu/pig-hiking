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
 * 领队认证申请表
 *
 * @author hiking
 * @date 2026-04-07
 */
@Data
@Schema(description = "领队认证申请")
@EqualsAndHashCode(callSuper = true)
@TableName("hiking_leader_apply")
public class HikingLeaderApply extends Model<HikingLeaderApply> {

	private static final long serialVersionUID = 1L;

	/**
	 * 申请ID
	 */
	@TableId(type = IdType.ASSIGN_ID)
	@Schema(description = "申请ID")
	private Long id;

	/**
	 * 用户ID
	 */
	@Schema(description = "用户ID", required = true)
	private Long userId;

	/**
	 * 真实姓名
	 */
	@Schema(description = "真实姓名", required = true)
	private String realName;

	/**
	 * 联系电话
	 */
	@Schema(description = "联系电话", required = true)
	private String phone;

	/**
	 * 紧急联系人
	 */
	@Schema(description = "紧急联系人")
	private String emergencyContact;

	/**
	 * 紧急联系电话
	 */
	@Schema(description = "紧急联系电话")
	private String emergencyPhone;

	/**
	 * 徒步经验描述
	 */
	@Schema(description = "徒步经验描述")
	private String hikingExperience;

	/**
	 * 资质证书图片URLs，逗号分隔
	 */
	@Schema(description = "资质证书图片URLs")
	private String certificateUrls;

	/**
	 * 状态: 0-待审核 1-已通过 2-已驳回
	 */
	@Schema(description = "状态: 0-待审核 1-已通过 2-已驳回")
	private Integer status;

	/**
	 * 驳回原因
	 */
	@Schema(description = "驳回原因")
	private String rejectReason;

	/**
	 * 审核人ID
	 */
	@Schema(description = "审核人ID")
	private Long reviewerId;

	/**
	 * 审核时间
	 */
	@Schema(description = "审核时间")
	private LocalDateTime reviewTime;

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
