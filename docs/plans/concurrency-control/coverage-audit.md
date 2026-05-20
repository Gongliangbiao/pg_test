# PostgreSQL 16.4 Chapter 13 Concurrency Control 覆盖审查

## 1. 审查结论

审查对象：

- 原文：PostgreSQL 16.4 官方文档 PDF（仓库外部资料，文件名可记录为 `j2ul-2965-02enz0.pdf`）中的 `Chapter 13. Concurrency Control`
- 当前历史用例目录：`docs/archive/concurrency-control-by-official-chapter/`

总体结论：

- 官方章节目录已经完整覆盖：`13.1` 到 `13.7` 及所有子章节均已建目录。
- 当前已有文本用例 `118` 个，主干语义基本覆盖。
- 但如果按“每个测试用例只测单一场景，并证明官方原文相关点都审阅过”的标准，仍存在若干遗漏或合并过粗的测试点。
- 边界值方面已覆盖一部分，例如 `READ UNCOMMITTED` 映射、sequence 非事务性、`40001`、`40P01`、`23505`、`23P01`、advisory lock shared memory、lock timeout、predicate lock escalation 等；但 `RC/RR 等待分支`、`表锁自冲突/非自冲突`、`Serializable 性能配置边界`、`row lock 特殊边界` 还需要补强。

建议动作：

- 不需要推翻当前目录结构。
- 建议在现有官方章节目录下新增或拆分至少 `39` 个独立用例。
- 其中 P0 建议优先补 `24` 个，P1/P2 可作为第二批。

## 2. 当前覆盖情况

| 官方章节 | 当前用例数 | 覆盖判断 |
|---|---:|---|
| 13.1 Introduction | 5 | 主干覆盖完整，无明显必须新增项。 |
| 13.2 Transaction Isolation | 5 | 总体矩阵覆盖完整。 |
| 13.2.1 Read Committed Isolation Level | 13 | 主干覆盖较好，但等待分支和 MERGE 边界仍有遗漏。 |
| 13.2.2 Repeatable Read Isolation Level | 10 | 主干覆盖较好，但 `MERGE`、`SELECT FOR SHARE`、仅锁定未更新等边界遗漏。 |
| 13.2.3 Serializable Isolation Level | 13 | SSI 主链路覆盖较好，但性能建议被合并过粗，部分应用边界缺少独立用例。 |
| 13.3 Explicit Locking | 5 | 总述覆盖较好。 |
| 13.3.1 Table-Level Locks | 9 | 8 类锁模式均有覆盖，但自冲突、默认锁模式、部分自动加锁命令清单覆盖不足。 |
| 13.3.2 Row-Level Locks | 8 | 4 类行锁矩阵覆盖，仍缺少同事务冲突锁、savepoint rollback、无内存数量限制等边界。 |
| 13.3.3 Page-Level Locks | 2 | 覆盖充分。 |
| 13.3.4 Deadlocks | 5 | 覆盖充分。 |
| 13.3.5 Advisory Locks | 7 | 主干覆盖较好，但 session/transaction 同 identifier 互斥和等待队列边界可补。 |
| 13.4 Data Consistency Checks at the Application Level | 11 | 主干覆盖较好，`SELECT FOR SHARE` 和 `LOCK TABLE` 建议拆成更单一场景。 |
| 13.5 Serialization Failure Handling | 9 | 覆盖充分。 |
| 13.6 Caveats | 9 | 覆盖充分。 |
| 13.7 Locking and Indexes | 7 | 主干覆盖较好，但 GiST/SP-GiST 合并，若严格单场景建议拆分。 |

## 3. 建议新增测试点

### 3.1 13.2.1 Read Committed Isolation Level

建议新增 `6` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `RC-OWN-WRITES-VISIBLE` | P0 | `SELECT` sees the effects of previous updates executed within its own transaction | 同一事务内未提交写入对本事务后续 `SELECT` 可见。 |
| `RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED` | P0 | If the first updater rolls back, second updater can proceed | 并发更新同一行时，先更新事务回滚后，等待中的 `UPDATE` 使用原始行继续执行。 |
| `RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE` | P0 | If first updater commits and deleted it, second updater ignores the row | 先事务删除并提交后，等待中的 `UPDATE` 忽略该目标行。 |
| `RC-SELECT-FOR-SHARE-WAIT-RECHECK` | P0 | `SELECT FOR SHARE` 与 `SELECT FOR UPDATE` 同列描述 | `SELECT FOR SHARE` 等待并发更新结束后重新检查目标行。 |
| `RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION` | P0 | If row is concurrently updated or deleted so join condition fails, MERGE evaluates NOT MATCHED actions | `MERGE` 目标行并发删除或更新导致 join condition 失败时，转入 `NOT MATCHED` action 评估。 |
| `RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION` | P0 | If MERGE attempts INSERT and duplicate row is concurrently inserted, uniqueness violation is raised | `MERGE` 并发插入唯一键冲突时，不像 upsert 那样重启匹配评估，而是返回 unique violation。 |

