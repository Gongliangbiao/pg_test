# IDX-HASH-BUCKET-LOCK-CONCURRENCY

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.7 Locking and Indexes

## 官方依据摘要
Hash index 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.7-locking-and-indexes/factor-matrix.md
- factor_values: F01-V05,F02-V04,F03-V01,F04-V01
- combination_strategy: single-factor

## 测试点
Hash index 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：INDEX。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例涉及具体索引访问方法的并发实现，适合作为索引专项覆盖，不建议全部进入核心并发回归集。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.7-locking-and-indexes/idx-hash-bucket-lock-concurrency.md