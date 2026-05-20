# PostgreSQL 16 Chapter 74 Transaction Processing 测试点充分性汇报大纲

## 文档定位
- 范围：Chapter 74 Transaction Processing，以及作为 SQL 入口边界补充的附录 A。
- 来源：`docs/plans/transaction-processing/test-point-plan.md`。
- 目标：按官方章节展示测试点、测试因子、组合方式和 no-test/不扩展边界，用于证明覆盖充分性。
- 测试点总数：104 个。

## 章节汇总

| 章节 | 测试点数量 |
|---|---:|
| 74.1 Transactions and Identifiers | 20 |
| 74.2 Transactions and Locking | 12 |
| 74.3 Subtransactions | 24 |
| 74.4 Two-Phase Transactions | 30 |
| 附录 A | 18 |

## 74.1 Transactions and Identifiers

### 章节定位
- 测试点数量：20 个。
- 覆盖原则：每个测试点只验证一个主要场景；内部机制类测试尽量通过稳定 SQL、系统视图或配置边界观测。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 事务标识与 xid/vxid/GID | 显式/隐式事务、vxid、xid 分配、xid8/epoch、GID | P0/P1/P2 | TXID-EXPLICIT-BEGIN-COMMIT、TXID-EXPLICIT-BEGIN-ROLLBACK、TXID-IMPLICIT-SINGLE-STMT-COMMIT、TXID-IMPLICIT-SINGLE-STMT-ROLLBACK、TXID-VXID-ASSIGNED-FOR-READONLY、TXID-VXID-FORMAT-BACKEND-LOCALXID、TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND、TXID-XID-NOT-ASSIGNED-BEFORE-WRITE、TXID-XID-ASSIGNED-ON-FIRST-WRITE、TXID-XID-WRITE-ORDER-NOT-START-ORDER、TXID-XID-LOWER-WRITES-EARLIER、TXID-XID-GLOBAL-CLUSTER-COUNTER、TXID-XID-32BIT-TYPE-BOUNDARY、TXID-XID-WRAPAROUND-EPOCH-INCREMENT、TXID-XID8-NO-INSTALLATION-WRAP、TXID-XID8-CAST-TO-XID、TXID-PG-XACT-COMMITTED-MARK、TXID-COMMIT-TS-WHEN-TRACK-ENABLED、TXID-GID-ASSIGNED-FOR-PREPARED、TXID-GID-MAPPED-IN-PG-PREPARED-XACTS |

### 边界值关注项

