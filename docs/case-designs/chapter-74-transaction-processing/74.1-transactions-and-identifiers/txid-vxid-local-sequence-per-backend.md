# TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND

## 来源
- source_test_point: docs/test-points/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-vxid-local-sequence-per-backend.md
- official_chapter: 74.1 Transactions and Identifiers
- source_factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
- factor_values: F01-V07,F02-V05,F03-V04,F04-V01
- combination_strategy: single-factor

## 测试目标
同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。

## 测试类型
正向

## 会话数量
2

## 前置条件
- PostgreSQL 16.x。
- 当前用户有创建普通表、序列和视图查询权限。
- 不依赖全局配置变更。

## 表结构设计
- 表名使用 tab_741_txid_vxid_local_sequence_per_backend，用 writer 和 xid_text 观察不同 backend/首次写入顺序。

## 测试数据
- 两个会话分别产生确定性事务观测数据。

## 执行设计
两个 backend 分别开启事务并通过 pg_locks 观测各自 virtualxid。

## 预期结果
- 两个会话都能观测到本 backend 的 virtualxid。

## SQL 生成约束
- 使用 pg-ab-regression，输出 _001A.sql 和 _001B.sql。
- 不使用 pg_sleep。
- 小数据量验证查询优先使用 SELECT * FROM 表 ORDER BY 主键。
- 只在 setup 阶段清理上次残留对象，不在末尾重复 DROP TABLE。
- 使用 commonScript 同步点协调两个会话。

## 清理策略
setup 阶段清理上次残留对象；用例末尾保留最终状态用于 regression 输出审查。

## 需要 pg-sql 确认的事实
- transaction ID assignment
- virtual transaction ID

## 生成状态
ready
