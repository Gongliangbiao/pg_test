# RR-SELECT-FOR-UPDATE-CONFLICT-40001

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.2 Repeatable Read Isolation Level

## 官方依据摘要
SELECT FOR UPDATE 遇到并发修改目标行时失败。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.2-repeatable-read/factor-matrix.md
- factor_values: F01-V13,F02-V09,F03-V02,F04-V01
- combination_strategy: boundary-directed

## 测试点
SELECT FOR UPDATE 遇到并发修改目标行时失败。

## 覆盖类型
正向 / 并发 / 反向

## 重要边界
- 被测对象/语句：SELECT / UPDATE / LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：SQLSTATE 40001。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Repeatable Read 的稳定快照、并发更新冲突或 40001 边界，是隔离级别核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.2-repeatable-read/rr-select-for-update-conflict-40001.md