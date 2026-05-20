# RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.1 Read Committed Isolation Level

## 官方依据摘要
If MERGE attempts INSERT and a duplicate row is concurrently inserted, a uniqueness violation is raised.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/factor-matrix.md
- factor_values: F01-V04,F02-V04,F03-V01,F04-V01
- combination_strategy: concurrency-directed

## 测试点
MERGE 并发插入唯一键冲突时，不像 upsert 那样重启匹配评估，而是返回 unique violation。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：INSERT / MERGE。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Read Committed 下直接可观察的快照、等待重检、ON CONFLICT 或 MERGE 行为，是并发语义核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.1-read-committed/rc-merge-concurrent-insert-unique-violation.md