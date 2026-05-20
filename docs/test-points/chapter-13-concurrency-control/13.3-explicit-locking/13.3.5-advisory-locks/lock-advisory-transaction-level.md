# LOCK-ADVISORY-TRANSACTION-LEVEL

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.5 Advisory Locks

## 官方依据摘要
Transaction-level advisory lock 在事务结束时自动释放。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.5-advisory-locks/factor-matrix.md
- factor_values: F01-V10,F02-V01,F03-V01,F04-V01
- combination_strategy: single-factor

## 测试点
Transaction-level advisory lock 在事务结束时自动释放。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：LOCK / advisory lock。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 advisory lock 的基本 session/transaction/reentrant/互斥语义，属于应用自定义锁的核心路径。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.5-advisory-locks/lock-advisory-transaction-level.md