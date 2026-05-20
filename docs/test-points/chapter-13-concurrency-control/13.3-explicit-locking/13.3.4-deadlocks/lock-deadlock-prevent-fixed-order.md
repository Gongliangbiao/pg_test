# LOCK-DEADLOCK-PREVENT-FIXED-ORDER

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.4 Deadlocks

## 官方依据摘要
按固定顺序获取多个对象锁可避免死锁。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.4-deadlocks/factor-matrix.md
- factor_values: F01-V01,F02-V01,F03-V01,F04-V01
- combination_strategy: concurrency-directed

## 测试点
按固定顺序获取多个对象锁可避免死锁。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该用例有官方依据，但主要承担覆盖说明或设计约束作用，独立执行收益低于核心并发行为用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.4-deadlocks/lock-deadlock-prevent-fixed-order.md