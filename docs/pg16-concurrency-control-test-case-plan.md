# PostgreSQL 16.4 Chapter 13 Concurrency Control 用例计划

## 1. 文档定位

本文档基于 `pg16-concurrency-control-test-design.md` 的 M1-M10 模块划分，进一步细化每个章节的计划用例名称和测试点。

当前阶段只定义用例边界、测试意图和建议用例数量，不展开具体 SQL、会话时序、同步点和 expected 输出。后续详细测试步骤应以本文档中的用例名称为索引继续补充。

建议标准覆盖总量约为 95 个用例：

- 基础多会话单实例用例：约 87 个。
- hot standby、logical replica、prepared transaction 等特殊环境用例：约 8 个。
- P0 基础并发链路：约 65 个。
- P1 专项和环境用例：约 22 个。
- P2 观测或性能建议类用例：约 8 个。

## 2. 用例分层

| 层级 | 说明 | 建议范围 |
|---|---|---:|
| P0 | 官方章节核心语义、错误码、锁冲突、隔离级别基础行为 | 65 |
| P1 | 特殊对象、特殊环境、应用一致性策略、索引专项 | 22 |
| P2 | 观测项、性能建议、实现细节提示类行为 | 8 |

## 3. M1 MVCC 与基础快照模型

建议用例数：7 个。

| 用例名称 | 测试点 |
|---|---|
| `MVCC-SNAPSHOT-SELECT-COMMITTED` | 普通 `SELECT` 只看到已提交版本。 |
| `MVCC-SNAPSHOT-NO-DIRTY-READ` | 并发未提交变更不可见。 |
| `MVCC-READ-WRITE-NONBLOCKING-SELECT-UPDATE` | 普通读不阻塞写。 |
| `MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT` | 写不阻塞普通读。 |
| `MVCC-CONCURRENT-UPDATE-SAME-ROW` | 同一行并发更新只暴露一致版本。 |
| `MVCC-EXPLICIT-LOCK-BOUNDARY` | MVCC 普通读写与显式锁边界。 |
| `MVCC-ADVISORY-LOCK-NOT-ROW-BOUND` | Advisory lock 不绑定具体数据行。 |

## 4. M2 隔离级别矩阵与异常现象

建议用例数：9 个。

| 用例名称 | 测试点 |
|---|---|
| `ISO-RU-MAPS-TO-RC` | `READ UNCOMMITTED` 在 PostgreSQL 中表现为 `READ COMMITTED`。 |
| `ISO-RC-NONREPEATABLE-READ` | `READ COMMITTED` 允许同事务多次 `SELECT` 看到不同结果。 |
| `ISO-RC-PHANTOM-READ` | `READ COMMITTED` 下新提交行可被后续语句看到。 |
| `ISO-RR-NO-NONREPEATABLE-READ` | `REPEATABLE READ` 下事务级快照稳定。 |
| `ISO-RR-NO-PHANTOM-READ` | PostgreSQL `REPEATABLE READ` 不出现 phantom read。 |
| `ISO-SER-NO-SERIALIZATION-ANOMALY` | `SERIALIZABLE` 防止序列化异常。 |
| `ISO-SET-TRANSACTION-BEFORE-FIRST-STMT` | `SET TRANSACTION` 对事务隔离级别的生效边界。 |
| `ISO-DEFAULT-READ-COMMITTED` | 默认隔离级别为 `READ COMMITTED`。 |
| `ISO-SEQUENCE-NONTRANSACTIONAL` | Sequence 或 serial 计数器变化立即可见，且事务 abort 后不回滚。 |

## 5. M3 Read Committed 与语句级快照

建议用例数：10 个。

| 用例名称 | 测试点 |
|---|---|
| `RC-STATEMENT-SNAPSHOT-BASIC` | 每条语句使用语句开始时快照。 |
| `RC-SAME-TXN-NEW-SNAPSHOT` | 同一事务后续语句看到其他事务新提交数据。 |
| `RC-SELECT-IGNORE-INPROGRESS` | 普通 `SELECT` 不看未提交并发变更。 |
| `RC-UPDATE-WAIT-RECHECK-WHERE-MATCH` | `UPDATE` 等待并发事务结束后重检 `WHERE`，匹配则继续更新。 |
| `RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH` | `UPDATE` 等待并发事务结束后重检 `WHERE`，不匹配则跳过。 |
| `RC-DELETE-WAIT-RECHECK` | `DELETE` 对并发更新行等待并重检条件。 |
| `RC-SELECT-FOR-UPDATE-WAIT-RECHECK` | `SELECT FOR UPDATE` 等待并发更新结束后重检目标行。 |
| `RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT` | 复杂搜索条件下，单条更新命令可能看到不一致快照。 |
| `RC-ON-CONFLICT-DO-UPDATE-GUARANTEE` | `INSERT ... ON CONFLICT DO UPDATE` 每行保证 insert 或 update 之一发生。 |
| `RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE` | `MERGE` 并发更新时重新评估 action，但不提供同等 upsert 保证。 |

