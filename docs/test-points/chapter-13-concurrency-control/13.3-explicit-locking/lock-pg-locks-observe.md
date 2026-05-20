# LOCK-PG-LOCKS-OBSERVE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3 Explicit Locking

## 官方依据摘要
pg_locks 可观测当前锁、锁模式与等待状态。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/factor-matrix.md
- factor_values: F01-V03,F02-V02,F03-V02,F04-V02
- combination_strategy: diagnostic-directed

## 测试点
pg_locks 可观测当前锁、锁模式与等待状态。

## 覆盖类型
正向 / 并发 / 诊断

## 重要边界
- 被测对象/语句：LOCK / diagnostic view。
- 触发状态/条件：等待/阻塞状态。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该用例主要是观测手段说明，通常服务于其他锁用例，不必作为独立核心执行点。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/lock-pg-locks-observe.md