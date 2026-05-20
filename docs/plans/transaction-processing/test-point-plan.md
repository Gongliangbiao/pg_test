# PostgreSQL 16.4 Chapter 74 Transaction Processing 测试点计划

## 1. 文档定位

本文档基于 PostgreSQL 16.4 官方文档 PDF（仓库外部资料，文件名可记录为 `j2ul-2965-02enz0.pdf`）中 `Chapter 74. Transaction Processing` 章节抽取测试点。

当前阶段只定义测试范围、用例名称、测试点和边界值关注项，不展开具体 SQL 步骤、会话编排、expected 输出。后续详细测试步骤应以本文档中的用例名称为索引继续补充。

官方章节结构如下：

| 官方章节 | 章节名称 | 建议用例数 |
|---|---|---:|
| 74.1 | Transactions and Identifiers | 20 |
| 74.2 | Transactions and Locking | 12 |
| 74.3 | Subtransactions | 24 |
| 74.4 | Two-Phase Transactions | 30 |
| 附录 A | TCL 命令入口边界补充 | 18 |
| 合计 |  | 104 |

说明：

- Chapter 74 本身偏内部机制说明，因此测试点既包括可通过 SQL 直接验证的行为，也包括通过系统视图、目录状态、配置参数和扩展观测的验证点。
- 附录 A 不替代 Chapter 74 的章节划分，只用于补齐可执行测试入口中容易漏掉的边界条件。
- 用例设计原则：每个用例只验证一个单一场景；并发场景默认使用 2 个会话，只有 2PC 跨会话确认或必须观测阻塞链时才考虑第 3 个会话。

## 2. 覆盖分层

| 层级 | 说明 | 建议数量 |
|---|---|---:|
| P0 | Chapter 74 明确描述的核心语义、分配时机、状态转换、边界错误 | 69 |
| P1 | 通过系统视图、扩展、配置参数、checkpoint 或权限条件验证的专项边界 | 30 |
| P2 | 成本、性能、长期状态、内部目录观测类建议项 | 5 |

## 3. 74.1 Transactions and Identifiers

建议用例数：20 个。

本节覆盖显式事务、隐式单语句事务、`VirtualTransactionId`、非虚拟 `xid`、`xid8`、wraparound、`pg_xact`、commit timestamp、prepared transaction GID 与 `pg_prepared_xacts` 映射。

| 用例名称 | 层级 | 测试点 |
|---|---|---|
| `TXID-EXPLICIT-BEGIN-COMMIT` | P0 | `BEGIN` 或 `START TRANSACTION` 显式创建事务，`COMMIT` 正常结束事务。 |
| `TXID-EXPLICIT-BEGIN-ROLLBACK` | P0 | `BEGIN` 或 `START TRANSACTION` 显式创建事务，`ROLLBACK` 放弃事务变更。 |
| `TXID-IMPLICIT-SINGLE-STMT-COMMIT` | P0 | 未显式开启事务时，单条成功 SQL 自动作为单语句事务提交。 |
| `TXID-IMPLICIT-SINGLE-STMT-ROLLBACK` | P0 | 未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。 |
| `TXID-VXID-ASSIGNED-FOR-READONLY` | P0 | 只读事务也具有唯一 `VirtualTransactionId`。 |
| `TXID-VXID-FORMAT-BACKEND-LOCALXID` | P1 | `VirtualTransactionId` 由 `backendID/localXID` 组成，格式可通过 `pg_locks.virtualxid` 观测。 |
| `TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND` | P1 | 同一 backend 内 `localXID` 顺序递增，不同 backend 的本地序列彼此独立。 |
| `TXID-XID-NOT-ASSIGNED-BEFORE-WRITE` | P0 | 事务只执行读操作时不分配非虚拟 `xid`。 |
| `TXID-XID-ASSIGNED-ON-FIRST-WRITE` | P0 | 事务第一次写数据库时才分配非虚拟 `xid`。 |
| `TXID-XID-WRITE-ORDER-NOT-START-ORDER` | P0 | `xid` 编号顺序反映首次写入顺序，而不一定反映事务开始顺序。 |
| `TXID-XID-LOWER-WRITES-EARLIER` | P1 | 较小 `xid` 的事务先完成首次数据库写入。 |
| `TXID-XID-GLOBAL-CLUSTER-COUNTER` | P1 | 非虚拟 `xid` 来自整个 PostgreSQL cluster 的全局计数器，而不是单库局部计数器。 |
| `TXID-XID-32BIT-TYPE-BOUNDARY` | P1 | 内部 `xid` 是 32 位类型，测试设计需覆盖接近 32 位上界的显示、比较或转换边界。 |
| `TXID-XID-WRAPAROUND-EPOCH-INCREMENT` | P2 | 普通 `xid` 是 32 位循环空间，超过 `2^32` 次分配后低 32 位数值会 wraparound 并再次出现；每次 wraparound 时 32 位 epoch 递增，完整逻辑顺序应结合 epoch/`xid8` 理解。 |
| `TXID-XID8-NO-INSTALLATION-WRAP` | P1 | `xid8` 包含 epoch，在单个 installation 生命周期内不发生 `xid` 式 wraparound。 |
| `TXID-XID8-CAST-TO-XID` | P1 | `xid8` 可转换为 `xid`，测试转换后低 32 位语义和边界表现。 |
| `TXID-PG-XACT-COMMITTED-MARK` | P1 | 带非虚拟 `xid` 的顶层事务提交后，在 `pg_xact` 中记录 committed 状态。 |
| `TXID-COMMIT-TS-WHEN-TRACK-ENABLED` | P1 | `track_commit_timestamp=on` 时，提交事务额外在 `pg_commit_ts` 记录提交时间信息。 |
| `TXID-GID-ASSIGNED-FOR-PREPARED` | P0 | prepared transaction 除 `vxid`、`xid` 外，还具有 `GID`。 |
| `TXID-GID-MAPPED-IN-PG-PREPARED-XACTS` | P0 | `pg_prepared_xacts` 可查看 `GID` 到 `xid` 的映射关系。 |

