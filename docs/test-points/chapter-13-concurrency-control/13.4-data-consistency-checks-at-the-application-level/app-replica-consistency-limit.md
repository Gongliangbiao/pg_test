# APP-REPLICA-CONSISTENCY-LIMIT

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.4 Data Consistency Checks at the Application Level

## 官方依据摘要
Serializable 一致性保护不扩展到 hot standby 或 logical replica。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.4-data-consistency-checks-at-the-application-level/factor-matrix.md
- factor_values: F01-V02,F02-V02,F03-V02,F04-V02
- combination_strategy: single-factor

## 测试点
Serializable 一致性保护不扩展到 hot standby 或 logical replica。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：事务/并发控制行为。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例依赖主备、standby 或复制环境，执行成本高，建议归入专项环境测试。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/app-replica-consistency-limit.md