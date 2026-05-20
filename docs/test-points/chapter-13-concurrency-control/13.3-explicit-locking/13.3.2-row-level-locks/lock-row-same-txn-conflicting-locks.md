# LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.2 Row-Level Locks

## 官方依据摘要
A transaction can hold conflicting locks on the same row, even in different subtransactions.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.2-row-level-locks/factor-matrix.md
- factor_values: F01-V10,F02-V02,F03-V03,F04-V02
- combination_strategy: concurrency-directed

## 测试点
同一事务甚至不同子事务可在同一行持有彼此冲突的行锁。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：LOCK。
- 触发状态/条件：同一行并发访问。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证行级锁冲突矩阵、阻塞或关键行锁边界，属于显式锁的核心可观察行为。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.2-row-level-locks/lock-row-same-txn-conflicting-locks.md