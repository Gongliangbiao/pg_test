# PostgreSQL 16.4 Chapter 13 Concurrency Control 测试设计框架

## 1. 设计目标

本测试设计覆盖 PostgreSQL 16.4 官方文档 `Chapter 13. Concurrency Control` 中提到的并发控制行为。当前阶段只定义测试范围、测试域、覆盖矩阵和后续用例拆分方向，不展开具体 SQL 步骤。

测试目标：

- 验证 PostgreSQL 在多会话并发访问同一数据时的数据一致性、隔离性和锁行为。
- 覆盖官方文档 Chapter 13 提到的所有主题，包括 MVCC、事务隔离、显式锁、应用层一致性检查、序列化失败处理、并发 caveats、索引锁行为。
- 为后续编写自动化并发测试、手工复现脚本、压力/稳定性测试提供统一规划。

## 2. 官方文档覆盖范围

来源文档：

- `/Users/gongliangbiao/pg文档/j2ul-2965-02enz0.pdf`
- PostgreSQL 16.4 Documentation
- `Chapter 13. Concurrency Control`
- 文档页码：486-501

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

## 3. 测试总体模型

测试按“多会话可控调度”设计，每个测试至少包含两个或更多数据库会话：

- `S1`, `S2`, `S3`: 并发事务会话。
- `OBS`: 观测会话，用于查询 `pg_locks`、事务状态、等待关系、错误码和最终数据。
- `DDL`: 必要时单独用于并发 DDL、TRUNCATE、ALTER TABLE rewrite 等场景。

每个测试用例后续应明确：

- 初始表结构和数据。
- 会话数量和事务隔离级别。
- 每个会话的执行时序。
- 期望阻塞、等待、成功、失败或回滚行为。
- 期望 SQLSTATE、错误消息类别或最终数据状态。
- 是否需要检查 `pg_locks`、锁模式、等待状态、系统 catalog 可见性。

## 4. 测试域划分

### 4.1 MVCC 基础行为

覆盖官方 `13.1 Introduction`。

测试点：

- 每条 SQL 语句看到的是某个时间点的数据快照。
- 读不阻塞写，写不阻塞读。
- 并发更新同一数据行时，事务隔离保证不会读取不一致中间状态。
- MVCC 与显式锁的使用边界。
- Advisory lock 不绑定单个普通数据行的应用定义锁语义。

产出用例组：

- `MVCC-SNAPSHOT`
- `MVCC-READ-WRITE-NONBLOCKING`
- `MVCC-EXPLICIT-LOCK-COMPARISON`

### 4.2 事务隔离级别与异常现象

覆盖官方 `13.2 Transaction Isolation` 和 Table 13.1。

测试点：

- Dirty read、nonrepeatable read、phantom read、serialization anomaly 四类现象。
- `READ UNCOMMITTED` 在 PostgreSQL 中等价表现为 `READ COMMITTED`。
- `READ COMMITTED` 禁止 dirty read，但允许 nonrepeatable read、phantom read、serialization anomaly。
- `REPEATABLE READ` 禁止 dirty read、nonrepeatable read，并且 PostgreSQL 中不出现 phantom read，但仍可能出现 serialization anomaly。
- `SERIALIZABLE` 禁止以上全部异常，但需要处理 serialization failure。
- `SET TRANSACTION` 对隔离级别设置的覆盖。
- Sequence 或 `serial` 计数器变化立即对其他事务可见，且事务 abort 后不回滚。

产出用例组：

- `ISO-MATRIX`
- `ISO-READ-UNCOMMITTED-AS-READ-COMMITTED`
- `ISO-SEQUENCE-VISIBILITY`

### 4.3 Read Committed 行为

覆盖官方 `13.2.1 Read Committed Isolation Level`。

测试点：

- 默认隔离级别为 `READ COMMITTED`。
- 普通 `SELECT` 只看到查询开始前已提交数据。
- 同一事务内连续 `SELECT` 可看到不同快照。
- `UPDATE`、`DELETE`、`SELECT FOR UPDATE`、`SELECT FOR SHARE` 对目标行的搜索、等待和条件重判定。
- 并发更新后，第二个更新事务基于更新后的行版本继续执行。
- `INSERT ... ON CONFLICT DO UPDATE` 在 Read Committed 下保证每行插入或更新之一发生。
- `INSERT ... ON CONFLICT DO NOTHING` 可能因不可见的并发事务结果而跳过插入。
- `MERGE` 并发更新时重新评估 action 条件，但不等价于 `ON CONFLICT DO UPDATE` 的保证。
- 复杂搜索条件下，单条更新命令可能看到不一致快照。

