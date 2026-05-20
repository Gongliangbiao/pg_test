# LOCK-READ-SKIP-LOCKED-INCOMPLETE-VIEW

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 所属扩展目录
本地知识补充：13.8.1 Locking Read Options

## 来源依据摘要
SKIP LOCKED 返回的是跳过锁行后的不完整视图，不适合完整一致性查询。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.8-lock-knowledge-extensions/13.8.1-locking-read-options/factor-matrix.md
- factor_values: F01-V04,F02-V02,F03-V01,F04-V03
- combination_strategy: diagnostic-directed

## 测试点
SKIP LOCKED 返回的是跳过锁行后的不完整视图，不适合完整一致性查询。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT / LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
P0 测试点；用于覆盖本地知识补充 13.8.1 Locking Read Options 中的 SKIP LOCKED 返回的是跳过锁行后的不完整视图，不适合完整一致性查询。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.1-locking-read-options/lock-read-skip-locked-incomplete-view.md