| 边界项 | 说明 |
|---|---|
| 只读事务 | 有 vxid，但不应因为普通读分配 xid。 |
| 首次写入 | xid 分配发生在第一次写数据库时，而不是 BEGIN 时。 |
| 事务开始顺序与写入顺序 | 先 BEGIN 的事务如果后写，可能拿到更大的 xid。 |
| xid 类型边界 | 普通 xid 是 32 位循环空间，超过 2^32 次分配后低 32 位数值会 wraparound 并再次出现；PostgreSQL 通过 epoch/xid8 表示完整逻辑顺序，并通过 VACUUM freeze/anti-wraparound 机制避免旧 tuple 因 xid 回卷产生可见性错误。 |
| GID 长度 | GID 是字符串字面量，长度必须小于 200 bytes。 |
| GID 唯一性 | GID 只要求在“当前 prepared transactions”中唯一。 |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | state-transition / boundary-directed | TXID-EXPLICIT-BEGIN-COMMIT、TXID-EXPLICIT-BEGIN-ROLLBACK、TXID-IMPLICIT-SINGLE-STMT-COMMIT、TXID-IMPLICIT-SINGLE-STMT-ROLLBACK、TXID-VXID-ASSIGNED-FOR-READONLY、TXID-VXID-FORMAT-BACKEND-LOCALXID、TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND、TXID-XID-NOT-ASSIGNED-BEFORE-WRITE、TXID-XID-ASSIGNED-ON-FIRST-WRITE、TXID-XID-WRITE-ORDER-NOT-START-ORDER、TXID-XID-LOWER-WRITES-EARLIER、TXID-XID-GLOBAL-CLUSTER-COUNTER、TXID-XID-32BIT-TYPE-BOUNDARY、TXID-XID-WRAPAROUND-EPOCH-INCREMENT、TXID-XID8-NO-INSTALLATION-WRAP、TXID-XID8-CAST-TO-XID、TXID-PG-XACT-COMMITTED-MARK、TXID-COMMIT-TS-WHEN-TRACK-ENABLED、TXID-GID-ASSIGNED-FOR-PREPARED、TXID-GID-MAPPED-IN-PG-PREPARED-XACTS | 根据事务状态转换、边界异常或诊断观测定向组合，避免全组合爆炸。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 74.1 Transactions and Identifiers 中的内部实现解释、性能成本说明或需要 crash/cluster 级环境的专项说明。 | 不适合作为普通自动化 SQL 主路径，或已由 P1/P2 special 测试点承接。 | 保留为 no-test/special 说明；由本节 20 个测试点及边界值关注项共同追溯。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 组合方式 |
|---|---|---|---|
| TXID-EXPLICIT-BEGIN-COMMIT | P0 | BEGIN 或 START TRANSACTION 显式创建事务，COMMIT 正常结束事务。 | state-transition |
| TXID-EXPLICIT-BEGIN-ROLLBACK | P0 | BEGIN 或 START TRANSACTION 显式创建事务，ROLLBACK 放弃事务变更。 | state-transition |
| TXID-IMPLICIT-SINGLE-STMT-COMMIT | P0 | 未显式开启事务时，单条成功 SQL 自动作为单语句事务提交。 | state-transition |
| TXID-IMPLICIT-SINGLE-STMT-ROLLBACK | P0 | 未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。 | state-transition |
| TXID-VXID-ASSIGNED-FOR-READONLY | P0 | 只读事务也具有唯一 VirtualTransactionId。 | state-transition |
| TXID-VXID-FORMAT-BACKEND-LOCALXID | P1 | VirtualTransactionId 由 backendID/localXID 组成，格式可通过 pg_locks.virtualxid 观测。 | state-transition |
| TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND | P1 | 同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。 | state-transition |
| TXID-XID-NOT-ASSIGNED-BEFORE-WRITE | P0 | 事务只执行读操作时不分配非虚拟 xid。 | state-transition |
| TXID-XID-ASSIGNED-ON-FIRST-WRITE | P0 | 事务第一次写数据库时才分配非虚拟 xid。 | state-transition |
| TXID-XID-WRITE-ORDER-NOT-START-ORDER | P0 | xid 编号顺序反映首次写入顺序，而不一定反映事务开始顺序。 | state-transition |
| TXID-XID-LOWER-WRITES-EARLIER | P1 | 较小 xid 的事务先完成首次数据库写入。 | state-transition |
| TXID-XID-GLOBAL-CLUSTER-COUNTER | P1 | 非虚拟 xid 来自整个 PostgreSQL cluster 的全局计数器，而不是单库局部计数器。 | state-transition |
| TXID-XID-32BIT-TYPE-BOUNDARY | P1 | 内部 xid 是 32 位类型，测试设计需覆盖接近 32 位上界的显示、比较或转换边界。 | boundary-directed |
| TXID-XID-WRAPAROUND-EPOCH-INCREMENT | P2 | 普通 xid 是 32 位循环空间，超过 2^32 次分配后低 32 位数值会 wraparound 并再次出现；每次 wraparound 时 32 位 epoch 递增，完整逻辑顺序应结合 epoch/xid8 理解。 | boundary-directed |
| TXID-XID8-NO-INSTALLATION-WRAP | P1 | xid8 包含 epoch，在单个 installation 生命周期内不发生 xid 式 wraparound。 | boundary-directed |
| TXID-XID8-CAST-TO-XID | P1 | xid8 可转换为 xid，测试转换后低 32 位语义和边界表现。 | state-transition |
| TXID-PG-XACT-COMMITTED-MARK | P1 | 带非虚拟 xid 的顶层事务提交后，在 pg_xact 中记录 committed 状态。 | state-transition |
| TXID-COMMIT-TS-WHEN-TRACK-ENABLED | P1 | track_commit_timestamp=on 时，提交事务额外在 pg_commit_ts 记录提交时间信息。 | state-transition |
| TXID-GID-ASSIGNED-FOR-PREPARED | P0 | prepared transaction 除 vxid、xid 外，还具有 GID。 | state-transition |
| TXID-GID-MAPPED-IN-PG-PREPARED-XACTS | P0 | pg_prepared_xacts 可查看 GID 到 xid 的映射关系。 | state-transition |

### 充分性结论
- 本节 20 个测试点覆盖了当前章节的核心行为、状态转换和边界条件。
- 组合方式以 state-transition、boundary-directed、diagnostic-directed 和 single-factor 为主。
- no-test 内容记录为内部解释、环境成本高或已由专项测试点承接的部分。

