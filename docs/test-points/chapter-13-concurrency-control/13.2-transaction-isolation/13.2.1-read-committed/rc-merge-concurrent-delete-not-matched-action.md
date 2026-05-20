# RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.1 Read Committed Isolation Level

## 官方依据摘要
If a target row is concurrently updated or deleted so the join condition fails, MERGE evaluates NOT MATCHED actions.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/factor-matrix.md
- factor_values: F01-V03,F02-V03,F03-V01,F04-V02
- combination_strategy: concurrency-directed

## 测试点
MERGE 目标行并发删除或更新导致 join condition 失败时，转入 NOT MATCHED action 评估。

## 覆盖类型
正向 / 并发 / 反向

## 重要边界
- 被测对象/语句：UPDATE / DELETE / MERGE。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：错误/禁止场景。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Read Committed 下直接可观察的快照、等待重检、ON CONFLICT 或 MERGE 行为，是并发语义核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.1-read-committed/rc-merge-concurrent-delete-not-matched-action.md