# MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 所属扩展目录
本地知识补充：13.8.5 Mvcc Vacuum And Long Transactions

## 来源依据摘要
UPDATE 创建新的 tuple version，旧版本仍可被旧 snapshot 读取。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.8-lock-knowledge-extensions/13.8.5-mvcc-vacuum-and-long-transactions/factor-matrix.md
- factor_values: F01-V06,F02-V06,F03-V02,F04-V02
- combination_strategy: single-factor

## 测试点
UPDATE 创建新的 tuple version，旧版本仍可被旧 snapshot 读取。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT / UPDATE / snapshot。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
P0 测试点；用于覆盖本地知识补充 13.8.5 Mvcc Vacuum And Long Transactions 中的 UPDATE 创建新的 tuple version，旧版本仍可被旧 snapshot 读取。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.5-mvcc-vacuum-and-long-transactions/mvcc-update-creates-new-tuple-version.md