# RC-UPDATE-WAIT-RECHECK-WHERE-MATCH

## 来源
- source_test_point: docs/test-points/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/rc-update-wait-recheck-where-match.md
- official_chapter: 13.2.1 Read Committed Isolation Level
- source_factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/factor-matrix.md
- factor_values: F01-V01,F02-V01,F03-V01,F04-V01,F05-V01,F06-V01,F07-V01,F07-V02
- combination_strategy: state-transition + diagnostic

## 测试目标
验证 `READ COMMITTED` 下 `UPDATE` 等待并发事务释放行锁后，会重新检查 `WHERE` 条件；若条件仍匹配，则继续更新目标行。

## 测试类型
并发 / 正向 / 边界

## 会话数量
2

## 前置条件
- 单实例 PostgreSQL 16.x。
- 两个会话均使用 `READ COMMITTED`。
- 创建测试表，包含一行 `flag = true` 的目标数据。

## 表结构设计
- 表名使用 `tab_1321_rc_update_wait_recheck_where_match`，不追加短哈希；该名称尽量贴近测试点 `rc-update-wait-recheck-where-match`。
- 表结构包含布尔条件列 `flag`、文本结果列 `note`、计数字段 `hit_count` 和命名检查约束 `cons_1321_rc_update_wait_recheck_where_match_hit_nonneg`，用于明确验证 WHERE 重检和继续更新。
- 仅使用主键约束，不额外创建索引，避免把测试目标扩展到索引行为。

## 测试数据
- 初始行：`id = 1, flag = true, note = 'base', hit_count = 0`。
- `S1` 更新 `note` 但保持 `flag = true`。
- `S2` 对 `flag IS TRUE` 的行执行 `UPDATE`，等待 `S1` 提交后继续。

## 执行设计
S1:
- 删除旧同步点。
- 清理并创建测试表。
- 插入初始行。
- `BEGIN`。
- 更新 `id = 1` 的行，将 `note` 改为 `s1_locked`，保持 `flag = true`，并持有行锁。
- 设置 `s1_to_s2_01`，通知 S2 准备执行阻塞 `UPDATE`。
- 等待 `s2_to_s1_01`，确认 S2 即将执行目标 `UPDATE`。
- 使用有界轮询确认 S2 的 `UPDATE` 处于锁等待状态。
- 在提交前执行一次 `SELECT`，确认 S1 当前事务内的行值仍满足 `flag IS TRUE`。
- `COMMIT`。
- 等待 `s2_to_s1_02`，确认 S2 完成最终验证。
- 在 S2 完成后执行一次 `SELECT`，确认最终表中数据状态。

S2:
- 等待 `s1_to_s2_01`。
- `BEGIN`。
- 设置 `s2_to_s1_01`，通知 S1 自己即将执行目标 `UPDATE`。
- 执行 `UPDATE ... WHERE flag IS TRUE`，该语句应等待 S1 提交。
- S1 提交后，语句重检 `WHERE`，仍匹配，并将 `note` 改为 `s2_rechecked`、`hit_count` 加 1。
- `COMMIT`。
- 查询最终数据。
- 设置 `s2_to_s1_02`。

## 预期结果
- S2 的 `UPDATE` 在 S1 提交前等待。
- S1 提交前查询可见 `note = 's1_locked'` 且 `flag = true`。
- S2 重检 `WHERE flag IS TRUE`，匹配并成功更新 1 行。
- 最终行值为 `id = 1, flag = true, note = 's2_rechecked', hit_count = 1`。

## SQL 生成约束
- 使用 `pg-ab-regression`。
- 输出 `_001A.sql` 和 `_001B.sql`。
- 不使用 `pg_sleep`。
- 使用 `commonScript` 同步点和有界轮询 helper。
- 阻塞判断 SQL 必须包含当前用例的短表名，避免误匹配其他用例。
- 该用例数据量小、单行较短，观察数据状态时优先使用 `SELECT * FROM tab_1321_rc_update_wait_recheck_where_match ORDER BY id;`。
- 对象名使用 `pg-sql-case-naming` 短命名规则。

## 清理策略
不在用例末尾额外清理测试表；仅在 A 文件 setup 阶段使用 `DROP TABLE IF EXISTS` 清理上次残留，避免重复 `DROP TABLE` 操作。

## 需要 pg-sql 确认的事实
- READ COMMITTED
- UPDATE row lock wait
- WHERE recheck after concurrent update
- BEGIN
- COMMIT
- pg_stat_activity

## 生成状态
ready
