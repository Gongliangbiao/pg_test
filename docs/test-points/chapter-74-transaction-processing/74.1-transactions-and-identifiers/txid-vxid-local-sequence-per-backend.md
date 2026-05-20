# TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节
74.1 Transactions and Identifiers

## 官方依据摘要
同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。

## 来源因子
- factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
- factor_values: F01-V07,F02-V05,F03-V04,F04-V01
- combination_strategy: single-factor

## 测试点
同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：xid。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只抽取事务处理机制的覆盖目标，不包含 SQL 执行步骤。

## 测试必要性
supporting

## 标记理由
P1 测试点；来自 Chapter 74 Transaction Processing 计划。

## 备注
来源：docs/plans/transaction-processing/test-point-plan.md