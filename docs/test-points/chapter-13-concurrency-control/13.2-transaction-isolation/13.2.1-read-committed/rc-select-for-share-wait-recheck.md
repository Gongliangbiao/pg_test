# RC-SELECT-FOR-SHARE-WAIT-RECHECK

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.1 Read Committed Isolation Level

## 官方依据摘要
SELECT FOR SHARE follows the same wait-and-recheck target-row rule as SELECT FOR UPDATE in Read Committed.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/factor-matrix.md
- factor_values: F01-V12,F02-V12,F03-V02,F04-V01
- combination_strategy: concurrency-directed

## 测试点
SELECT FOR SHARE 等待并发更新结束后重新检查目标行。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：SELECT / UPDATE / LOCK。
- 触发状态/条件：等待/阻塞状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Read Committed 下直接可观察的快照、等待重检、ON CONFLICT 或 MERGE 行为，是并发语义核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.1-read-committed/rc-select-for-share-wait-recheck.md