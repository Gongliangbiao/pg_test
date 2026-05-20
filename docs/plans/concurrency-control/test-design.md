# PostgreSQL 16.4 Chapter 13 Concurrency Control 测试设计框架

## 1. 设计目标

本文档用于规划 PostgreSQL 16.4 官方文档 `Chapter 13. Concurrency Control` 的并发控制测试。当前阶段只定义测试范围、模块划分、覆盖矩阵和后续用例展开方向，不展开逐条 SQL 步骤。

测试目标：

- 覆盖官方文档 Chapter 13 提到的全部并发控制行为。
- 验证多会话并发访问下的数据可见性、隔离性、锁冲突、错误码和一致性保证。
- 为后续自动化并发测试、手工复现脚本、压力测试和回归测试提供稳定的模块边界。

来源文档：

- PostgreSQL 16.4 官方文档 PDF（仓库外部资料，文件名可记录为 `j2ul-2965-02enz0.pdf`）
- PostgreSQL 16.4 Documentation
- `Chapter 13. Concurrency Control`
- 文档页码：486-501

## 2. 优化后的模块划分原则

当前设计不再完全按官方小节机械拆分，而是按“测试意图”分层。这样可以减少重复，也更方便后续落到用例。

划分原则：

- 官方章节负责覆盖追踪，测试模块负责用例组织。
- `13.2` 中的隔离级别语义、DML 并发行为、Serializable SSI 行为拆成不同测试模块，避免一个模块过大。
- `13.4` 应用层一致性不再重复描述 Read Committed / Repeatable Read / Serializable 的基础行为，只测试业务一致性策略。
- `13.5` 只负责错误码与重试策略，不重复触发 serialization failure 的所有场景。
- `13.3` 锁相关行为集中为一个显式锁模块，再按表锁、行锁、页锁、死锁、Advisory Lock 分子域。
- `13.6` 和 `13.7` 保持为专项模块，因为它们分别依赖 DDL/复制/catalog 环境和索引类型环境。

## 3. 官方章节覆盖清单

必须覆盖的小节：

- `13.1 Introduction`
- `13.2 Transaction Isolation`
- `13.2.1 Read Committed Isolation Level`
- `13.2.2 Repeatable Read Isolation Level`
- `13.2.3 Serializable Isolation Level`
- `13.3 Explicit Locking`
- `13.3.1 Table-Level Locks`
- `13.3.2 Row-Level Locks`
- `13.3.3 Page-Level Locks`
- `13.3.4 Deadlocks`
- `13.3.5 Advisory Locks`
- `13.4 Data Consistency Checks at the Application Level`
- `13.4.1 Enforcing Consistency with Serializable Transactions`
- `13.4.2 Enforcing Consistency with Explicit Blocking Locks`
- `13.5 Serialization Failure Handling`
- `13.6 Caveats`
- `13.7 Locking and Indexes`

## 4. 测试总体模型

测试按“多会话可控调度”设计，每个并发测试至少包含两个或更多数据库会话：

- `S1`, `S2`, `S3`: 并发事务会话。
- `OBS`: 观测会话，用于查询 `pg_locks`、等待状态、错误码和最终数据。
- `DDL`: 必要时用于 `TRUNCATE`、`ALTER TABLE` rewrite、`CREATE INDEX` 等并发 DDL 场景。

每个详细用例后续应明确：

- 初始表结构和数据。
- 会话数量、隔离级别、事务边界。
- 每个会话的执行时序和同步点。
- 期望阻塞、等待、成功、失败或回滚行为。
- 期望 SQLSTATE、错误消息类别和最终数据状态。
- 是否检查 `pg_locks`、锁模式、等待状态、system catalog 可见性。

## 5. 测试模块

### M1. MVCC 与基础快照模型

覆盖官方章节：

- `13.1 Introduction`

测试范围：

- 每条 SQL 语句看到某个时间点的数据快照。
- 并发更新同一数据行时，不应读取到不一致中间状态。
- 普通读写在 MVCC 下互不阻塞：读不阻塞写，写不阻塞读。
- MVCC 与显式锁的使用边界。
- Advisory Lock 作为应用定义锁，不绑定单个普通数据行。

用例组：

- `MVCC-SNAPSHOT-VISIBILITY`
- `MVCC-READ-WRITE-NONBLOCKING`
- `MVCC-LOCKING-BOUNDARY`

### M2. 隔离级别矩阵与异常现象

覆盖官方章节：

- `13.2 Transaction Isolation`

