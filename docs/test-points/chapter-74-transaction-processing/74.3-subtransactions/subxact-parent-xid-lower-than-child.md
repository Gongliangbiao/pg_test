# SUBXACT-PARENT-XID-LOWER-THAN-CHILD

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节
74.3 Subtransactions

## 官方依据摘要
父级 xid 总是小于任一子级 subxid。

## 来源因子
- factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.3-subtransactions/factor-matrix.md
- factor_values: F01-V11,F02-V05,F03-V01,F04-V02
- combination_strategy: single-factor

## 测试点
父级 xid 总是小于任一子级 subxid。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：xid。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：边界值。
- 本测试点只抽取事务处理机制的覆盖目标，不包含 SQL 执行步骤。

## 测试必要性
core

## 标记理由
P0 测试点；来自 Chapter 74 Transaction Processing 计划。

## 备注
来源：docs/plans/transaction-processing/test-point-plan.md