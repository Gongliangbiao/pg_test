# PostgreSQL 锁知识库

本文档面向已经熟悉 MySQL、正在学习 PostgreSQL 并发控制与锁机制的开发者。PostgreSQL 的主线不是 InnoDB 的 gap lock / next-key lock，也不是 Oracle 的 ITL/enqueue 体系，而是 MVCC tuple version、明确的表级锁模式、行级锁模式、Serializable Snapshot Isolation、predicate lock、advisory lock，以及 `pg_locks` / `pg_stat_activity` 排查体系。

本文主要依据 PostgreSQL 16.4 官方并发控制章节与本仓库本地 YAML 知识库整理。最后只保留三库对比索引，系统性差异后续应单独写成 `锁知识/database-locks-comparison.md`。

## 1. PostgreSQL 并发控制总览

PostgreSQL 使用 MVCC，Multiversion Concurrency Control，来提高并发读写能力。

基本原则：

- 普通读不阻塞写。
- 写不阻塞普通读。
- 写写冲突会等待、失败或触发重试错误。
- 每个 SQL 语句或事务看到的是某个 snapshot 下可见的数据版本。
- `VACUUM` 负责清理不再需要的旧版本。

PostgreSQL 锁体系可以按层次理解：

| 分类 | 代表机制 | 主要对象 | 常见观测入口 |
| --- | --- | --- | --- |
| Table-level locks | `ACCESS SHARE` 到 `ACCESS EXCLUSIVE` | relation | `pg_locks` |
| Row-level locks | `FOR UPDATE`、`FOR KEY SHARE` 等 | tuple | `pg_locks`、等待事件 |
| Page-level locks | page share/exclusive locks | 表页、索引页 | 通常短暂、用户少感知 |
| Advisory locks | `pg_advisory_lock` 系列 | 应用自定义 key | `pg_locks` |
| Predicate locks | SIREAD locks | tuple/page/relation predicate | `pg_locks`、SSI |
| Internal locks | LWLock、buffer pin 等 | 共享内存、buffer、内部结构 | `pg_stat_activity.wait_event` |

排查 PostgreSQL 锁问题，最重要的入口通常是：

- `pg_stat_activity`
- `pg_locks`
- `pg_blocking_pids(pid)`

## 2. MVCC、Tuple Version 与可见性

### 2.1 Tuple 多版本

PostgreSQL 的 `UPDATE` 不是原地覆盖一行，而是创建新的 tuple version。旧版本在一段时间内仍然保留，用于支持并发事务的一致性读。

简化理解：

```sql
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
```

执行后，旧 tuple 对某些旧 snapshot 仍可能可见，新 tuple 对后续事务或语句可见。

### 2.2 `xmin` / `xmax`

每个 tuple 有事务可见性相关元信息，常见概念包括：

- `xmin`：创建该 tuple version 的事务 ID。
- `xmax`：删除或更新该 tuple version 的事务 ID，或锁定相关信息。

这些字段帮助 PostgreSQL 判断某个 tuple version 对当前 snapshot 是否可见。

### 2.3 Snapshot 与 Visibility

Snapshot 决定当前语句或事务能看到哪些事务提交的结果。

在 `READ COMMITTED` 下：

- 每条语句通常使用新的 snapshot。
- 同一事务内两次查询可能看到不同已提交结果。

在 `REPEATABLE READ` / `SERIALIZABLE` 下：

- 事务内使用更稳定的 snapshot。
- 并发写冲突可能导致 `40001`。

### 2.4 `UPDATE` / `DELETE` 与旧版本

`UPDATE` 创建新版本，旧版本之后会被 vacuum 清理。

`DELETE` 标记旧 tuple 不再对新事务可见，但也不是立即物理删除。

这会带来几个重要后果：

- 长事务会阻止旧版本被清理。
- 表和索引可能膨胀。
- `VACUUM` 对 OLTP 系统很重要。
- `backend_xmin` 可以帮助识别阻碍清理的长事务。

### 2.5 VACUUM 与长事务

长事务或长时间 `idle in transaction` 会让旧版本长期不能回收。

风险：

- 表膨胀。
- 索引膨胀。
- autovacuum 效果变差。
- 事务 ID 年龄风险。
- 查询性能下降。

所以 PostgreSQL 的锁知识不能只看“谁阻塞谁”，还要看长事务对 MVCC 清理的影响。

## 3. 事务隔离级别与并发行为

### 3.1 `READ UNCOMMITTED`

PostgreSQL 接受 SQL 标准中的 `READ UNCOMMITTED` 名称，但实际行为等价于 `READ COMMITTED`。