### 74.1 边界值关注项

| 边界项 | 说明 |
|---|---|
| 只读事务 | 有 `vxid`，但不应因为普通读分配 `xid`。 |
| 首次写入 | `xid` 分配发生在第一次写数据库时，而不是 `BEGIN` 时。 |
| 事务开始顺序与写入顺序 | 先 `BEGIN` 的事务如果后写，可能拿到更大的 `xid`。 |
| `xid` 类型边界 | 普通 `xid` 是 32 位循环空间，超过 `2^32` 次分配后低 32 位数值会 wraparound 并再次出现；PostgreSQL 通过 epoch/`xid8` 表示完整逻辑顺序，并通过 VACUUM freeze/anti-wraparound 机制避免旧 tuple 因 xid 回卷产生可见性错误。 |
| GID 长度 | GID 是字符串字面量，长度必须小于 200 bytes。 |
| GID 唯一性 | GID 只要求在“当前 prepared transactions”中唯一。 |

## 4. 74.2 Transactions and Locking

建议用例数：12 个。

本节覆盖 `pg_locks` 中事务标识观测、只读与读写事务的 `virtualxid`/`transactionid` 差异、等待锁类型、行级锁的存储位置、`pgrowlocks` 观测，以及 row-level read lock 与 multixact ID 的关系。

| 用例名称 | 层级 | 测试点 |
|---|---|---|
| `TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE` | P0 | 当前执行事务可在 `pg_locks.virtualxid` 中观测到事务 `vxid`。 |
| `TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL` | P0 | 只读事务在 `pg_locks` 中有 `virtualxid`，但 `transactionid` 为 `NULL`。 |
| `TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET` | P0 | 读写事务在 `pg_locks` 中同时具有 `virtualxid` 和 `transactionid`。 |
| `TXLOCK-WAIT-ON-VIRTUALXID` | P1 | 某些锁等待目标为 `virtualxid`，可通过 `pg_locks` 的等待记录确认。 |
| `TXLOCK-WAIT-ON-TRANSACTIONID` | P1 | 某些锁等待目标为 `transactionid`，可通过 `pg_locks` 的等待记录确认。 |
| `TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW` | P1 | 行级读写锁记录在被锁行上，不能简单按每行锁从 `pg_locks` 直接读取。 |
| `TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT` | P1 | 使用 `pgrowlocks` 扩展检查被锁行的行级锁信息。 |
| `TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE` | P1 | 行级读锁可能需要分配 multixact ID。 |
| `TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE` | P1 | 多个事务对同一行持有兼容读锁时，可形成 multixact 观测场景。 |
| `TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK` | P0 | 只读事务可以持有事务锁观测项，但不因此分配非虚拟 `xid`。 |
| `TXLOCK-READWRITE-XID-AFTER-DML-LOCK` | P0 | DML 写入后事务锁观测中出现非空 `transactionid`。 |
| `TXLOCK-PREPARED-XACT-LOCK-RETAINED` | P1 | prepared transaction 继续持有其已获取锁，直到 `COMMIT PREPARED` 或 `ROLLBACK PREPARED`。 |

### 74.2 边界值关注项