测试范围：

- Dirty read、nonrepeatable read、phantom read、serialization anomaly 四类现象。
- `READ UNCOMMITTED` 在 PostgreSQL 中表现为 `READ COMMITTED`。
- `READ COMMITTED`、`REPEATABLE READ`、`SERIALIZABLE` 对四类现象的禁止或允许关系。
- PostgreSQL `REPEATABLE READ` 不出现 phantom read，强于 SQL 标准最低要求。
- `SET TRANSACTION` 对事务隔离级别的设置。
- Sequence 或 `serial` 计数器变化立即对其他事务可见，且事务 abort 后不回滚。

用例组：

- `ISO-PHENOMENA-MATRIX`
- `ISO-READ-UNCOMMITTED-MAPPING`
- `ISO-SET-TRANSACTION`
- `ISO-SEQUENCE-NONTRANSACTIONAL`

### M3. Read Committed 与语句级快照

覆盖官方章节：

- `13.2.1 Read Committed Isolation Level`

测试范围：

- 默认隔离级别为 `READ COMMITTED`。
- 普通 `SELECT` 只看到查询开始前已提交的数据。
- 同一事务内连续 `SELECT` 可看到不同快照。
- `UPDATE`、`DELETE`、`SELECT FOR UPDATE`、`SELECT FOR SHARE` 搜索目标行时使用命令开始时的快照。
- 目标行被并发事务更新后，等待结束后重新检查 `WHERE` 条件并基于更新后的行版本继续。
- 复杂搜索条件下，单条更新命令可能看到不一致快照。
- `INSERT ... ON CONFLICT DO UPDATE` 在 Read Committed 下每行保证插入或更新之一发生。
- `INSERT ... ON CONFLICT DO NOTHING` 可能因不可见并发事务结果跳过插入。
- `MERGE` 并发更新时重新评估 action 条件，但不提供与 `ON CONFLICT DO UPDATE` 相同的保证。

用例组：

- `RC-STATEMENT-SNAPSHOT`
- `RC-UPDATE-RECHECK`
- `RC-COMPLEX-PREDICATE`
- `RC-ON-CONFLICT`
- `RC-MERGE`

### M4. Repeatable Read 与事务级快照

覆盖官方章节：

- `13.2.2 Repeatable Read Isolation Level`

测试范围：

- 事务快照固定在第一个非事务控制语句开始时。
- 同一事务内连续查询看到稳定视图。
- 不看到事务开始后其他事务提交的变更。
- 并发事务修改或删除目标行后，当前事务执行 `UPDATE`、`DELETE`、`MERGE`、`SELECT FOR UPDATE`、`SELECT FOR SHARE` 应失败。
- 失败消息覆盖 `could not serialize access due to concurrent update`。
- 只读事务不会产生 serialization conflicts。
- Repeatable Read 是 Snapshot Isolation，稳定视图不必然等价于某个串行执行顺序。

用例组：

- `RR-TRANSACTION-SNAPSHOT`
- `RR-CONCURRENT-UPDATE-FAILURE`
- `RR-READONLY-NO-CONFLICT`
- `RR-SNAPSHOT-NOT-SERIAL`

### M5. Serializable 与 SSI

覆盖官方章节：

- `13.2.3 Serializable Isolation Level`

测试范围：

- 成功提交的 Serializable 并发事务结果应等价于某个串行顺序。
- Serializable 基于 Repeatable Read，并额外监控可能导致 serialization anomaly 的危险读写依赖。
- 聚合读后写、write skew 等模式应触发其中一个事务回滚。
- 错误 SQLSTATE 覆盖 `40001`。
- Predicate locking 在 `pg_locks` 中以 `SIReadLock` 出现。
- Predicate locks 不造成阻塞，不参与死锁。
- `SERIALIZABLE READ ONLY DEFERRABLE` 会等待安全快照。
- READ ONLY 事务在安全条件下可减少或释放 predicate locks。
- SIRead locks 可能在事务提交后保留，直到重叠读写事务完成。
- 并发 Serializable 下可能出现 unique constraint violation，需要协议化避免。
- 性能建议需覆盖：`READ ONLY`、连接数控制、事务最小化、避免 `idle in transaction`、去除不必要显式锁、predicate lock 参数、顺序扫描可能增加 relation-level predicate lock。

用例组：

- `SER-WRITE-SKEW`
- `SER-SI-READ-LOCK`
- `SER-READ-ONLY-DEFERRABLE`
- `SER-UNIQUE-VIOLATION`
- `SER-PERFORMANCE-OBSERVABILITY`