## 6. M4 Repeatable Read 与事务级快照

建议用例数：8 个。

| 用例名称 | 测试点 |
|---|---|
| `RR-SNAPSHOT-FIRST-NON-TCL-STMT` | 事务快照固定在第一个非事务控制语句开始时。 |
| `RR-REPEATABLE-SELECT-STABLE` | 同一事务内连续查询看到稳定视图。 |
| `RR-NOT-SEE-LATER-COMMIT` | 不看到事务开始后其他事务提交的变更。 |
| `RR-UPDATE-CONCURRENT-UPDATE-40001` | 并发更新目标行后，当前事务 `UPDATE` 失败并返回 serialization failure。 |
| `RR-DELETE-CONCURRENT-UPDATE-40001` | 并发修改或删除目标行后，当前事务 `DELETE` 失败。 |
| `RR-SELECT-FOR-UPDATE-CONFLICT-40001` | `SELECT FOR UPDATE` 遇到并发修改目标行时失败。 |
| `RR-READONLY-NO-SERIALIZATION-CONFLICT` | 只读 `REPEATABLE READ` 事务不会产生 serialization conflicts。 |
| `RR-SNAPSHOT-ISOLATION-WRITE-SKEW` | `REPEATABLE READ` 是 Snapshot Isolation，稳定视图不必然等价于某个串行顺序。 |

## 7. M5 Serializable 与 SSI

建议用例数：11 个。

| 用例名称 | 测试点 |
|---|---|
| `SER-WRITE-SKEW-ABORT-ONE` | Write skew 模式下回滚其中一个事务。 |
| `SER-AGGREGATE-READ-THEN-WRITE` | 聚合读后写模式触发危险读写依赖。 |
| `SER-SUCCESS-EQUIVALENT-SERIAL-ORDER` | 成功提交的 Serializable 并发事务结果等价于某个串行顺序。 |
| `SER-SQLSTATE-40001` | Serialization failure SQLSTATE 为 `40001`。 |
| `SER-SIREADLOCK-PG-LOCKS` | Predicate locking 在 `pg_locks` 中以 `SIReadLock` 出现。 |
| `SER-SIREADLOCK-NONBLOCKING` | Predicate locks 不造成阻塞。 |
| `SER-SIREADLOCK-RETAIN-AFTER-COMMIT` | `SIReadLock` 可能在事务提交后保留，直到重叠读写事务完成。 |
| `SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT` | `SERIALIZABLE READ ONLY DEFERRABLE` 会等待安全快照。 |
| `SER-READ-ONLY-REDUCE-PREDICATE-LOCKS` | 安全只读事务可减少或释放 predicate locks。 |
| `SER-UNIQUE-VIOLATION-CONCURRENT-INSERT` | 并发 Serializable 下仍可能出现 unique constraint violation。 |
| `SER-PREDICATE-LOCK-ESCALATION-OBSERVE` | 顺序扫描可能增加 relation-level predicate lock。 |

## 8. M6 显式锁与等待行为

建议用例数：20 个。

