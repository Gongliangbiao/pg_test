# PostgreSQL 16.4 Concurrency Control 与 Transaction Processing 测试点关系总结

## 1. 文档定位

本文档用于说明两个测试模块之间的关系、交集、区别和后续用例编写边界。

涉及文档：

- `docs/archive/concurrency-control-by-official-chapter/`
- `docs/plans/concurrency-control/coverage-audit.md`
- `docs/plans/transaction-processing/test-point-plan.md`

两个模块都与事务有关，但来源章节、测试视角和证明目标不同：

- `Concurrency Control` 基于官方 `Chapter 13. Concurrency Control`，重点验证并发访问同一数据时，用户可观察到的隔离、锁、阻塞、错误和一致性行为。
- `Transaction Processing` 基于官方 `Chapter 74. Transaction Processing`，重点验证 PostgreSQL 事务管理内部机制，包括事务 ID、subtransaction、2PC、内部目录和系统视图观测。

## 2. 总体区别

| 对比项 | Concurrency Control | Transaction Processing |
|---|---|---|
| 官方章节 | Chapter 13 | Chapter 74 |
| 文档定位 | 用户行为和应用开发层面的并发语义 | PostgreSQL 内部事务管理机制 |
| 核心问题 | 多会话同时访问同一数据时会发生什么 | 一个事务在系统内部如何被标识、记录、提交、回滚和恢复 |
| 主要对象 | MVCC、隔离级别、锁冲突、死锁、Serializable、应用一致性、索引并发 | vxid、xid、xid8、pg_xact、pg_subtrans、subxid、GID、pg_prepared_xacts、pg_twophase |
| 测试结果形态 | 可见性变化、阻塞/不阻塞、SQLSTATE、最终数据一致性 | ID 分配时机、系统视图/目录状态、内部状态转换、边界限制 |
| 常用会话模型 | 多为 2 会话并发交互 | 单会话机制验证 + 必要的 2 会话观测 |
| 典型错误码 | `40001`、`40P01`、`23505`、`23P01` | 2PC、TCL、GID、事务块边界相关错误 |
| 后续用例风格 | 更强调并发时序和业务结果 | 更强调状态观测和内部边界 |

## 3. 交集概览

两个模块存在交集，但交集通常不是重复，而是同一现象的不同观察层。

| 交集主题 | Concurrency Control 关注点 | Transaction Processing 关注点 | 是否重复 |
|---|---|---|---|
| 显式事务 `BEGIN/COMMIT/ROLLBACK` | 事务边界对可见性、锁持有和隔离级别的影响 | 显式事务如何创建和结束，隐式单语句事务如何工作 | 有交集，不重复 |
| 隔离级别 | `READ COMMITTED`、`REPEATABLE READ`、`SERIALIZABLE` 下并发现象 | TCL 入口中 `SET TRANSACTION`、`BEGIN` transaction mode 的生效边界 | 有交集，侧重点不同 |
| MVCC 可见性 | 读不阻塞写、写不阻塞读、快照稳定性、phantom、serialization anomaly | xid 分配、pg_xact committed 状态、xid8/wraparound 是 MVCC 的内部基础 | 有交集，层次不同 |
| 锁 | 表锁、行锁、页锁、advisory lock、死锁、阻塞关系 | `pg_locks` 中 `virtualxid`/`transactionid`、行锁 tuple 存储、multixact | 有交集，不重复 |
| Savepoint/subtransaction | savepoint rollback 释放锁、行锁和表锁回滚边界 | subtransaction 树、subxid、pg_subtrans、subcommit/abort 传播 | 有交集，transaction 更底层 |
| Prepared transaction/2PC | prepared transaction 可能阻塞重试或保持锁 | 2PC 状态机、GID、pg_prepared_xacts、pg_twophase、跨 checkpoint/crash | 有交集，transaction 是主模块 |
| Read-only 事务 | Serializable read only deferrable、只读事务冲突风险 | 只读事务有 vxid 但通常不分配 xid；只读 subtransaction 不分配 subxid | 有交集，观察点不同 |
| 系统视图观测 | `pg_locks` 用于证明锁和 SIReadLock | `pg_locks`、`pg_prepared_xacts`、pg_xact/pg_subtrans/pg_twophase 用于证明内部状态 | 有交集，观测目的不同 |

