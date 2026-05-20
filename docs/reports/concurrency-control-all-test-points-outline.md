# PostgreSQL 16 Chapter 13 Concurrency Control 测试点充分性汇报大纲

## 文档定位
- 范围：Chapter 13 Concurrency Control 及当前补充的 13.8 lock knowledge extensions。
- 来源：`docs/archive/concurrency-control-by-official-chapter/` 下所有非 README 文本用例。
- 目标：按官方章节展示测试点、测试因子、组合方式和 no-test/不扩展边界，用于证明覆盖充分性。
- 测试点总数：188 个。

## 章节汇总

| 章节目录 | 测试点数量 |
|---|---:|
| 13.1-introduction | 5 |
| 13.2-transaction-isolation | 5 |
| 13.2-transaction-isolation/13.2.1-read-committed | 19 |
| 13.2-transaction-isolation/13.2.2-repeatable-read | 16 |
| 13.2-transaction-isolation/13.2.3-serializable | 21 |
| 13.3-explicit-locking | 5 |
| 13.3-explicit-locking/13.3.1-table-level-locks | 16 |
| 13.3-explicit-locking/13.3.2-row-level-locks | 13 |
| 13.3-explicit-locking/13.3.3-page-level-locks | 2 |
| 13.3-explicit-locking/13.3.4-deadlocks | 5 |
| 13.3-explicit-locking/13.3.5-advisory-locks | 10 |
| 13.4-data-consistency-checks-at-the-application-level | 3 |
| 13.4-data-consistency-checks-at-the-application-level/13.4.1-enforcing-consistency-with-serializable-transactions | 4 |
| 13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks | 6 |
| 13.5-serialization-failure-handling | 9 |
| 13.6-caveats | 9 |
| 13.7-locking-and-indexes | 9 |
| 13.8-lock-knowledge-extensions/13.8.1-locking-read-options | 5 |
| 13.8-lock-knowledge-extensions/13.8.2-constraints-and-key-locks | 5 |
| 13.8-lock-knowledge-extensions/13.8.3-maintenance-and-ddl-lock-practices | 6 |
| 13.8-lock-knowledge-extensions/13.8.4-diagnostics-and-wait-events | 6 |
| 13.8-lock-knowledge-extensions/13.8.5-mvcc-vacuum-and-long-transactions | 6 |
| 13.8-lock-knowledge-extensions/13.8.6-lock-timeout-and-retry-controls | 3 |

## 13.1 Introduction

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.1-introduction/`
- 测试点数量：5 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | MVCC 可见性与读写非阻塞 | 普通 SELECT、UPDATE、提交前/提交后状态 | P0/P1 | MVCC-CONCURRENT-UPDATE-SAME-ROW、MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE、MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT、MVCC-SNAPSHOT-NO-DIRTY-READ、MVCC-SNAPSHOT-SELECT-COMMITTED |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | concurrency-directed / single-factor / state-transition | MVCC-CONCURRENT-UPDATE-SAME-ROW、MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE、MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT、MVCC-SNAPSHOT-NO-DIRTY-READ、MVCC-SNAPSHOT-SELECT-COMMITTED | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.1 Introduction 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 5 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| MVCC-CONCURRENT-UPDATE-SAME-ROW | P0 | 同一行并发更新只暴露一致版本。 | 多会话并发文本用例 | core | concurrency-directed |
| MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE | P0 | 普通读不阻塞写。 | 多会话并发文本用例 | core | single-factor |
| MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT | P0 | 写不阻塞普通读。 | 多会话并发文本用例 | core | single-factor |
| MVCC-SNAPSHOT-NO-DIRTY-READ | P0 | 并发未提交变更不可见。 | 多会话并发文本用例 | core | state-transition |
| MVCC-SNAPSHOT-SELECT-COMMITTED | P0 | 普通 SELECT 只看到已提交版本。 | 多会话并发文本用例 | core | state-transition |

### 充分性结论
- 本节 5 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.2 Transaction Isolation

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/`
- 测试点数量：5 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 隔离级别矩阵与异常现象 | READ UNCOMMITTED/READ COMMITTED/REPEATABLE READ/SERIALIZABLE、dirty/nonrepeatable/phantom/serialization anomaly | P0/P1 | ISO-DEFAULT-READ-COMMITTED、ISO-PHENOMENA-DIRTY-READ-PREVENTED、ISO-RU-MAPS-TO-RC、ISO-SEQUENCE-NONTRANSACTIONAL、ISO-SET-TRANSACTION-BEFORE-FIRST-STMT |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed | ISO-DEFAULT-READ-COMMITTED、ISO-PHENOMENA-DIRTY-READ-PREVENTED、ISO-RU-MAPS-TO-RC、ISO-SEQUENCE-NONTRANSACTIONAL、ISO-SET-TRANSACTION-BEFORE-FIRST-STMT | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.2 Transaction Isolation 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 5 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| ISO-DEFAULT-READ-COMMITTED | P0 | 默认隔离级别为 READ COMMITTED。 | 多会话并发文本用例 | core | boundary-directed |
| ISO-PHENOMENA-DIRTY-READ-PREVENTED | P0 | 验证 PostgreSQL 所有隔离级别均不允许 dirty read。 | 多会话并发文本用例 | core | boundary-directed |
| ISO-RU-MAPS-TO-RC | P0 | READ UNCOMMITTED 在 PostgreSQL 中表现为 READ COMMITTED。 | 多会话并发文本用例 | core | boundary-directed |
| ISO-SEQUENCE-NONTRANSACTIONAL | P0 | Sequence 或 serial 计数器变化立即可见，且事务 abort 后不回滚。 | 多会话并发文本用例 | core | boundary-directed |
| ISO-SET-TRANSACTION-BEFORE-FIRST-STMT | P0 | SET TRANSACTION 对事务隔离级别的生效边界。 | 多会话并发文本用例 | supporting | boundary-directed |

