# TXID-IMPLICIT-SINGLE-STMT-ROLLBACK

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节
74.1 Transactions and Identifiers

## 官方依据摘要
未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。

## 来源因子
- factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
- factor_values: F01-V04,F02-V02,F03-V02,F04-V02
- combination_strategy: state-transition

## 测试点
未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。

## 覆盖类型
正向 / 反向

## 重要边界
- 被测对象/语句：ROLLBACK。
- 触发状态/条件：回滚状态。
- 边界或异常：错误/禁止场景。
- 本测试点只抽取事务处理机制的覆盖目标，不包含 SQL 执行步骤。

## 测试必要性
core

## 标记理由
P0 测试点；来自 Chapter 74 Transaction Processing 计划。

## 备注
来源：docs/plans/transaction-processing/test-point-plan.md