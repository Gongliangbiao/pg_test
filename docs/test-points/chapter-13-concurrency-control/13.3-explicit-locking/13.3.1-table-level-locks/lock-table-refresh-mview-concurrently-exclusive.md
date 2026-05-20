# LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.1 Table-Level Locks

## 官方依据摘要
REFRESH MATERIALIZED VIEW CONCURRENTLY acquires an EXCLUSIVE table-level lock.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.1-table-level-locks/factor-matrix.md
- factor_values: F01-V08,F02-V04,F03-V02,F04-V02
- combination_strategy: diagnostic-directed

## 测试点
REFRESH MATERIALIZED VIEW CONCURRENTLY 获取 EXCLUSIVE 锁。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例具有覆盖价值，但依赖特殊配置、环境或较高执行成本，建议归入专项测试。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.1-table-level-locks/lock-table-refresh-mview-concurrently-exclusive.md