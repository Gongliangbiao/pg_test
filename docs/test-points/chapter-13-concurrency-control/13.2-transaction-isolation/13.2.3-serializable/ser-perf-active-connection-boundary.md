# SER-PERF-ACTIVE-CONNECTION-BOUNDARY

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.3 Serializable Isolation Level

## 官方依据摘要
For optimal serializable performance, control the number of active connections, using a connection pool if needed.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.3-serializable/factor-matrix.md
- factor_values: F01-V02,F02-V01,F03-V01,F04-V02
- combination_strategy: risk-based

## 测试点
高并发 serializable 场景下，控制 active connections 数量是性能边界。

## 覆盖类型
正向 / 并发 / 边界

## 重要边界
- 被测对象/语句：SERIALIZABLE behavior。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：边界值。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该用例来自官方性能建议，更适合作为设计约束或专项说明；不建议作为常规回归的独立执行用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.3-serializable/ser-perf-active-connection-boundary.md