### 3.2 13.2.2 Repeatable Read Isolation Level

建议新增 `6` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `RR-OWN-WRITES-VISIBLE` | P0 | Each query sees effects of previous updates within its own transaction | `REPEATABLE READ` 下本事务前序未提交写入对后续查询可见。 |
| `RR-MERGE-CONCURRENT-UPDATE-40001` | P0 | `UPDATE, DELETE, MERGE, SELECT FOR UPDATE, SELECT FOR SHARE` 同列描述 | `MERGE` 遇到事务开始后已被其他事务更新或删除的目标行时返回 serialization failure。 |
| `RR-SELECT-FOR-SHARE-CONFLICT-40001` | P0 | `SELECT FOR SHARE` 同列描述 | `SELECT FOR SHARE` 遇到事务开始后已被其他事务更新或删除的目标行时返回 `40001`。 |
| `RR-CONCURRENT-LOCK-ONLY-NO-40001` | P0 | If first updater committed and actually updated or deleted the row, not just locked it | 并发事务只锁定目标行但未更新/删除并提交后，`REPEATABLE READ` 事务不应因该锁定本身返回 `40001`。 |
| `RR-FIRST-UPDATER-ROLLBACK-PROCEED` | P0 | If the first updater rolls back, effects are negated and RR transaction can proceed | 等待并发更新时，先事务回滚后，`REPEATABLE READ` 事务继续处理原始目标行。 |
| `RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL` | P1 | read-only transaction may see control record updated but not detail record | 只读 `REPEATABLE READ` 有稳定视图，但可能不对应任何串行执行顺序，不能单独支撑业务一致性。 |

### 3.3 13.2.3 Serializable Isolation Level

建议新增 `8` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `SER-READ-RESULT-VALID-AFTER-COMMIT` | P0 | Data read from permanent user table should not be considered valid until transaction successfully committed | 非 deferrable serializable 事务读取结果只有在事务成功提交后才可作为有效业务判断。 |
| `SER-READONLY-DEFERRABLE-READ-VALID-AT-READ` | P0 | Except deferrable read-only transaction, data is known valid as soon as read | `SERIALIZABLE READ ONLY DEFERRABLE` 取得安全快照后，读取结果在读取时即可视为有效。 |
| `SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION` | P1 | Unique violations can be avoided by ensuring all Serializable transactions check first | 所有可能插入冲突 key 的 serializable 事务都先执行一致的显式检查时，避免原文描述的异常 unique violation 场景。 |
| `SER-PERF-DECLARE-READ-ONLY` | P1 | Declare transactions as READ ONLY when possible | 可声明只读的 serializable 事务应使用 `READ ONLY`，降低 SSI 负担。 |
| `SER-PERF-ACTIVE-CONNECTION-BOUNDARY` | P1 | Control number of active connections, using a connection pool if needed | 高并发 serializable 场景下，控制 active connections 数量是性能边界。 |
| `SER-PERF-SHORT-TRANSACTION-SCOPE` | P1 | Don't put more into a single transaction than needed | Serializable 事务范围越大，冲突监控与重试成本越高，应验证最小事务范围策略。 |
| `SER-PERF-IDLE-IN-TXN-TIMEOUT` | P1 | idle_in_transaction_session_timeout may be used | 长时间 `idle in transaction` 可用 `idle_in_transaction_session_timeout` 自动断开。 |
| `SER-PREDICATE-LOCK-MEMORY-PARAMETERS` | P1 | Increase max_pred_locks_per_transaction/relation/page | predicate lock 内存不足导致粗粒度锁和失败率增加时，相关参数是边界配置。 |

