# 2PC-GID-REUSE-AFTER-RESOLVE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节
74.4 Two-Phase Transactions

## 官方依据摘要
原 GID 的 prepared transaction 被 commit/rollback 后，该 GID 不再属于当前 prepared 集合，可验证复用边界。

## 来源因子
- factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.4-two-phase-transactions/factor-matrix.md
- factor_values: F01-V15,F02-V06,F03-V01,F04-V03
- combination_strategy: boundary-directed

## 测试点
原 GID 的 prepared transaction 被 commit/rollback 后，该 GID 不再属于当前 prepared 集合，可验证复用边界。

## 覆盖类型
正向 / 边界

## 重要边界
- 被测对象/语句：PREPARE TRANSACTION / COMMIT / ROLLBACK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：边界值。
- 本测试点只抽取事务处理机制的覆盖目标，不包含 SQL 执行步骤。

## 测试必要性
supporting

## 标记理由
P1 测试点；来自 Chapter 74 Transaction Processing 计划。

## 备注
来源：docs/plans/transaction-processing/test-point-plan.md