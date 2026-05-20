# APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.4.2 Enforcing Consistency with Explicit Blocking Locks

## 官方依据摘要
如需确保一行不被后续更新或删除，应实际更新该行，即使值不变。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks/factor-matrix.md
- factor_values: F01-V06,F02-V05,F03-V03,F04-V01
- combination_strategy: single-factor

## 测试点
如需确保一行不被后续更新或删除，应实际更新该行，即使值不变。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：UPDATE / DELETE。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证应用层一致性策略的关键选择，直接影响业务正确性，建议保留为核心执行用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks/app-update-same-value-to-protect-row.md