### 充分性结论
- 本节 5 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.2.1 Read Committed

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.1-read-committed/`
- 测试点数量：19 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | Read Committed 语句级快照与等待重检 | READ COMMITTED、语句级快照、等待后 WHERE 重检、UPDATE/DELETE/MERGE/ON CONFLICT | P0/P1 | RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT、RC-DELETE-WAIT-RECHECK、RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION、RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION、RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE、RC-NONREPEATABLE-READ、RC-ON-CONFLICT-DO-NOTHING-INVISIBLE-CONFLICT、RC-ON-CONFLICT-DO-UPDATE-GUARANTEE、RC-OWN-WRITES-VISIBLE、RC-PHANTOM-READ、RC-SAME-TXN-NEW-SNAPSHOT、RC-SELECT-FOR-SHARE-WAIT-RECHECK、RC-SELECT-FOR-UPDATE-WAIT-RECHECK、RC-SELECT-IGNORE-INPROGRESS、RC-STATEMENT-SNAPSHOT-BASIC、RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE、RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED、RC-UPDATE-WAIT-RECHECK-WHERE-MATCH、RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | single-factor / state-transition | RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT、RC-DELETE-WAIT-RECHECK、RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION、RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION、RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE、RC-NONREPEATABLE-READ、RC-ON-CONFLICT-DO-NOTHING-INVISIBLE-CONFLICT、RC-ON-CONFLICT-DO-UPDATE-GUARANTEE、RC-OWN-WRITES-VISIBLE、RC-PHANTOM-READ、RC-SAME-TXN-NEW-SNAPSHOT、RC-SELECT-FOR-SHARE-WAIT-RECHECK、RC-SELECT-FOR-UPDATE-WAIT-RECHECK、RC-SELECT-IGNORE-INPROGRESS、RC-STATEMENT-SNAPSHOT-BASIC、RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE、RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED、RC-UPDATE-WAIT-RECHECK-WHERE-MATCH、RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.2.1 Read Committed 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 19 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT | P0 | 复杂搜索条件下，单条更新命令可能看到不一致快照。 | 多会话并发文本用例 | core | single-factor |
| RC-DELETE-WAIT-RECHECK | P0 | DELETE 对并发更新行等待并重检条件。 | 多会话并发文本用例 | core | state-transition |
| RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION | P0 | MERGE 目标行并发删除或更新导致 join condition 失败时，转入 NOT MATCHED action 评估。 | 文本用例 | core | single-factor |
| RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION | P0 | MERGE 并发插入唯一键冲突时，不像 upsert 那样重启匹配评估，而是返回 unique violation。 | 文本用例 | core | single-factor |
| RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE | P0 | MERGE 并发更新时重新评估 action，但不提供同等 upsert 保证。 | 多会话并发文本用例 | core | single-factor |
| RC-NONREPEATABLE-READ | P0 | READ COMMITTED 允许同事务多次 SELECT 看到不同结果。 | 多会话并发文本用例 | core | single-factor |
| RC-ON-CONFLICT-DO-NOTHING-INVISIBLE-CONFLICT | P0 | INSERT ... ON CONFLICT DO NOTHING 可因不可见并发事务结果跳过插入。 | 多会话并发文本用例 | core | single-factor |
| RC-ON-CONFLICT-DO-UPDATE-GUARANTEE | P0 | INSERT ... ON CONFLICT DO UPDATE 每行保证 insert 或 update 之一发生。 | 多会话并发文本用例 | core | single-factor |
| RC-OWN-WRITES-VISIBLE | P0 | 同一事务内未提交写入对本事务后续 SELECT 可见。 | 文本用例 | supporting | single-factor |
| RC-PHANTOM-READ | P0 | READ COMMITTED 下新提交行可被后续语句看到。 | 多会话并发文本用例 | core | single-factor |
| RC-SAME-TXN-NEW-SNAPSHOT | P0 | 同一事务后续语句看到其他事务新提交数据。 | 多会话并发文本用例 | core | single-factor |
| RC-SELECT-FOR-SHARE-WAIT-RECHECK | P0 | SELECT FOR SHARE 等待并发更新结束后重新检查目标行。 | 文本用例 | core | state-transition |
| RC-SELECT-FOR-UPDATE-WAIT-RECHECK | P0 | SELECT FOR UPDATE 等待并发更新结束后重检目标行。 | 多会话并发文本用例 | core | state-transition |
| RC-SELECT-IGNORE-INPROGRESS | P0 | 普通 SELECT 不看未提交并发变更。 | 多会话并发文本用例 | core | single-factor |
| RC-STATEMENT-SNAPSHOT-BASIC | P0 | 每条语句使用语句开始时快照。 | 多会话并发文本用例 | core | single-factor |
| RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE | P0 | 先事务删除并提交后，等待中的 UPDATE 忽略该目标行。 | 文本用例 | core | state-transition |
| RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED | P0 | 并发更新同一行时，先更新事务回滚后，等待中的 UPDATE 使用原始目标行继续执行。 | 文本用例 | core | state-transition |
| RC-UPDATE-WAIT-RECHECK-WHERE-MATCH | P0 | UPDATE 等待并发事务结束后重检 WHERE，匹配则继续更新。 | 多会话并发文本用例 | core | state-transition |
| RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH | P0 | UPDATE 等待并发事务结束后重检 WHERE，不匹配则跳过。 | 多会话并发文本用例 | core | state-transition |

### 充分性结论
- 本节 19 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.2.2 Repeatable Read

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.2-repeatable-read/`
- 测试点数量：16 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | Repeatable Read 事务级快照与 40001 | REPEATABLE READ、事务级快照、并发更新/锁定、SQLSTATE 40001 | P0/P1 | RR-CONCURRENT-LOCK-ONLY-NO-40001、RR-DELETE-CONCURRENT-UPDATE-40001、RR-FIRST-UPDATER-ROLLBACK-PROCEED、RR-MERGE-CONCURRENT-UPDATE-40001、RR-NO-NONREPEATABLE-READ、RR-NO-PHANTOM-READ、RR-NOT-SEE-LATER-COMMIT、RR-OWN-WRITES-VISIBLE、RR-READONLY-NO-SERIALIZATION-CONFLICT、RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL、RR-REPEATABLE-SELECT-STABLE、RR-SELECT-FOR-SHARE-CONFLICT-40001、RR-SELECT-FOR-UPDATE-CONFLICT-40001、RR-SNAPSHOT-FIRST-NON-TCL-STMT、RR-SNAPSHOT-ISOLATION-WRITE-SKEW、RR-UPDATE-CONCURRENT-UPDATE-40001 |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed / state-transition | RR-CONCURRENT-LOCK-ONLY-NO-40001、RR-DELETE-CONCURRENT-UPDATE-40001、RR-FIRST-UPDATER-ROLLBACK-PROCEED、RR-MERGE-CONCURRENT-UPDATE-40001、RR-NO-NONREPEATABLE-READ、RR-NO-PHANTOM-READ、RR-NOT-SEE-LATER-COMMIT、RR-OWN-WRITES-VISIBLE、RR-READONLY-NO-SERIALIZATION-CONFLICT、RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL、RR-REPEATABLE-SELECT-STABLE、RR-SELECT-FOR-SHARE-CONFLICT-40001、RR-SELECT-FOR-UPDATE-CONFLICT-40001、RR-SNAPSHOT-FIRST-NON-TCL-STMT、RR-SNAPSHOT-ISOLATION-WRITE-SKEW、RR-UPDATE-CONCURRENT-UPDATE-40001 | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.2.2 Repeatable Read 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 16 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| RR-CONCURRENT-LOCK-ONLY-NO-40001 | P0 | 并发事务只锁定目标行但未更新/删除并提交后，REPEATABLE READ 事务不应因该锁定本身返回 40001。 | 文本用例 | core | boundary-directed |
| RR-DELETE-CONCURRENT-UPDATE-40001 | P0 | 并发修改或删除目标行后，当前事务 DELETE 失败。 | 多会话并发文本用例 | core | boundary-directed |
| RR-FIRST-UPDATER-ROLLBACK-PROCEED | P0 | 等待并发更新时，先事务回滚后，REPEATABLE READ 事务继续处理原始目标行。 | 文本用例 | core | boundary-directed |
| RR-MERGE-CONCURRENT-UPDATE-40001 | P0 | MERGE 遇到事务开始后已被其他事务更新或删除的目标行时返回 serialization failure。 | 文本用例 | core | boundary-directed |
| RR-NO-NONREPEATABLE-READ | P0 | REPEATABLE READ 下不出现不可重复读。 | 多会话并发文本用例 | core | state-transition |
| RR-NO-PHANTOM-READ | P0 | PostgreSQL REPEATABLE READ 不出现 phantom read。 | 多会话并发文本用例 | core | state-transition |
| RR-NOT-SEE-LATER-COMMIT | P0 | 不看到事务开始后其他事务提交的变更。 | 多会话并发文本用例 | core | state-transition |
| RR-OWN-WRITES-VISIBLE | P0 | REPEATABLE READ 下本事务前序未提交写入对后续查询可见。 | 文本用例 | supporting | state-transition |
| RR-READONLY-NO-SERIALIZATION-CONFLICT | P0 | 只读 REPEATABLE READ 事务不会产生 serialization conflicts。 | 多会话并发文本用例 | core | state-transition |
| RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL | P1 | 只读 REPEATABLE READ 有稳定视图，但可能不对应任何串行执行顺序，不能单独支撑业务一致性。 | 文本用例 | core | state-transition |
| RR-REPEATABLE-SELECT-STABLE | P0 | 同一事务内连续查询看到稳定视图。 | 多会话并发文本用例 | core | state-transition |
| RR-SELECT-FOR-SHARE-CONFLICT-40001 | P0 | SELECT FOR SHARE 遇到事务开始后已被其他事务更新或删除的目标行时返回 40001。 | 文本用例 | core | boundary-directed |
| RR-SELECT-FOR-UPDATE-CONFLICT-40001 | P0 | SELECT FOR UPDATE 遇到并发修改目标行时失败。 | 多会话并发文本用例 | core | boundary-directed |
| RR-SNAPSHOT-FIRST-NON-TCL-STMT | P0 | 事务快照固定在第一个非事务控制语句开始时。 | 多会话并发文本用例 | core | state-transition |
| RR-SNAPSHOT-ISOLATION-WRITE-SKEW | P0 | REPEATABLE READ 是 Snapshot Isolation，稳定视图不必然等价于某个串行顺序。 | 多会话并发文本用例 | core | state-transition |
| RR-UPDATE-CONCURRENT-UPDATE-40001 | P0 | 并发更新目标行后，当前事务 UPDATE 失败并返回 serialization failure。 | 多会话并发文本用例 | core | boundary-directed |