| 用例名称 | 测试点 |
|---|---|
| `LOCK-PG-LOCKS-OBSERVE` | `pg_locks` 可观测当前锁、锁模式与等待状态。 |
| `LOCK-TABLE-ACCESS-SHARE-CONFLICT` | `ACCESS SHARE` 只与 `ACCESS EXCLUSIVE` 冲突。 |
| `LOCK-TABLE-ROW-SHARE-CONFLICT` | `ROW SHARE` 表级锁冲突矩阵。 |
| `LOCK-TABLE-ROW-EXCLUSIVE-CONFLICT` | `INSERT`、`UPDATE`、`DELETE`、`MERGE` 获取 `ROW EXCLUSIVE` 及其冲突关系。 |
| `LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE` | `VACUUM`、`ANALYZE`、`CREATE INDEX CONCURRENTLY` 等获取 `SHARE UPDATE EXCLUSIVE`。 |
| `LOCK-TABLE-SHARE` | 非 concurrently `CREATE INDEX` 获取 `SHARE`。 |
| `LOCK-TABLE-SHARE-ROW-EXCLUSIVE` | `CREATE TRIGGER` 和部分 `ALTER TABLE` 获取 `SHARE ROW EXCLUSIVE`。 |
| `LOCK-TABLE-EXCLUSIVE` | `EXCLUSIVE` 表级锁的阻塞关系。 |
| `LOCK-TABLE-ACCESS-EXCLUSIVE-BLOCKS-SELECT` | 只有 `ACCESS EXCLUSIVE` 会阻塞普通 `SELECT`。 |
| `LOCK-TABLE-SAVEPOINT-ROLLBACK-RELEASE` | Savepoint rollback 释放 savepoint 后获取的锁。 |
| `LOCK-ROW-FOR-UPDATE-MATRIX` | `FOR UPDATE` 行级锁冲突矩阵。 |
| `LOCK-ROW-FOR-NO-KEY-UPDATE-MATRIX` | `FOR NO KEY UPDATE` 行级锁冲突矩阵。 |
| `LOCK-ROW-FOR-SHARE-MATRIX` | `FOR SHARE` 行级锁冲突矩阵。 |
| `LOCK-ROW-FOR-KEY-SHARE-MATRIX` | `FOR KEY SHARE` 行级锁冲突矩阵。 |
| `LOCK-ROW-UPDATE-KEY-COLUMN` | `DELETE` 和修改 key 列的 `UPDATE` 获取 `FOR UPDATE`。 |
| `LOCK-ROW-UPDATE-NONKEY-COLUMN` | 不修改 key 的 `UPDATE` 获取 `FOR NO KEY UPDATE`。 |
| `LOCK-ROW-NORMAL-SELECT-NONBLOCKING` | 行级锁只阻塞同一行上的写入和加锁，不影响普通查询。 |
| `LOCK-DEADLOCK-TABLE-40P01` | 表锁死锁检测，SQLSTATE 为 `40P01`。 |
| `LOCK-DEADLOCK-ROW-40P01` | 行锁死锁检测，SQLSTATE 为 `40P01`。 |
| `LOCK-ADVISORY-SESSION-XACT-SEMANTICS` | Advisory lock 的 session-level、transaction-level、重复获取、释放语义和 `pg_locks` 可见性。 |

## 9. M7 应用层一致性策略

建议用例数：8 个。

| 用例名称 | 测试点 |
|---|---|
| `APP-RC-CHECK-UNSAFE` | `READ COMMITTED` 下视图随语句变化，业务一致性检查不可靠。 |
| `APP-RR-SNAPSHOT-CHECK-LIMIT` | `REPEATABLE READ` 有稳定视图，但 read/write conflict 可导致业务检查不成立。 |
| `APP-SER-CHECK-COMMIT-GUARANTEE` | 全部相关读写使用 Serializable 时，可依赖事务成功提交保证业务一致性。 |
| `APP-SER-RETRY-FRAMEWORK-REQUIRED` | 应用框架应自动重试 serialization failure。 |
| `APP-FORCE-SERIALIZABLE-BY-DEFAULT` | 通过 `default_transaction_isolation=serializable` 防止误用其他隔离级别。 |
| `APP-TRIGGER-REJECT-NON-SERIALIZABLE` | 通过触发器检查防止误用非 Serializable 事务。 |
| `APP-BLOCKING-SELECT-FOR-UPDATE` | 非 Serializable 写存在时，使用 `SELECT FOR UPDATE` 或 `SELECT FOR SHARE` 阻塞冲突事务。 |
| `APP-GLOBAL-CHECK-LOCK-ALL-TABLES` | 全局一致性检查可能需要锁定所有相关表，`SHARE` 或更高锁保证无其他未提交变更。 |

## 10. M8 错误处理与重试策略

建议用例数：8 个。

