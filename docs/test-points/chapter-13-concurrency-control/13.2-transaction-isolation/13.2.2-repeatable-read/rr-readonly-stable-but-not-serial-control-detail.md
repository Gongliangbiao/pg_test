# RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.2 Repeatable Read Isolation Level

## 官方依据摘要
A read-only repeatable read transaction can see a stable view that is not necessarily consistent with any serial execution.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.2-repeatable-read/factor-matrix.md
- factor_values: F01-V10,F02-V05,F03-V05,F04-V03
- combination_strategy: single-factor

## 测试点
只读 REPEATABLE READ 有稳定视图，但可能不对应任何串行执行顺序，不能单独支撑业务一致性。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT。
- 触发状态/条件：只读事务状态。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Repeatable Read 的稳定快照、并发更新冲突或 40001 边界，是隔离级别核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.2-repeatable-read/rr-readonly-stable-but-not-serial-control-detail.md