说明：当前已有 `SER-READ-ONLY-PERFORMANCE-SETTING` 和 `SER-PREDICATE-LOCK-ESCALATION-OBSERVE`，但这两个用例更像合并项。若严格单一场景，建议拆成以上独立用例。

### 3.4 13.3.1 Table-Level Locks

建议新增 `7` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `LOCK-TABLE-SAME-TXN-NO-SELF-CONFLICT` | P0 | A transaction never conflicts with itself | 同一事务内先后获取同一表上的冲突模式锁不与自身冲突。 |
| `LOCK-TABLE-SELF-CONFLICT-MULTI-SESSION` | P0 | Some lock modes are self-conflicting | 两个会话不能同时持有自冲突锁模式，例如 `ACCESS EXCLUSIVE`。 |
| `LOCK-TABLE-NON-SELF-CONFLICT-MULTI-SESSION` | P0 | Others are not self-conflicting | 两个会话可同时持有非自冲突锁模式，例如 `ACCESS SHARE`。 |
| `LOCK-TABLE-DEFAULT-MODE-ACCESS-EXCLUSIVE` | P0 | Default lock mode for LOCK TABLE without mode is ACCESS EXCLUSIVE | `LOCK TABLE` 未指定模式时默认获取 `ACCESS EXCLUSIVE`。 |
| `LOCK-TABLE-REFRESH-MVIEW-CONCURRENTLY-EXCLUSIVE` | P1 | `REFRESH MATERIALIZED VIEW CONCURRENTLY` acquires EXCLUSIVE | `REFRESH MATERIALIZED VIEW CONCURRENTLY` 获取 `EXCLUSIVE` 锁。 |
| `LOCK-TABLE-SHARE-UPDATE-EXCLUSIVE-COMMANDS-SPLIT` | P1 | VACUUM/ANALYZE/CREATE INDEX CONCURRENTLY/CREATE STATISTICS/COMMENT/REINDEX CONCURRENTLY | 当前 `SHARE UPDATE EXCLUSIVE` 用例合并了多个命令；建议至少拆出 `VACUUM without FULL`、`ANALYZE`、`CREATE INDEX CONCURRENTLY`、`REINDEX CONCURRENTLY`。 |
| `LOCK-TABLE-ACCESS-EXCLUSIVE-COMMANDS-SPLIT` | P1 | DROP/TRUNCATE/REINDEX/CLUSTER/VACUUM FULL/REFRESH MV without concurrently | 当前只显式覆盖 `DROP/TRUNCATE`；建议补 `REINDEX`、`CLUSTER`、`VACUUM FULL`、非 concurrently `REFRESH MATERIALIZED VIEW`。 |

### 3.5 13.3.2 Row-Level Locks

建议新增 `5` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS` | P0 | A transaction can hold conflicting locks on the same row, even in different subtransactions | 同一事务甚至不同子事务可在同一行持有彼此冲突的行锁。 |
| `LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE` | P0 | Row-level locks are released during savepoint rollback | savepoint 后获取的行锁在 `ROLLBACK TO SAVEPOINT` 时释放。 |
| `LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS` | P1 | PostgreSQL doesn't remember modified rows in memory, no limit on number of rows locked | PostgreSQL 不因内存记录限制而限制单事务锁定行数。 |
| `LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE` | P0 | `SELECT FOR UPDATE` waits then returns updated row or no row if deleted | `SELECT FOR UPDATE` 等待并发事务后，返回更新后的行，若行被删除则不返回。 |
| `LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY` | P1 | Key columns are those with unique index usable in FK; partial/expression indexes not considered | 修改 key 列触发 `FOR UPDATE` 的边界应排除 partial index 和 expression index。 |

### 3.6 13.3.5 Advisory Locks

建议新增 `3` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL` | P0 | Unlock is effective even if calling transaction fails later | session-level advisory unlock 即使所在事务后续失败也立即生效。 |
| `LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK` | P0 | Session-level and transaction-level requests for same identifier block each other | session-level 和 transaction-level advisory lock 使用同一 identifier 时会互相阻塞。 |
| `LOCK-ADVISORY-REENTRANT-WHILE-OTHERS-WAITING` | P1 | If a session already holds lock, additional requests always succeed even if others await | 已持有 advisory lock 的会话再次获取同一锁，即使其他会话正在等待，也应立即成功。 |

### 3.7 13.4.2 Enforcing Consistency with Explicit Blocking Locks