## 74.2 Transactions and Locking

### 章节定位
- 测试点数量：12 个。
- 覆盖原则：每个测试点只验证一个主要场景；内部机制类测试尽量通过稳定 SQL、系统视图或配置边界观测。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | 事务锁观测与行锁内部表示 | pg_locks、virtualxid、transactionid、pgrowlocks、multixact | P0/P1/P2 | TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE、TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL、TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET、TXLOCK-WAIT-ON-VIRTUALXID、TXLOCK-WAIT-ON-TRANSACTIONID、TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW、TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT、TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE、TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE、TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK、TXLOCK-READWRITE-XID-AFTER-DML-LOCK、TXLOCK-PREPARED-XACT-LOCK-RETAINED |

### 边界值关注项

| 边界项 | 说明 |
|---|---|
| 只读事务观测 | virtualxid 非空、transactionid 为空。 |
| 读写事务观测 | 首次写入后 transactionid 变为可观测。 |
| 行级锁观测 | 行级锁主要记录在 tuple 上，需用 pgrowlocks 这类扩展验证。 |
| multixact | 多事务共享行级读锁时，关注 mxid 分配和可见性。 |
| prepared transaction | prepared 状态下锁不会随会话结束而释放。 |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | single-factor / diagnostic-directed | TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE、TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL、TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET、TXLOCK-WAIT-ON-VIRTUALXID、TXLOCK-WAIT-ON-TRANSACTIONID、TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW、TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT、TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE、TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE、TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK、TXLOCK-READWRITE-XID-AFTER-DML-LOCK、TXLOCK-PREPARED-XACT-LOCK-RETAINED | 根据事务状态转换、边界异常或诊断观测定向组合，避免全组合爆炸。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 74.2 Transactions and Locking 中的内部实现解释、性能成本说明或需要 crash/cluster 级环境的专项说明。 | 不适合作为普通自动化 SQL 主路径，或已由 P1/P2 special 测试点承接。 | 保留为 no-test/special 说明；由本节 12 个测试点及边界值关注项共同追溯。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 组合方式 |
|---|---|---|---|
| TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE | P0 | 当前执行事务可在 pg_locks.virtualxid 中观测到事务 vxid。 | single-factor |
| TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL | P0 | 只读事务在 pg_locks 中有 virtualxid，但 transactionid 为 NULL。 | single-factor |
| TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET | P0 | 读写事务在 pg_locks 中同时具有 virtualxid 和 transactionid。 | single-factor |
| TXLOCK-WAIT-ON-VIRTUALXID | P1 | 某些锁等待目标为 virtualxid，可通过 pg_locks 的等待记录确认。 | diagnostic-directed |
| TXLOCK-WAIT-ON-TRANSACTIONID | P1 | 某些锁等待目标为 transactionid，可通过 pg_locks 的等待记录确认。 | diagnostic-directed |
| TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW | P1 | 行级读写锁记录在被锁行上，不能简单按每行锁从 pg_locks 直接读取。 | single-factor |
| TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT | P1 | 使用 pgrowlocks 扩展检查被锁行的行级锁信息。 | single-factor |
| TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE | P1 | 行级读锁可能需要分配 multixact ID。 | single-factor |
| TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE | P1 | 多个事务对同一行持有兼容读锁时，可形成 multixact 观测场景。 | single-factor |
| TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK | P0 | 只读事务可以持有事务锁观测项，但不因此分配非虚拟 xid。 | single-factor |
| TXLOCK-READWRITE-XID-AFTER-DML-LOCK | P0 | DML 写入后事务锁观测中出现非空 transactionid。 | single-factor |
| TXLOCK-PREPARED-XACT-LOCK-RETAINED | P1 | prepared transaction 继续持有其已获取锁，直到 COMMIT PREPARED 或 ROLLBACK PREPARED。 | single-factor |

### 充分性结论
- 本节 12 个测试点覆盖了当前章节的核心行为、状态转换和边界条件。
- 组合方式以 state-transition、boundary-directed、diagnostic-directed 和 single-factor 为主。
- no-test 内容记录为内部解释、环境成本高或已由专项测试点承接的部分。

## 74.3 Subtransactions

