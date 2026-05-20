# LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.5 Advisory Locks

## 官方依据摘要
A session-level advisory unlock is effective even if the calling transaction fails later.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.5-advisory-locks/factor-matrix.md
- factor_values: F01-V07,F02-V03,F03-V01,F04-V03
- combination_strategy: single-factor

## 测试点
session-level advisory unlock 即使所在事务后续失败也立即生效。

## 覆盖类型
正向 / 反向

## 重要边界
- 被测对象/语句：advisory lock。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：错误/禁止场景。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 advisory lock 的基本 session/transaction/reentrant/互斥语义，属于应用自定义锁的核心路径。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.5-advisory-locks/lock-advisory-session-unlock-effective-after-txn-fail.md