建议新增 `2` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `APP-BLOCKING-SELECT-FOR-SHARE` | P0 | Use SELECT FOR UPDATE, SELECT FOR SHARE, or LOCK TABLE | 当前 `SELECT FOR UPDATE` 和 `SELECT FOR SHARE` 合并在一个用例中；建议拆出 `SELECT FOR SHARE`。 |
| `APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE` | P0 | LOCK TABLE locks the whole table | 非 serializable 写存在时，`LOCK TABLE` 保护全表而不是单行。 |

### 3.8 13.7 Locking and Indexes

建议新增或拆分 `2` 个。

| 建议用例名称 | 优先级 | 原文依据 | 测试点 |
|---|---|---|---|
| `IDX-GIST-PAGE-LOCK-CONCURRENCY` | P1 | B-tree, GiST and SP-GiST use short-term page-level locks | 当前 GiST/SP-GiST 合并，建议拆出 GiST 独立用例。 |
| `IDX-SPGIST-PAGE-LOCK-CONCURRENCY` | P1 | B-tree, GiST and SP-GiST use short-term page-level locks | 当前 GiST/SP-GiST 合并，建议拆出 SP-GiST 独立用例。 |

## 4. 边界值审查

### 4.1 已覆盖的关键边界

| 边界 | 当前覆盖 |
|---|---|
| `READ UNCOMMITTED` 映射为 `READ COMMITTED` | 已覆盖：`ISO-RU-MAPS-TO-RC` |
| 默认隔离级别为 `READ COMMITTED` | 已覆盖：`ISO-DEFAULT-READ-COMMITTED` |
| sequence/serial 非事务性 | 已覆盖：`ISO-SEQUENCE-NONTRANSACTIONAL` |
| `READ COMMITTED` 非重复读和幻读 | 已覆盖 |
| PostgreSQL `REPEATABLE READ` 不允许 phantom read | 已覆盖 |
| `REPEATABLE READ`/`SERIALIZABLE` 的 `40001` | 已覆盖 |
| deadlock `40P01` | 已覆盖 |
| 可谨慎重试 `23505` 和 `23P01` | 已覆盖 |
| `SIReadLock` 可见、非阻塞、提交后保留 | 已覆盖 |
| page-level lock 用户无需直接关心 | 已覆盖 |
| advisory lock shared memory 上限 | 已覆盖 |
| `TRUNCATE` 和 rewrite `ALTER TABLE` 非 MVCC-safe | 已覆盖 |
| hot standby 不支持 serializable | 已覆盖 |
| hash index bucket lock 可能 deadlock | 已覆盖 |

### 4.2 需要补强的边界

| 边界 | 建议补强 |
|---|---|
| `READ COMMITTED` 等待并发事务后的 commit/rollback/delete 分支 | 补 `RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED`、`RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE` |
| `READ COMMITTED` 的 `SELECT FOR SHARE` 分支 | 补 `RC-SELECT-FOR-SHARE-WAIT-RECHECK` |
| `MERGE` 在并发 delete/unique conflict 下的特殊行为 | 补 `RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION`、`RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION` |
| `REPEATABLE READ` 仅锁定但未更新不触发 `40001` | 补 `RR-CONCURRENT-LOCK-ONLY-NO-40001` |
| `REPEATABLE READ` 的 `MERGE` 和 `SELECT FOR SHARE` | 补 `RR-MERGE-CONCURRENT-UPDATE-40001`、`RR-SELECT-FOR-SHARE-CONFLICT-40001` |
| 表锁自身不冲突、自冲突、非自冲突 | 补 3 个表锁边界用例 |
| 行锁同事务冲突锁、savepoint rollback、无行数内存限制 | 补 3 个行锁边界用例 |
| Serializable 性能建议逐条证明 | 拆分 `READ ONLY`、连接数、事务长度、idle timeout、predicate lock 参数 |
| Advisory lock session/xact 同 identifier 和 unlock 失败事务边界 | 补 3 个 advisory lock 用例 |

## 5. 推荐后续执行

建议分两步处理：

1. 先补 P0 缺口，确保官方原文行为边界都能被独立用例证明。
2. 再补 P1/P2，主要用于证明性能建议、配置边界和实现细节已审阅。

如果按本审查补齐，当前官方章节目录仍保持不变，只是在对应目录下新增文件，并更新各级 `README.md` 用例数即可。
