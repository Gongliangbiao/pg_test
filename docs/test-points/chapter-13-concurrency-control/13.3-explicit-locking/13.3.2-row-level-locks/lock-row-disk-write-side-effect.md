# LOCK-ROW-DISK-WRITE-SIDE-EFFECT

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.2 Row-Level Locks

## 官方依据摘要
行级锁可能导致磁盘写入，但不受内存中锁数量上限限制。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.2-row-level-locks/factor-matrix.md
- factor_values: F01-V01,F02-V01,F03-V01,F04-V01
- combination_strategy: boundary-directed

## 测试点
行级锁可能导致磁盘写入，但不受内存中锁数量上限限制。

## 覆盖类型
正向 / 边界

## 重要边界
- 被测对象/语句：UPDATE / LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：边界值。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该用例偏实现说明或资源特性，建议保留为覆盖说明，必要时再转为专项验证。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.2-row-level-locks/lock-row-disk-write-side-effect.md