## 4. 模块侧重点

### 4.1 Concurrency Control 的侧重点

Concurrency Control 更偏“外部语义”和“应用正确性”。

重点问题：

- 同一数据被多个会话同时读写时，哪些结果可见，哪些不可见。
- 不同隔离级别下是否允许 dirty read、nonrepeatable read、phantom read、serialization anomaly。
- `READ COMMITTED` 下语句级快照、等待后重检 `WHERE`、`ON CONFLICT`、`MERGE` 的可观察行为。
- `REPEATABLE READ` 下事务级快照和 `40001`。
- `SERIALIZABLE` 下 SSI、predicate lock、可串行化保证和重试策略。
- 表级锁、行级锁、页级锁、advisory lock 的冲突矩阵与阻塞关系。
- 应用层一致性检查应该使用 Serializable，还是显式阻塞锁。
- 重试策略应该覆盖哪些 SQLSTATE。
- hot standby、logical replica、DDL 非 MVCC-safe、索引并发访问等 Caveats。

一句话概括：Concurrency Control 证明“用户和应用在并发环境下能看到什么、会等什么、会报什么错、最终数据是否一致”。

### 4.2 Transaction Processing 的侧重点

Transaction Processing 更偏“内部机制”和“状态管理”。

重点问题：

- 显式事务和隐式单语句事务如何建立和结束。
- 每个事务如何获得 `VirtualTransactionId`，什么时候获得非虚拟 `xid`。
- `xid`、`xid8`、epoch、wraparound 的边界。
- 提交状态如何写入 `pg_xact`，开启 `track_commit_timestamp` 后如何记录提交时间。
- 锁等待在 `pg_locks` 中如何表现为 `virtualxid` 或 `transactionid`。
- subtransaction 如何形成层级树，什么时候分配 `subxid`，父子 xid 顺序如何保证。
- `pg_subtrans` 记录什么，不记录什么。
- 64 个 open subxids 缓存阈值之后为什么会增加 `pg_subtrans` 查找开销。
- 2PC 的 `PREPARE TRANSACTION`、`COMMIT PREPARED`、`ROLLBACK PREPARED` 状态机。
- GID 长度、唯一性、跨会话完成、权限、配置上限和 crash/checkpoint 边界。

一句话概括：Transaction Processing 证明“PostgreSQL 内部如何给事务编号、保存状态、处理子事务和 prepared transaction”。

## 5. 主要交集的处理原则

### 5.1 锁相关

Concurrency Control 应负责：

- 锁模式冲突矩阵。
- 哪些 SQL 自动获取哪些表锁/行锁。
- 阻塞、死锁、lock timeout、`pg_locks` 可观察结果。
- 行锁是否阻塞普通查询。

Transaction Processing 应负责：

- 事务锁在 `pg_locks.virtualxid` 和 `pg_locks.transactionid` 中如何出现。
- 只读事务为什么有 `virtualxid` 但无 `transactionid`。
- 行级锁为何不按每行直接保存在 `pg_locks`。
- multixact 是否因多个行级读锁产生。

避免重复的写法：

- 如果用例目标是“锁冲突是否阻塞”，放在 Concurrency Control。
- 如果用例目标是“锁等待关联到哪个事务 ID”，放在 Transaction Processing。

### 5.2 Savepoint/subtransaction 相关

Concurrency Control 应负责：

- savepoint rollback 后释放在 savepoint 之后获取的表锁或行锁。
- 显式锁与 savepoint 之间的用户可观察行为。

Transaction Processing 应负责：

- `SAVEPOINT` 启动 subtransaction。
- 只读 subtransaction 不分配 subxid。
- 写 subtransaction 分配 subxid，并让父链分配 xid。
- `pg_subtrans` 父子映射。
- subcommit/abort 如何受顶层事务最终结果控制。
- 64 open subxids 缓存阈值。

避免重复的写法：