产出用例组：

- `RC-SNAPSHOT-PER-STATEMENT`
- `RC-UPDATE-RECHECK`
- `RC-ON-CONFLICT`
- `RC-MERGE-CONCURRENCY`
- `RC-COMPLEX-PREDICATE-ANOMALY`

### 4.4 Repeatable Read 行为

覆盖官方 `13.2.2 Repeatable Read Isolation Level`。

测试点：

- 事务快照固定在第一个非事务控制语句开始时。
- 同一事务内连续查询看到稳定视图。
- 不看到事务开始后其他事务提交的变更。
- 并发事务修改或删除目标行后，当前事务尝试 `UPDATE`、`DELETE`、`MERGE`、`SELECT FOR UPDATE`、`SELECT FOR SHARE` 应产生 serialization failure。
- 只读事务不会产生 serialization conflicts。
- Repeatable Read 是 Snapshot Isolation；其稳定视图不必然等价于某个串行执行顺序。
- 使用 Repeatable Read 做业务一致性检查时，需要谨慎使用显式锁。

产出用例组：

- `RR-STABLE-SNAPSHOT`
- `RR-CONCURRENT-UPDATE-FAILURE`
- `RR-READONLY-NO-CONFLICT`
- `RR-BUSINESS-RULE-LIMITATION`

### 4.5 Serializable 与 SSI

覆盖官方 `13.2.3 Serializable Isolation Level`。

测试点：

- Serializable 提供最严格隔离，成功提交结果应等价于某个串行顺序。
- Serializable 与 Repeatable Read 基础行为类似，但额外监控可能导致 serialization anomaly 的危险读写依赖。
- 典型 write skew / 聚合读后写场景应回滚其中一个事务。
- 错误 SQLSTATE 为 `40001`。
- Predicate locking 使用 `SIReadLock` 出现在 `pg_locks`。
- Predicate locks 不造成阻塞，不参与死锁。
- `SERIALIZABLE READ ONLY DEFERRABLE` 可等待安全快照。
- READ ONLY 事务在安全条件下可减少或释放 predicate locks。
- SIRead locks 可能在事务提交后保留，直到重叠读写事务完成。
- 可能出现并发 Serializable 下的 unique constraint violation，需要协议化避免。
- 性能建议覆盖：READ ONLY、连接数控制、事务最小化、避免 idle in transaction、去除不必要显式锁、predicate lock 参数、顺序扫描可能增加 relation-level predicate lock。

产出用例组：

- `SER-WRITE-SKEW`
- `SER-SI-READ-LOCK`
- `SER-READ-ONLY-DEFERRABLE`
- `SER-UNIQUE-VIOLATION`
- `SER-PERFORMANCE-OBSERVABILITY`

### 4.6 显式表级锁

覆盖官方 `13.3.1 Table-Level Locks` 和 Table 13.2。

测试点：

- `LOCK` 显式获取表锁。
- `pg_locks` 可观测当前锁。
- 八种表级锁模式及冲突关系：
  - `ACCESS SHARE`
  - `ROW SHARE`
  - `ROW EXCLUSIVE`
  - `SHARE UPDATE EXCLUSIVE`
  - `SHARE`
  - `SHARE ROW EXCLUSIVE`
  - `EXCLUSIVE`
  - `ACCESS EXCLUSIVE`
- `SELECT` 获取 `ACCESS SHARE`。
- `SELECT ... FOR UPDATE/NO KEY UPDATE/SHARE/KEY SHARE` 获取 `ROW SHARE`。
- `INSERT`、`UPDATE`、`DELETE`、`MERGE` 获取 `ROW EXCLUSIVE`。
- `VACUUM`、`ANALYZE`、`CREATE INDEX CONCURRENTLY` 等获取 `SHARE UPDATE EXCLUSIVE`。
- `CREATE INDEX` 非 concurrently 获取 `SHARE`。
- `CREATE TRIGGER` 和部分 `ALTER TABLE` 获取 `SHARE ROW EXCLUSIVE`。
- `REFRESH MATERIALIZED VIEW CONCURRENTLY` 获取 `EXCLUSIVE`。
- `DROP TABLE`、`TRUNCATE`、`REINDEX`、`CLUSTER`、`VACUUM FULL`、非 concurrently refresh、许多 `ALTER TABLE/INDEX` 获取 `ACCESS EXCLUSIVE`。
- 只有 `ACCESS EXCLUSIVE` 会阻塞普通 `SELECT`。
- 锁通常持有到事务结束；savepoint rollback 会释放 savepoint 后获取的锁。

