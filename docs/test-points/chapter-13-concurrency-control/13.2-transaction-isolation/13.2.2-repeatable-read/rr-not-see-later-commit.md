# RR-NOT-SEE-LATER-COMMIT

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.2 Repeatable Read Isolation Level

## 官方依据摘要
不看到事务开始后其他事务提交的变更。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.2-repeatable-read/factor-matrix.md
- factor_values: F01-V07,F02-V06,F03-V01,F04-V02
- combination_strategy: state-transition

## 测试点
不看到事务开始后其他事务提交的变更。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：COMMIT。
- 触发状态/条件：提交后状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Repeatable Read 的稳定快照、并发更新冲突或 40001 边界，是隔离级别核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.2-repeatable-read/rr-not-see-later-commit.md