### 充分性结论
- 本节 16 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.2.3 Serializable

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.2-transaction-isolation/13.2.3-serializable/`
- 测试点数量：21 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | Serializable SSI 与 predicate lock | SERIALIZABLE、SSI 冲突、SIReadLock、read only/deferrable、SQLSTATE 40001 | P0/P1 | SER-AGGREGATE-READ-THEN-WRITE、SER-PERF-ACTIVE-CONNECTION-BOUNDARY、SER-PERF-DECLARE-READ-ONLY、SER-PERF-IDLE-IN-TXN-TIMEOUT、SER-PERF-SHORT-TRANSACTION-SCOPE、SER-PREDICATE-LOCK-ESCALATION-OBSERVE、SER-PREDICATE-LOCK-MEMORY-PARAMETERS、SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT、SER-READ-ONLY-PERFORMANCE-SETTING、SER-READ-ONLY-REDUCE-PREDICATE-LOCKS、SER-READ-RESULT-VALID-AFTER-COMMIT、SER-READONLY-DEFERRABLE-READ-VALID-AT-READ、SER-SIREADLOCK-NONBLOCKING、SER-SIREADLOCK-NOT-DEADLOCK-PARTICIPANT、SER-SIREADLOCK-PG-LOCKS、SER-SIREADLOCK-RETAIN-AFTER-COMMIT、SER-SQLSTATE-40001、SER-SUCCESS-EQUIVALENT-SERIAL-ORDER、SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION、SER-UNIQUE-VIOLATION-CONCURRENT-INSERT、SER-WRITE-SKEW-ABORT-ONE |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | state-transition / risk-based / concurrency-directed | SER-AGGREGATE-READ-THEN-WRITE、SER-PERF-ACTIVE-CONNECTION-BOUNDARY、SER-PERF-DECLARE-READ-ONLY、SER-PERF-IDLE-IN-TXN-TIMEOUT、SER-PERF-SHORT-TRANSACTION-SCOPE、SER-PREDICATE-LOCK-ESCALATION-OBSERVE、SER-PREDICATE-LOCK-MEMORY-PARAMETERS、SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT、SER-READ-ONLY-PERFORMANCE-SETTING、SER-READ-ONLY-REDUCE-PREDICATE-LOCKS、SER-READ-RESULT-VALID-AFTER-COMMIT、SER-READONLY-DEFERRABLE-READ-VALID-AT-READ、SER-SIREADLOCK-NONBLOCKING、SER-SIREADLOCK-NOT-DEADLOCK-PARTICIPANT、SER-SIREADLOCK-PG-LOCKS、SER-SIREADLOCK-RETAIN-AFTER-COMMIT、SER-SQLSTATE-40001、SER-SUCCESS-EQUIVALENT-SERIAL-ORDER、SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION、SER-UNIQUE-VIOLATION-CONCURRENT-INSERT、SER-WRITE-SKEW-ABORT-ONE | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.2.3 Serializable 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 21 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| SER-AGGREGATE-READ-THEN-WRITE | P0 | 聚合读后写模式触发危险读写依赖。 | 多会话并发文本用例 | core | state-transition |
| SER-PERF-ACTIVE-CONNECTION-BOUNDARY | P1 | 高并发 serializable 场景下，控制 active connections 数量是性能边界。 | 文本用例 | supporting | risk-based |
| SER-PERF-DECLARE-READ-ONLY | P1 | 可声明只读的 serializable 事务应使用 READ ONLY，降低 SSI 负担。 | 文本用例 | supporting | risk-based |
| SER-PERF-IDLE-IN-TXN-TIMEOUT | P1 | 长时间 idle in transaction 可用 idle_in_transaction_session_timeout 自动断开。 | 文本用例 | special | risk-based |
| SER-PERF-SHORT-TRANSACTION-SCOPE | P1 | Serializable 事务范围越大，冲突监控与重试成本越高，应验证最小事务范围策略。 | 文本用例 | supporting | risk-based |
| SER-PREDICATE-LOCK-ESCALATION-OBSERVE | P2 | 顺序扫描可能增加 relation-level predicate lock。 | 多会话并发文本用例 | special | concurrency-directed |
| SER-PREDICATE-LOCK-MEMORY-PARAMETERS | P1 | predicate lock 内存不足导致粗粒度锁和失败率增加时，相关参数是边界配置。 | 文本用例 | special | concurrency-directed |
| SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT | P0 | SERIALIZABLE READ ONLY DEFERRABLE 会等待安全快照。 | 多会话并发文本用例 | core | state-transition |
| SER-READ-ONLY-PERFORMANCE-SETTING | P0 | Serializable 只读事务声明 READ ONLY 可降低 SSI 开销。 | 多会话并发文本用例 | supporting | risk-based |
| SER-READ-ONLY-REDUCE-PREDICATE-LOCKS | P0 | 安全只读事务可减少或释放 predicate locks。 | 多会话并发文本用例 | core | state-transition |
| SER-READ-RESULT-VALID-AFTER-COMMIT | P0 | 非 deferrable serializable 事务读取结果只有在事务成功提交后才可作为有效业务判断。 | 文本用例 | supporting | state-transition |
| SER-READONLY-DEFERRABLE-READ-VALID-AT-READ | P0 | SERIALIZABLE READ ONLY DEFERRABLE 取得安全快照后，读取结果在读取时即可视为有效。 | 文本用例 | duplicate-covered | state-transition |
| SER-SIREADLOCK-NONBLOCKING | P0 | Predicate locks 不造成阻塞。 | 多会话并发文本用例 | core | state-transition |
| SER-SIREADLOCK-NOT-DEADLOCK-PARTICIPANT | P0 | Predicate locks 不参与死锁检测。 | 多会话并发文本用例 | supporting | state-transition |
| SER-SIREADLOCK-PG-LOCKS | P0 | Predicate locking 在 pg_locks 中以 SIReadLock 出现。 | 多会话并发文本用例 | core | state-transition |
| SER-SIREADLOCK-RETAIN-AFTER-COMMIT | P0 | SIReadLock 可能在事务提交后保留，直到重叠读写事务完成。 | 多会话并发文本用例 | core | state-transition |
| SER-SQLSTATE-40001 | P0 | Serialization failure SQLSTATE 为 40001。 | 多会话并发文本用例 | core | concurrency-directed |
| SER-SUCCESS-EQUIVALENT-SERIAL-ORDER | P0 | 成功提交的 Serializable 并发事务结果等价于某个串行顺序。 | 多会话并发文本用例 | core | concurrency-directed |
| SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION | P1 | 所有可能插入冲突 key 的 serializable 事务都先执行一致的显式检查时，避免原文描述的异常 unique violation 场景。 | 文本用例 | supporting | concurrency-directed |
| SER-UNIQUE-VIOLATION-CONCURRENT-INSERT | P0 | 并发 Serializable 下仍可能出现 unique constraint violation。 | 多会话并发文本用例 | core | concurrency-directed |
| SER-WRITE-SKEW-ABORT-ONE | P0 | Write skew 模式下回滚其中一个事务。 | 多会话并发文本用例 | core | concurrency-directed |

### 充分性结论
- 本节 21 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.3 Explicit Locking

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/`
- 测试点数量：5 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 并发控制行为 | 状态转换、边界 | P0/P1 | LOCK-EXPLICIT-LOCK-COMMAND-BASIC、LOCK-HELD-UNTIL-TXN-END、LOCK-PG-LOCKS-OBSERVE、LOCK-SAVEPOINT-ROLLBACK-RELEASE、LOCK-TIMEOUT-WAIT-BOUNDARY |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | single-factor | LOCK-EXPLICIT-LOCK-COMMAND-BASIC、LOCK-HELD-UNTIL-TXN-END、LOCK-PG-LOCKS-OBSERVE、LOCK-SAVEPOINT-ROLLBACK-RELEASE、LOCK-TIMEOUT-WAIT-BOUNDARY | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.3 Explicit Locking 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 5 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-EXPLICIT-LOCK-COMMAND-BASIC | P0 | 显式 LOCK 命令可获取表级锁。 | 多会话并发文本用例 | supporting | single-factor |
| LOCK-HELD-UNTIL-TXN-END | P0 | 事务中获取的锁通常保持到事务结束。 | 多会话并发文本用例 | core | single-factor |
| LOCK-PG-LOCKS-OBSERVE | P2 | pg_locks 可观测当前锁、锁模式与等待状态。 | 多会话并发文本用例 | supporting | single-factor |
| LOCK-SAVEPOINT-ROLLBACK-RELEASE | P0 | Savepoint rollback 释放 savepoint 后获取的锁。 | 多会话并发文本用例 | core | single-factor |
| LOCK-TIMEOUT-WAIT-BOUNDARY | P0 | 未检测到死锁时锁等待可持续，lock_timeout 可限制等待时间。 | 多会话并发文本用例 | special | single-factor |