产出用例组：

- `TLOCK-MODE-ACQUISITION`
- `TLOCK-CONFLICT-MATRIX`
- `TLOCK-ACCESS-EXCLUSIVE-BLOCKS-SELECT`
- `TLOCK-SAVEPOINT-RELEASE`

### 4.7 行级锁

覆盖官方 `13.3.2 Row-Level Locks` 和 Table 13.3。

测试点：

- 行级锁只阻塞同一行上的写入和加锁，不影响普通查询。
- 四种行级锁模式及冲突关系：
  - `FOR UPDATE`
  - `FOR NO KEY UPDATE`
  - `FOR SHARE`
  - `FOR KEY SHARE`
- `DELETE` 获取 `FOR UPDATE` 行锁。
- 修改特定 key 列的 `UPDATE` 获取 `FOR UPDATE`。
- 不修改 key 的 `UPDATE` 获取 `FOR NO KEY UPDATE`。
- `FOR SHARE` 阻塞 `UPDATE`、`DELETE`、`FOR UPDATE`、`FOR NO KEY UPDATE`。
- `FOR KEY SHARE` 阻塞 `DELETE` 和修改 key 的 `UPDATE`，但不阻塞普通非 key update。
- Repeatable Read 或 Serializable 下，待锁行在事务开始后被改变时应报错。
- 行锁数量无内存记录上限，但加锁可能造成磁盘写入。
- savepoint rollback 释放之后获取的行锁。

产出用例组：

- `RLOCK-MODE-CONFLICT`
- `RLOCK-QUERY-NONBLOCKING`
- `RLOCK-KEY-UPDATE`
- `RLOCK-SAVEPOINT-RELEASE`
- `RLOCK-DISK-WRITE-OBSERVATION`

### 4.8 页级锁

覆盖官方 `13.3.3 Page-Level Locks`。

测试点：

- 共享/排他页级锁用于 shared buffer pool 中表页读写访问控制。
- 页级锁在行被获取或更新后立即释放。
- 应作为观测性/完整性测试点，不作为应用可直接控制锁接口。

产出用例组：

- `PLOCK-OBSERVABILITY`

### 4.9 死锁

覆盖官方 `13.3.4 Deadlocks`。

测试点：

- 表锁死锁：两个事务以相反顺序锁定表。
- 行锁死锁：两个事务以相反顺序更新不同账户行。
- PostgreSQL 自动检测死锁，并 abort 其中一个事务。
- 不应依赖哪个事务被 abort。
- SQLSTATE 应覆盖 `40P01`。
- 避免死锁的策略：多对象按固定顺序加锁；首个锁应使用所需最严格模式。
- 未检测到死锁时，表级或行级锁等待可能无限期持续。
- 长事务和用户交互期间持锁风险。

产出用例组：

- `DEADLOCK-TABLE`
- `DEADLOCK-ROW`
- `DEADLOCK-ORDERING-PREVENTION`
- `DEADLOCK-LONG-WAIT`

### 4.10 Advisory Locks

覆盖官方 `13.3.5 Advisory Locks`。

测试点：

- Advisory lock 由应用定义含义，系统不强制业务使用。
- 可模拟悲观锁策略。
- Session-level advisory lock 持有到显式释放或会话结束。
- Session-level advisory lock 不遵守事务语义：rollback 后仍持有；unlock 即使事务后续失败也生效。
- Transaction-level advisory lock 事务结束自动释放，无显式 unlock。
- 同一 advisory lock identifier 的 session-level 和 transaction-level 请求互相阻塞。
- 同一会话重复获取同一 advisory lock 总是成功，但需要对应次数释放。
- `pg_locks` 可观测 advisory locks。
- Advisory lock 与 regular lock 共享由 `max_locks_per_transaction` 和 `max_connections` 决定的共享内存池。
- 使用 advisory lock 函数时，`ORDER BY` / `LIMIT` 场景存在 SQL 表达式求值顺序风险。