### M6. 显式锁与等待行为

覆盖官方章节：

- `13.3 Explicit Locking`
- `13.3.1 Table-Level Locks`
- `13.3.2 Row-Level Locks`
- `13.3.3 Page-Level Locks`
- `13.3.4 Deadlocks`
- `13.3.5 Advisory Locks`

测试范围：

- `pg_locks` 可观测当前锁。
- 显式 `LOCK` 获取表锁。
- 八种表级锁模式及冲突矩阵：
  - `ACCESS SHARE`
  - `ROW SHARE`
  - `ROW EXCLUSIVE`
  - `SHARE UPDATE EXCLUSIVE`
  - `SHARE`
  - `SHARE ROW EXCLUSIVE`
  - `EXCLUSIVE`
  - `ACCESS EXCLUSIVE`
- 自动获取表锁的命令：
  - `SELECT` 获取 `ACCESS SHARE`
  - `SELECT ... FOR UPDATE/NO KEY UPDATE/SHARE/KEY SHARE` 获取 `ROW SHARE`
  - `INSERT`、`UPDATE`、`DELETE`、`MERGE` 获取 `ROW EXCLUSIVE`
  - `VACUUM`、`ANALYZE`、`CREATE INDEX CONCURRENTLY` 等获取 `SHARE UPDATE EXCLUSIVE`
  - `CREATE INDEX` 非 concurrently 获取 `SHARE`
  - `CREATE TRIGGER` 和部分 `ALTER TABLE` 获取 `SHARE ROW EXCLUSIVE`
  - `REFRESH MATERIALIZED VIEW CONCURRENTLY` 获取 `EXCLUSIVE`
  - `DROP TABLE`、`TRUNCATE`、`REINDEX`、`CLUSTER`、`VACUUM FULL`、非 concurrently refresh、许多 `ALTER TABLE/INDEX` 获取 `ACCESS EXCLUSIVE`
- 只有 `ACCESS EXCLUSIVE` 会阻塞普通 `SELECT`。
- 锁通常持有到事务结束，savepoint rollback 会释放 savepoint 后获取的锁。
- 四种行级锁模式及冲突矩阵：
  - `FOR UPDATE`
  - `FOR NO KEY UPDATE`
  - `FOR SHARE`
  - `FOR KEY SHARE`
- 行级锁只阻塞同一行上的写入和加锁，不影响普通查询。
- `DELETE` 和修改特定 key 列的 `UPDATE` 获取 `FOR UPDATE`。
- 不修改 key 的 `UPDATE` 获取 `FOR NO KEY UPDATE`。
- `FOR SHARE` 和 `FOR KEY SHARE` 的冲突差异。
- Row lock 数量没有内存记录上限，但加锁可能导致磁盘写入。
- Page-level locks 用于 shared buffer pool 中表页读写访问控制，获取或更新行后立即释放。
- 表锁和行锁死锁检测，SQLSTATE 覆盖 `40P01`。
- 避免死锁策略：多对象固定顺序加锁，首个锁使用所需最严格模式。
- 未检测到死锁时，锁等待可能无限期持续。
- Advisory locks 的 session-level、transaction-level、重复获取、释放语义、`pg_locks` 可见性、共享内存限制。
- Advisory lock 函数与 `ORDER BY` / `LIMIT` 查询求值顺序风险。

用例组：

- `LOCK-TABLE-MATRIX`
- `LOCK-TABLE-AUTO-MODES`
- `LOCK-TABLE-SAVEPOINT`
- `LOCK-ROW-MATRIX`
- `LOCK-ROW-KEY-UPDATE`
- `LOCK-PAGE-OBSERVABILITY`
- `LOCK-DEADLOCK`
- `LOCK-ADVISORY`

### M7. 应用层一致性策略

覆盖官方章节：

- `13.4 Data Consistency Checks at the Application Level`
- `13.4.1 Enforcing Consistency with Serializable Transactions`
- `13.4.2 Enforcing Consistency with Explicit Blocking Locks`

测试范围：