### 充分性结论
- 本节 5 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.3.1 Table Level Locks

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.1-table-level-locks/`
- 测试点数量：16 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 表级锁模式与冲突矩阵 | LOCK TABLE、表锁模式、自冲突/非自冲突、自动加锁命令 | P0/P1 | LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT、LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT、LOCK-TABLE-ACCESS-SHARE-CONFLICT、LOCK-TABLE-DEFAULT-MODE-ACCESS-EXCLUSIVE、LOCK-TABLE-DROP-TRUNCATE-ACCESS-EXCLUSIVE、LOCK-TABLE-EXCLUSIVE、LOCK-TABLE-NON-SELF-CONFLICT-MULTI-SESSION、LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE、LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT、LOCK-TABLE-ROW-SHARE-CONFLICT、LOCK-TABLE-SAME-TXN-NO-SELF-CONFLICT、LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION、LOCK-TABLE-SHARE-ROW-EXCLUSIVE、LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT、LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE、LOCK-TABLE-SHARE |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | pairwise/risk-based | LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT、LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT、LOCK-TABLE-ACCESS-SHARE-CONFLICT、LOCK-TABLE-DEFAULT-MODE-ACCESS-EXCLUSIVE、LOCK-TABLE-DROP-TRUNCATE-ACCESS-EXCLUSIVE、LOCK-TABLE-EXCLUSIVE、LOCK-TABLE-NON-SELF-CONFLICT-MULTI-SESSION、LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE、LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT、LOCK-TABLE-ROW-SHARE-CONFLICT、LOCK-TABLE-SAME-TXN-NO-SELF-CONFLICT、LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION、LOCK-TABLE-SHARE-ROW-EXCLUSIVE、LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT、LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE、LOCK-TABLE-SHARE | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.3.1 Table Level Locks 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 16 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT | P0 | 只有 ACCESS EXCLUSIVE 会阻塞普通 SELECT。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT | P1 | 将 ACCESS EXCLUSIVE 自动加锁命令清单拆成后续独立用例来源，补充 REINDEX、CLUSTER、VACUUM FULL、非 concurrently REFRESH MATERIALIZED VIEW。 | 文本用例 | supporting | pairwise/risk-based |
| LOCK-TABLE-ACCESS-SHARE-CONFLICT | P0 | ACCESS SHARE 只与 ACCESS EXCLUSIVE 冲突。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-DEFAULT-MODE-ACCESS-EXCLUSIVE | P0 | LOCK TABLE 未指定模式时默认获取 ACCESS EXCLUSIVE。 | 文本用例 | supporting | pairwise/risk-based |
| LOCK-TABLE-DROP-TRUNCATE-ACCESS-EXCLUSIVE | P0 | DROP TABLE、TRUNCATE 等命令获取 ACCESS EXCLUSIVE。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-EXCLUSIVE | P0 | EXCLUSIVE 表级锁的阻塞关系。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-NON-SELF-CONFLICT-MULTI-SESSION | P0 | 两个会话可同时持有非自冲突锁模式，例如 ACCESS SHARE。 | 文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE | P1 | REFRESH MATERIALIZED VIEW CONCURRENTLY 获取 EXCLUSIVE 锁。 | 文本用例 | special | pairwise/risk-based |
| LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT | P0 | INSERT、UPDATE、DELETE、MERGE 获取 ROW EXCLUSIVE 及其冲突关系。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-ROW-SHARE-CONFLICT | P0 | ROW SHARE 表级锁冲突矩阵。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-SAME-TXN-NO-SELF-CONFLICT | P0 | 同一事务内先后获取同一表上的冲突模式锁不与自身冲突。 | 文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION | P0 | 两个会话不能同时持有自冲突锁模式，例如 ACCESS EXCLUSIVE。 | 文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-SHARE-ROW-EXCLUSIVE | P0 | CREATE TRIGGER 和部分 ALTER TABLE 获取 SHARE ROW EXCLUSIVE。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT | P1 | 将 SHARE UPDATE EXCLUSIVE 自动加锁命令清单拆成后续独立用例来源，至少覆盖 VACUUM without FULL、ANALYZE、CREATE INDEX CONCURRENTLY、REINDEX CONCURRENTLY。 | 文本用例 | supporting | pairwise/risk-based |
| LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE | P0 | VACUUM、ANALYZE、CREATE INDEX CONCURRENTLY 等获取 SHARE UPDATE EXCLUSIVE。 | 多会话并发文本用例 | core | pairwise/risk-based |
| LOCK-TABLE-SHARE | P0 | 非 concurrently CREATE INDEX 获取 SHARE。 | 多会话并发文本用例 | core | pairwise/risk-based |

### 充分性结论
- 本节 16 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.3.2 Row Level Locks

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.2-row-level-locks/`
- 测试点数量：13 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 行级锁模式与冲突矩阵 | FOR UPDATE/FOR NO KEY UPDATE/FOR SHARE/FOR KEY SHARE、行锁冲突、savepoint 边界 | P0/P1 | LOCK-ROW-DISK-WRITE-SIDE-EFFECT、LOCK-ROW-FOR-KEY-SHARE-MATRIX、LOCK-ROW-FOR-NO-KEY-UPDATE-MATRIX、LOCK-ROW-FOR-SHARE-MATRIX、LOCK-ROW-FOR-UPDATE-MATRIX、LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE、LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY、LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS、LOCK-ROW-NORMAL-SELECT-NONBLOCKING、LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS、LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE、LOCK-ROW-UPDATE-KEY-COLUMN、LOCK-ROW-UPDATE-NONKEY-COLUMN |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | pairwise/boundary-directed | LOCK-ROW-DISK-WRITE-SIDE-EFFECT、LOCK-ROW-FOR-KEY-SHARE-MATRIX、LOCK-ROW-FOR-NO-KEY-UPDATE-MATRIX、LOCK-ROW-FOR-SHARE-MATRIX、LOCK-ROW-FOR-UPDATE-MATRIX、LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE、LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY、LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS、LOCK-ROW-NORMAL-SELECT-NONBLOCKING、LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS、LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE、LOCK-ROW-UPDATE-KEY-COLUMN、LOCK-ROW-UPDATE-NONKEY-COLUMN | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.3.2 Row Level Locks 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 13 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-ROW-DISK-WRITE-SIDE-EFFECT | P0 | 行级锁可能导致磁盘写入，但不受内存中锁数量上限限制。 | 多会话并发文本用例 | supporting | pairwise/boundary-directed |
| LOCK-ROW-FOR-KEY-SHARE-MATRIX | P0 | FOR KEY SHARE 行级锁冲突矩阵。 | 多会话并发文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-FOR-NO-KEY-UPDATE-MATRIX | P0 | FOR NO KEY UPDATE 行级锁冲突矩阵。 | 多会话并发文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-FOR-SHARE-MATRIX | P0 | FOR SHARE 行级锁冲突矩阵。 | 多会话并发文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-FOR-UPDATE-MATRIX | P0 | FOR UPDATE 行级锁冲突矩阵。 | 多会话并发文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE | P0 | SELECT FOR UPDATE 等待并发事务后，返回更新后的行，若行被删除则不返回。 | 文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY | P1 | 修改 key 列触发 FOR UPDATE 的边界应排除 partial index 和 expression index。 | 文本用例 | special | pairwise/boundary-directed |
| LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS | P1 | PostgreSQL 不因内存记录限制而限制单事务锁定行数。 | 文本用例 | supporting | pairwise/boundary-directed |
| LOCK-ROW-NORMAL-SELECT-NONBLOCKING | P0 | 行级锁只阻塞同一行上的写入和加锁，不影响普通查询。 | 多会话并发文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS | P0 | 同一事务甚至不同子事务可在同一行持有彼此冲突的行锁。 | 文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE | P0 | savepoint 后获取的行锁在 ROLLBACK TO SAVEPOINT 时释放。 | 文本用例 | duplicate-covered | pairwise/boundary-directed |
| LOCK-ROW-UPDATE-KEY-COLUMN | P0 | DELETE 和修改 key 列的 UPDATE 获取 FOR UPDATE。 | 多会话并发文本用例 | core | pairwise/boundary-directed |
| LOCK-ROW-UPDATE-NONKEY-COLUMN | P0 | 不修改 key 的 UPDATE 获取 FOR NO KEY UPDATE。 | 多会话并发文本用例 | core | pairwise/boundary-directed |

