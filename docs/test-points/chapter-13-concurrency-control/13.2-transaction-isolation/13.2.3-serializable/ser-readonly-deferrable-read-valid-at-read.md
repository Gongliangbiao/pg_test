# SER-READONLY-DEFERRABLE-READ-VALID-AT-READ

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.2.3 Serializable Isolation Level

## 官方依据摘要
In a deferrable read-only serializable transaction, data is known to be valid as soon as it is read.

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.3-serializable/factor-matrix.md
- factor_values: F01-V12,F02-V04,F03-V02,F04-V01
- combination_strategy: single-factor

## 测试点
SERIALIZABLE READ ONLY DEFERRABLE 取得安全快照后，读取结果在读取时即可视为有效。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT / snapshot。
- 触发状态/条件：只读事务状态。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
duplicate-covered

## 标记理由
该场景与 SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT 的安全快照语义重合，建议由安全快照主用例承接。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.3-serializable/ser-readonly-deferrable-read-valid-at-read.md