| 边界项 | 说明 |
|---|---|
| 只读事务观测 | `virtualxid` 非空、`transactionid` 为空。 |
| 读写事务观测 | 首次写入后 `transactionid` 变为可观测。 |
| 行级锁观测 | 行级锁主要记录在 tuple 上，需用 `pgrowlocks` 这类扩展验证。 |
| multixact | 多事务共享行级读锁时，关注 mxid 分配和可见性。 |
| prepared transaction | prepared 状态下锁不会随会话结束而释放。 |

## 5. 74.3 Subtransactions

建议用例数：24 个。

本节覆盖 subtransaction/subxact 层级、`SAVEPOINT`、PL 语言异常触发、只读 subtransaction 不分配 subxid、写 subtransaction 分配 subxid、父子 xid 顺序、`pg_subtrans`、subcommit、abort 传播，以及 64 个 open subxid 缓存阈值。

| 用例名称 | 层级 | 测试点 |
|---|---|---|
| `SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION` | P0 | `SAVEPOINT` 在顶层事务内部显式启动 subtransaction。 |
| `SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION` | P1 | PL/pgSQL `EXCEPTION` 块可隐式启动 subtransaction。 |
| `SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION` | P2 | PL/Python 显式 subtransaction 能进入同一内部模型。 |
| `SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION` | P2 | PL/Tcl 显式 subtransaction 能进入同一内部模型。 |
| `SUBXACT-NESTED-SAVEPOINT-TREE` | P0 | subtransaction 可以在其他 subtransaction 内部继续启动，形成层级树。 |
| `SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT` | P0 | 子事务提交不结束父事务，父事务可继续执行。 |
| `SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT` | P0 | 子事务回滚不影响父事务继续执行。 |
| `SUBXACT-READONLY-NO-SUBXID` | P0 | 只读 subtransaction 不分配 `subxid`。 |
| `SUBXACT-WRITE-ASSIGNS-SUBXID` | P0 | subtransaction 第一次写入时分配非虚拟 transaction ID，称为 `subxid`。 |
| `SUBXACT-WRITE-ASSIGNS-PARENTS-XID` | P0 | 子事务写入导致其所有父级直到顶层事务都分配非虚拟 transaction ID。 |
| `SUBXACT-PARENT-XID-LOWER-THAN-CHILD` | P0 | 父级 `xid` 总是小于任一子级 `subxid`。 |
| `SUBXACT-PG-SUBTRANS-PARENT-MAPPING` | P1 | 每个 `subxid` 的直接父级 xid 记录在 `pg_subtrans`。 |
| `SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY` | P1 | 顶层 xid 没有父级，不在 `pg_subtrans` 建父映射项。 |
| `SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY` | P1 | 只读 subtransaction 不分配 subxid，因此不在 `pg_subtrans` 建映射项。 |
| `SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED` | P0 | subtransaction 提交时，其已提交且有 subxid 的子事务被视为 subcommitted。 |
| `SUBXACT-ABORT-CHILDREN-ABORTED` | P0 | subtransaction 回滚时，其所有子 subtransaction 也被视为 aborted。 |
| `SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN` | P0 | 带 xid 的顶层事务提交时，其 subcommitted 子事务在 `pg_xact` 中持久记录为 committed。 |
| `SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED` | P0 | 顶层事务回滚时，已 subcommitted 的子事务也最终回滚。 |
| `SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO` | P0 | `ROLLBACK TO SAVEPOINT` 只撤销保存点之后的变更，并允许事务继续。 |
| `SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS` | P0 | `RELEASE SAVEPOINT` 不撤销变更，而是释放保存点并合并未回滚变更。 |
| `SUBXACT-SAME-NAME-SAVEPOINT-LATEST` | P1 | 同名保存点存在时，最近定义且未释放的保存点优先生效。 |
| `SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS` | P0 | `ROLLBACK TO SAVEPOINT` 隐式销毁目标保存点之后创建的保存点。 |
| `SUBXACT-OPEN-SUBXID-CACHE-64` | P1 | 每个 backend 最多缓存 64 个 open subxids 到共享内存。 |
| `SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO` | P2 | open subxids 超过 64 后，因额外 `pg_subtrans` 查找导致事务管理 I/O 开销显著增加。 |

### 74.3 边界值关注项