### 章节定位
- 测试点数量：24 个。
- 覆盖原则：每个测试点只验证一个主要场景；内部机制类测试尽量通过稳定 SQL、系统视图或配置边界观测。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | Subtransaction/savepoint 状态转换 | SAVEPOINT、subxid、pg_subtrans、subcommit/abort、64 open subxids | P0/P1/P2 | SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION、SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION、SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION、SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION、SUBXACT-NESTED-SAVEPOINT-TREE、SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT、SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT、SUBXACT-READONLY-NO-SUBXID、SUBXACT-WRITE-ASSIGNS-SUBXID、SUBXACT-WRITE-ASSIGNS-PARENTS-XID、SUBXACT-PARENT-XID-LOWER-THAN-CHILD、SUBXACT-PG-SUBTRANS-PARENT-MAPPING、SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY、SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY、SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED、SUBXACT-ABORT-CHILDREN-ABORTED、SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN、SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED、SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO、SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS、SUBXACT-SAME-NAME-SAVEPOINT-LATEST、SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS、SUBXACT-OPEN-SUBXID-CACHE-64、SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO |

### 边界值关注项

| 边界项 | 说明 |
|---|---|
| 0 个 subtransaction | 只有顶层事务，无 pg_subtrans 父映射。 |
| 只读 subtransaction | 不分配 subxid，不写 pg_subtrans 父映射。 |
| 第一次写入 | subxid 分配点，同时触发父链分配 xid。 |
| 嵌套层级 | 多层 savepoint 构成 tree，需分别验证提交、回滚、释放的传播方向。 |
| 同名 savepoint | 最近未释放保存点生效；重复释放会逐步释放更老的同名保存点。 |
| 64 个 open subxids | 64 是共享内存缓存阈值；65 及以上进入额外 pg_subtrans 查找场景。 |
| 顶层事务最终结果 | 子事务 subcommitted 不是最终持久提交；顶层 commit/abort 决定最终结果。 |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | state-transition / boundary-directed | SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION、SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION、SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION、SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION、SUBXACT-NESTED-SAVEPOINT-TREE、SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT、SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT、SUBXACT-READONLY-NO-SUBXID、SUBXACT-WRITE-ASSIGNS-SUBXID、SUBXACT-WRITE-ASSIGNS-PARENTS-XID、SUBXACT-PARENT-XID-LOWER-THAN-CHILD、SUBXACT-PG-SUBTRANS-PARENT-MAPPING、SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY、SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY、SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED、SUBXACT-ABORT-CHILDREN-ABORTED、SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN、SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED、SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO、SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS、SUBXACT-SAME-NAME-SAVEPOINT-LATEST、SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS、SUBXACT-OPEN-SUBXID-CACHE-64、SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO | 根据事务状态转换、边界异常或诊断观测定向组合，避免全组合爆炸。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 74.3 Subtransactions 中的内部实现解释、性能成本说明或需要 crash/cluster 级环境的专项说明。 | 不适合作为普通自动化 SQL 主路径，或已由 P1/P2 special 测试点承接。 | 保留为 no-test/special 说明；由本节 24 个测试点及边界值关注项共同追溯。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 组合方式 |
|---|---|---|---|
| SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION | P0 | SAVEPOINT 在顶层事务内部显式启动 subtransaction。 | state-transition |
| SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION | P1 | PL/pgSQL EXCEPTION 块可隐式启动 subtransaction。 | state-transition |
| SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION | P2 | PL/Python 显式 subtransaction 能进入同一内部模型。 | state-transition |
| SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION | P2 | PL/Tcl 显式 subtransaction 能进入同一内部模型。 | state-transition |
| SUBXACT-NESTED-SAVEPOINT-TREE | P0 | subtransaction 可以在其他 subtransaction 内部继续启动，形成层级树。 | state-transition |
| SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT | P0 | 子事务提交不结束父事务，父事务可继续执行。 | state-transition |
| SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT | P0 | 子事务回滚不影响父事务继续执行。 | state-transition |
| SUBXACT-READONLY-NO-SUBXID | P0 | 只读 subtransaction 不分配 subxid。 | state-transition |
| SUBXACT-WRITE-ASSIGNS-SUBXID | P0 | subtransaction 第一次写入时分配非虚拟 transaction ID，称为 subxid。 | state-transition |
| SUBXACT-WRITE-ASSIGNS-PARENTS-XID | P0 | 子事务写入导致其所有父级直到顶层事务都分配非虚拟 transaction ID。 | state-transition |
| SUBXACT-PARENT-XID-LOWER-THAN-CHILD | P0 | 父级 xid 总是小于任一子级 subxid。 | state-transition |
| SUBXACT-PG-SUBTRANS-PARENT-MAPPING | P1 | 每个 subxid 的直接父级 xid 记录在 pg_subtrans。 | state-transition |
| SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY | P1 | 顶层 xid 没有父级，不在 pg_subtrans 建父映射项。 | state-transition |
| SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY | P1 | 只读 subtransaction 不分配 subxid，因此不在 pg_subtrans 建映射项。 | state-transition |
| SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED | P0 | subtransaction 提交时，其已提交且有 subxid 的子事务被视为 subcommitted。 | state-transition |
| SUBXACT-ABORT-CHILDREN-ABORTED | P0 | subtransaction 回滚时，其所有子 subtransaction 也被视为 aborted。 | state-transition |
| SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN | P0 | 带 xid 的顶层事务提交时，其 subcommitted 子事务在 pg_xact 中持久记录为 committed。 | state-transition |
| SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED | P0 | 顶层事务回滚时，已 subcommitted 的子事务也最终回滚。 | state-transition |
| SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO | P0 | ROLLBACK TO SAVEPOINT 只撤销保存点之后的变更，并允许事务继续。 | state-transition |
| SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS | P0 | RELEASE SAVEPOINT 不撤销变更，而是释放保存点并合并未回滚变更。 | state-transition |
| SUBXACT-SAME-NAME-SAVEPOINT-LATEST | P1 | 同名保存点存在时，最近定义且未释放的保存点优先生效。 | state-transition |
| SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS | P0 | ROLLBACK TO SAVEPOINT 隐式销毁目标保存点之后创建的保存点。 | state-transition |
| SUBXACT-OPEN-SUBXID-CACHE-64 | P1 | 每个 backend 最多缓存 64 个 open subxids 到共享内存。 | boundary-directed |
| SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO | P2 | open subxids 超过 64 后，因额外 pg_subtrans 查找导致事务管理 I/O 开销显著增加。 | boundary-directed |

