# TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节
74.2 Transactions and Locking

## 官方依据摘要
行级读写锁记录在被锁行上，不能简单按每行锁从 pg_locks 直接读取。

## 来源因子
- factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.2-transactions-and-locking/factor-matrix.md
- factor_values: F01-V06,F02-V04,F03-V01,F04-V01
- combination_strategy: diagnostic-directed

## 测试点
行级读写锁记录在被锁行上，不能简单按每行锁从 pg_locks 直接读取。

## 覆盖类型
正向 / 诊断

## 重要边界
- 被测对象/语句：SELECT / LOCK / diagnostic view。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：诊断观测。
- 本测试点只抽取事务处理机制的覆盖目标，不包含 SQL 执行步骤。

## 测试必要性
supporting

## 标记理由
P1 测试点；来自 Chapter 74 Transaction Processing 计划。

## 备注
来源：docs/plans/transaction-processing/test-point-plan.md