# LOCK-DEADLOCK-ROW-40P01

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.4 Deadlocks

## 官方依据摘要
行锁死锁检测，SQLSTATE 为 40P01。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.4-deadlocks/factor-matrix.md
- factor_values: F01-V02,F02-V01,F03-V01,F04-V02
- combination_strategy: boundary-directed

## 测试点
行锁死锁检测，SQLSTATE 为 40P01。

## 覆盖类型
正向 / 反向

## 重要边界
- 被测对象/语句：LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：SQLSTATE 40P01。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证死锁检测或 SQLSTATE 40P01，属于并发控制必须覆盖的失败路径。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.4-deadlocks/lock-deadlock-row-40p01.md