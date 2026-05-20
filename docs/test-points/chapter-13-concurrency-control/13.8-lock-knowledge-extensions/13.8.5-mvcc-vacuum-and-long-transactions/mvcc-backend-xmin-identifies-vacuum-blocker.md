# MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 所属扩展目录
本地知识补充：13.8.5 Mvcc Vacuum And Long Transactions

## 来源依据摘要
通过 pg_stat_activity.backend_xmin 辅助识别阻碍 VACUUM 清理的长事务。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.8-lock-knowledge-extensions/13.8.5-mvcc-vacuum-and-long-transactions/factor-matrix.md
- factor_values: F01-V01,F02-V01,F03-V01,F04-V01
- combination_strategy: diagnostic-directed

## 测试点
通过 pg_stat_activity.backend_xmin 辅助识别阻碍 VACUUM 清理的长事务。

## 覆盖类型
正向 / 诊断

## 重要边界
- 被测对象/语句：VACUUM / diagnostic view。
- 触发状态/条件：等待/阻塞状态。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
P0 测试点；用于覆盖本地知识补充 13.8.5 Mvcc Vacuum And Long Transactions 中的 通过 pg_stat_activity.backend_xmin 辅助识别阻碍 VACUUM 清理的长事务。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.5-mvcc-vacuum-and-long-transactions/mvcc-backend-xmin-identifies-vacuum-blocker.md