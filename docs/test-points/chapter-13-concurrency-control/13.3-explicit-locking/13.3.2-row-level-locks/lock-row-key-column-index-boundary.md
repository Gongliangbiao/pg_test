# LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.2 Row-Level Locks

## 官方依据摘要
For deciding whether an UPDATE acquires FOR UPDATE, key columns are those with a unique index usable in a foreign key; partial and expression indexes are not considered.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.2-row-level-locks/factor-matrix.md
- factor_values: F01-V07,F02-V04,F03-V01,F04-V01
- combination_strategy: boundary-directed

## 测试点
修改 key 列触发 FOR UPDATE 的边界应排除 partial index 和 expression index。

## 覆盖类型
正向 / 边界

## 重要边界
- 被测对象/语句：UPDATE / LOCK / INDEX。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：边界值。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例具有覆盖价值，但依赖特殊配置、环境或较高执行成本，建议归入专项测试。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.2-row-level-locks/lock-row-key-column-index-boundary.md