# RETRY-NO-AUTO-RETRY-BY-SERVER

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.5 Serialization Failure Handling

## 官方依据摘要
PostgreSQL 不提供自动重试能力。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.5-serialization-failure-handling/factor-matrix.md
- factor_values: F01-V07,F02-V01,F03-V01,F04-V05
- combination_strategy: single-factor

## 测试点
PostgreSQL 不提供自动重试能力。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：事务/并发控制行为。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证应用重试策略需要识别的核心错误码或完整事务重试原则，建议保留为核心执行用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.5-serialization-failure-handling/retry-no-auto-retry-by-server.md