# SER-PREDICATE-LOCK-MEMORY-PARAMETERS

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.3 Serializable Isolation Level

## 官方依据摘要
Increasing max_pred_locks_per_transaction, max_pred_locks_per_relation, and/or max_pred_locks_per_page can reduce relation-level predicate lock promotion.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.3-serializable/factor-matrix.md
- factor_values: F01-V07,F02-V03,F03-V01,F04-V03
- combination_strategy: boundary-directed

## 测试点
predicate lock 内存不足导致粗粒度锁和失败率增加时，相关参数是边界配置。

## 覆盖类型
正向 / 反向 / 边界

## 重要边界
- 被测对象/语句：LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：错误/禁止场景。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例涉及内存阈值、锁升级或资源上限，验证成本和稳定性要求较高，建议归入专项测试。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.3-serializable/ser-predicate-lock-memory-parameters.md