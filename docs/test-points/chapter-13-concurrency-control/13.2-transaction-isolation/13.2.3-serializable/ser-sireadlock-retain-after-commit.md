# SER-SIREADLOCK-RETAIN-AFTER-COMMIT

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.3 Serializable Isolation Level

## 官方依据摘要
SIReadLock 可能在事务提交后保留，直到重叠读写事务完成。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.3-serializable/factor-matrix.md
- factor_values: F01-V16,F02-V05,F03-V04,F04-V01
- combination_strategy: state-transition

## 测试点
SIReadLock 可能在事务提交后保留，直到重叠读写事务完成。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT / COMMIT。
- 触发状态/条件：提交后状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 Serializable/SSI 的可串行化保证、40001、SIReadLock 或关键异常场景，是高风险并发核心路径，建议进入常规执行集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.3-serializable/ser-sireadlock-retain-after-commit.md