### 充分性结论
- 本节 24 个测试点覆盖了当前章节的核心行为、状态转换和边界条件。
- 组合方式以 state-transition、boundary-directed、diagnostic-directed 和 single-factor 为主。
- no-test 内容记录为内部解释、环境成本高或已由专项测试点承接的部分。

## 74.4 Two-Phase Transactions

### 章节定位
- 测试点数量：30 个。
- 覆盖原则：每个测试点只验证一个主要场景；内部机制类测试尽量通过稳定 SQL、系统视图或配置边界观测。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | Two-phase transaction 状态机与边界 | PREPARE、COMMIT PREPARED、ROLLBACK PREPARED、GID、max_prepared_transactions、禁止场景 | P0/P1/P2 | 2PC-PREPARE-BASIC、2PC-PREPARE-REQUIRES-TXN-BLOCK、2PC-PREPARE-ENDS-CURRENT-SESSION-XACT、2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED、2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE、2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS、2PC-COMMIT-FROM-DIFFERENT-SESSION、2PC-ROLLBACK-FROM-DIFFERENT-SESSION、2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK、2PC-PREPARED-XACTS-VIEW-LISTING、2PC-GID-STRING-LITERAL、2PC-GID-LENGTH-199-BYTES、2PC-GID-LENGTH-200-BYTES-ERROR、2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR、2PC-GID-REUSE-AFTER-RESOLVE、2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED、2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY、2PC-LOCKS-HELD-WHILE-PREPARED、2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED、2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED、2PC-SHORT-LIVED-IN-SHMEM-WAL、2PC-SPAN-CHECKPOINT-PG-TWOPHASE、2PC-PERSIST-ACROSS-CRASH-RECOVERY、2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT、2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED、2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED、2PC-PREPARE-LISTEN-NOT-ALLOWED、2PC-PREPARE-UNLISTEN-NOT-ALLOWED、2PC-PREPARE-NOTIFY-NOT-ALLOWED、2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE |

### 边界值关注项

