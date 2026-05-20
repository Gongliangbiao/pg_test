# TXID-XID-WRITE-ORDER-NOT-START-ORDER

## 来源
- source_test_point: docs/test-points/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid-write-order-not-start-order.md
- official_chapter: 74.1 Transactions and Identifiers
- source_factor_matrix: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
- factor_values: F01-V10,F02-V06,F03-V05,F04-V01
- combination_strategy: state-transition

## 测试目标
xid 编号顺序反映首次写入顺序，而不一定反映事务开始顺序。

## 测试类型
正向

## 会话数量
2

## 前置条件
- PostgreSQL 16.x。
- 当前用户有创建普通表、序列和视图查询权限。
- 不依赖全局配置变更。

## 表结构设计
- 表名使用 tab_741_txid_xid_write_order_not_start_order，用 writer 和 xid_text 观察不同 backend/首次写入顺序。

## 测试数据
- 两个会话分别产生确定性事务观测数据。

## 执行设计
S1 先 BEGIN 但不写；S2 先完成首次写入；S1 随后首次写入，用于说明 xid 分配顺序取决于首次写入而非 BEGIN 顺序。

## 预期结果
- 两个事务均在首次写入后拥有 xid。
- 输出记录显示 S2 先写入、S1 后写入。

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