| 用例名称 | 测试点 |
|---|---|
| `RETRY-40001-RR` | `REPEATABLE READ` 下 `serialization_failure` 需要完整事务重试。 |
| `RETRY-40001-SER` | `SERIALIZABLE` 下 `serialization_failure` 需要完整事务重试。 |
| `RETRY-40P01-DEADLOCK` | Deadlock SQLSTATE `40P01` 建议纳入重试策略。 |
| `RETRY-23505-SERIALIZABLE-INSERT-RACE` | 某些 `unique_violation` SQLSTATE `23505` 可按场景谨慎重试。 |
| `RETRY-23P01-EXCLUSION-RACE` | 某些 `exclusion_violation` SQLSTATE `23P01` 可按场景谨慎重试。 |
| `RETRY-WHOLE-TRANSACTION-DECISION-LOGIC` | 重试必须包含决定 SQL 和决定值的全部事务逻辑。 |
| `RETRY-NO-AUTO-RETRY-BY-SERVER` | PostgreSQL 不提供自动重试能力。 |
| `RETRY-PREPARED-TRANSACTION-BLOCKING` | 与 prepared transaction 冲突时，可能直到 prepared transaction commit 或 rollback 后才有进展。 |

## 11. M9 Caveats 与环境限制

建议用例数：8 个。

| 用例名称 | 测试点 |
|---|---|
| `CAVEAT-TRUNCATE-NOT-MVCC-SAFE` | `TRUNCATE` 不是 MVCC-safe。 |
| `CAVEAT-ALTER-REWRITE-NOT-MVCC-SAFE` | 表重写形式的 `ALTER TABLE` 不是 MVCC-safe。 |
| `CAVEAT-DDL-BLOCKED-BY-ACCESS-SHARE` | 并发事务之前访问过目标表时，其 `ACCESS SHARE` 表锁会阻塞相关 DDL。 |
| `CAVEAT-DDL-CROSS-TABLE-VISIBILITY` | 相关 DDL 可能造成目标表与其他表之间的可见性不一致。 |
| `CAVEAT-HOT-STANDBY-NO-SERIALIZABLE` | Hot standby 上尚不支持 Serializable，最严格为 Repeatable Read。 |
| `CAVEAT-STANDBY-RR-NONPRIMARY-SERIAL-STATE` | Standby 上 Repeatable Read 事务可能看到不对应任何 primary 串行执行的瞬时状态。 |
| `CAVEAT-CATALOG-INTERNAL-NONISOLATED` | 内部访问 system catalogs 不使用当前事务隔离级别。 |
| `CAVEAT-CREATE-OBJECT-CATALOG-VS-DATA` | 新建数据库对象对并发高隔离事务可见，但数据行和显式 catalog 查询可见性存在差异。 |

## 12. M10 索引访问方法并发行为

建议用例数：6 个。

| 用例名称 | 测试点 |
|---|---|
| `IDX-BTREE-PAGE-LOCK-CONCURRENCY` | B-tree 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放。 |
| `IDX-GIST-SPGIST-PAGE-LOCK-CONCURRENCY` | GiST、SP-GiST 使用短期 page-level locks，提供较高并发。 |
| `IDX-HASH-BUCKET-LOCK-CONCURRENCY` | Hash index 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放。 |
| `IDX-HASH-DEADLOCK-RISK` | Hash index 比 index-level 并发更好，但可能死锁。 |
| `IDX-GIN-MULTI-KEY-INSERT` | GIN 单个 indexed value 插入通常产生多个 index key insertions。 |
| `IDX-INDEX-TYPE-RECOMMENDATION` | 并发应用中 scalar data 推荐 B-tree，非 scalar data 推荐 GiST、SP-GiST 或 GIN。 |

## 13. 后续展开模板

后续为每个用例补充具体步骤时，建议使用以下结构：

```markdown
### <用例名称>

- 覆盖模块：
- 优先级：
- 环境要求：
- 初始对象：
- 会话：
- 隔离级别：
- 执行时序：
- 同步点：
- 阻塞或错误预期：
- SQLSTATE：
- 最终数据断言：
- `pg_locks` 或 catalog 观测：
- 清理：
```

## 14. 展开顺序建议

1. 先展开 `M1`、`M2`、`M3`，建立 MVCC、隔离级别和 Read Committed 的基础模型。
2. 再展开 `M4`、`M5`、`M8`，覆盖事务级快照、SSI 和重试策略。
3. 然后展开 `M6`，补齐表锁、行锁、死锁和 Advisory Lock。
4. 接着展开 `M7`，构造业务不变量和应用层一致性场景。
5. 最后展开 `M9`、`M10`，补齐 caveats、特殊环境和索引访问方法专项。
