# ISO-RU-MAPS-TO-RC

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2 Transaction Isolation

## 官方依据摘要
READ UNCOMMITTED 在 PostgreSQL 中表现为 READ COMMITTED。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/factor-matrix.md
- factor_values: F01-V02,F02-V01,F03-V02,F04-V03
- combination_strategy: equivalence-class

## 测试点
READ UNCOMMITTED 在 PostgreSQL 中表现为 READ COMMITTED。

## 覆盖类型
正向

## 重要边界
- 隔离级别参数：READ UNCOMMITTED。
- 被测对象/语句：SELECT 可见性查询。
- 触发状态/条件：并发事务存在未提交写入。
- 行为结果：READ UNCOMMITTED 表现为 READ COMMITTED。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证官方隔离级别矩阵中的基础行为或 PostgreSQL 特有映射，是理解后续隔离用例的核心入口。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/iso-ru-maps-to-rc.md
