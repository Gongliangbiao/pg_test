# MVCC-SNAPSHOT-SELECT-COMMITTED

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.1 Introduction

## 官方依据摘要
普通 SELECT 只看到已提交版本。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.1-introduction/factor-matrix.md
- factor_values: F01-V05,F02-V05,F03-V04,F04-V01
- combination_strategy: state-transition

## 测试点
普通 SELECT 只看到已提交版本。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT / COMMIT。
- 触发状态/条件：提交后状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 MVCC 的基础可见性和读写不阻塞语义，是 Chapter 13 的核心入口。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.1-introduction/mvcc-snapshot-select-committed.md