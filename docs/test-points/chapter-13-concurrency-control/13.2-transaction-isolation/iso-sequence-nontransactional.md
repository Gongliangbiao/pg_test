# ISO-SEQUENCE-NONTRANSACTIONAL

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2 Transaction Isolation

## 官方依据摘要
Sequence 或 serial 计数器变化立即可见，且事务 abort 后不回滚。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/factor-matrix.md
- factor_values: F02-V03,F03-V04,F04-V04,F05-V02
- combination_strategy: exception-directed

## 测试点
Sequence 或 serial 计数器变化立即可见，且事务 abort 后不回滚。

## 覆盖类型
正向

## 重要边界
- 被测对象或语句：sequence/serial 计数器。
- 触发状态/条件：调用 nextval 后事务回滚。
- 行为结果：sequence/serial 变化立即可见且不回滚。
- 边界或异常：事务回滚不回退 sequence/serial 计数器。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证官方隔离级别矩阵中的基础行为或 PostgreSQL 特有映射，是理解后续隔离用例的核心入口。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/iso-sequence-nontransactional.md