也就是说，PostgreSQL 不会提供脏读。

### 3.2 `READ COMMITTED`

PostgreSQL 默认隔离级别。

特点：

- 每条语句看到语句开始时已提交的数据。
- 普通 `SELECT` 使用当前语句 snapshot。
- 同一事务内两次 `SELECT` 可能看到不同结果。
- `UPDATE` / `DELETE` 遇到并发更新时，会等待对方事务结束，然后重新检查 `WHERE` 条件。

例子：

```sql
BEGIN;
SELECT * FROM accounts WHERE id = 1;
-- 其他事务提交修改
SELECT * FROM accounts WHERE id = 1;
COMMIT;
```

两次查询可能看到不同结果。

### 3.3 `REPEATABLE READ`

PostgreSQL 的 `REPEATABLE READ` 基于 Snapshot Isolation。

特点：

- 事务内使用稳定 snapshot。
- 防止不可重复读。
- PostgreSQL 的实现也防止幻读。
- 如果事务尝试更新自事务开始后已被其他事务修改的行，可能报 `40001`。

常见错误：

```text
could not serialize access due to concurrent update
```

### 3.4 `SERIALIZABLE`

PostgreSQL 的 `SERIALIZABLE` 使用 Serializable Snapshot Isolation，简称 SSI。

特点：

- 不靠简单阻塞所有并发读写实现。
- 通过检测读写依赖和 dangerous structure 防止序列化异常。
- 可能在提交或执行过程中报 `40001 serialization_failure`。
- 应用必须准备重试整个事务。

### 3.5 隔离级别与锁的关系

隔离级别决定快照可见性和冲突处理；锁决定谁能同时访问或修改资源。

分析并发问题时要同时看：

- 当前隔离级别。
- 是普通读、加锁读还是 DML。
- 是否涉及唯一约束、外键、SSI。
- 等待的是 relation、tuple、transactionid、advisory，还是 LWLock/buffer pin。

## 4. 表级锁 Table-Level Locks

PostgreSQL 提供八种表级锁模式。它们可以由 SQL 自动获取，也可以通过 `LOCK TABLE` 显式获取。

### 4.1 `ACCESS SHARE`

普通 `SELECT` 获取 `ACCESS SHARE`。

它只和 `ACCESS EXCLUSIVE` 冲突。

这意味着：普通 `SELECT` 一般不会被 DML 阻塞，但会被某些强 DDL 或显式 `ACCESS EXCLUSIVE` 锁阻塞。

### 4.2 `ROW SHARE`

`SELECT FOR UPDATE` / `SELECT FOR SHARE` 等加锁读会获取 `ROW SHARE` 表级锁。

名字里有 `ROW`，但它仍然是表级锁模式。

### 4.3 `ROW EXCLUSIVE`

常见 DML 获取 `ROW EXCLUSIVE`：

- `INSERT`
- `UPDATE`
- `DELETE`
- `MERGE`

它会和 `SHARE`、`SHARE ROW EXCLUSIVE`、`EXCLUSIVE`、`ACCESS EXCLUSIVE` 等冲突。

### 4.4 `SHARE UPDATE EXCLUSIVE`

常见来源：

- `VACUUM`
- `ANALYZE`
- `CREATE INDEX CONCURRENTLY`
- `REINDEX CONCURRENTLY`

它用于防止并发 schema 变更和某些维护命令冲突。

### 4.5 `SHARE`

非 concurrent 的 `CREATE INDEX` 通常获取 `SHARE`。

它允许查询，但会阻止并发数据修改。

### 4.6 `SHARE ROW EXCLUSIVE`

常见于：

- `CREATE TRIGGER`
- 某些 `ALTER TABLE`

它是自排他的，通常同一时间只允许一个会话持有。

### 4.7 `EXCLUSIVE`

例如：

- `REFRESH MATERIALIZED VIEW CONCURRENTLY`

`EXCLUSIVE` 仍允许并发 `ACCESS SHARE`，也就是普通读，但会阻止更多写和锁请求。

### 4.8 `ACCESS EXCLUSIVE`

最强表级锁。常见来源：

- `DROP TABLE`
- `TRUNCATE`
- `VACUUM FULL`
- 大多数 `ALTER TABLE`
- `LOCK TABLE` 默认模式

`ACCESS EXCLUSIVE` 和所有锁模式冲突，包括普通 `SELECT` 的 `ACCESS SHARE`。

### 4.9 表级锁注意点

重点：

