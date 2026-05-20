# MySQL / PostgreSQL / Oracle 锁机制差异总结

本文是三套单库锁知识库的横向总结，目标不是重复定义每个术语，而是回答迁移和业务开发中最常见的问题：同一个并发场景，在 MySQL、PostgreSQL、Oracle 中分别如何实现、如何阻塞、如何报错、如何排查，以及代码迁移时要改哪里。

对应单库文档：

- `锁知识/mysql/mysql-locks-knowledge-base.md`
- `锁知识/postgresql/postgresql-locks-knowledge-base.md`
- `锁知识/oracle/oracle-locks-knowledge-base.md`

## 1. 三种数据库的并发控制主线

| 数据库 | 并发控制主线 | 最需要建立的心智模型 |
| --- | --- | --- |
| MySQL/InnoDB | MVCC + index record lock + gap/next-key lock + MDL | SQL 走哪个索引，决定锁住哪些索引记录和范围 |
| PostgreSQL | MVCC tuple version + table/row lock modes + SSI predicate lock | tuple 多版本、明确的行锁模式、`pg_locks` 可观测 |
| Oracle | multiversion read consistency + undo/SCN + TX/TM enqueue + ITL | 普通读写不互阻，写写看 TX，表级协调看 TM，行锁和数据块/ITL 相关 |

粗略来说：

- MySQL 锁问题经常要问：执行计划走哪个索引？有没有 gap/next-key？是不是 MDL？
- PostgreSQL 锁问题经常要问：等的是 relation、tuple、transactionid、advisory，还是 LWLock/BufferPin？
- Oracle 锁问题经常要问：等的是 TX、TM、DDL lock、ITL，还是 latch/mutex？

## 2. 普通读与写的关系

| 问题 | MySQL/InnoDB | PostgreSQL | Oracle |
| --- | --- | --- | --- |
| 普通 `SELECT` 是否阻塞 `UPDATE` | 通常不阻塞 | 不阻塞 | 不阻塞 |
| `UPDATE` 是否阻塞普通 `SELECT` | 通常不阻塞 | 不阻塞 | 不阻塞 |
| 是否允许脏读 | `READ UNCOMMITTED` 可读未提交 | 不允许，RU 等价 RC | 不允许 |
| 普通读依赖什么 | read view + undo | snapshot + tuple version | SCN + undo |
| 普通读是否加业务行锁 | 通常不加 | 不加 | 不加 |

三者都能做到普通读写不互相阻塞，但实现不同：

- MySQL/InnoDB 通过 read view 和 undo 构造一致性读。
- PostgreSQL 通过 tuple version 和 snapshot 判断可见性。
- Oracle 通过 SCN 和 undo 构造 read consistency。

迁移提醒：不要因为“普通读不阻塞写”这个表象相同，就认为三者隔离级别、加锁读、范围查询行为相同。

## 3. MVCC 实现差异

| 维度 | MySQL/InnoDB | PostgreSQL | Oracle |
| --- | --- | --- | --- |
| 旧版本来源 | undo log | 表内 tuple versions | undo segment |
| 可见性依据 | read view、事务 ID | snapshot、`xmin` / `xmax` | SCN |
| 清理机制 | purge | vacuum / autovacuum | undo 空间复用 |
| 长事务风险 | purge 滞后、history list 增长 | vacuum 受阻、表/索引膨胀 | undo 保留压力、`ORA-01555` |
| 常见诊断重点 | 长事务、undo、purge | `backend_xmin`、autovacuum、膨胀 | undo retention、长查询 |

迁移时尤其要注意 PostgreSQL：长事务不只是持锁问题，还会阻止旧 tuple 被清理，导致表膨胀和 autovacuum 压力。

Oracle 则要特别关注长查询和 undo 保留时间，典型错误是：

```text
ORA-01555: snapshot too old
```

## 4. 隔离级别差异

### 4.1 `READ UNCOMMITTED`