| 边界项 | 说明 |
|---|---|
| 0 个 subtransaction | 只有顶层事务，无 `pg_subtrans` 父映射。 |
| 只读 subtransaction | 不分配 subxid，不写 `pg_subtrans` 父映射。 |
| 第一次写入 | subxid 分配点，同时触发父链分配 xid。 |
| 嵌套层级 | 多层 savepoint 构成 tree，需分别验证提交、回滚、释放的传播方向。 |
| 同名 savepoint | 最近未释放保存点生效；重复释放会逐步释放更老的同名保存点。 |
| 64 个 open subxids | 64 是共享内存缓存阈值；65 及以上进入额外 `pg_subtrans` 查找场景。 |
| 顶层事务最终结果 | 子事务 subcommitted 不是最终持久提交；顶层 commit/abort 决定最终结果。 |

## 6. 74.4 Two-Phase Transactions

建议用例数：30 个。

本节覆盖 2PC 协议、`PREPARE TRANSACTION`、`COMMIT PREPARED`、`ROLLBACK PREPARED`、prepared 状态、GID、跨会话完成、崩溃可恢复概率、shared memory/WAL、跨 checkpoint 的 `pg_twophase`、`pg_prepared_xacts`、锁保持、配置参数和禁止场景。

| 用例名称 | 层级 | 测试点 |
|---|---|---|
| `2PC-PREPARE-BASIC` | P0 | 事务内执行 `PREPARE TRANSACTION` 后进入 prepared state。 |
| `2PC-PREPARE-REQUIRES-TXN-BLOCK` | P0 | `PREPARE TRANSACTION` 必须在事务块内执行。 |
| `2PC-PREPARE-ENDS-CURRENT-SESSION-XACT` | P0 | 从发起会话视角看，`PREPARE TRANSACTION` 后当前会话不再有关联的活动事务。 |
| `2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED` | P0 | prepared 后变更暂不作为已提交结果对其他事务可见。 |
| `2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE` | P0 | `COMMIT PREPARED` 后 prepared 事务变更对其他事务可见。 |
| `2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS` | P0 | `ROLLBACK PREPARED` 后 prepared 事务变更被放弃。 |
| `2PC-COMMIT-FROM-DIFFERENT-SESSION` | P0 | `COMMIT PREPARED` 可由非原始会话执行。 |
| `2PC-ROLLBACK-FROM-DIFFERENT-SESSION` | P0 | `ROLLBACK PREPARED` 可由非原始会话执行。 |
| `2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK` | P0 | 进入 prepared state 后，事务本身只允许后续被 commit prepared 或 rollback prepared 终结。 |
| `2PC-PREPARED-XACTS-VIEW-LISTING` | P0 | 当前 prepared transactions 可通过 `pg_prepared_xacts` 查询。 |
| `2PC-GID-STRING-LITERAL` | P0 | GID 必须以字符串字面量形式提供。 |
| `2PC-GID-LENGTH-199-BYTES` | P0 | GID 长度 199 bytes 可作为小于 200 bytes 的有效边界。 |
| `2PC-GID-LENGTH-200-BYTES-ERROR` | P0 | GID 长度达到 200 bytes 时违反“小于 200 bytes”限制。 |
| `2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR` | P0 | 与当前 prepared transaction 已使用 GID 重复时应失败。 |
| `2PC-GID-REUSE-AFTER-RESOLVE` | P1 | 原 GID 的 prepared transaction 被 commit/rollback 后，该 GID 不再属于当前 prepared 集合，可验证复用边界。 |
| `2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED` | P0 | `max_prepared_transactions=0` 时禁用 prepared transaction。 |
| `2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY` | P1 | prepared transaction 数达到 `max_prepared_transactions` 上限时，新的 prepare 应失败。 |
| `2PC-LOCKS-HELD-WHILE-PREPARED` | P0 | prepared transaction 持续持有已获取锁。 |
| `2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED` | P0 | `COMMIT PREPARED` 后锁释放。 |
| `2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED` | P0 | `ROLLBACK PREPARED` 后锁释放。 |
| `2PC-SHORT-LIVED-IN-SHMEM-WAL` | P2 | 短时间 prepared transaction 存储在 shared memory 和 WAL 中。 |
| `2PC-SPAN-CHECKPOINT-PG-TWOPHASE` | P1 | prepared transaction 跨 checkpoint 后在 `pg_twophase` 目录记录状态文件。 |
| `2PC-PERSIST-ACROSS-CRASH-RECOVERY` | P1 | prepared transaction 在数据库崩溃恢复后仍可通过 commit/rollback prepared 处理。 |
| `2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT` | P0 | `PREPARE TRANSACTION` 因任何原因失败时，当前事务被取消，效果等同 rollback。 |
| `2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED` | P0 | 涉及临时表或 session 临时 namespace 的事务不允许 prepare。 |
| `2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED` | P0 | 创建 `WITH HOLD` cursor 的事务不允许 prepare。 |
| `2PC-PREPARE-LISTEN-NOT-ALLOWED` | P0 | 执行过 `LISTEN` 的事务不允许 prepare。 |
| `2PC-PREPARE-UNLISTEN-NOT-ALLOWED` | P0 | 执行过 `UNLISTEN` 的事务不允许 prepare。 |
| `2PC-PREPARE-NOTIFY-NOT-ALLOWED` | P0 | 执行过 `NOTIFY` 的事务不允许 prepare。 |
| `2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE` | P1 | 事务内 `SET` 非 `LOCAL` 修改的运行时参数在 prepare 后保留，不受后续 commit/rollback prepared 影响。 |

