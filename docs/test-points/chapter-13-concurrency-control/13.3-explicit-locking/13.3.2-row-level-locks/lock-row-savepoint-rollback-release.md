# LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.3.2 Row-Level Locks

## 官方依据摘要
Row-level locks are released at transaction end or during savepoint rollback, like table-level locks.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.3-explicit-locking/13.3.2-row-level-locks/factor-matrix.md
- factor_values: F01-V11,F02-V06,F03-V04,F04-V02
- combination_strategy: state-transition

## 测试点
savepoint 后获取的行锁在 ROLLBACK TO SAVEPOINT 时释放。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：LOCK / SAVEPOINT / ROLLBACK。
- 触发状态/条件：回滚状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
duplicate-covered

## 标记理由
该场景与显式锁总述中的 savepoint rollback 释放锁用例高度重合；本文件保留章节覆盖痕迹，详细执行可由锁释放主用例承接。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.2-row-level-locks/lock-row-savepoint-rollback-release.md