| 数据库 | 行为 |
| --- | --- |
| MySQL | 支持脏读语义，可能读到未提交数据 |
| PostgreSQL | 接受该级别名称，但实际等价 `READ COMMITTED` |
| Oracle | 不提供真正脏读 |

迁移提醒：如果旧 MySQL 业务依赖 `READ UNCOMMITTED` 做“脏读提速”，迁移到 PostgreSQL 或 Oracle 时不能照搬。

### 4.2 `READ COMMITTED`

| 数据库 | 行为重点 |
| --- | --- |
| MySQL | 每次 consistent read 新 read view；gap lock 更少；`UPDATE` 可用 semi-consistent read |
| PostgreSQL | 每条语句新 snapshot；DML 等待并发事务后 recheck 条件 |
| Oracle | 每条语句基于语句开始时 SCN 做一致性读 |

PostgreSQL 的 recheck 很重要：`UPDATE` 等待另一个事务结束后，不是盲目继续更新，而是重新检查 `WHERE` 条件。

MySQL 的半一致性读也容易被忽略：它主要用于减少 `READ COMMITTED` 下 `UPDATE` 扫描到无关锁定行时的无谓等待。

### 4.3 `REPEATABLE READ`

| 数据库 | 行为重点 |
| --- | --- |
| MySQL | InnoDB 默认；普通读事务级 read view；范围加锁读可能 next-key lock |
| PostgreSQL | Snapshot Isolation；防不可重复读和幻读；并发更新可能 `40001` |
| Oracle | 无同名常用主线，更多看 `SERIALIZABLE` / `READ ONLY` |

迁移提醒：MySQL `REPEATABLE READ` 和 PostgreSQL `REPEATABLE READ` 不能按名字等价理解。

### 4.4 `SERIALIZABLE`

| 数据库 | 实现重点 | 常见失败 |
| --- | --- | --- |
| MySQL | 更强隔离和加锁行为 | 死锁、锁等待 |
| PostgreSQL | SSI + predicate/SIREAD lock | `40001 serialization_failure` |
| Oracle | 事务级一致性视图 | `ORA-08177` |

PostgreSQL 和 Oracle 的可串行化冲突更需要应用层事务级重试。

## 5. 行锁模型差异

| 维度 | MySQL/InnoDB | PostgreSQL | Oracle |
| --- | --- | --- | --- |
| 行锁底层对象 | index record | tuple | row + block transaction info |
| 是否按二级索引记录锁理解 | 是，二级索引路径可能锁二级索引记录和聚簇索引记录 | 否 | 否 |
| 行锁是否阻塞普通读 | 否 | 否 | 否 |
| 行锁模式 | S/X，加 gap/next-key/insert intention 等 | `FOR UPDATE`、`FOR NO KEY UPDATE`、`FOR SHARE`、`FOR KEY SHARE` | 业务上多看 TX 行锁 |
| 持有到何时 | 事务结束 | 事务结束，或 savepoint 回滚释放 | 事务结束 |

最容易踩坑的是 MySQL：

```sql
SELECT * FROM orders WHERE status = 1 FOR UPDATE;
```

如果走二级索引 `idx_status`，InnoDB 可能锁二级索引记录，也锁对应聚簇索引记录，还可能涉及 gap/next-key。这个模型不能套到 PostgreSQL 或 Oracle。

PostgreSQL 要关注 tuple 行锁模式，Oracle 要关注 TX/TM、数据块和 ITL。

## 6. 加锁读差异