- 如果断言是“锁被释放了”，放在 Concurrency Control。
- 如果断言是“subxid/pg_subtrans 状态如何变化”，放在 Transaction Processing。

### 5.3 Prepared transaction/2PC 相关

Concurrency Control 应负责：

- prepared transaction 持锁导致其他事务无法推进。
- prepared transaction 可能影响重试策略。
- 与 prepared transaction 冲突时，必须等待其 commit/rollback。

Transaction Processing 应负责：

- `PREPARE TRANSACTION` 的状态转换。
- GID 的长度、唯一性和 `pg_prepared_xacts` 映射。
- `COMMIT PREPARED`/`ROLLBACK PREPARED` 跨会话完成。
- `max_prepared_transactions` 边界。
- `pg_twophase`、checkpoint、crash recovery。
- 禁止 prepare 的场景，例如临时表、`WITH HOLD` cursor、`LISTEN/UNLISTEN/NOTIFY`。

避免重复的写法：

- 如果目标是“prepared transaction 是否阻塞其他事务”，放在 Concurrency Control。
- 如果目标是“prepared transaction 本身如何保存、查询、提交或回滚”，放在 Transaction Processing。

### 5.4 隔离级别相关

Concurrency Control 应负责：

- `READ COMMITTED`、`REPEATABLE READ`、`SERIALIZABLE` 的并发语义。
- 隔离级别矩阵和并发现象。
- serialization failure 和应用重试。

Transaction Processing 应负责：

- `SET TRANSACTION`、`BEGIN`、`START TRANSACTION` 的事务入口边界。
- `COMMIT AND CHAIN`、`ROLLBACK AND CHAIN` 的事务特性继承。
- `SET TRANSACTION SNAPSHOT` 的导入限制。

避免重复的写法：

- 如果目标是“某隔离级别下看到什么数据”，放在 Concurrency Control。
- 如果目标是“事务特性如何设置、生效或继承”，放在 Transaction Processing。

## 6. 不同模块的测试设计关键词

| 模块 | 关键词 |
|---|---|
| Concurrency Control | visibility、snapshot、blocking、conflict matrix、deadlock、retry、serialization failure、business consistency、index concurrency |
| Transaction Processing | identifier、xid、vxid、xid8、epoch、pg_xact、pg_subtrans、subxid、GID、pg_prepared_xacts、pg_twophase、checkpoint、crash recovery |

## 7. 后续写详细步骤时的归属规则

建议使用以下判断规则：

| 判断问题 | 归属 |
|---|---|
| 是否需要两个会话竞争同一行或同一表来证明结果？ | 优先 Concurrency Control |
| 是否主要验证隔离级别下的可见性或异常现象？ | Concurrency Control |
| 是否主要验证锁冲突、阻塞、死锁、advisory lock 行为？ | Concurrency Control |
| 是否主要验证事务 ID 何时分配、如何显示或如何持久化？ | Transaction Processing |
| 是否主要验证 subtransaction 内部父子关系或 `pg_subtrans`？ | Transaction Processing |
| 是否主要验证 prepared transaction 的状态、GID、系统视图或磁盘状态？ | Transaction Processing |
| 是否只是用 `pg_locks` 做辅助观测？ | 看主断言；主断言是冲突行为则 Concurrency，主断言是事务 ID 状态则 Transaction |
| 是否涉及应用层一致性策略？ | Concurrency Control |
| 是否涉及 crash/checkpoint 后事务状态恢复？ | Transaction Processing |

## 8. 结论

这两个模块不是简单重复关系，而是上下两层关系：

- Concurrency Control 是“外部并发语义层”，面向应用和 SQL 用户，证明并发场景下的数据可见性、锁冲突和错误处理。
- Transaction Processing 是“内部事务机制层”，面向 PostgreSQL 内部实现和系统状态，证明事务标识、子事务、2PC 和事务状态记录。

真正的交集集中在锁、savepoint、prepared transaction 和事务入口命令上。后续写详细用例时，应坚持“主断言归属原则”：看这个用例最终要证明的是外部并发行为，还是内部事务状态。这样既能保留两个模块的完整覆盖，又不会让相同场景在两个目录里重复堆叠。