### 充分性结论
- 本节 13 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.3.3 Page Level Locks

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.3-page-level-locks/`
- 测试点数量：2 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 页级锁内部行为 | page-level lock、立即释放、用户不可直接等待 | P0/P1 | LOCK-PAGE-IMMEDIATE-RELEASE、LOCK-PAGE-NOT-USER-VISIBLE-WAIT |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | single-factor | LOCK-PAGE-IMMEDIATE-RELEASE、LOCK-PAGE-NOT-USER-VISIBLE-WAIT | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.3.3 Page Level Locks 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 2 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-PAGE-IMMEDIATE-RELEASE | P2 | 页级锁在获取或更新行后立即释放。 | 多会话并发文本用例 | core | single-factor |
| LOCK-PAGE-NOT-USER-VISIBLE-WAIT | P2 | 页级锁用于 shared buffer 内部控制，不作为用户级长时间等待对象。 | 多会话并发文本用例 | core | single-factor |

### 充分性结论
- 本节 2 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.3.4 Deadlocks

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.4-deadlocks/`
- 测试点数量：5 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 死锁检测与规避 | 循环等待、SQLSTATE 40P01、锁顺序、victim 不确定性 | P0/P1 | LOCK-DEADLOCK-PREVENT-FIXED-ORDER、LOCK-DEADLOCK-ROW-40P01、LOCK-DEADLOCK-STRICTEST-FIRST、LOCK-DEADLOCK-TABLE-40P01、LOCK-DEADLOCK-VICTIM-UNPREDICTABLE |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed | LOCK-DEADLOCK-PREVENT-FIXED-ORDER、LOCK-DEADLOCK-ROW-40P01、LOCK-DEADLOCK-STRICTEST-FIRST、LOCK-DEADLOCK-TABLE-40P01、LOCK-DEADLOCK-VICTIM-UNPREDICTABLE | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.3.4 Deadlocks 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 5 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-DEADLOCK-PREVENT-FIXED-ORDER | P0 | 按固定顺序获取多个对象锁可避免死锁。 | 多会话并发文本用例 | supporting | boundary-directed |
| LOCK-DEADLOCK-ROW-40P01 | P0 | 行锁死锁检测，SQLSTATE 为 40P01。 | 多会话并发文本用例 | core | boundary-directed |
| LOCK-DEADLOCK-STRICTEST-FIRST | P0 | 首个锁使用所需最严格模式可避免升级锁死锁。 | 多会话并发文本用例 | supporting | boundary-directed |
| LOCK-DEADLOCK-TABLE-40P01 | P0 | 表锁死锁检测，SQLSTATE 为 40P01。 | 多会话并发文本用例 | core | boundary-directed |
| LOCK-DEADLOCK-VICTIM-UNPREDICTABLE | P0 | 死锁中被中止的事务不可依赖固定选择。 | 多会话并发文本用例 | supporting | boundary-directed |

### 充分性结论
- 本节 5 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.3.5 Advisory Locks

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.3-explicit-locking/13.3.5-advisory-locks/`
- 测试点数量：10 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | Advisory lock 语义 | session-level、transaction-level、shared memory、reentrant、pg_locks | P0/P1 | LOCK-ADVISORY-LIMIT-ORDER-BY-RISK、LOCK-ADVISORY-NOT-ROW-BOUND、LOCK-ADVISORY-PG-LOCKS-VISIBLE、LOCK-ADVISORY-REENTRANT-ACQUIRE、LOCK-ADVISORY-REENTRANT-WHILE-OTHERS-WAITING、LOCK-ADVISORY-SESSION-LEVEL、LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL、LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK、LOCK-ADVISORY-SHARED-MEMORY-LIMIT、LOCK-ADVISORY-TRANSACTION-LEVEL |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | single-factor/boundary-directed | LOCK-ADVISORY-LIMIT-ORDER-BY-RISK、LOCK-ADVISORY-NOT-ROW-BOUND、LOCK-ADVISORY-PG-LOCKS-VISIBLE、LOCK-ADVISORY-REENTRANT-ACQUIRE、LOCK-ADVISORY-REENTRANT-WHILE-OTHERS-WAITING、LOCK-ADVISORY-SESSION-LEVEL、LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL、LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK、LOCK-ADVISORY-SHARED-MEMORY-LIMIT、LOCK-ADVISORY-TRANSACTION-LEVEL | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.3.5 Advisory Locks 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 10 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-ADVISORY-LIMIT-ORDER-BY-RISK | P1 | Advisory lock 函数与 ORDER BY / LIMIT 组合存在求值顺序风险。 | 多会话并发文本用例 | supporting | single-factor/boundary-directed |
| LOCK-ADVISORY-NOT-ROW-BOUND | P1 | Advisory lock 不绑定具体数据行。 | 多会话并发文本用例 | core | single-factor/boundary-directed |
| LOCK-ADVISORY-PG-LOCKS-VISIBLE | P1 | Advisory lock 在 pg_locks 中可见。 | 多会话并发文本用例 | core | single-factor/boundary-directed |
| LOCK-ADVISORY-REENTRANT-ACQUIRE | P1 | 同一会话可重复获取同一 advisory lock，需匹配释放。 | 多会话并发文本用例 | core | single-factor/boundary-directed |
| LOCK-ADVISORY-REENTRANT-WHILE-OTHERS-WAITING | P1 | 已持有 advisory lock 的会话再次获取同一锁，即使其他会话正在等待，也应立即成功。 | 文本用例 | duplicate-covered | single-factor/boundary-directed |
| LOCK-ADVISORY-SESSION-LEVEL | P1 | Session-level advisory lock 跨事务保持，需显式释放。 | 多会话并发文本用例 | core | single-factor/boundary-directed |
| LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL | P0 | session-level advisory unlock 即使所在事务后续失败也立即生效。 | 文本用例 | core | single-factor/boundary-directed |
| LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK | P0 | session-level 和 transaction-level advisory lock 使用同一 identifier 时会互相阻塞。 | 文本用例 | core | single-factor/boundary-directed |
| LOCK-ADVISORY-SHARED-MEMORY-LIMIT | P1 | Advisory lock 受共享内存锁表容量限制。 | 多会话并发文本用例 | special | single-factor/boundary-directed |
| LOCK-ADVISORY-TRANSACTION-LEVEL | P1 | Transaction-level advisory lock 在事务结束时自动释放。 | 多会话并发文本用例 | core | single-factor/boundary-directed |

### 充分性结论
- 本节 10 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.4 Data Consistency Checks At The Application Level

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/`
- 测试点数量：3 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 应用层一致性策略 | Serializable、显式阻塞锁、SELECT FOR UPDATE/SHARE、触发器/重试框架 | P0/P1 | APP-RC-CHECK-UNSAFE、APP-REPLICA-CONSISTENCY-LIMIT、APP-RR-SNAPSHOT-CHECK-LIMIT |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | risk-based | APP-RC-CHECK-UNSAFE、APP-REPLICA-CONSISTENCY-LIMIT、APP-RR-SNAPSHOT-CHECK-LIMIT | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.4 Data Consistency Checks At The Application Level 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 3 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| APP-RC-CHECK-UNSAFE | P0 | READ COMMITTED 下视图随语句变化，业务一致性检查不可靠。 | 多会话并发文本用例 | core | risk-based |
| APP-REPLICA-CONSISTENCY-LIMIT | P0 | Serializable 一致性保护不扩展到 hot standby 或 logical replica。 | 多会话并发文本用例 | special | risk-based |
| APP-RR-SNAPSHOT-CHECK-LIMIT | P0 | REPEATABLE READ 有稳定视图，但 read/write conflict 可导致业务检查不成立。 | 多会话并发文本用例 | core | risk-based |

### 充分性结论
- 本节 3 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.4.1 Enforcing Consistency With Serializable Transactions

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/13.4.1-enforcing-consistency-with-serializable-transactions/`
- 测试点数量：4 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 应用层一致性策略 | Serializable、显式阻塞锁、SELECT FOR UPDATE/SHARE、触发器/重试框架 | P0/P1 | APP-FORCE-SERIALIZABLE-BY-DEFAULT、APP-SER-CHECK-COMMIT-GUARANTEE、APP-SER-RETRY-FRAMEWORK-REQUIRED、APP-TRIGGER-REJECT-NON-SERIALIZABLE |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | risk-based | APP-FORCE-SERIALIZABLE-BY-DEFAULT、APP-SER-CHECK-COMMIT-GUARANTEE、APP-SER-RETRY-FRAMEWORK-REQUIRED、APP-TRIGGER-REJECT-NON-SERIALIZABLE | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.4.1 Enforcing Consistency With Serializable Transactions 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 4 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| APP-FORCE-SERIALIZABLE-BY-DEFAULT | P0 | 通过 default_transaction_isolation=serializable 防止误用其他隔离级别。 | 多会话并发文本用例 | core | risk-based |
| APP-SER-CHECK-COMMIT-GUARANTEE | P0 | 全部相关读写使用 Serializable 时，可依赖事务成功提交保证业务一致性。 | 多会话并发文本用例 | core | risk-based |
| APP-SER-RETRY-FRAMEWORK-REQUIRED | P0 | 应用框架应自动重试 serialization failure。 | 多会话并发文本用例 | core | risk-based |
| APP-TRIGGER-REJECT-NON-SERIALIZABLE | P0 | 通过触发器检查防止误用非 Serializable 事务。 | 多会话并发文本用例 | special | risk-based |

### 充分性结论
- 本节 4 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.4.2 Enforcing Consistency With Explicit Blocking Locks

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.4-data-consistency-checks-at-the-application-level/13.4.2-enforcing-consistency-with-explicit-blocking-locks/`
- 测试点数量：6 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 应用层一致性策略 | Serializable、显式阻塞锁、SELECT FOR UPDATE/SHARE、触发器/重试框架 | P0/P1 | APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE、APP-BLOCKING-SELECT-FOR-SHARE、APP-BLOCKING-SELECT-FOR-UPDATE、APP-GLOBAL-CHECK-LOCK-ALL-TABLES、APP-RR-LOCK-BEFORE-SNAPSHOT、APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | risk-based | APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE、APP-BLOCKING-SELECT-FOR-SHARE、APP-BLOCKING-SELECT-FOR-UPDATE、APP-GLOBAL-CHECK-LOCK-ALL-TABLES、APP-RR-LOCK-BEFORE-SNAPSHOT、APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.4.2 Enforcing Consistency With Explicit Blocking Locks 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 6 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE | P0 | 非 serializable 写存在时，LOCK TABLE 保护全表而不是单行。 | 文本用例 | core | risk-based |
| APP-BLOCKING-SELECT-FOR-SHARE | P0 | 非 serializable 写存在时，单独验证 SELECT FOR SHARE 保护返回行免受并发更新。 | 文本用例 | duplicate-covered | risk-based |
| APP-BLOCKING-SELECT-FOR-UPDATE | P0 | 非 Serializable 写存在时，使用 SELECT FOR UPDATE 或 SELECT FOR SHARE 阻塞冲突事务。 | 多会话并发文本用例 | core | risk-based |
| APP-GLOBAL-CHECK-LOCK-ALL-TABLES | P0 | 全局一致性检查可能需要锁定所有相关表，SHARE 或更高锁保证无其他未提交变更。 | 多会话并发文本用例 | core | risk-based |
| APP-RR-LOCK-BEFORE-SNAPSHOT | P0 | Repeatable Read 下依赖显式锁时，应在快照冻结前获取锁。 | 多会话并发文本用例 | core | risk-based |
| APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW | P0 | 如需确保一行不被后续更新或删除，应实际更新该行，即使值不变。 | 多会话并发文本用例 | core | risk-based |