| 能力 | MySQL | PostgreSQL | Oracle |
| --- | --- | --- | --- |
| 最强加锁读 | `FOR UPDATE` | `FOR UPDATE` | `FOR UPDATE` |
| 共享加锁读 | `FOR SHARE` | `FOR SHARE` / `FOR KEY SHARE` | 无完全同构模式 |
| 中间模式 | 无 PG 那么细 | `FOR NO KEY UPDATE` | 无完全同构模式 |
| 指定锁表 | 子查询需单独写锁定子句 | `FOR UPDATE OF table_name` | `FOR UPDATE OF column` 语法关注列/表语义 |
| 立即失败 | `NOWAIT` | `NOWAIT` | `NOWAIT` |
| 跳过锁行 | `SKIP LOCKED` | `SKIP LOCKED` | `SKIP LOCKED` |
| 有限等待 | 依赖锁等待参数/语法支持情况 | 通常用 `lock_timeout` | `WAIT n` |

业务迁移建议：

- MySQL 到 PostgreSQL：根据意图选择 `FOR UPDATE`、`FOR NO KEY UPDATE`、`FOR SHARE`、`FOR KEY SHARE`，不要一律 `FOR UPDATE`。
- MySQL 到 Oracle：重点看是否需要 `NOWAIT` / `WAIT n` / `SKIP LOCKED`，以及事务是否足够短。
- PostgreSQL 队列场景通常可以用 `FOR UPDATE SKIP LOCKED`，但返回的是不完整视图。

## 7. 范围查询、防幻读与 Predicate/GAP 差异

| 数据库 | 主要机制 | 是否直接阻止范围插入 |
| --- | --- | --- |
| MySQL/InnoDB | gap lock / next-key lock | 是，特定隔离级别和加锁读下会阻止 |
| PostgreSQL | SSI predicate/SIREAD lock | 通常不直接阻止，而是检测冲突后可能 `40001` |
| Oracle | read consistency + serializable 冲突检测 | 不按 MySQL gap lock 模型理解 |

MySQL 例子：

```sql
SELECT * FROM t WHERE c BETWEEN 10 AND 20 FOR UPDATE;
```

在 InnoDB `REPEATABLE READ` 下，这类范围加锁读可能通过 next-key lock 阻止其他事务插入范围内的新值。

PostgreSQL 的 predicate lock 不等价于 MySQL gap lock：

- 它主要用于 Serializable SSI 冲突检测。
- 它不直接作为业务锁阻塞普通插入。
- 冲突结果通常是某个事务 `40001`。

Oracle 也没有 MySQL 式 next-key lock 主线。可串行化冲突更多表现为 `ORA-08177`。

核心提醒：

**MySQL next-key lock、PostgreSQL predicate lock、Oracle serializable 冲突，三者都和幻读/可串行化相关，但机制和业务表现完全不同。**

## 8. 表锁、元数据锁与 DDL 锁差异

| 维度 | MySQL | PostgreSQL | Oracle |
| --- | --- | --- | --- |
| 元数据/DDL 主线 | MDL | table lock modes，尤其 `ACCESS EXCLUSIVE` | DDL locks |
| 普通 DDL 风险 | 长事务持 MDL，DDL 等待并阻塞后续 DML | `ALTER TABLE` 等获取强表锁 | DML 未提交阻塞 DDL，DDL 可能隐式提交 |
| 显式表锁 | `LOCK TABLES` | `LOCK TABLE` | `LOCK TABLE` |
| 最常见线上坑 | pending DDL 引发阻塞链 | `ACCESS EXCLUSIVE` 阻塞普通 SELECT | DDL implicit commit + object lock |

MySQL 典型阻塞链：

1. 长事务访问表，持有 MDL。
2. DDL 等待更强 MDL。
3. 后续 DML/SELECT 被 pending DDL 阻塞。

PostgreSQL 典型风险：

- `ALTER TABLE`
- `DROP TABLE`
- `TRUNCATE`
- `VACUUM FULL`
- 默认 `LOCK TABLE`

这些可能获取 `ACCESS EXCLUSIVE`，阻塞普通 `SELECT`。

Oracle 典型风险：

- DDL lock 需要对象定义稳定。
- DML 未提交可能阻塞 DDL。
- DDL 通常伴随隐式提交，不应混入普通业务事务。

