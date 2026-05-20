# LOCK-TIMEOUT-WAIT-BOUNDARY

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3 Explicit Locking

## 官方依据摘要
未检测到死锁时锁等待可持续，lock_timeout 可限制等待时间。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/factor-matrix.md
- factor_values: F01-V05,F02-V01,F03-V02,F04-V03
- combination_strategy: boundary-directed

## 测试点
未检测到死锁时锁等待可持续，lock_timeout 可限制等待时间。

## 覆盖类型
正向 / 并发 / 边界

## 重要边界
- 被测对象/语句：LOCK。
- 触发状态/条件：等待/阻塞状态。
- 边界或异常：边界值。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例依赖超时参数和等待时序，容易受环境影响，建议归入专项稳定性测试。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/lock-timeout-wait-boundary.md