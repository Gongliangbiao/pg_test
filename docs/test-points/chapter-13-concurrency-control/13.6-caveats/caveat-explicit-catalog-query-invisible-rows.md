# CAVEAT-EXPLICIT-CATALOG-QUERY-INVISIBLE-ROWS

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.6 Caveats

## 官方依据摘要
高隔离级别下显式 catalog 查询看不到并发创建对象对应的 catalog rows。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.6-caveats/factor-matrix.md
- factor_values: F01-V06,F02-V02,F03-V01,F04-V02
- combination_strategy: risk-based

## 测试点
高隔离级别下显式 catalog 查询看不到并发创建对象对应的 catalog rows。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：SELECT。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例验证官方 Caveats 或内部可见性限制，风险重要但环境/对象准备较特殊，建议归入专项测试。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.6-caveats/caveat-explicit-catalog-query-invisible-rows.md