- 表级锁通常持有到事务结束。
- 如果锁是在 savepoint 之后获得的，回滚到该 savepoint 会释放这些锁。
- 事务不和自身冲突。
- 名称里的 `ROW` 是历史命名，不代表行锁。
- 线上最容易造成大面积阻塞的是 `ACCESS EXCLUSIVE`。

## 5. 行级锁 Row-Level Locks

PostgreSQL 行级锁用于锁定特定 tuple，防止其他事务修改、删除或获取冲突锁。

行级锁不阻塞普通 `SELECT`。

### 5.1 `FOR UPDATE`

最强行级锁。

会阻止其他事务：

- `UPDATE`
- `DELETE`
- `SELECT FOR UPDATE`
- `SELECT FOR NO KEY UPDATE`
- `SELECT FOR SHARE`
- `SELECT FOR KEY SHARE`

常见来源：

- `SELECT ... FOR UPDATE`
- `DELETE`
- 修改 key column 的 `UPDATE`

### 5.2 `FOR NO KEY UPDATE`

比 `FOR UPDATE` 弱。

普通 `UPDATE` 如果不修改 key column，通常获取 `FOR NO KEY UPDATE`。

它不会阻塞 `SELECT FOR KEY SHARE`。

### 5.3 `FOR SHARE`

共享行锁。

允许其他事务获取 `FOR SHARE` 或 `FOR KEY SHARE`，但阻止强更新和删除相关操作。

```sql
SELECT * FROM accounts WHERE id = 1 FOR SHARE;
```

### 5.4 `FOR KEY SHARE`

最弱行级锁。

主要用于保护可被外键引用的 key 不被删除或修改。

```sql
SELECT * FROM parent WHERE id = 1 FOR KEY SHARE;
```

### 5.5 行级锁的重要特性

- 行级锁持有到事务结束。
- savepoint 回滚可以释放 savepoint 之后获得的行锁。
- 行级锁不阻塞普通查询。
- 锁定行可能导致磁盘写入，因为 tuple 需要标记锁状态。
- 行级锁数量没有固定内存上限，可以锁很多行，但这会增加事务和 I/O 成本。

## 6. `SELECT ... FOR UPDATE/SHARE` 加锁读

### 6.1 基本语法

```sql
SELECT ...
FROM table_name
WHERE condition
FOR { UPDATE | NO KEY UPDATE | SHARE | KEY SHARE }
[ OF table_name [, ...] ]
[ NOWAIT | SKIP LOCKED ];
```

### 6.2 `OF table_name`

多表 join 中，`OF` 可以指定锁定哪些表的行。

```sql
SELECT o.*, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.id = 100
FOR UPDATE OF o;
```

这样只锁 `orders` 的目标行，不锁 `customers` 的行。

### 6.3 `NOWAIT`

无法立即获取行锁时报错，而不是等待。

```sql
SELECT * FROM jobs WHERE id = 1 FOR UPDATE NOWAIT;
```

适合用户请求、后台抢占式任务等不希望长时间等待的场景。

### 6.4 `SKIP LOCKED`

跳过已经被其他事务锁定的行。

典型队列领取：

```sql
BEGIN;

SELECT id
FROM jobs
WHERE status = 'pending'
ORDER BY id
FOR UPDATE SKIP LOCKED
LIMIT 1;

-- UPDATE jobs SET status = 'running' WHERE id = ...;
COMMIT;
```

注意：

- 返回的是不完整视图。
- 适合队列，不适合完整一致性查询。
- 需要配合短事务和合适索引。

### 6.5 大范围加锁读风险

避免在大范围查询上直接加锁：

```sql
SELECT * FROM orders WHERE status = 'pending' FOR UPDATE;
```

风险：

- 锁住大量行。
- 阻塞其他写入。
- 增加死锁概率。
- 增加 tuple 标记写入成本。

更好方式：

- 使用精确条件。
- 分批。
- 稳定排序。
- 队列场景使用 `SKIP LOCKED`。
- 缩短事务。

## 7. `UPDATE` / `DELETE` / `INSERT` / `MERGE` 的锁行为

### 7.1 `UPDATE`

`UPDATE` 通常：

- 获取表级 `ROW EXCLUSIVE`。
- 对目标行获取行级锁。
- 如果不修改 key column，通常获取 `FOR NO KEY UPDATE` 语义的锁。
- 如果修改 key column，可能需要更强的 `FOR UPDATE` 语义。

`READ COMMITTED` 下，如果目标行已被其他事务更新，当前语句会等待对方结束，然后重新检查 `WHERE` 条件。

`REPEATABLE READ` / `SERIALIZABLE` 下，如果目标行自事务开始后已被并发修改，可能报 `40001`。

### 7.2 `DELETE`