### 74.4 边界值关注项

| 边界项 | 说明 |
|---|---|
| `max_prepared_transactions=0` | 官方建议未配置外部事务管理器时保持为 0，防止误创建 prepared transaction。 |
| GID 长度 | 必须小于 200 bytes；199 bytes 与 200 bytes 是关键边界。 |
| GID 唯一性 | 只要求在当前 prepared transaction 集合中唯一。 |
| prepared 状态持续时间 | 设计预期很短，但可因外部可用性问题长期存在；长期存在会影响 VACUUM 和 xid wraparound 风险。 |
| 跨会话完成 | commit/rollback prepared 不要求与 prepare 相同会话。 |
| 权限边界 | 只能由原始执行用户或 superuser commit/rollback prepared。 |
| 事务块边界 | `PREPARE TRANSACTION` 必须在事务块内；`COMMIT PREPARED` 和 `ROLLBACK PREPARED` 不能在事务块内。 |
| checkpoint 边界 | 短期 prepared 存 shared memory/WAL；跨 checkpoint 后写入 `pg_twophase`。 |
| crash recovery | prepare 后状态应具备高概率崩溃后可提交能力。 |
| 禁止 prepare 的 session 绑定对象 | 临时对象、`WITH HOLD` cursor、`LISTEN`、`UNLISTEN`、`NOTIFY` 都应单独覆盖。 |

## 7. 附录 A：TCL 命令入口边界补充

建议用例数：18 个。

这些测试点来自 Chapter 74 涉及的 SQL 入口命令说明，用于后续把内部测试点转化为可执行 SQL 用例时补齐边界。它们不改变 Chapter 74 的主章节归属。

| 用例名称 | 层级 | 测试点 |
|---|---|---|
| `TCL-BEGIN-INSIDE-TXN-WARNING` | P0 | 已在事务块内再次执行 `BEGIN` 只产生 warning，不影响事务状态；嵌套事务应使用 savepoint。 |
| `TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION` | P0 | `BEGIN` 指定 isolation/read write/deferrable 模式时，效果等同事务开始时执行 `SET TRANSACTION`。 |
| `TCL-START-TRANSACTION-EQUIVALENT-BEGIN` | P0 | `START TRANSACTION` 与 `BEGIN` 功能等价。 |
| `TCL-START-TRANSACTION-MODE-COMMA-OMIT` | P1 | PostgreSQL 为兼容历史允许 transaction modes 之间省略逗号。 |
| `TCL-COMMIT-OUTSIDE-TXN-WARNING` | P0 | 不在事务块内执行 `COMMIT` 无实际影响但产生 warning。 |
| `TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR` | P0 | 不在事务块内执行 `COMMIT AND CHAIN` 是错误。 |
| `TCL-COMMIT-AND-CHAIN-KEEPS-MODES` | P0 | `COMMIT AND CHAIN` 立即开启新事务，并继承刚结束事务的 transaction characteristics。 |
| `TCL-ROLLBACK-OUTSIDE-TXN-WARNING` | P0 | 不在事务块内执行 `ROLLBACK` 产生 warning 且无其他效果。 |
| `TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR` | P0 | 不在事务块内执行 `ROLLBACK AND CHAIN` 是错误。 |
| `TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES` | P0 | `ROLLBACK AND CHAIN` 立即开启新的非 aborted 事务，并继承刚结束事务的 transaction characteristics。 |
| `TCL-SET-TRANSACTION-NO-BEGIN-WARNING` | P0 | 未先 `BEGIN` 或 `START TRANSACTION` 时执行 `SET TRANSACTION` 产生 warning 且无效果。 |
| `TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR` | P0 | 事务执行第一个查询或数据修改语句后，不允许再改变 isolation level。 |
| `TCL-SET-SESSION-DEFAULT-MODES` | P1 | `SET SESSION CHARACTERISTICS` 只影响后续事务默认特征，可被单个事务 `SET TRANSACTION` 覆盖。 |
| `TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED` | P0 | PostgreSQL 中 `READ UNCOMMITTED` 按 `READ COMMITTED` 处理。 |
| `TCL-READONLY-DISALLOW-DML-DDL` | P0 | `READ ONLY` 事务禁止对非临时表执行写 DML，并禁止 DDL、权限、truncate 等修改类命令。 |
| `TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY` | P0 | `DEFERRABLE` 只有在 `SERIALIZABLE READ ONLY` 事务中才有实际效果。 |
| `TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE` | P0 | `SET TRANSACTION SNAPSHOT` 只能在事务开始处，且事务隔离级别已为 `REPEATABLE READ` 或 `SERIALIZABLE`。 |
| `TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY` | P1 | 导入方若为 `SERIALIZABLE`，导出 snapshot 的事务也必须为 `SERIALIZABLE`；非只读 serializable 事务不能从只读事务导入 snapshot。 |

