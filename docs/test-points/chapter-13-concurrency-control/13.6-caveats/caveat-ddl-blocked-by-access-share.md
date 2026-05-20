# CAVEAT-DDL-BLOCKED-BY-ACCESS-SHARE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.6 Caveats

## 官方依据摘要
并发事务之前访问过目标表时，其 ACCESS SHARE 表锁会阻塞相关 DDL。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.6-caveats/factor-matrix.md
- factor_values: F01-V04,F02-V03,F03-V02,F04-V01
- combination_strategy: risk-based

## 测试点
并发事务之前访问过目标表时，其 ACCESS SHARE 表锁会阻塞相关 DDL。

## 覆盖类型
正向 / 并发

## 重要边界
- 被测对象/语句：LOCK。
- 触发状态/条件：等待/阻塞状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
该用例验证 DDL 与普通读锁之间的基础阻塞关系，可作为 Caveats 中最直接的核心执行点。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.6-caveats/caveat-ddl-blocked-by-access-share.md