产出用例组：

- `ADVLOCK-SESSION`
- `ADVLOCK-TRANSACTION`
- `ADVLOCK-REENTRANT`
- `ADVLOCK-MEMORY-LIMIT`
- `ADVLOCK-LIMIT-EVALUATION`

### 4.11 应用层一致性检查

覆盖官方 `13.4 Data Consistency Checks at the Application Level`。

测试点：

- Read Committed 下视图随语句变化，难以可靠执行业务一致性检查。
- Repeatable Read 有稳定视图，但 read/write conflict 可导致业务检查不成立。
- Serializable 通过非阻塞监控危险读写依赖并回滚事务来破坏异常循环。
- 所有需要一致视图的读写均使用 Serializable 时，应用层可减少额外锁控制。
- 应用框架应自动重试 serialization failure。
- 可通过 `default_transaction_isolation=serializable` 和触发器检查防止误用其他隔离级别。
- Serializable 一致性保护不扩展到 hot standby 或 logical replica。
- 非 Serializable 写存在时，需要 `SELECT FOR UPDATE`、`SELECT FOR SHARE` 或 `LOCK TABLE`。
- `SELECT FOR UPDATE` 只在持锁期间暂时阻塞，提交/回滚后不能永久阻止其他事务更新或删除；如需确保，应实际更新该行。
- 全局一致性检查可能需要锁定所有相关表，`SHARE` 或更高锁可确保除当前事务外无未提交变更。
- Repeatable Read 下依赖显式锁时，应在快照冻结前获取锁。

产出用例组：

- `APPCHK-RC-UNRELIABLE`
- `APPCHK-RR-RW-CONFLICT`
- `APPCHK-SERIALIZABLE`
- `APPCHK-EXPLICIT-LOCK`
- `APPCHK-REPLICATION-LIMITATION`

### 4.12 序列化失败与重试

覆盖官方 `13.5 Serialization Failure Handling`。

测试点：

- Repeatable Read 和 Serializable 均可能产生防止 serialization anomaly 的错误。
- `serialization_failure` SQLSTATE 为 `40001`，应无条件重试完整事务。
- Deadlock SQLSTATE 为 `40P01`，建议纳入重试策略。
- 某些 `unique_violation` SQLSTATE `23505` 和 `exclusion_violation` SQLSTATE `23P01` 可视场景谨慎重试。
- 重试必须包含决定 SQL 和决定值的全部事务逻辑。
- PostgreSQL 不提供自动重试能力。
- 高竞争下可能需要多次重试。
- 与 prepared transaction 冲突时，可能直到 prepared transaction commit 或 rollback 后才有进展。

产出用例组：

- `RETRY-40001`
- `RETRY-40P01`
- `RETRY-23505-23P01`
- `RETRY-WHOLE-TRANSACTION`
- `RETRY-PREPARED-TRANSACTION`

### 4.13 Caveats

覆盖官方 `13.6 Caveats`。

测试点：

- `TRUNCATE` 和表重写形式的 `ALTER TABLE` 不是 MVCC-safe。
- DDL commit 后，对使用旧快照且之前未访问该表的并发事务，该表可能表现为空。
- 若并发事务之前访问过目标表，其 `ACCESS SHARE` 表锁会阻塞相关 DDL。
- 这类 DDL 可能造成目标表与数据库中其他表之间的可见性不一致。
- Hot standby 上尚不支持 Serializable；最严格为 Repeatable Read。
- Primary 上 Serializable 写可最终让 standby 达到一致状态，但 standby 上 Repeatable Read 事务可能看到不对应任何 primary 串行执行的瞬时状态。
- 内部访问 system catalogs 不使用当前事务隔离级别。
- 新建数据库对象对并发 Repeatable Read 和 Serializable 事务可见，但其中数据行不可见。
- 显式查询 system catalogs 在高隔离级别下看不到并发创建对象对应的 catalog rows。

产出用例组：

- `CAVEAT-TRUNCATE-MVCC`
- `CAVEAT-ALTER-REWRITE-MVCC`
- `CAVEAT-HOT-STANDBY`
- `CAVEAT-SYSTEM-CATALOG`

### 4.14 Locking and Indexes