## 8. 建议执行顺序

| 阶段 | 覆盖范围 | 建议说明 |
|---|---|---|
| 第一阶段 | 74.1 + 74.2 P0 | 先建立 xid/vxid/pg_locks 的基础观测能力。 |
| 第二阶段 | 74.3 P0 | 完成 savepoint/subtransaction 的提交、回滚、嵌套和父子状态传播。 |
| 第三阶段 | 74.4 P0 | 完成 2PC 主链路、GID 边界、配置禁用、锁保持和禁止 prepare 场景。 |
| 第四阶段 | P1/P2 | 补充 `pg_subtrans`、`pg_twophase`、checkpoint、crash recovery、性能开销类专项。 |
| 第五阶段 | 附录 A | 把 SQL 命令入口边界补齐为独立回归用例。 |

## 9. 减法标签建议

本节用于把 Chapter 74 的测试点从“覆盖证明型清单”收敛为后续可执行测试集。这里不删除原测试点，只标注建议处理方式。

| 用例名称 | 标签 | 理由 |
|---|---|---|
| `TXID-EXPLICIT-BEGIN-COMMIT` | `supporting` | 该测试点是基础事务入口语义，通常会被其他事务用例自然覆盖，建议保留为覆盖说明。 |
| `TXID-EXPLICIT-BEGIN-ROLLBACK` | `supporting` | 该测试点是基础事务入口语义，通常会被其他事务用例自然覆盖，建议保留为覆盖说明。 |
| `TXID-IMPLICIT-SINGLE-STMT-COMMIT` | `supporting` | 该测试点是基础事务入口语义，通常会被其他事务用例自然覆盖，建议保留为覆盖说明。 |
| `TXID-IMPLICIT-SINGLE-STMT-ROLLBACK` | `supporting` | 该测试点是基础事务入口语义，通常会被其他事务用例自然覆盖，建议保留为覆盖说明。 |
| `TXID-VXID-ASSIGNED-FOR-READONLY` | `core` | 该测试点验证 vxid/xid 的核心分配时机或 prepared GID 映射，是事务标识章节的关键执行点。 |
| `TXID-VXID-FORMAT-BACKEND-LOCALXID` | `supporting` | 该测试点用于解释事务 ID 的排序或组成规则，适合作为设计依据，独立执行收益低于分配时机核心用例。 |
| `TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND` | `supporting` | 该测试点用于解释事务 ID 的排序或组成规则，适合作为设计依据，独立执行收益低于分配时机核心用例。 |
| `TXID-XID-NOT-ASSIGNED-BEFORE-WRITE` | `core` | 该测试点验证 vxid/xid 的核心分配时机或 prepared GID 映射，是事务标识章节的关键执行点。 |
| `TXID-XID-ASSIGNED-ON-FIRST-WRITE` | `core` | 该测试点验证 vxid/xid 的核心分配时机或 prepared GID 映射，是事务标识章节的关键执行点。 |
| `TXID-XID-WRITE-ORDER-NOT-START-ORDER` | `core` | 该测试点验证 vxid/xid 的核心分配时机或 prepared GID 映射，是事务标识章节的关键执行点。 |
| `TXID-XID-LOWER-WRITES-EARLIER` | `supporting` | 该测试点用于解释事务 ID 的排序或组成规则，适合作为设计依据，独立执行收益低于分配时机核心用例。 |
| `TXID-XID-GLOBAL-CLUSTER-COUNTER` | `supporting` | 该测试点用于解释事务 ID 的排序或组成规则，适合作为设计依据，独立执行收益低于分配时机核心用例。 |
| `TXID-XID-32BIT-TYPE-BOUNDARY` | `special` | 该测试点涉及 xid wraparound、内部提交状态或提交时间戳，验证成本较高，建议作为事务内部专项测试。 |
| `TXID-XID-WRAPAROUND-EPOCH-INCREMENT` | `special` | 该测试点涉及 xid wraparound、内部提交状态或提交时间戳，验证成本较高，建议作为事务内部专项测试。 |
| `TXID-XID8-NO-INSTALLATION-WRAP` | `special` | 该测试点涉及 xid wraparound、内部提交状态或提交时间戳，验证成本较高，建议作为事务内部专项测试。 |
| `TXID-XID8-CAST-TO-XID` | `special` | 该测试点涉及 xid wraparound、内部提交状态或提交时间戳，验证成本较高，建议作为事务内部专项测试。 |
| `TXID-PG-XACT-COMMITTED-MARK` | `special` | 该测试点涉及 xid wraparound、内部提交状态或提交时间戳，验证成本较高，建议作为事务内部专项测试。 |
| `TXID-COMMIT-TS-WHEN-TRACK-ENABLED` | `special` | 该测试点涉及 xid wraparound、内部提交状态或提交时间戳，验证成本较高，建议作为事务内部专项测试。 |
| `TXID-GID-ASSIGNED-FOR-PREPARED` | `core` | 该测试点验证 vxid/xid 的核心分配时机或 prepared GID 映射，是事务标识章节的关键执行点。 |
| `TXID-GID-MAPPED-IN-PG-PREPARED-XACTS` | `core` | 该测试点验证 vxid/xid 的核心分配时机或 prepared GID 映射，是事务标识章节的关键执行点。 |
| `TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-WAIT-ON-VIRTUALXID` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-WAIT-ON-TRANSACTIONID` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT` | `special` | 该测试点需要扩展或 multixact 观测，执行与断言成本高，建议作为锁内部观测专项。 |
| `TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE` | `special` | 该测试点需要扩展或 multixact 观测，执行与断言成本高，建议作为锁内部观测专项。 |
| `TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE` | `special` | 该测试点需要扩展或 multixact 观测，执行与断言成本高，建议作为锁内部观测专项。 |
| `TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-READWRITE-XID-AFTER-DML-LOCK` | `core` | 该测试点验证事务锁和事务 ID 在系统视图中的核心观测语义，建议进入事务处理核心执行集。 |
| `TXLOCK-PREPARED-XACT-LOCK-RETAINED` | `duplicate-covered` | prepared transaction 持锁行为也由 2PC 锁保持用例覆盖；本项保留在事务锁观测章节用于追溯，不建议重复展开。 |
| `SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION` | `special` | 该测试点依赖 PL 语言环境或异常块机制，执行前置条件较多，建议归入语言/子事务专项。 |
| `SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION` | `special` | 该测试点依赖 PL 语言环境或异常块机制，执行前置条件较多，建议归入语言/子事务专项。 |
| `SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION` | `special` | 该测试点依赖 PL 语言环境或异常块机制，执行前置条件较多，建议归入语言/子事务专项。 |
| `SUBXACT-NESTED-SAVEPOINT-TREE` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-READONLY-NO-SUBXID` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-WRITE-ASSIGNS-SUBXID` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-WRITE-ASSIGNS-PARENTS-XID` | `special` | 该测试点涉及 subxid/pg_subtrans 内部映射或 64 open subxids 阈值，属于内部机制专项，不建议进入常规核心执行集。 |
| `SUBXACT-PARENT-XID-LOWER-THAN-CHILD` | `special` | 该测试点涉及 subxid/pg_subtrans 内部映射或 64 open subxids 阈值，属于内部机制专项，不建议进入常规核心执行集。 |
| `SUBXACT-PG-SUBTRANS-PARENT-MAPPING` | `special` | 该测试点涉及 subxid/pg_subtrans 内部映射或 64 open subxids 阈值，属于内部机制专项，不建议进入常规核心执行集。 |
| `SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY` | `special` | 该测试点涉及 subxid/pg_subtrans 内部映射或 64 open subxids 阈值，属于内部机制专项，不建议进入常规核心执行集。 |
| `SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY` | `special` | 该测试点涉及 subxid/pg_subtrans 内部映射或 64 open subxids 阈值，属于内部机制专项，不建议进入常规核心执行集。 |
| `SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-ABORT-CHILDREN-ABORTED` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO` | `core` | 该测试点验证 subtransaction 的层级、提交回滚传播或 subxid 分配语义，是 Chapter 74 的核心事务处理路径。 |
| `SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS` | `supporting` | 该测试点更接近 savepoint 命令语义，可作为子事务覆盖说明保留，必要时由 savepoint 专项展开。 |
| `SUBXACT-SAME-NAME-SAVEPOINT-LATEST` | `supporting` | 该测试点更接近 savepoint 命令语义，可作为子事务覆盖说明保留，必要时由 savepoint 专项展开。 |
| `SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS` | `supporting` | 该测试点更接近 savepoint 命令语义，可作为子事务覆盖说明保留，必要时由 savepoint 专项展开。 |
| `SUBXACT-OPEN-SUBXID-CACHE-64` | `special` | 该测试点涉及 subxid/pg_subtrans 内部映射或 64 open subxids 阈值，属于内部机制专项，不建议进入常规核心执行集。 |
| `SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO` | `special` | 该测试点涉及 subxid/pg_subtrans 内部映射或 64 open subxids 阈值，属于内部机制专项，不建议进入常规核心执行集。 |
| `2PC-PREPARE-BASIC` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-REQUIRES-TXN-BLOCK` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-ENDS-CURRENT-SESSION-XACT` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-COMMIT-FROM-DIFFERENT-SESSION` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-ROLLBACK-FROM-DIFFERENT-SESSION` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARED-XACTS-VIEW-LISTING` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-GID-STRING-LITERAL` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-GID-LENGTH-199-BYTES` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-GID-LENGTH-200-BYTES-ERROR` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-GID-REUSE-AFTER-RESOLVE` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED` | `special` | 该测试点涉及 shared memory、checkpoint、crash recovery 或配置上限，环境成本较高，建议归入 2PC 专项测试。 |
| `2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY` | `special` | 该测试点涉及 shared memory、checkpoint、crash recovery 或配置上限，环境成本较高，建议归入 2PC 专项测试。 |
| `2PC-LOCKS-HELD-WHILE-PREPARED` | `duplicate-covered` | 该锁保持/释放行为与 Concurrency Control 中 prepared transaction 阻塞场景存在重叠；若执行，建议由 2PC 主链路统一承接。 |
| `2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED` | `duplicate-covered` | 该锁保持/释放行为与 Concurrency Control 中 prepared transaction 阻塞场景存在重叠；若执行，建议由 2PC 主链路统一承接。 |
| `2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED` | `duplicate-covered` | 该锁保持/释放行为与 Concurrency Control 中 prepared transaction 阻塞场景存在重叠；若执行，建议由 2PC 主链路统一承接。 |
| `2PC-SHORT-LIVED-IN-SHMEM-WAL` | `special` | 该测试点涉及 shared memory、checkpoint、crash recovery 或配置上限，环境成本较高，建议归入 2PC 专项测试。 |
| `2PC-SPAN-CHECKPOINT-PG-TWOPHASE` | `special` | 该测试点涉及 shared memory、checkpoint、crash recovery 或配置上限，环境成本较高，建议归入 2PC 专项测试。 |
| `2PC-PERSIST-ACROSS-CRASH-RECOVERY` | `special` | 该测试点涉及 shared memory、checkpoint、crash recovery 或配置上限，环境成本较高，建议归入 2PC 专项测试。 |
| `2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-LISTEN-NOT-ALLOWED` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-UNLISTEN-NOT-ALLOWED` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-PREPARE-NOTIFY-NOT-ALLOWED` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE` | `core` | 该测试点验证 prepared transaction/2PC 的状态转换、GID、可见性或禁止场景，是 Chapter 74 的核心事务处理路径。 |
| `TCL-BEGIN-INSIDE-TXN-WARNING` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-START-TRANSACTION-EQUIVALENT-BEGIN` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-START-TRANSACTION-MODE-COMMA-OMIT` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-COMMIT-OUTSIDE-TXN-WARNING` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-COMMIT-AND-CHAIN-KEEPS-MODES` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-ROLLBACK-OUTSIDE-TXN-WARNING` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-SET-TRANSACTION-NO-BEGIN-WARNING` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-SET-SESSION-DEFAULT-MODES` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-READONLY-DISALLOW-DML-DDL` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY` | `supporting` | 该测试点属于 SQL 事务控制命令入口边界，重要但主要服务于并发/事务用例的前置设置，建议作为覆盖说明或命令专项保留。 |
| `TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE` | `special` | 该测试点涉及导出/导入 snapshot 的事务编排，属于事务命令专项边界。 |
| `TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY` | `special` | 该测试点涉及导出/导入 snapshot 的事务编排，属于事务命令专项边界。 |

标签统计：

- `core`：47 个
- `supporting`：27 个
- `special`：26 个
- `duplicate-covered`：4 个
