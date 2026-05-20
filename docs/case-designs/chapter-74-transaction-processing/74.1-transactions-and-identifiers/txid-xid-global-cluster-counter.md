# TXID-XID-GLOBAL-CLUSTER-COUNTER

## 来源
- source_test_point: docs/test-points/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid-global-cluster-counter.md
- official_chapter: 74.1 Transactions and Identifiers
- source_factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
- factor_values: F01-V12,F02-V05,F03-V04,F04-V01
- combination_strategy: single-factor

## 测试目标
非虚拟 xid 来自整个 PostgreSQL cluster 的全局计数器，而不是单库局部计数器。

## 测试类型
正向

## 会话数量
1

## 前置条件
- PostgreSQL 16.x。
- 当前用户有创建普通表、序列和视图查询权限。
- 不依赖全局配置变更。

## 表结构设计
- 表名使用 tab_741_txid_xid_global_cluster_counter，按事务 ID 观测场景使用 marker、numeric/date 或诊断函数输出。

## 测试数据
- 使用少量确定性数据，必要时通过事务 ID 函数和系统视图观测。

## 执行设计
单会话顺序执行事务动作并通过稳定 SELECT 验证状态。

## 预期结果
- 输出与测试点描述一致，且无非预期错误。

## SQL 生成约束
- 使用普通 regression 单 SQL 文件。
- 不使用 pg_sleep。
- 小数据量验证查询优先使用 SELECT * FROM 表 ORDER BY 主键。
- 只在 setup 阶段清理上次残留对象，不在末尾重复 DROP TABLE。


## 清理策略
setup 阶段清理上次残留对象；用例末尾保留最终状态用于 regression 输出审查。

## 需要 pg-sql 确认的事实
- transaction ID
- virtual transaction ID
- pg_current_xact_id_if_assigned()

## 生成状态
ready