## 9. 外键与唯一约束锁差异

| 主题 | MySQL | PostgreSQL | Oracle |
| --- | --- | --- | --- |
| 外键检查 | 父子表锁等待，受索引和隔离级别影响 | `FOR KEY SHARE` / key column 语义关键 | 未索引外键是高风险点 |
| 删除/更新父表 key | 可能等待子表相关检查 | 和子表引用、key share 冲突相关 | 子表外键无索引可能导致 TM 等待 |
| 唯一键并发插入 | 等待未提交事务，可能冲突 | unique conflict，`ON CONFLICT` | 等待未提交事务，提交后判断 |
| upsert | `ON DUPLICATE KEY UPDATE` | `ON CONFLICT` | `MERGE` 或应用逻辑 |

迁移提醒：

- Oracle 高并发 OLTP 中，外键列是否建索引要重点检查。
- PostgreSQL 外键相关锁要理解 `FOR KEY SHARE` 和 key column。
- MySQL 外键/唯一检查可能叠加 gap/next-key 和索引路径影响。

## 10. 应用级锁差异

| 数据库 | 机制 | 生命周期 | 主要风险 |
| --- | --- | --- | --- |
| MySQL | `GET_LOCK()` / `RELEASE_LOCK()` | session | 事务提交不释放，连接池复用危险 |
| PostgreSQL | advisory locks | session-level 或 transaction-level | session-level 回滚不释放，锁 key 设计不当 |
| Oracle | `DBMS_LOCK` / UL enqueue | 取决于调用和释放策略 | 权限、使用成本、业务封装 |

建议：

- 短期业务互斥优先使用事务级语义的锁。
- session-level 应用锁必须和连接池严格隔离。
- 应用锁的 key 命名要规范，避免不同业务误用同一 key。
- 应用锁不能替代数据库约束。

PostgreSQL 的 transaction-level advisory lock 是三者里对短事务业务互斥比较友好的工具：

```sql
BEGIN;
SELECT pg_advisory_xact_lock(12345);
-- business work
COMMIT;
```

## 11. 锁升级与锁范围扩大差异

| 数据库 | 是否传统自动行锁升级表锁 | 更常见的误判来源 |
| --- | --- | --- |
| MySQL/InnoDB | 通常不做 | 索引路径导致锁范围扩大、gap/next-key、MDL |
| PostgreSQL | 不做 | DDL 强锁、大量行锁、predicate lock 粒度提升 |
| Oracle | 通常不做 | 未索引外键、DDL lock、ITL、显式表锁 |

重要区分：

- MySQL 锁范围扩大常来自执行计划和索引路径。
- PostgreSQL 表级锁和行级锁同时存在是正常协议，不是升级。
- PostgreSQL predicate lock 粒度提升服务于 SSI 检测，不是业务行锁升级。
- Oracle lock conversion 是正常机制，不等于行锁升级表锁。

看到“像锁表”的现象时，先不要说锁升级，要先查：

1. 是否 DDL 或显式表锁。
2. 是否扫描/锁住大量行。
3. 是否约束检查。
4. 是否长事务。
5. 是否内部同步等待。

## 12. 内部同步机制差异

| 数据库 | 内部同步关键词 | 主要观测入口 |
| --- | --- | --- |
| MySQL/InnoDB | latch、mutex、rw-lock、spin wait | Performance Schema `wait/synch/...` |
| PostgreSQL | LWLock、BufferPin、heavyweight lock manager | `pg_stat_activity.wait_event_type` |
| Oracle | latch、mutex、enqueue、buffer busy waits | wait events、ASH、AWR |

内部同步和业务事务锁不同：

- 业务锁通常能对应到表、行、事务或对象。
- 内部同步更多是共享内存、buffer、解析、缓存、日志、索引页等内部结构竞争。
- 解决方式往往不是“提交事务”，而是优化热点、SQL、索引、连接数、缓存或系统参数。