### 充分性结论
- 本节 6 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.5 Serialization Failure Handling

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.5-serialization-failure-handling/`
- 测试点数量：9 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 失败重试策略 | 40001、40P01、23505、23P01、whole transaction retry | P0/P1 | RETRY-23505-SERIALIZABLE-INSERT-RACE、RETRY-23P01-EXCLUSION-RACE、RETRY-40001-RR、RETRY-40001-SER、RETRY-40P01-DEADLOCK、RETRY-HIGH-CONTENTION-MULTIPLE-ATTEMPTS、RETRY-NO-AUTO-RETRY-BY-SERVER、RETRY-PREPARED-TRANSACTION-BLOCKING、RETRY-WHOLE-TRANSACTION-DECISION-LOGIC |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed | RETRY-23505-SERIALIZABLE-INSERT-RACE、RETRY-23P01-EXCLUSION-RACE、RETRY-40001-RR、RETRY-40001-SER、RETRY-40P01-DEADLOCK、RETRY-HIGH-CONTENTION-MULTIPLE-ATTEMPTS、RETRY-NO-AUTO-RETRY-BY-SERVER、RETRY-PREPARED-TRANSACTION-BLOCKING、RETRY-WHOLE-TRANSACTION-DECISION-LOGIC | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.5 Serialization Failure Handling 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 9 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| RETRY-23505-SERIALIZABLE-INSERT-RACE | P0 | 某些 unique_violation SQLSTATE 23505 可按场景谨慎重试。 | 多会话并发文本用例 | core | boundary-directed |
| RETRY-23P01-EXCLUSION-RACE | P0 | 某些 exclusion_violation SQLSTATE 23P01 可按场景谨慎重试。 | 多会话并发文本用例 | core | boundary-directed |
| RETRY-40001-RR | P0 | REPEATABLE READ 下 serialization_failure 需要完整事务重试。 | 多会话并发文本用例 | core | boundary-directed |
| RETRY-40001-SER | P0 | SERIALIZABLE 下 serialization_failure 需要完整事务重试。 | 多会话并发文本用例 | core | boundary-directed |
| RETRY-40P01-DEADLOCK | P0 | Deadlock SQLSTATE 40P01 建议纳入重试策略。 | 多会话并发文本用例 | core | boundary-directed |
| RETRY-HIGH-CONTENTION-MULTIPLE-ATTEMPTS | P0 | 高竞争下可能需要多次重试。 | 多会话并发文本用例 | special | boundary-directed |
| RETRY-NO-AUTO-RETRY-BY-SERVER | P0 | PostgreSQL 不提供自动重试能力。 | 多会话并发文本用例 | core | boundary-directed |
| RETRY-PREPARED-TRANSACTION-BLOCKING | P0 | 与 prepared transaction 冲突时，可能直到 prepared transaction commit 或 rollback 后才有进展。 | 多会话并发文本用例 | special | boundary-directed |
| RETRY-WHOLE-TRANSACTION-DECISION-LOGIC | P0 | 重试必须包含决定 SQL 和决定值的全部事务逻辑。 | 多会话并发文本用例 | core | boundary-directed |

### 充分性结论
- 本节 9 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.6 Caveats

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.6-caveats/`
- 测试点数量：9 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 官方 caveats 与非 MVCC-safe 边界 | TRUNCATE、ALTER TABLE rewrite、catalog/internal consistency、standby/replica | P0/P1 | CAVEAT-ALTER-REWRITE-NOT-MVCC-SAFE、CAVEAT-CATALOG-INTERNAL-NONISOLATED、CAVEAT-CREATE-OBJECT-CATALOG-VS-DATA、CAVEAT-DDL-BLOCKED-BY-ACCESS-SHARE、CAVEAT-DDL-CROSS-TABLE-VISIBILITY、CAVEAT-EXPLICIT-CATALOG-QUERY-INVISIBLE-ROWS、CAVEAT-HOT-STANDBY-NO-SERIALIZABLE、CAVEAT-STANDBY-RR-NONPRIMARY-SERIAL-STATE、CAVEAT-TRUNCATE-NOT-MVCC-SAFE |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed/risk-based | CAVEAT-ALTER-REWRITE-NOT-MVCC-SAFE、CAVEAT-CATALOG-INTERNAL-NONISOLATED、CAVEAT-CREATE-OBJECT-CATALOG-VS-DATA、CAVEAT-DDL-BLOCKED-BY-ACCESS-SHARE、CAVEAT-DDL-CROSS-TABLE-VISIBILITY、CAVEAT-EXPLICIT-CATALOG-QUERY-INVISIBLE-ROWS、CAVEAT-HOT-STANDBY-NO-SERIALIZABLE、CAVEAT-STANDBY-RR-NONPRIMARY-SERIAL-STATE、CAVEAT-TRUNCATE-NOT-MVCC-SAFE | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.6 Caveats 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 9 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| CAVEAT-ALTER-REWRITE-NOT-MVCC-SAFE | P1 | 表重写形式的 ALTER TABLE 不是 MVCC-safe。 | 多会话并发文本用例 | special | boundary-directed/risk-based |
| CAVEAT-CATALOG-INTERNAL-NONISOLATED | P1 | 内部访问 system catalogs 不使用当前事务隔离级别。 | 多会话并发文本用例 | special | boundary-directed/risk-based |
| CAVEAT-CREATE-OBJECT-CATALOG-VS-DATA | P1 | 新建数据库对象对并发高隔离事务可见，但数据行和显式 catalog 查询可见性存在差异。 | 多会话并发文本用例 | special | boundary-directed/risk-based |
| CAVEAT-DDL-BLOCKED-BY-ACCESS-SHARE | P1 | 并发事务之前访问过目标表时，其 ACCESS SHARE 表锁会阻塞相关 DDL。 | 多会话并发文本用例 | core | boundary-directed/risk-based |
| CAVEAT-DDL-CROSS-TABLE-VISIBILITY | P1 | 相关 DDL 可能造成目标表与其他表之间的可见性不一致。 | 多会话并发文本用例 | special | boundary-directed/risk-based |
| CAVEAT-EXPLICIT-CATALOG-QUERY-INVISIBLE-ROWS | P1 | 高隔离级别下显式 catalog 查询看不到并发创建对象对应的 catalog rows。 | 多会话并发文本用例 | special | boundary-directed/risk-based |
| CAVEAT-HOT-STANDBY-NO-SERIALIZABLE | P1 | Hot standby 上尚不支持 Serializable，最严格为 Repeatable Read。 | 多会话并发文本用例 | special | boundary-directed/risk-based |
| CAVEAT-STANDBY-RR-NONPRIMARY-SERIAL-STATE | P1 | Standby 上 Repeatable Read 事务可能看到不对应任何 primary 串行执行的瞬时状态。 | 多会话并发文本用例 | special | boundary-directed/risk-based |
| CAVEAT-TRUNCATE-NOT-MVCC-SAFE | P1 | TRUNCATE 不是 MVCC-safe。 | 多会话并发文本用例 | special | boundary-directed/risk-based |