覆盖官方 `13.7 Locking and Indexes`。

测试点：

- PostgreSQL 表数据支持非阻塞读写访问，但不是所有索引访问方法都提供同等非阻塞读写访问。
- B-tree、GiST、SP-GiST 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放，提供最高并发且无 deadlock 条件。
- Hash indexes 使用 hash-bucket-level share/exclusive locks，bucket 处理完释放；比 index-level 并发更好，但可能死锁。
- GIN 使用短期 share/exclusive page-level locks，索引行 fetch 或 insert 后立即释放；但单个 GIN-indexed value 插入通常产生多个 index key insertions。
- 并发应用中 scalar data 推荐 B-tree。
- 非 scalar data 应使用 GiST、SP-GiST 或 GIN。

产出用例组：

- `IDX-BTREE-GIST-SPGIST`
- `IDX-HASH-DEADLOCK-RISK`
- `IDX-GIN-MULTI-KEY-WORK`
- `IDX-RECOMMENDATION-SCALAR-NONSCALAR`

## 5. 覆盖矩阵

| 官方章节 | 测试域 | 优先级 | 自动化建议 |
|---|---|---:|---|
| 13.1 | MVCC 基础行为 | P0 | 多会话 SQL 自动化 |
| 13.2 | 隔离级别矩阵 | P0 | 多会话 SQL 自动化 |
| 13.2.1 | Read Committed | P0 | 多会话 SQL 自动化 |
| 13.2.2 | Repeatable Read | P0 | 多会话 SQL 自动化 |
| 13.2.3 | Serializable / SSI | P0 | 多会话 SQL 自动化 + pg_locks 观测 |
| 13.3.1 | 表级锁 | P0 | 锁冲突矩阵自动化 |
| 13.3.2 | 行级锁 | P0 | 锁冲突矩阵自动化 |
| 13.3.3 | 页级锁 | P2 | 观测性/补充测试 |
| 13.3.4 | 死锁 | P0 | 多会话阻塞编排 |
| 13.3.5 | Advisory locks | P1 | 多会话 SQL 自动化 |
| 13.4 | 应用层一致性 | P0 | 业务不变量场景 |
| 13.5 | 序列化失败处理 | P0 | 错误码与重试框架 |
| 13.6 | Caveats | P1 | DDL/复制/catalog 专项 |
| 13.7 | 索引锁行为 | P1 | 索引类型专项 |

## 6. 测试基建规划

建议后续测试框架具备：

- 多连接会话编排能力：可精确控制 `BEGIN`、锁获取、阻塞点、commit/rollback 顺序。
- 阻塞检测能力：支持超时、等待状态查询、`pg_locks` 快照采集。
- 错误码采集能力：必须记录 SQLSTATE，例如 `40001`、`40P01`、`23505`、`23P01`。
- 数据一致性断言：支持最终数据、事务可见性、业务不变量、对象可见性断言。
- 隔离级别控制：支持每个事务单独设置 isolation level。
- DDL 并发控制：支持 `TRUNCATE`、`ALTER TABLE` rewrite、`LOCK TABLE`、`CREATE INDEX` 等阻塞场景。
- 可重复运行：每个用例有独立 schema 或自动清理机制，避免锁和 advisory lock 泄漏。
- 观测日志：每个会话 SQL、时间点、等待事件、错误码和最终断言应可追踪。

## 7. 后续用例展开顺序

建议按以下顺序展开详细测试：

1. `ISO-*` 与 `MVCC-*`：先建立并发测试基础和快照模型。
2. `TLOCK-*` 与 `RLOCK-*`：完善锁冲突矩阵和阻塞检测。
3. `SER-*` 与 `RETRY-*`：加入错误码、重试和 SSI 观测。
4. `APPCHK-*`：构造业务一致性场景。
5. `DEADLOCK-*` 与 `ADVLOCK-*`：覆盖异常与应用定义锁。
6. `CAVEAT-*` 与 `IDX-*`：补齐 DDL、catalog、replication、index 专项。

## 8. 当前阶段不展开的细节

本框架暂不展开：

- 具体 SQL 脚本。
- 每个会话的逐步执行时序。
- 自动化框架选型。
- 性能指标阈值。
- hot standby / logical replica 的环境搭建方式。

这些内容应在下一阶段基于本框架拆成详细测试用例设计。
