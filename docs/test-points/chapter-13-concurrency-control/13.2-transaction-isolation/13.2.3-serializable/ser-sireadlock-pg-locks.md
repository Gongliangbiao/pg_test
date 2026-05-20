# SER-SIREADLOCK-PG-LOCKS

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.3 Serializable Isolation Level

## 官方依据摘要
Predicate locking 在 pg_locks 中以 SIReadLock 出现。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.3-serializable/factor-matrix.md
- factor_values: F01-V15,F02-V06,F03-V01,F04-V04
- combination_strategy: diagnostic-directed

## 测试点
Predicate locking 在 pg_locks 中以 SIReadLock 出现。

## 覆盖类型
正向 / 诊断

## 重要边界
- 被测对象/语句：SELECT / diagnostic view。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Serializable/SSI 的可串行化保证、40001、SIReadLock 或关键异常场景，是高风险并发核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.3-serializable/ser-sireadlock-pg-locks.md