### 充分性结论
- 本节 9 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.7 Locking And Indexes

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.7-locking-and-indexes/`
- 测试点数量：9 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 索引并发访问与索引类型建议 | B-tree、Hash、GiST、SP-GiST、GIN、deadlock risk | P0/P1 | IDX-BTREE-PAGE-LOCK-CONCURRENCY、IDX-GIN-MULTI-KEY-INSERT、IDX-GIST-PAGE-LOCK-CONCURRENCY、IDX-GIST-SPGIST-PAGE-LOCK-CONCURRENCY、IDX-HASH-BUCKET-LOCK-CONCURRENCY、IDX-HASH-DEADLOCK-RISK、IDX-NONSCALAR-DATA-GIST-SPGIST-GIN-RECOMMENDATION、IDX-SCALAR-DATA-BTREE-RECOMMENDATION、IDX-SPGIST-PAGE-LOCK-CONCURRENCY |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | equivalence-class/boundary-directed | IDX-BTREE-PAGE-LOCK-CONCURRENCY、IDX-GIN-MULTI-KEY-INSERT、IDX-GIST-PAGE-LOCK-CONCURRENCY、IDX-GIST-SPGIST-PAGE-LOCK-CONCURRENCY、IDX-HASH-BUCKET-LOCK-CONCURRENCY、IDX-HASH-DEADLOCK-RISK、IDX-NONSCALAR-DATA-GIST-SPGIST-GIN-RECOMMENDATION、IDX-SCALAR-DATA-BTREE-RECOMMENDATION、IDX-SPGIST-PAGE-LOCK-CONCURRENCY | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.7 Locking And Indexes 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 9 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| IDX-BTREE-PAGE-LOCK-CONCURRENCY | P1 | B-tree 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放。 | 多会话并发文本用例 | special | equivalence-class/boundary-directed |
| IDX-GIN-MULTI-KEY-INSERT | P1 | GIN 单个 indexed value 插入通常产生多个 index key insertions。 | 多会话并发文本用例 | special | equivalence-class/boundary-directed |
| IDX-GIST-PAGE-LOCK-CONCURRENCY | P1 | GiST 索引读写使用短期 page-level share/exclusive lock，并在每个 index row 读取或插入后立即释放。 | 文本用例 | special | equivalence-class/boundary-directed |
| IDX-GIST-SPGIST-PAGE-LOCK-CONCURRENCY | P1 | GiST、SP-GiST 使用短期 page-level locks，提供较高并发。 | 多会话并发文本用例 | duplicate-covered | equivalence-class/boundary-directed |
| IDX-HASH-BUCKET-LOCK-CONCURRENCY | P1 | Hash index 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放。 | 多会话并发文本用例 | special | equivalence-class/boundary-directed |
| IDX-HASH-DEADLOCK-RISK | P1 | Hash index 比 index-level 并发更好，但可能死锁。 | 多会话并发文本用例 | special | equivalence-class/boundary-directed |
| IDX-NONSCALAR-DATA-GIST-SPGIST-GIN-RECOMMENDATION | P2 | 并发应用中非 scalar data 推荐 GiST、SP-GiST 或 GIN。 | 多会话并发文本用例 | supporting | equivalence-class/boundary-directed |
| IDX-SCALAR-DATA-BTREE-RECOMMENDATION | P2 | 并发应用中 scalar data 推荐 B-tree。 | 多会话并发文本用例 | supporting | equivalence-class/boundary-directed |
| IDX-SPGIST-PAGE-LOCK-CONCURRENCY | P1 | SP-GiST 索引读写使用短期 page-level share/exclusive lock，并在每个 index row 读取或插入后立即释放。 | 文本用例 | special | equivalence-class/boundary-directed |

### 充分性结论
- 本节 9 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.8.1 Locking Read Options

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.1-locking-read-options/`
- 测试点数量：5 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 锁定读选项 | FOR UPDATE、NOWAIT、SKIP LOCKED、OF table | P0/P1 | LOCK-READ-FOR-UPDATE-OF-SPECIFIC-TABLE、LOCK-READ-LARGE-RANGE-FOR-UPDATE-RISK、LOCK-READ-NOWAIT-CONFLICT-ERROR、LOCK-READ-SKIP-LOCKED-INCOMPLETE-VIEW、LOCK-READ-SKIP-LOCKED-QUEUE-CLAIM |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed | LOCK-READ-FOR-UPDATE-OF-SPECIFIC-TABLE、LOCK-READ-LARGE-RANGE-FOR-UPDATE-RISK、LOCK-READ-NOWAIT-CONFLICT-ERROR、LOCK-READ-SKIP-LOCKED-INCOMPLETE-VIEW、LOCK-READ-SKIP-LOCKED-QUEUE-CLAIM | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.8.1 Locking Read Options 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 5 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-READ-FOR-UPDATE-OF-SPECIFIC-TABLE | P0 | FOR UPDATE OF table_name 在多表 join 中只锁定指定表的目标行，不锁其他 join 表行。 | 文本用例 | core | boundary-directed |
| LOCK-READ-LARGE-RANGE-FOR-UPDATE-RISK | P0 | 大范围 FOR UPDATE 会锁住大量行，增加阻塞、死锁和 tuple 标记写入成本，应作为风险场景记录。 | 文本用例 | core | boundary-directed |
| LOCK-READ-NOWAIT-CONFLICT-ERROR | P0 | 目标行已被其他事务锁定时，FOR UPDATE NOWAIT 应立即失败而不是等待。 | 文本用例 | core | boundary-directed |
| LOCK-READ-SKIP-LOCKED-INCOMPLETE-VIEW | P0 | SKIP LOCKED 返回的是跳过锁行后的不完整视图，不适合完整一致性查询。 | 文本用例 | core | boundary-directed |
| LOCK-READ-SKIP-LOCKED-QUEUE-CLAIM | P0 | 多 worker 队列领取场景中，FOR UPDATE SKIP LOCKED LIMIT 1 跳过已锁定 pending 任务并领取其他任务。 | 文本用例 | core | boundary-directed |

### 充分性结论
- 本节 5 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.8.2 Constraints And Key Locks

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.2-constraints-and-key-locks/`
- 测试点数量：5 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 约束与键锁 | foreign key、unique check、exclusion constraint、uncommitted conflict | P0/P1 | LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01、LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE、LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK、LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505、LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed | LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01、LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE、LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK、LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505、LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.8.2 Constraints And Key Locks 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 5 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01 | P0 | 并发插入违反排除约束时返回 23P01 exclusion_violation，并按业务判断是否可重试。 | 文本用例 | core | boundary-directed |
| LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE | P0 | 子表插入外键引用时，需要确认父表 key 存在，并与父表 key 的删除/修改形成锁协调。 | 文本用例 | core | boundary-directed |
| LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK | P0 | 删除或修改父表被引用 key 时，应与并发子表外键检查产生等待或冲突。 | 文本用例 | core | boundary-directed |
| LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505 | P0 | 两个事务插入相同唯一键时，后发事务等待先发事务；先发提交后，后发返回 23505 unique_violation。 | 文本用例 | core | boundary-directed |
| LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS | P0 | 两个事务插入相同唯一键时，后发事务等待先发事务；先发回滚后，后发继续成功。 | 文本用例 | core | boundary-directed |

### 充分性结论
- 本节 5 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.8.3 Maintenance And Ddl Lock Practices

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.3-maintenance-and-ddl-lock-practices/`
- 测试点数量：6 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 维护/DDL 锁实践 | VACUUM、CREATE INDEX CONCURRENTLY、VACUUM FULL、long transaction | P0/P1 | LOCK-CREATE-INDEX-CONCURRENTLY-ALLOWS-WRITES、LOCK-CREATE-INDEX-CONCURRENTLY-NOT-IN-TXN-BLOCK、LOCK-DDL-PREFLIGHT-CHECK-LONG-TXN、LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS、LOCK-VACUUM-ANALYZE-DO-NOT-BLOCK-NORMAL-READ-WRITE、LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | risk-based | LOCK-CREATE-INDEX-CONCURRENTLY-ALLOWS-WRITES、LOCK-CREATE-INDEX-CONCURRENTLY-NOT-IN-TXN-BLOCK、LOCK-DDL-PREFLIGHT-CHECK-LONG-TXN、LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS、LOCK-VACUUM-ANALYZE-DO-NOT-BLOCK-NORMAL-READ-WRITE、LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.8.3 Maintenance And Ddl Lock Practices 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 6 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-CREATE-INDEX-CONCURRENTLY-ALLOWS-WRITES | P0 | 相对普通 CREATE INDEX，CREATE INDEX CONCURRENTLY 应允许更多并发写入，只持有更温和的锁。 | 文本用例 | core | risk-based |
| LOCK-CREATE-INDEX-CONCURRENTLY-NOT-IN-TXN-BLOCK | P0 | CREATE INDEX CONCURRENTLY 不能在普通事务块中执行。 | 文本用例 | core | risk-based |
| LOCK-DDL-PREFLIGHT-CHECK-LONG-TXN | P0 | 执行强 DDL 前应检查长事务、idle in transaction 和目标表锁，避免 ACCESS EXCLUSIVE 阻塞事故。 | 文本用例 | core | risk-based |
| LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS | P0 | REFRESH MATERIALIZED VIEW CONCURRENTLY 允许更多并发访问，但需要满足唯一索引等前置条件。 | 文本用例 | core | risk-based |
| LOCK-VACUUM-ANALYZE-DO-NOT-BLOCK-NORMAL-READ-WRITE | P0 | 普通 VACUUM 和 ANALYZE 使用相对温和的锁，通常不阻塞普通读写。 | 文本用例 | core | risk-based |
| LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL | P0 | VACUUM FULL 重写表并获取 ACCESS EXCLUSIVE，会阻塞所有访问。 | 文本用例 | core | risk-based |