## 13. 死锁、序列化失败与错误码差异

| 场景 | MySQL | PostgreSQL | Oracle |
| --- | --- | --- | --- |
| 死锁 | `Deadlock found...` | `40P01 deadlock_detected` | `ORA-00060` |
| 序列化失败 | 依隔离级别和冲突而定 | `40001 serialization_failure` | `ORA-08177` |
| 锁等待超时 | `innodb_lock_wait_timeout` | `lock_timeout` | `ORA-00054` 或等待超时相关机制 |
| 快照/旧版本问题 | purge/undo 压力 | vacuum 受长事务影响 | `ORA-01555` |
| 唯一冲突 | duplicate key | `23505` | unique constraint violated |

重试原则：

- 死锁要重试整个事务。
- PostgreSQL `40001` 要重试整个事务。
- Oracle `ORA-08177` 要重试整个事务。
- MySQL 锁等待超时是否重试要看事务状态和业务语义。
- 不要只重试失败的单条 SQL，除非你非常确定事务上下文仍然正确。

## 14. 锁问题排查视图差异

| 数据库 | 核心入口 | 重点 |
| --- | --- | --- |
| MySQL | `SHOW ENGINE INNODB STATUS` | 最近死锁、事务和锁等待 |
| MySQL | `performance_schema.data_locks` / `data_lock_waits` | 行锁和等待关系 |
| MySQL | `performance_schema.metadata_locks` | MDL |
| MySQL | `events_waits_summary...` | latch/mutex 等内部等待 |
| PostgreSQL | `pg_stat_activity` | session、等待事件、长事务 |
| PostgreSQL | `pg_locks` | relation/tuple/transactionid/advisory/predicate locks |
| PostgreSQL | `pg_blocking_pids()` | 阻塞链 |
| Oracle | `V$SESSION` | session、等待事件、blocking session |
| Oracle | `V$LOCK` / `V$LOCKED_OBJECT` | TX/TM 和对象锁 |
| Oracle | `DBA_BLOCKERS` / `DBA_WAITERS` | 阻塞关系 |
| Oracle | ASH / AWR | 历史等待和性能诊断 |

排查顺序建议：

1. 先确认等待类型。
2. 再找 blocker 和 blocked。
3. 看事务年龄和 SQL。
4. 判断是业务锁、DDL 锁、约束等待还是内部同步。
5. 最后回到索引、事务边界和业务访问顺序。

## 15. 业务迁移场景对照

### 15.1 读后更新

| 数据库 | 推荐关注 |
| --- | --- |
| MySQL | `FOR UPDATE` 是否走合适索引，是否触发 gap/next-key |
| PostgreSQL | 选择 `FOR UPDATE` / `FOR NO KEY UPDATE` / `FOR KEY SHARE` |
| Oracle | `FOR UPDATE`，必要时加 `NOWAIT` / `WAIT n` |

迁移建议：从 MySQL 迁到 PostgreSQL 时，不要一律把读后更新写成 `FOR UPDATE`，如果只是防止 key 被删改，可能 `FOR KEY SHARE` 或 `FOR NO KEY UPDATE` 更合适。

### 15.2 队列任务领取

| 数据库 | 常见写法 |
| --- | --- |
| MySQL | `SELECT ... FOR UPDATE SKIP LOCKED` |
| PostgreSQL | `SELECT ... FOR UPDATE SKIP LOCKED LIMIT n` |
| Oracle | `SELECT ... FOR UPDATE SKIP LOCKED` |

共同注意：

- 结果是不完整视图。
- 事务要短。
- 任务状态更新要和领取在同一事务内。
- 要有合适索引支持筛选和排序。

### 15.3 高并发 upsert