`DELETE` 对目标行获取强行锁。

它会和其他事务对同一行的更新、删除、加锁读冲突。

外键引用场景中，删除父表 key 还会和子表外键检查相关锁发生关系。

### 7.3 `INSERT`

`INSERT` 通常获取表级 `ROW EXCLUSIVE`。

常见冲突不是“和普通读冲突”，而是：

- 唯一约束冲突。
- 排除约束冲突。
- 外键检查。
- 插入热点导致索引页或内部等待。

### 7.4 `INSERT ... ON CONFLICT`

`ON CONFLICT` 是 PostgreSQL 的 upsert 机制。

高并发下要关注：

- 唯一索引冲突。
- 冲突行更新。
- `DO NOTHING` 可能因为不可见冲突而跳过。
- `DO UPDATE` 需要对冲突行加锁并更新。

### 7.5 `MERGE`

`MERGE` 根据匹配结果执行不同 action。

在 `READ COMMITTED` 下，如果并发修改导致条件变化，PostgreSQL 可能重新评估 action。业务上不要假设一次判断永久有效。

## 8. 外键、唯一约束与锁

### 8.1 外键与 `FOR KEY SHARE`

PostgreSQL 有专门的 `FOR KEY SHARE` 行锁模式，用来保护外键相关 key。

典型场景：

- 子表插入需要确认父表 key 存在。
- 父表 key 被删除或修改时，需要和子表引用检查协调。

### 8.2 Key Column

PG 文档中的 key column 通常指有唯一索引且可用于外键引用的列。

修改这些列时，锁模式可能更强，因为它会影响外键引用的稳定性。

### 8.3 唯一约束并发插入

两个事务插入相同唯一键：

```sql
INSERT INTO users(email) VALUES ('a@example.com');
```

后发事务可能等待先发事务结果：

- 先发事务提交：后发事务报 `23505 unique_violation`。
- 先发事务回滚：后发事务继续成功。

某些 `23505` 在业务上其实来自并发选择相同 key，可能需要按重试策略处理。

### 8.4 排除约束

排除约束冲突可能返回：

```text
23P01 exclusion_violation
```

在某些业务场景中，这也可能是并发竞争的结果。

### 8.5 约束检查与重试

PostgreSQL 官方建议无条件重试 `40001`。对于 `23505` 和 `23P01`，是否重试要看业务语义：

- 如果是客户端生成确定性重复 key，重试无意义。
- 如果是并发事务都根据当前状态选择同一个 key，重试可能有意义。

## 9. Predicate Locks 与 Serializable SSI

### 9.1 SSI 主线

PostgreSQL 的 `SERIALIZABLE` 使用 Serializable Snapshot Isolation。

它不会简单阻塞所有可能冲突的读写，而是跟踪读写依赖，在发现可能产生非串行化结果时中止其中一个事务。

### 9.2 Predicate Lock / SIREAD Lock

Serializable 中会使用 predicate lock，也称 SIREAD lock。

特点：

- 用于检测读写依赖。
- 不阻塞普通读写。
- 可能显示在 `pg_locks`。
- 可能在事务提交后短暂保留。
- 不是 MySQL gap lock 那种阻止插入的业务锁。

### 9.3 粒度

Predicate lock 粒度可能是：

- tuple
- page
- relation

在内存压力下，锁粒度可能被提升。例如多个细粒度 predicate lock 合并成更粗粒度 lock。

这可能增加 `40001 serialization_failure` 概率，但不等于传统行锁升级为表锁。

### 9.4 配置参数

相关参数：

- `max_pred_locks_per_transaction`
- `max_pred_locks_per_relation`
- `max_pred_locks_per_page`

如果 Serializable 工作负载误报或失败率较高，除了优化事务逻辑，也可能需要检查这些配置。

### 9.5 `40001 serialization_failure`

错误：

```text
40001 serialization_failure
```

处理原则：

- 回滚整个事务。
- 重新执行完整业务逻辑。
- 高争用时加入退避。
- 保证业务幂等。

## 10. Page-Level Locks、Buffer Pin 与内部同步

### 10.1 Page-Level Locks

PostgreSQL 文档提到表页和索引页上有 page-level share/exclusive locks。

这些锁：

- 控制页级读写一致性。
- 通常在获取或更新一行后立即释放。
- 用户一般不直接感知。

### 10.2 Buffer Pin

Buffer pin 表示某个 backend 正在使用 buffer。

它不是普通业务行锁，但可能导致等待，例如：

- 某些 vacuum 或 DDL 等待其他 backend 释放 buffer pin。
- 长时间运行的查询持有 buffer pin。

