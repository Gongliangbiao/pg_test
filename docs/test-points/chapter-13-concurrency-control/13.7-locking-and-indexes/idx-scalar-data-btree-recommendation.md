# IDX-SCALAR-DATA-BTREE-RECOMMENDATION

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.7 Locking and Indexes

## 官方依据摘要
并发应用中 scalar data 推荐 B-tree。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.7-locking-and-indexes/factor-matrix.md
- factor_values: F01-V08,F02-V03,F03-V01,F04-V01
- combination_strategy: concurrency-directed

## 测试点
并发应用中 scalar data 推荐 B-tree。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：事务/并发控制行为。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
supporting

## 标记理由
该用例是官方建议类结论，适合记录覆盖依据，执行价值低于具体并发行为用例。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.7-locking-and-indexes/idx-scalar-data-btree-recommendation.md