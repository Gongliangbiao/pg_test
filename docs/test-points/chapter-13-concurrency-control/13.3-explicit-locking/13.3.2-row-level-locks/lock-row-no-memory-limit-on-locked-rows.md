# LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.2 Row-Level Locks

## 官方依据摘要
PostgreSQL does not remember modified rows in memory, so there is no memory-tracking limit on the number of rows locked at one time.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.2-row-level-locks/factor-matrix.md
- factor_values: F01-V08,F02-V02,F03-V01,F04-V02
- combination_strategy: single-factor

## 测试点
PostgreSQL 不因内存记录限制而限制单事务锁定行数。

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
该用例偏实现说明或资源特性，建议保留为覆盖说明，必要时再转为专项验证。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.2-row-level-locks/lock-row-no-memory-limit-on-locked-rows.md