在 `pg_stat_activity` 中可能看到 wait event type 相关信息。

### 10.3 LWLock

LWLock 是 lightweight lock，用于保护共享内存内部结构。

常见等待类型：

```text
wait_event_type = 'LWLock'
```

它和 SQL 级表锁、行锁不同，更多用于内部并发控制。

### 10.4 Heavyweight Lock Manager

PostgreSQL 的表锁、某些事务锁、advisory lock 等通过 heavyweight lock manager 管理。

`pg_locks` 主要展示这一层面的锁信息，同时也可以看到 advisory lock、predicate lock 等。

### 10.5 业务锁和内部等待的区别

排查时要先看：

```sql
SELECT wait_event_type, wait_event
FROM pg_stat_activity
WHERE pid = ...;
```

粗略判断：

- `Lock`：多半和 heavyweight lock、行锁等待、事务 ID 等有关。
- `LWLock`：内部共享结构竞争。
- `BufferPin`：buffer 使用者未释放。
- `IO`：I/O 等待。

## 11. Advisory Locks

### 11.1 基本概念

Advisory lock 是应用自定义语义的锁。数据库只负责提供锁机制，不理解业务含义。

适合：

- 应用级互斥。
- 外部资源协调。
- 跨表业务资源锁。
- 少量任务调度保护。

### 11.2 Session-Level Advisory Lock

会话级 advisory lock 持有到显式释放或 session 结束。

```sql
SELECT pg_advisory_lock(12345);
SELECT pg_advisory_unlock(12345);
```

注意：

- 不遵循事务语义。
- `ROLLBACK` 不会释放。
- 同一 session 多次获取需要对应释放。
- 连接池中要非常小心。

### 11.3 Transaction-Level Advisory Lock

事务级 advisory lock 在事务结束时自动释放。

```sql
BEGIN;
SELECT pg_advisory_xact_lock(12345);
COMMIT;
```

通常比 session-level 更适合短期业务互斥。

### 11.4 Shared 与 Exclusive

支持共享和排他模式：

- `pg_advisory_lock`
- `pg_advisory_lock_shared`
- `pg_advisory_xact_lock`
- `pg_advisory_xact_lock_shared`

### 11.5 Try Lock

非阻塞尝试：

```sql
SELECT pg_try_advisory_lock(12345);
SELECT pg_try_advisory_xact_lock(12345);
```

返回 `true` / `false`，不会一直等待。

### 11.6 容量与危险写法

Advisory lock 使用共享内存，容量受以下参数影响：

- `max_locks_per_transaction`
- `max_connections`

危险写法：

```sql
SELECT pg_advisory_lock(id)
FROM foo
WHERE id > 12345
LIMIT 100;
```

函数可能在 `LIMIT` 前被执行，导致锁住超过预期的 key。

安全写法：

```sql
SELECT pg_advisory_lock(q.id)
FROM (
  SELECT id
  FROM foo
  WHERE id > 12345
  LIMIT 100
) q;
```

## 12. DDL、`LOCK TABLE` 与维护命令锁

### 12.1 `LOCK TABLE`

语法概览：

```sql
LOCK TABLE table_name [ IN lockmode MODE ] [ NOWAIT ];
```

如果不指定 lock mode，默认是 `ACCESS EXCLUSIVE`。

这很危险，因为它会阻塞普通 `SELECT`。

### 12.2 常见 DDL 锁

常见强锁来源：

- `ALTER TABLE`
- `DROP TABLE`
- `TRUNCATE`
- `VACUUM FULL`
- 非 concurrent 的 `CREATE INDEX`

很多线上阻塞事故都和 `ACCESS EXCLUSIVE` 有关。

### 12.3 `CREATE INDEX` 与 `CREATE INDEX CONCURRENTLY`

普通 `CREATE INDEX` 会阻塞并发写。

`CREATE INDEX CONCURRENTLY` 并发性更好，但：

- 耗时更长。
- 不能在普通事务块中执行。
- 失败后可能留下 invalid index。
- 仍然会持有一定锁，只是比普通建索引友好。

### 12.4 `VACUUM` / `ANALYZE`

普通 `VACUUM` 和 `ANALYZE` 使用相对温和的锁，通常不阻塞普通读写。

但 `VACUUM FULL` 会重写表，需要 `ACCESS EXCLUSIVE`，会阻塞所有访问。

### 12.5 `TRUNCATE`

`TRUNCATE` 获取强锁，不是普通 `DELETE`。

注意：

- 会阻塞并发访问。
- 不逐行删除。
- 对并发事务可见性有特殊 caveat。
- 需要谨慎用于在线业务。