- Read Committed 下视图随语句变化，业务一致性检查不可靠。
- Repeatable Read 有稳定视图，但 read/write conflict 可导致业务检查不成立。
- 全部相关读写使用 Serializable 时，可依赖事务成功提交来保证业务一致性。
- 应用框架应自动重试 serialization failure。
- 可通过 `default_transaction_isolation=serializable` 和触发器检查防止误用其他隔离级别。
- Serializable 一致性保护不扩展到 hot standby 或 logical replica。
- 非 Serializable 写存在时，需要 `SELECT FOR UPDATE`、`SELECT FOR SHARE` 或 `LOCK TABLE`。
- `SELECT FOR UPDATE` 只在持锁期间暂时阻塞；提交或回滚后，等待事务可继续执行冲突操作。
- 如需确保一行不会被后续事务更新或删除，应实际更新该行，即使值不变。
- 全局一致性检查可能需要锁定所有相关表，`SHARE` 或更高锁可确保除当前事务外无未提交变更。
- Repeatable Read 下依赖显式锁时，应在快照冻结前获取锁。

用例组：

- `APP-CHECK-RC-UNSAFE`
- `APP-CHECK-RR-SNAPSHOT-LIMIT`
- `APP-CHECK-SERIALIZABLE`
- `APP-CHECK-BLOCKING-LOCKS`
- `APP-CHECK-REPLICA-LIMIT`

### M8. 错误处理与重试策略

覆盖官方章节：

- `13.5 Serialization Failure Handling`

测试范围：

- Repeatable Read 和 Serializable 均可能产生防止 serialization anomaly 的错误。
- `serialization_failure` SQLSTATE 为 `40001`，应无条件重试完整事务。
- Deadlock SQLSTATE 为 `40P01`，建议纳入重试策略。
- 某些 `unique_violation` SQLSTATE `23505` 和 `exclusion_violation` SQLSTATE `23P01` 可视场景谨慎重试。
- 重试必须包含决定 SQL 和决定值的全部事务逻辑。
- PostgreSQL 不提供自动重试能力。
- 高竞争下可能需要多次重试。
- 与 prepared transaction 冲突时，可能直到 prepared transaction commit 或 rollback 后才有进展。

用例组：

- `RETRY-40001`
- `RETRY-40P01`
- `RETRY-23505`
- `RETRY-23P01`
- `RETRY-WHOLE-TRANSACTION`
- `RETRY-PREPARED-TRANSACTION`

### M9. Caveats 与环境限制

覆盖官方章节：

- `13.6 Caveats`

测试范围：

- `TRUNCATE` 和表重写形式的 `ALTER TABLE` 不是 MVCC-safe。
- DDL commit 后，对使用旧快照且之前未访问该表的并发事务，该表可能表现为空。
- 若并发事务之前访问过目标表，其 `ACCESS SHARE` 表锁会阻塞相关 DDL。
- 这类 DDL 可能造成目标表与数据库中其他表之间的可见性不一致。
- Hot standby 上尚不支持 Serializable；最严格为 Repeatable Read。
- Primary 上 Serializable 写可最终让 standby 达到一致状态，但 standby 上 Repeatable Read 事务可能看到不对应任何 primary 串行执行的瞬时状态。
- 内部访问 system catalogs 不使用当前事务隔离级别。
- 新建数据库对象对并发 Repeatable Read 和 Serializable 事务可见，但其中数据行不可见。
- 显式查询 system catalogs 在高隔离级别下看不到并发创建对象对应的 catalog rows。

用例组：

- `CAVEAT-TRUNCATE-MVCC`
- `CAVEAT-ALTER-REWRITE-MVCC`
- `CAVEAT-HOT-STANDBY`
- `CAVEAT-SYSTEM-CATALOG`

### M10. 索引访问方法并发行为

覆盖官方章节：

- `13.7 Locking and Indexes`

测试范围：

- PostgreSQL 表数据支持非阻塞读写访问，但不是所有索引访问方法都提供同等非阻塞读写访问。
- B-tree、GiST、SP-GiST 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放，提供最高并发且无 deadlock 条件。
- Hash indexes 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放；比 index-level 并发更好，但可能死锁。
- GIN 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放；单个 GIN-indexed value 插入通常产生多个 index key insertions。
- 并发应用中 scalar data 推荐 B-tree。
- 非 scalar data 应使用 GiST、SP-GiST 或 GIN。

用例组：

- `IDX-BTREE-GIST-SPGIST`
- `IDX-HASH-DEADLOCK-RISK`
- `IDX-GIN-MULTI-KEY-WORK`
- `IDX-INDEX-TYPE-RECOMMENDATION`

## 6. 去重与边界说明

本轮优化后，重复内容按以下方式收敛：

