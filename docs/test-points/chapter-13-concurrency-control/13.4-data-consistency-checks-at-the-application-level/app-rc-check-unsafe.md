# APP-RC-CHECK-UNSAFE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.4 Data Consistency Checks at the Application Level

## 官方依据摘要
READ COMMITTED 下视图随语句变化，业务一致性检查不可靠。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.4-data-consistency-checks-at-the-application-level/factor-matrix.md
- factor_values: F01-V01,F02-V01,F03-V01,F04-V01
- combination_strategy: state-transition

## 测试点
READ COMMITTED 下视图随语句变化，业务一致性检查不可靠。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT。
- 触发状态/条件：提交后状态。
- 边界或异常：诊断观测。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证应用层一致性策略的关键选择，直接影响业务正确性，建议保留为核心执行用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/app-rc-check-unsafe.md