| 边界项 | 说明 |
|---|---|
| max_prepared_transactions=0 | 官方建议未配置外部事务管理器时保持为 0，防止误创建 prepared transaction。 |
| GID 长度 | 必须小于 200 bytes；199 bytes 与 200 bytes 是关键边界。 |
| GID 唯一性 | 只要求在当前 prepared transaction 集合中唯一。 |
| prepared 状态持续时间 | 设计预期很短，但可因外部可用性问题长期存在；长期存在会影响 VACUUM 和 xid wraparound 风险。 |
| 跨会话完成 | commit/rollback prepared 不要求与 prepare 相同会话。 |
| 权限边界 | 只能由原始执行用户或 superuser commit/rollback prepared。 |
| 事务块边界 | PREPARE TRANSACTION 必须在事务块内；COMMIT PREPARED 和 ROLLBACK PREPARED 不能在事务块内。 |
| checkpoint 边界 | 短期 prepared 存 shared memory/WAL；跨 checkpoint 后写入 pg_twophase。 |
| crash recovery | prepare 后状态应具备高概率崩溃后可提交能力。 |
| 禁止 prepare 的 session 绑定对象 | 临时对象、WITH HOLD cursor、LISTEN、UNLISTEN、NOTIFY 都应单独覆盖。 |

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | state-transition / boundary-directed | 2PC-PREPARE-BASIC、2PC-PREPARE-REQUIRES-TXN-BLOCK、2PC-PREPARE-ENDS-CURRENT-SESSION-XACT、2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED、2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE、2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS、2PC-COMMIT-FROM-DIFFERENT-SESSION、2PC-ROLLBACK-FROM-DIFFERENT-SESSION、2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK、2PC-PREPARED-XACTS-VIEW-LISTING、2PC-GID-STRING-LITERAL、2PC-GID-LENGTH-199-BYTES、2PC-GID-LENGTH-200-BYTES-ERROR、2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR、2PC-GID-REUSE-AFTER-RESOLVE、2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED、2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY、2PC-LOCKS-HELD-WHILE-PREPARED、2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED、2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED、2PC-SHORT-LIVED-IN-SHMEM-WAL、2PC-SPAN-CHECKPOINT-PG-TWOPHASE、2PC-PERSIST-ACROSS-CRASH-RECOVERY、2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT、2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED、2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED、2PC-PREPARE-LISTEN-NOT-ALLOWED、2PC-PREPARE-UNLISTEN-NOT-ALLOWED、2PC-PREPARE-NOTIFY-NOT-ALLOWED、2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE | 根据事务状态转换、边界异常或诊断观测定向组合，避免全组合爆炸。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 74.4 Two-Phase Transactions 中的内部实现解释、性能成本说明或需要 crash/cluster 级环境的专项说明。 | 不适合作为普通自动化 SQL 主路径，或已由 P1/P2 special 测试点承接。 | 保留为 no-test/special 说明；由本节 30 个测试点及边界值关注项共同追溯。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 组合方式 |
|---|---|---|---|
| 2PC-PREPARE-BASIC | P0 | 事务内执行 PREPARE TRANSACTION 后进入 prepared state。 | state-transition |
| 2PC-PREPARE-REQUIRES-TXN-BLOCK | P0 | PREPARE TRANSACTION 必须在事务块内执行。 | state-transition |
| 2PC-PREPARE-ENDS-CURRENT-SESSION-XACT | P0 | 从发起会话视角看，PREPARE TRANSACTION 后当前会话不再有关联的活动事务。 | state-transition |
| 2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED | P0 | prepared 后变更暂不作为已提交结果对其他事务可见。 | state-transition |
| 2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE | P0 | COMMIT PREPARED 后 prepared 事务变更对其他事务可见。 | state-transition |
| 2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS | P0 | ROLLBACK PREPARED 后 prepared 事务变更被放弃。 | state-transition |
| 2PC-COMMIT-FROM-DIFFERENT-SESSION | P0 | COMMIT PREPARED 可由非原始会话执行。 | state-transition |
| 2PC-ROLLBACK-FROM-DIFFERENT-SESSION | P0 | ROLLBACK PREPARED 可由非原始会话执行。 | state-transition |
| 2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK | P0 | 进入 prepared state 后，事务本身只允许后续被 commit prepared 或 rollback prepared 终结。 | state-transition |
| 2PC-PREPARED-XACTS-VIEW-LISTING | P0 | 当前 prepared transactions 可通过 pg_prepared_xacts 查询。 | state-transition |
| 2PC-GID-STRING-LITERAL | P0 | GID 必须以字符串字面量形式提供。 | state-transition |
| 2PC-GID-LENGTH-199-BYTES | P0 | GID 长度 199 bytes 可作为小于 200 bytes 的有效边界。 | boundary-directed |
| 2PC-GID-LENGTH-200-BYTES-ERROR | P0 | GID 长度达到 200 bytes 时违反“小于 200 bytes”限制。 | boundary-directed |
| 2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR | P0 | 与当前 prepared transaction 已使用 GID 重复时应失败。 | state-transition |
| 2PC-GID-REUSE-AFTER-RESOLVE | P1 | 原 GID 的 prepared transaction 被 commit/rollback 后，该 GID 不再属于当前 prepared 集合，可验证复用边界。 | state-transition |
| 2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED | P0 | max_prepared_transactions=0 时禁用 prepared transaction。 | boundary-directed |
| 2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY | P1 | prepared transaction 数达到 max_prepared_transactions 上限时，新的 prepare 应失败。 | boundary-directed |
| 2PC-LOCKS-HELD-WHILE-PREPARED | P0 | prepared transaction 持续持有已获取锁。 | state-transition |
| 2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED | P0 | COMMIT PREPARED 后锁释放。 | state-transition |
| 2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED | P0 | ROLLBACK PREPARED 后锁释放。 | state-transition |
| 2PC-SHORT-LIVED-IN-SHMEM-WAL | P2 | 短时间 prepared transaction 存储在 shared memory 和 WAL 中。 | state-transition |
| 2PC-SPAN-CHECKPOINT-PG-TWOPHASE | P1 | prepared transaction 跨 checkpoint 后在 pg_twophase 目录记录状态文件。 | state-transition |
| 2PC-PERSIST-ACROSS-CRASH-RECOVERY | P1 | prepared transaction 在数据库崩溃恢复后仍可通过 commit/rollback prepared 处理。 | state-transition |
| 2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT | P0 | PREPARE TRANSACTION 因任何原因失败时，当前事务被取消，效果等同 rollback。 | state-transition |
| 2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED | P0 | 涉及临时表或 session 临时 namespace 的事务不允许 prepare。 | boundary-directed |
| 2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED | P0 | 创建 WITH HOLD cursor 的事务不允许 prepare。 | boundary-directed |
| 2PC-PREPARE-LISTEN-NOT-ALLOWED | P0 | 执行过 LISTEN 的事务不允许 prepare。 | boundary-directed |
| 2PC-PREPARE-UNLISTEN-NOT-ALLOWED | P0 | 执行过 UNLISTEN 的事务不允许 prepare。 | boundary-directed |
| 2PC-PREPARE-NOTIFY-NOT-ALLOWED | P0 | 执行过 NOTIFY 的事务不允许 prepare。 | boundary-directed |
| 2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE | P1 | 事务内 SET 非 LOCAL 修改的运行时参数在 prepare 后保留，不受后续 commit/rollback prepared 影响。 | state-transition |