### 12.6 `REFRESH MATERIALIZED VIEW`

`REFRESH MATERIALIZED VIEW` 与 `REFRESH MATERIALIZED VIEW CONCURRENTLY` 锁行为不同。

后者允许更多并发访问，但需要满足前置条件，例如唯一索引。

## 13. 锁升级、锁范围与常见误区

### 13.1 PostgreSQL 没有传统自动锁升级

PostgreSQL 不会因为事务锁住很多行，就自动把行锁升级为表锁。

表级锁和行级锁可以同时存在，但这不是锁升级。例如 `UPDATE` 会同时有：

- 表级 `ROW EXCLUSIVE`
- 目标行的行级锁

这是正常锁协议。

### 13.2 大量行锁不等于表锁

一个事务更新大量行，会持有大量行级锁，但不会自动变成 `ACCESS EXCLUSIVE`。

但它仍然可能造成：

- 大量写写冲突。
- 长事务。
- vacuum 清理受阻。
- 死锁概率上升。
- 回滚成本高。

### 13.3 Predicate Lock 粒度提升不是业务锁升级

Serializable 下 predicate lock 可能从 tuple/page 级提升到 relation 级。

这服务于 SSI 冲突检测，可能增加 `40001` 概率，但它不等同于业务行锁升级为表锁，也不直接阻塞普通读写。

### 13.4 容易误判为锁升级的场景

- DDL 获取 `ACCESS EXCLUSIVE`。
- 显式 `LOCK TABLE`。
- 大事务锁住大量行。
- 外键或唯一约束等待。
- `VACUUM FULL` / `TRUNCATE`。
- Serializable predicate lock 粒度提升。
- autovacuum 或 maintenance 相关等待。
- advisory lock 使用不当。

## 14. 死锁、锁等待与错误码

### 14.1 死锁

PostgreSQL 自动检测死锁，并中止其中一个事务。

错误码：

```text
40P01 deadlock_detected
```

被中止的事务不可预测，不应依赖某个事务一定获胜。

### 14.2 序列化失败

错误码：

```text
40001 serialization_failure
```

常见于：

- `REPEATABLE READ` 并发更新冲突。
- `SERIALIZABLE` SSI 检测到危险读写依赖。

处理方式：重试整个事务。

### 14.3 锁等待控制参数

常用参数：

- `lock_timeout`
- `statement_timeout`
- `idle_in_transaction_session_timeout`
- `deadlock_timeout`

说明：

- `lock_timeout` 控制等待锁的最长时间。
- `statement_timeout` 控制语句总执行时间。
- `idle_in_transaction_session_timeout` 防止事务空闲太久。
- `deadlock_timeout` 影响死锁检测启动时机。

### 14.4 其他可能需要重试的错误

官方建议无条件重试 `40001`，也建议重试死锁 `40P01`。

此外某些业务里也可能考虑重试：

- `23505 unique_violation`
- `23P01 exclusion_violation`

但这两个要结合业务判断，不能无脑重试。

## 15. 锁问题排查工具

### 15.1 `pg_stat_activity`

常用字段：

- `pid`
- `state`
- `wait_event_type`
- `wait_event`
- `backend_xid`
- `backend_xmin`
- `query`
- `xact_start`
- `query_start`

识别长事务：

```sql
SELECT pid, state, xact_start, now() - xact_start AS xact_age, query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY xact_start;
```

### 15.2 `pg_locks`

`pg_locks` 显示当前锁状态。

常见 locktype：

- `relation`
- `tuple`
- `transactionid`
- `virtualxid`
- `advisory`
- `page`
- `object`

关键字段：

- `locktype`
- `database`
- `relation`
- `page`
- `tuple`
- `virtualxid`
- `transactionid`
- `classid`
- `objid`
- `mode`
- `granted`
- `pid`

### 15.3 `pg_blocking_pids`

查谁阻塞某个 session：

```sql
SELECT
  a.pid,
  a.wait_event_type,
  a.wait_event,
  pg_blocking_pids(a.pid) AS blocking_pids,
  a.query
FROM pg_stat_activity a
WHERE cardinality(pg_blocking_pids(a.pid)) > 0;
```

### 15.4 对象定位

常用系统目录：

- `pg_class`
- `pg_namespace`
- `pg_constraint`
- `pg_index`
- `pg_attribute`

例如把 relation oid 转成表名：

```sql
SELECT relation::regclass, mode, granted, pid
FROM pg_locks
WHERE relation IS NOT NULL;
```

### 15.5 排查典型问题

排查方向：