### 充分性结论
- 本节 6 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.8.4 Diagnostics And Wait Events

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.4-diagnostics-and-wait-events/`
- 测试点数量：6 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 诊断视图与等待事件 | pg_locks、pg_stat_activity、blocking pids、wait_event | P0/P1 | LOCK-DIAGNOSE-BLOCKING-CHAIN-QUERY、LOCK-DIAGNOSE-BLOCKING-PIDS-BASIC、LOCK-DIAGNOSE-PG-STAT-ACTIVITY-WAIT-EVENT-LOCK、LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS、LOCK-WAIT-EVENT-BUFFERPIN-OBSERVE、LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | diagnostic-directed | LOCK-DIAGNOSE-BLOCKING-CHAIN-QUERY、LOCK-DIAGNOSE-BLOCKING-PIDS-BASIC、LOCK-DIAGNOSE-PG-STAT-ACTIVITY-WAIT-EVENT-LOCK、LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS、LOCK-WAIT-EVENT-BUFFERPIN-OBSERVE、LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.8.4 Diagnostics And Wait Events 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 6 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-DIAGNOSE-BLOCKING-CHAIN-QUERY | P0 | 使用 pg_stat_activity + pg_blocking_pids 查询阻塞链，定位 blocker query 与 blocked query。 | 文本用例 | core | diagnostic-directed |
| LOCK-DIAGNOSE-BLOCKING-PIDS-BASIC | P0 | 构造阻塞后，通过 pg_blocking_pids(pid) 定位 blocker 和 blocked。 | 文本用例 | core | diagnostic-directed |
| LOCK-DIAGNOSE-PG-STAT-ACTIVITY-WAIT-EVENT-LOCK | P0 | 行锁或表锁等待时，pg_stat_activity.wait_event_type 应能体现 Lock 类等待。 | 文本用例 | core | diagnostic-directed |
| LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS | P0 | 使用 pg_locks.relation::regclass 将 relation oid 转成表名，辅助定位被锁对象。 | 文本用例 | core | diagnostic-directed |
| LOCK-WAIT-EVENT-BUFFERPIN-OBSERVE | P0 | 某些 vacuum 或 DDL 可能等待其他 backend 释放 buffer pin，需通过 wait event 观察 BufferPin。 | 文本用例 | core | diagnostic-directed |
| LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK | P0 | LWLock 等待属于内部共享结构竞争，不应误判为 SQL 级表锁或行锁。 | 文本用例 | core | diagnostic-directed |

### 充分性结论
- 本节 6 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.8.5 Mvcc Vacuum And Long Transactions

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.5-mvcc-vacuum-and-long-transactions/`
- 测试点数量：6 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | MVCC 可见性与读写非阻塞 | 普通 SELECT、UPDATE、提交前/提交后状态 | P0/P1 | MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER、MVCC-DELETE-MARKS-OLD-TUPLE-NOT-IMMEDIATE-PHYSICAL-DELETE、MVCC-IDLE-IN-TRANSACTION-VACUUM-RISK、MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP、MVCC-TUPLE-VERSION-XMIN-XMAX-OBSERVE、MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | state-transition | MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER、MVCC-DELETE-MARKS-OLD-TUPLE-NOT-IMMEDIATE-PHYSICAL-DELETE、MVCC-IDLE-IN-TRANSACTION-VACUUM-RISK、MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP、MVCC-TUPLE-VERSION-XMIN-XMAX-OBSERVE、MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.8.5 Mvcc Vacuum And Long Transactions 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 6 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| MVCC-BACKEND-XMIN-IDENTIFIES-VACUUM-BLOCKER | P0 | 通过 pg_stat_activity.backend_xmin 辅助识别阻碍 VACUUM 清理的长事务。 | 文本用例 | core | state-transition |
| MVCC-DELETE-MARKS-OLD-TUPLE-NOT-IMMEDIATE-PHYSICAL-DELETE | P0 | DELETE 标记旧 tuple 对新事务不可见，但不是立即物理删除。 | 文本用例 | core | state-transition |
| MVCC-IDLE-IN-TRANSACTION-VACUUM-RISK | P0 | idle in transaction 不只是持锁风险，还会阻碍 vacuum、造成膨胀和事务 ID 年龄风险。 | 文本用例 | core | state-transition |
| MVCC-LONG-TRANSACTION-BLOCKS-VACUUM-CLEANUP | P0 | 长事务持有旧 snapshot，会阻止旧 tuple 被 VACUUM 完全清理。 | 文本用例 | core | state-transition |
| MVCC-TUPLE-VERSION-XMIN-XMAX-OBSERVE | P0 | 通过系统列观察 xmin/xmax，理解 tuple version 的创建、更新、删除或锁定元信息。 | 文本用例 | core | state-transition |
| MVCC-UPDATE-CREATES-NEW-TUPLE-VERSION | P0 | UPDATE 创建新的 tuple version，旧版本仍可被旧 snapshot 读取。 | 文本用例 | core | state-transition |

### 充分性结论
- 本节 6 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。

## 13.8.6 Lock Timeout And Retry Controls

### 章节定位
- 来源目录：`docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.6-lock-timeout-and-retry-controls/`
- 测试点数量：3 个。
- 覆盖原则：每个测试点只验证一个主要场景；并发测试默认 2 个会话。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 死锁检测与规避 | 循环等待、SQLSTATE 40P01、锁顺序、victim 不确定性 | P0/P1 | LOCK-DEADLOCK-TIMEOUT-DETECTION-WINDOW |
| F02 | behavior/state/boundary | 并发控制行为 | 状态转换、边界 | P0/P1 | LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY |
| F03 | behavior/state/boundary | 失败重试策略 | 40001、40P01、23505、23P01、whole transaction retry | P0/P1 | RETRY-40001-40P01-WITH-BACKOFF |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed | LOCK-DEADLOCK-TIMEOUT-DETECTION-WINDOW | 按单一测试点验证一个官方行为，避免交叉覆盖。 |
| C02 | single-factor | LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY | 按单一测试点验证一个官方行为，避免交叉覆盖。 |
| C03 | boundary-directed | RETRY-40001-40P01-WITH-BACKOFF | 按单一测试点验证一个官方行为，避免交叉覆盖。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 13.8.6 Lock Timeout And Retry Controls 中的概念性背景、实现解释或与其他章节重复的说明。 | 不是独立可执行行为，或已被本节/相邻章节的具体行为测试点覆盖。 | 在本节因子矩阵中保留 no-test 说明；由本节 3 个测试点共同证明主行为。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 测试类型 | 减法标签 | 组合方式 |
|---|---|---|---|---|---|
| LOCK-DEADLOCK-TIMEOUT-DETECTION-WINDOW | P0 | deadlock_timeout 影响死锁检测启动时机，不等同于普通 lock wait timeout。 | 文本用例 | core | boundary-directed |
| LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY | P0 | 区分 lock_timeout 只控制锁等待时长，statement_timeout 控制语句总执行时长。 | 文本用例 | core | single-factor |
| RETRY-40001-40P01-WITH-BACKOFF | P0 | 高争用场景重试 40001/40P01 时应加入有限次数和退避策略。 | 文本用例 | core | boundary-directed |

### 充分性结论
- 本节 3 个测试点覆盖了当前章节的主要行为因子和边界条件。
- 组合方式以 single-factor、state-transition、boundary-directed、concurrency-directed 和 risk-based 为主，避免无价值全组合。
- no-test 内容已记录为概念性、重复覆盖或不适合独立自动化的边界。
