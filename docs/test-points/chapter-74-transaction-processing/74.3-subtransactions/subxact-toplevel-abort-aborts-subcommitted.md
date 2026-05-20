# SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节
74.3 Subtransactions

## 官方依据摘要
顶层事务回滚时，已 subcommitted 的子事务也最终回滚。

## 来源因子
- factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.3-subtransactions/factor-matrix.md
- factor_values: F01-V18,F02-V04,F03-V02,F04-V01
- combination_strategy: state-transition

## 测试点
顶层事务回滚时，已 subcommitted 的子事务也最终回滚。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：ROLLBACK。
- 触发状态/条件：提交后状态。
- 边界或异常：常规核心路径。
- 本测试点只抽取事务处理机制的覆盖目标，不包含 SQL 执行步骤。

## 测试必要性
core

## 标记理由
P0 测试点；来自 Chapter 74 Transaction Processing 计划。

## 备注
来源：docs/plans/transaction-processing/test-point-plan.md