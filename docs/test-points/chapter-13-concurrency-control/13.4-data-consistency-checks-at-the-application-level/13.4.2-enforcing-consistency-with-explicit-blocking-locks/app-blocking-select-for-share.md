# APP-BLOCKING-SELECT-FOR-SHARE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.4.2 Enforcing Consistency with Explicit Blocking Locks

## 官方依据摘要
When non-serializable writes are possible, SELECT FOR SHARE can be used to ensure current row validity and protect rows against concurrent updates.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks/factor-matrix.md
- factor_values: F01-V02,F02-V02,F03-V01,F04-V01
- combination_strategy: concurrency-directed

## 测试点
非 serializable 写存在时，单独验证 SELECT FOR SHARE 保护返回行免受并发更新。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：SELECT / UPDATE / LOCK。
- 触发状态/条件：等待/阻塞状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
duplicate-covered

## 标记理由
该场景与 APP-BLOCKING-SELECT-FOR-UPDATE 同属显式阻塞锁策略，建议后续在 FOR UPDATE/FOR SHARE 对照用例中合并执行。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks/app-blocking-select-for-share.md