- 谁阻塞谁？
- 是否 DDL 获取强锁？
- 是否行锁等待？
- 是否等待 `transactionid`？
- 是否 advisory lock？
- 是否 `idle in transaction`？
- 是否 autovacuum / vacuum 相关？
- 是否 Serializable predicate lock？
- 是否长事务阻碍 vacuum？

### 15.6 一个基础阻塞链查询

```sql
SELECT
  blocked.pid AS blocked_pid,
  blocked.query AS blocked_query,
  blocker.pid AS blocker_pid,
  blocker.query AS blocker_query
FROM pg_stat_activity blocked
JOIN LATERAL unnest(pg_blocking_pids(blocked.pid)) AS b(pid) ON true
JOIN pg_stat_activity blocker ON blocker.pid = b.pid;
```

这只是起点。生产排查还需要结合锁模式、事务年龄、应用名、客户端地址和 SQL 执行计划。

## 16. 业务开发最佳实践

### 16.1 短事务

事务越长，越容易：

- 持有锁。
- 阻碍 vacuum。
- 造成表膨胀。
- 增加死锁概率。
- 放大回滚成本。

不要在事务中等待用户输入或外部系统响应。

### 16.2 避免 `idle in transaction`

`idle in transaction` 是 PostgreSQL 事故高发来源。

建议设置：

```sql
SET idle_in_transaction_session_timeout = '10min';
```

生产中应结合系统情况配置为合理值。

### 16.3 固定访问顺序

多行、多表更新要固定顺序，降低死锁。

```sql
SELECT *
FROM accounts
WHERE id IN (1, 2)
ORDER BY id
FOR UPDATE;
```

### 16.4 首先获取最严格锁模式

如果事务后续一定需要更强锁，尽早获取最严格锁模式，避免中途升级意图导致死锁。

### 16.5 事务级重试

必须重试整个事务：

- `40001`
- `40P01`

重试时：

- 回滚当前事务。
- 重新执行完整业务逻辑。
- 使用有限次数。
- 高争用时加退避。
- 保证幂等。

### 16.6 队列场景使用 `SKIP LOCKED`

`FOR UPDATE SKIP LOCKED` 适合多 worker 领取任务。

但要注意：

- 结果不是完整一致视图。
- 需要短事务。
- 需要合适索引。
- 任务状态更新必须和领取在同一事务内。

### 16.7 谨慎使用 advisory lock

建议：

- 优先使用 transaction-level advisory lock。
- session-level 必须显式释放。
- 连接池场景非常小心。
- 锁 key 设计要有命名规范。
- 避免一次获取过多 advisory locks。

### 16.8 DDL 前检查阻塞风险

执行 DDL 前：

- 查长事务。
- 查 `idle in transaction`。
- 查目标表上的锁。
- 评估是否会获取 `ACCESS EXCLUSIVE`。
- 优先使用 `CREATE INDEX CONCURRENTLY` 等并发友好方案。

### 16.9 控制连接数

过多活跃连接会增加锁竞争、调度开销和内存压力。

建议使用连接池，并控制数据库实际活跃连接数。

### 16.10 Serializable 事务建议

使用 `SERIALIZABLE` 时：

- 事务要短。
- 准备重试。
- 尽量声明 `READ ONLY`。
- 避免不必要的显式锁。
- 关注 predicate lock 配置。

## 17. 实验案例库

这些实验后续可以拆成可执行 SQL 用例。

### 17.1 普通 `SELECT` 不阻塞 `UPDATE`

目标：验证 MVCC 下普通读不阻塞写。

流程：

- session 1 普通 `SELECT`。
- session 2 `UPDATE` 同一行。
- 观察 session 2 不等待 session 1。

### 17.2 `UPDATE` 阻塞另一个 `UPDATE`

目标：验证写写冲突。

流程：

- session 1 更新某行不提交。
- session 2 更新同一行。
- 观察等待。

### 17.3 `SELECT FOR UPDATE` 阻塞更新

目标：验证加锁读。

流程：

- session 1 `SELECT ... FOR UPDATE`。
- session 2 `UPDATE` 同一行。
- 观察等待。

### 17.4 `FOR NO KEY UPDATE` 与 `FOR KEY SHARE`

目标：验证行锁兼容性。

流程：

- session 1 对某行 `FOR NO KEY UPDATE`。
- session 2 对同一行 `FOR KEY SHARE`。
- 观察兼容行为。

### 17.5 `NOWAIT`

目标：验证无法拿锁立即失败。

流程：

- session 1 锁住行。
- session 2 `FOR UPDATE NOWAIT`。
- 观察报错。

