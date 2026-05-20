# CAVEAT-STANDBY-RR-NONPRIMARY-SERIAL-STATE

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节
13.6 Caveats

## 官方依据摘要
Standby 上 Repeatable Read 事务可能看到不对应任何 primary 串行执行的瞬时状态。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.6-caveats/factor-matrix.md
- factor_values: F01-V08,F02-V02,F03-V01,F04-V01
- combination_strategy: risk-based

## 测试点
Standby 上 Repeatable Read 事务可能看到不对应任何 primary 串行执行的瞬时状态。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：SELECT。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
special

## 标记理由
该用例依赖主备、standby 或复制环境，执行成本高，建议归入专项环境测试。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.6-caveats/caveat-standby-rr-nonprimary-serial-state.md