- 隔离级别异常矩阵只放在 `M2`，各隔离级别模块只描述本级别特有行为。
- `40001` 的触发场景放在 `M4`、`M5`，完整重试策略放在 `M8`。
- 业务一致性问题放在 `M7`，不再在 `M4` 中重复展开应用层策略。
- 表锁、行锁、页锁、死锁、Advisory Lock 合并到 `M6`，避免多个锁模块之间重复描述 `pg_locks`、等待和 savepoint 规则。
- Hot standby / logical replica 限制在 `M7` 中作为应用一致性的限制出现，在 `M9` 中作为环境 caveat 覆盖，后续详细用例可共用同一环境。
- 索引锁行为独立为 `M10`，不混入页级锁模块，因为它需要不同索引类型环境。

## 7. 覆盖矩阵

| 官方章节 | 主要测试模块 | 辅助模块 | 优先级 |
|---|---|---|---:|
| 13.1 | M1 MVCC 与基础快照模型 | M6 显式锁与等待行为 | P0 |
| 13.2 | M2 隔离级别矩阵与异常现象 | M3/M4/M5 | P0 |
| 13.2.1 | M3 Read Committed 与语句级快照 | M8 错误处理与重试策略 | P0 |
| 13.2.2 | M4 Repeatable Read 与事务级快照 | M8 错误处理与重试策略 | P0 |
| 13.2.3 | M5 Serializable 与 SSI | M8 错误处理与重试策略 | P0 |
| 13.3 | M6 显式锁与等待行为 | M1 MVCC 与基础快照模型 | P0 |
| 13.3.1 | M6 显式锁与等待行为 | 无 | P0 |
| 13.3.2 | M6 显式锁与等待行为 | M4/M5 | P0 |
| 13.3.3 | M6 显式锁与等待行为 | M10 索引访问方法并发行为 | P2 |
| 13.3.4 | M6 显式锁与等待行为 | M8 错误处理与重试策略 | P0 |
| 13.3.5 | M6 显式锁与等待行为 | 无 | P1 |
| 13.4 | M7 应用层一致性策略 | M5/M6/M8 | P0 |
| 13.4.1 | M7 应用层一致性策略 | M5 Serializable 与 SSI | P0 |
| 13.4.2 | M7 应用层一致性策略 | M6 显式锁与等待行为 | P0 |
| 13.5 | M8 错误处理与重试策略 | M4/M5/M6 | P0 |
| 13.6 | M9 Caveats 与环境限制 | M7 应用层一致性策略 | P1 |
| 13.7 | M10 索引访问方法并发行为 | M6 显式锁与等待行为 | P1 |

## 8. 测试基建规划

建议后续测试框架具备：

- 多连接会话编排能力：可精确控制 `BEGIN`、隔离级别、锁获取、阻塞点、commit/rollback 顺序。
- 阻塞检测能力：支持超时、等待状态查询、`pg_locks` 快照采集。
- 错误码采集能力：必须记录 SQLSTATE，例如 `40001`、`40P01`、`23505`、`23P01`。
- 数据一致性断言：支持最终数据、事务可见性、业务不变量、对象可见性断言。
- DDL 并发控制：支持 `TRUNCATE`、`ALTER TABLE` rewrite、`LOCK TABLE`、`CREATE INDEX` 等阻塞场景。
- 重试框架：支持完整事务级重试，不只重试最后一条 SQL。
- 环境分层：基础单实例、多连接测试为主；hot standby、logical replica、prepared transaction、索引专项作为扩展环境。
- 可重复运行：每个用例有独立 schema 或自动清理机制，避免锁和 advisory lock 泄漏。
- 观测日志：每个会话 SQL、时间点、等待事件、错误码和最终断言应可追踪。

## 9. 后续用例展开顺序

建议按以下顺序展开详细测试：

1. `M1`、`M2`、`M3`：先建立 MVCC、隔离级别和 Read Committed 基础模型。
2. `M4`、`M5`、`M8`：覆盖事务级快照、SSI 和重试框架。
3. `M6`：完善表锁、行锁、死锁、Advisory Lock 和锁观测能力。
4. `M7`：构造业务不变量和应用层一致性场景。
5. `M9`：补齐 DDL、catalog、standby、replica 等 caveat。
6. `M10`：加入索引访问方法专项。

## 10. 当前阶段不展开的细节

本框架暂不展开：

- 具体 SQL 脚本。
- 每个会话的逐步执行时序。
- 自动化框架选型。
- 性能指标阈值。
- hot standby / logical replica 的环境搭建方式。

这些内容应在下一阶段基于本框架拆成详细测试用例设计。
