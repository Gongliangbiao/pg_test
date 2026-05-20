# LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.1 Table-Level Locks

## 官方依据摘要
DROP TABLE, TRUNCATE, REINDEX, CLUSTER, VACUUM FULL, and non-concurrent REFRESH MATERIALIZED VIEW acquire ACCESS EXCLUSIVE in documented contexts.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.1-table-level-locks/factor-matrix.md
- factor_values: F01-V02,F02-V02,F03-V02,F04-V02
- combination_strategy: diagnostic-directed

## 测试点
将 ACCESS EXCLUSIVE 自动加锁命令清单拆成后续独立用例来源，补充 REINDEX、CLUSTER、VACUUM FULL、非 concurrently REFRESH MATERIALIZED VIEW。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：LOCK / VACUUM。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该用例用于提醒后续可按命令拆分覆盖，但当前更适合作为清单型覆盖说明，不必立即展开为独立执行步骤。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.1-table-level-locks/lock-table-access-exclusive-commands-split.md