### 17.6 `SKIP LOCKED`

目标：验证队列领取。

流程：

- session 1 锁住部分 pending 任务。
- session 2 `FOR UPDATE SKIP LOCKED LIMIT 1`。
- 观察跳过已锁定行。

### 17.7 `READ COMMITTED` 等待后重查条件

目标：理解等待后 recheck。

流程：

- session 1 更新某行使其不再满足条件。
- session 2 在 `READ COMMITTED` 下更新相同条件。
- session 2 等待后重查，可能不再更新该行。

### 17.8 `REPEATABLE READ` 并发更新触发 `40001`

目标：理解 snapshot isolation 下并发更新失败。

流程：

- 两个事务使用 `REPEATABLE READ`。
- 同时尝试更新同一行。
- 后提交或后更新者可能报 `40001`。

### 17.9 `SERIALIZABLE` 写偏斜触发 `40001`

目标：理解 SSI。

流程：

- 构造两个事务都读取集合条件。
- 分别写入不同记录。
- 在 `SERIALIZABLE` 下观察其中一个事务失败。

### 17.10 表级锁冲突矩阵

目标：验证 `ACCESS EXCLUSIVE` 阻塞普通 `SELECT`。

流程：

- session 1 `LOCK TABLE t IN ACCESS EXCLUSIVE MODE`。
- session 2 `SELECT * FROM t`。
- 观察等待。

### 17.11 Advisory lock session-level 回滚不释放

目标：理解 session-level 生命周期。

流程：

- session 1 开事务获取 `pg_advisory_lock`。
- rollback。
- session 2 尝试获取同一锁。
- 观察仍被阻塞。

### 17.12 Transaction-level advisory lock 自动释放

目标：理解 transaction-level 生命周期。

流程：

- session 1 获取 `pg_advisory_xact_lock`。
- commit。
- session 2 获取同一锁成功。

### 17.13 死锁触发 `40P01`

目标：复现死锁。

流程：

- 两事务按相反顺序更新两行。
- 观察 `40P01`。

### 17.14 `pg_locks` / `pg_blocking_pids` 排查

目标：把阻塞和视图关联。

流程：

- 构造行锁等待。
- 查询 `pg_blocking_pids`。
- 查询 `pg_locks`。
- 定位 blocker 和 blocked。

### 17.15 长事务阻止 vacuum 清理旧版本

目标：理解 MVCC 清理影响。

流程：

- session 1 开长事务保持 snapshot。
- session 2 大量更新并 vacuum。
- 观察旧版本不能完全清理。

## 18. 后续对比文档索引

本章不展开三库差异，只记录后续 `database-locks-comparison.md` 应覆盖的主题：

1. MVCC 实现差异。
2. 行锁存储差异。
3. 加锁读语法与语义差异。
4. 表锁、元数据锁、DDL 锁差异。
5. gap lock、predicate lock、SSI 差异。
6. 外键与唯一约束锁差异。
7. 锁升级与锁范围差异。
8. 内部同步机制差异。
9. 错误码与重试策略差异。
10. 锁排查视图差异。

## 参考资料

### 本地知识库

- `release-preview/skills/pg-sql/references/pg_skills/concurrency/mvcc.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/transaction_isolation.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/table_locks.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/row_locks.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/deadlock.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/serialization_failure.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/advisory_locks.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/locking_indexes.yaml`
- `release-preview/skills/pg-sql/references/pg_skills/concurrency/best_practices.yaml`

### 官方文档

- [PostgreSQL 16 Documentation: Chapter 13. Concurrency Control](https://www.postgresql.org/docs/16/mvcc.html)
- [PostgreSQL 16 Documentation: Transaction Isolation](https://www.postgresql.org/docs/16/transaction-iso.html)
- [PostgreSQL 16 Documentation: Explicit Locking](https://www.postgresql.org/docs/16/explicit-locking.html)
- [PostgreSQL 16 Documentation: Locking and Indexes](https://www.postgresql.org/docs/16/index-locking.html)
- [PostgreSQL 16 Documentation: Serialization Failure Handling](https://www.postgresql.org/docs/16/mvcc-serialization-failure-handling.html)
- [PostgreSQL 16 Documentation: The Statistics Collector](https://www.postgresql.org/docs/16/monitoring-stats.html)
- [PostgreSQL 16 Documentation: `pg_locks`](https://www.postgresql.org/docs/16/view-pg-locks.html)
- [PostgreSQL 16 Documentation: `pg_stat_activity`](https://www.postgresql.org/docs/16/monitoring-stats.html#MONITORING-PG-STAT-ACTIVITY-VIEW)
