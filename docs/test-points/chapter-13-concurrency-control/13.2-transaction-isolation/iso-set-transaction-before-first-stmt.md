# ISO-SET-TRANSACTION-BEFORE-FIRST-STMT

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2 Transaction Isolation

## 官方依据摘要
SET TRANSACTION 对事务隔离级别的生效边界。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/factor-matrix.md
- factor_values: F02-V02,F03-V03,F04-V05,F05-V03
- combination_strategy: boundary-directed

## 测试点
SET TRANSACTION 对事务隔离级别的生效边界。

## 覆盖类型
正向 / 边界

## 重要边界
- 被测对象或语句：SET TRANSACTION。
- 触发状态/条件：事务内首条查询或数据修改前。
- 行为结果：SET TRANSACTION 的隔离级别生效边界。
- 边界或异常：SET TRANSACTION 必须在事务内查询或数据修改前设置。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该用例有官方依据，但主要承担覆盖说明或设计约束作用，独立执行收益低于核心并发行为用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/iso-set-transaction-before-first-stmt.md