### 充分性结论
- 本节 30 个测试点覆盖了当前章节的核心行为、状态转换和边界条件。
- 组合方式以 state-transition、boundary-directed、diagnostic-directed 和 single-factor 为主。
- no-test 内容记录为内部解释、环境成本高或已由专项测试点承接的部分。

## 附录 A

### 章节定位
- 测试点数量：18 个。
- 覆盖原则：每个测试点只验证一个主要场景；内部机制类测试尽量通过稳定 SQL、系统视图或配置边界观测。

### 测试因子矩阵

| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 覆盖测试点/用例名称 |
|---|---|---|---|---|---|
| F01 | behavior/state/boundary | TCL 命令入口与 transaction mode 边界 | BEGIN/START、COMMIT/ROLLBACK、SET TRANSACTION、READ ONLY/DEFERRABLE、SNAPSHOT | P0/P1/P2 | TCL-BEGIN-INSIDE-TXN-WARNING、TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION、TCL-START-TRANSACTION-EQUIVALENT-BEGIN、TCL-START-TRANSACTION-MODE-COMMA-OMIT、TCL-COMMIT-OUTSIDE-TXN-WARNING、TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR、TCL-COMMIT-AND-CHAIN-KEEPS-MODES、TCL-ROLLBACK-OUTSIDE-TXN-WARNING、TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR、TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES、TCL-SET-TRANSACTION-NO-BEGIN-WARNING、TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR、TCL-SET-SESSION-DEFAULT-MODES、TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED、TCL-READONLY-DISALLOW-DML-DDL、TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY、TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE、TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY |

### 边界值关注项

- 无单独边界表；边界已体现在测试点和组合方式中。

### 组合方式

| 组合ID | 组合方法 | 生成的测试点 | 组合理由 |
|---|---|---|---|
| C01 | boundary-directed / single-factor | TCL-BEGIN-INSIDE-TXN-WARNING、TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION、TCL-START-TRANSACTION-EQUIVALENT-BEGIN、TCL-START-TRANSACTION-MODE-COMMA-OMIT、TCL-COMMIT-OUTSIDE-TXN-WARNING、TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR、TCL-COMMIT-AND-CHAIN-KEEPS-MODES、TCL-ROLLBACK-OUTSIDE-TXN-WARNING、TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR、TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES、TCL-SET-TRANSACTION-NO-BEGIN-WARNING、TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR、TCL-SET-SESSION-DEFAULT-MODES、TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED、TCL-READONLY-DISALLOW-DML-DDL、TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY、TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE、TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY | 根据事务状态转换、边界异常或诊断观测定向组合，避免全组合爆炸。 |

