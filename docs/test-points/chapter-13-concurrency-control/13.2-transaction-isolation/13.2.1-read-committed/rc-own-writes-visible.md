# RC-OWN-WRITES-VISIBLE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.1 Read Committed Isolation Level

## 官方依据摘要
SELECT sees the effects of previous updates executed within its own transaction.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/factor-matrix.md
- factor_values: F01-V09,F02-V09,F03-V04,F04-V01
- combination_strategy: state-transition

## 测试点
同一事务内未提交写入对本事务后续 SELECT 可见。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT / UPDATE / COMMIT。
- 触发状态/条件：并发事务提交前。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该行为是事务内自写可见的基础语义，重要但通常可被其他隔离级别用例顺带验证，建议作为覆盖说明保留。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.1-read-committed/rc-own-writes-visible.md