| 数据库 | 常见机制 | 注意点 |
| --- | --- | --- |
| MySQL | `INSERT ... ON DUPLICATE KEY UPDATE` | 死锁、唯一索引、更新路径 |
| PostgreSQL | `INSERT ... ON CONFLICT` | unique conflict、`DO NOTHING`/`DO UPDATE` 差异 |
| Oracle | `MERGE` 或应用逻辑 | 并发 action 判断、唯一冲突 |

迁移建议：upsert 是高并发死锁/重试高发区，应先设计唯一键、访问顺序和事务重试。

### 15.4 父子表删除/更新

| 数据库 | 重点 |
| --- | --- |
| MySQL | 外键检查、索引、gap/next-key 影响 |
| PostgreSQL | `FOR KEY SHARE` 和 key column |
| Oracle | 子表外键列必须重点检查索引 |

Oracle 未索引外键尤其容易导致 TM 等待，是迁移审查重点。

### 15.5 在线 DDL

| 数据库 | 最大风险 |
| --- | --- |
| MySQL | MDL 阻塞链 |
| PostgreSQL | `ACCESS EXCLUSIVE` 阻塞普通读 |
| Oracle | DDL lock 和 implicit commit |

上线 DDL 前都应检查长事务和阻塞，但三者要看的视图和风险点不同。

### 15.6 可串行化事务

| 数据库 | 重点 |
| --- | --- |
| MySQL | 更强隔离下锁行为变化 |
| PostgreSQL | SSI + `40001` |
| Oracle | `ORA-08177` |

迁移建议：如果业务依赖可串行化，必须把事务级重试作为应用协议的一部分。

## 16. 最终速查表

### 16.1 加锁读语法

| 数据库 | 主要语法 |
| --- | --- |
| MySQL | `FOR UPDATE`、`FOR SHARE`、`NOWAIT`、`SKIP LOCKED` |
| PostgreSQL | `FOR UPDATE`、`FOR NO KEY UPDATE`、`FOR SHARE`、`FOR KEY SHARE`、`OF`、`NOWAIT`、`SKIP LOCKED` |
| Oracle | `FOR UPDATE`、`NOWAIT`、`WAIT n`、`SKIP LOCKED` |

### 16.2 最强 DDL/表锁风险

| 数据库 | 高危点 |
| --- | --- |
| MySQL | MDL、`LOCK TABLES` |
| PostgreSQL | `ACCESS EXCLUSIVE` |
| Oracle | DDL lock、implicit commit |

### 16.3 应用锁

| 数据库 | 应用锁 |
| --- | --- |
| MySQL | `GET_LOCK()` |
| PostgreSQL | advisory locks |
| Oracle | `DBMS_LOCK` |

### 16.4 必须重试的典型错误

| 数据库 | 错误 |
| --- | --- |
| MySQL | deadlock found；部分锁等待超时视业务处理 |
| PostgreSQL | `40001`、`40P01` |
| Oracle | `ORA-00060`、`ORA-08177` |

### 16.5 最容易踩坑点

| 数据库 | 踩坑点 |
| --- | --- |
| MySQL | 把行锁误解成逻辑行，忽略二级索引/gap/MDL |
| PostgreSQL | 忽略 `ACCESS EXCLUSIVE`、长事务阻碍 vacuum、没有重试 `40001` |
| Oracle | 忽略未索引外键、DDL 隐式提交、把 latch/ITL/TX/TM 混为一谈 |

## 17. 迁移时的通用原则

1. 不按术语直译，按并发问题映射。
2. 普通读写不互阻只是表象，隔离级别和加锁读差异更重要。
3. 所有高并发写路径都要有事务级重试策略。
4. DDL 上线前必须查长事务和锁等待。
5. 队列领取可以用 `SKIP LOCKED`，但要接受不完整视图。
6. 外键和唯一约束是锁问题高发区，不只是数据完整性定义。
7. 内部同步等待不是业务锁，排查和优化路径不同。
8. 先用各自数据库的官方观测视图确认事实，再修改业务代码。
