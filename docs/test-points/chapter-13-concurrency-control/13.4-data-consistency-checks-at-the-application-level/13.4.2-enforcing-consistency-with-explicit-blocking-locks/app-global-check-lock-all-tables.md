# APP-GLOBAL-CHECK-LOCK-ALL-TABLES

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.4.2 Enforcing Consistency with Explicit Blocking Locks

## 官方依据摘要
全局一致性检查可能需要锁定所有相关表，SHARE 或更高锁保证无其他未提交变更。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks/factor-matrix.md
- factor_values: F01-V04,F02-V03,F03-V02,F04-V01
- combination_strategy: state-transition

## 测试点
全局一致性检查可能需要锁定所有相关表，SHARE 或更高锁保证无其他未提交变更。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：LOCK / COMMIT。
- 触发状态/条件：并发事务提交前。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证应用层一致性策略的关键选择，直接影响业务正确性，建议保留为核心执行用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks/app-global-check-lock-all-tables.md