### No-test 记录

| no-test ID | 官方内容/边界 | 不单独生成测试点的原因 | 覆盖或追溯方式 |
|---|---|---|---|
| NT01 | 附录 A 中的内部实现解释、性能成本说明或需要 crash/cluster 级环境的专项说明。 | 不适合作为普通自动化 SQL 主路径，或已由 P1/P2 special 测试点承接。 | 保留为 no-test/special 说明；由本节 18 个测试点及边界值关注项共同追溯。 |

### 测试点清单

| 用例名称 | 优先级 | 测试点 | 组合方式 |
|---|---|---|---|
| TCL-BEGIN-INSIDE-TXN-WARNING | P0 | 已在事务块内再次执行 BEGIN 只产生 warning，不影响事务状态；嵌套事务应使用 savepoint。 | boundary-directed |
| TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION | P0 | BEGIN 指定 isolation/read write/deferrable 模式时，效果等同事务开始时执行 SET TRANSACTION。 | single-factor |
| TCL-START-TRANSACTION-EQUIVALENT-BEGIN | P0 | START TRANSACTION 与 BEGIN 功能等价。 | single-factor |
| TCL-START-TRANSACTION-MODE-COMMA-OMIT | P1 | PostgreSQL 为兼容历史允许 transaction modes 之间省略逗号。 | single-factor |
| TCL-COMMIT-OUTSIDE-TXN-WARNING | P0 | 不在事务块内执行 COMMIT 无实际影响但产生 warning。 | boundary-directed |
| TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR | P0 | 不在事务块内执行 COMMIT AND CHAIN 是错误。 | boundary-directed |
| TCL-COMMIT-AND-CHAIN-KEEPS-MODES | P0 | COMMIT AND CHAIN 立即开启新事务，并继承刚结束事务的 transaction characteristics。 | single-factor |
| TCL-ROLLBACK-OUTSIDE-TXN-WARNING | P0 | 不在事务块内执行 ROLLBACK 产生 warning 且无其他效果。 | boundary-directed |
| TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR | P0 | 不在事务块内执行 ROLLBACK AND CHAIN 是错误。 | boundary-directed |
| TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES | P0 | ROLLBACK AND CHAIN 立即开启新的非 aborted 事务，并继承刚结束事务的 transaction characteristics。 | single-factor |
| TCL-SET-TRANSACTION-NO-BEGIN-WARNING | P0 | 未先 BEGIN 或 START TRANSACTION 时执行 SET TRANSACTION 产生 warning 且无效果。 | boundary-directed |
| TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR | P0 | 事务执行第一个查询或数据修改语句后，不允许再改变 isolation level。 | boundary-directed |
| TCL-SET-SESSION-DEFAULT-MODES | P1 | SET SESSION CHARACTERISTICS 只影响后续事务默认特征，可被单个事务 SET TRANSACTION 覆盖。 | single-factor |
| TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED | P0 | PostgreSQL 中 READ UNCOMMITTED 按 READ COMMITTED 处理。 | single-factor |
| TCL-READONLY-DISALLOW-DML-DDL | P0 | READ ONLY 事务禁止对非临时表执行写 DML，并禁止 DDL、权限、truncate 等修改类命令。 | single-factor |
| TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY | P0 | DEFERRABLE 只有在 SERIALIZABLE READ ONLY 事务中才有实际效果。 | single-factor |
| TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE | P0 | SET TRANSACTION SNAPSHOT 只能在事务开始处，且事务隔离级别已为 REPEATABLE READ 或 SERIALIZABLE。 | boundary-directed |
| TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY | P1 | 导入方若为 SERIALIZABLE，导出 snapshot 的事务也必须为 SERIALIZABLE；非只读 serializable 事务不能从只读事务导入 snapshot。 | single-factor |

### 充分性结论
- 本节 18 个测试点覆盖了当前章节的核心行为、状态转换和边界条件。
- 组合方式以 state-transition、boundary-directed、diagnostic-directed 和 single-factor 为主。
- no-test 内容记录为内部解释、环境成本高或已由专项测试点承接的部分。
