# LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 所属扩展目录
本地知识补充：13.8.2 Constraints And Key Locks

## 来源依据摘要
两个事务插入相同唯一键时，后发事务等待先发事务；先发提交后，后发返回 23505 unique_violation。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.8-lock-knowledge-extensions/13.8.2-constraints-and-key-locks/factor-matrix.md
- factor_values: F01-V04,F02-V04,F03-V03,F04-V03
- combination_strategy: boundary-directed

## 测试点
两个事务插入相同唯一键时，后发事务等待先发事务；先发提交后，后发返回 23505 unique_violation。

## 覆盖类型
正向 / 并发 / 反向

## 重要边界
- 被测对象/语句：INSERT / COMMIT。
- 触发状态/条件：并发事务提交前。
- 边界或异常：SQLSTATE 23505。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
P0 测试点；用于覆盖本地知识补充 13.8.2 Constraints And Key Locks 中的 两个事务插入相同唯一键时，后发事务等待先发事务；先发提交后，后发返回 23505 unique_violation。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.2-constraints-and-key-locks/lock-unique-insert-waits-uncommitted-commit-23505.md