# LOCK-TABLE-ACCESS-SHARE-CONFLICT

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.1 Table-Level Locks

## 官方依据摘要
ACCESS SHARE 只与 ACCESS EXCLUSIVE 冲突。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.1-table-level-locks/factor-matrix.md
- factor_values: F01-V03,F02-V03,F03-V02,F04-V01
- combination_strategy: concurrency-directed

## 测试点
ACCESS SHARE 只与 ACCESS EXCLUSIVE 冲突。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：事务/并发控制行为。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证表级锁冲突矩阵或关键锁模式边界，属于显式锁的核心可观察行为。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.1-table-level-locks/lock-table-access-share-conflict.md