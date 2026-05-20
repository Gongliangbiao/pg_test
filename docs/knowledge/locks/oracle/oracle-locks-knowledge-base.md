# Oracle 锁知识库

本文档面向已经熟悉 MySQL、正在学习 Oracle 并发控制与锁机制的开发者。Oracle 的锁体系和 MySQL/InnoDB 差异较大：它的主线不是 gap lock / next-key lock，而是多版本读一致性、Undo、SCN、TX/TM enqueue、DDL lock、ITL、latch/mutex 等概念。

本文按 Oracle 自身体系组织，最后只保留一个三库对比索引。MySQL、PostgreSQL、Oracle 的系统性差异后续应单独写成 `锁知识/database-locks-comparison.md`。

## 1. Oracle 并发控制总览

Oracle 并发控制的核心目标是：在保证一致性的同时，让读写尽量少互相阻塞。

几个基本原则：

- 普通读不阻塞写。
- 写不阻塞普通读。
- 写同一行会阻塞写。
- 查询通过 read consistency 看到一致性结果。
- 旧版本数据主要通过 undo 构造。
- 每个一致性视图和 SCN 相关。

Oracle 锁可以粗略分为：

| 分类 | 代表机制 | 保护对象 | 业务可见性 |
| --- | --- | --- | --- |
| DML locks | TX、TM | 行数据、表级 DML/DDL 协调 | 高 |
| DDL locks | Exclusive DDL lock、Share DDL lock、parse lock | schema object 定义 | 高 |
| System locks | enqueue、latch、mutex、internal lock | 内部结构和共享资源 | 中 |
| User-defined locks | DBMS_LOCK | 应用自定义资源 | 中 |

理解 Oracle 锁时，建议先区分三类问题：

1. 业务行被谁锁住了？
2. DML 和 DDL 是否互相阻塞？
3. 系统是否卡在内部 latch/mutex/enqueue 等等待上？

其中 TX/TM 等 enqueue 常常能直接解释业务 SQL 阻塞；latch/mutex 更多是内部性能诊断概念。

## 2. Oracle 读一致性与 MVCC

### 2.1 Statement-Level Read Consistency

Oracle 默认隔离级别是 `READ COMMITTED`。在这个隔离级别下，每条 SQL 语句看到语句开始时的一致性视图。

例如：

```sql
SELECT * FROM orders WHERE id = 100;
```

如果另一事务正在修改 `id = 100` 但尚未提交，普通 `SELECT` 不会等待它释放行锁，而是通过 undo 构造出符合当前语句一致性要求的已提交版本。

这意味着：

- 普通查询不会读到未提交数据。
- Oracle 不需要 dirty read 来提高并发。
- 同一个事务中两条普通查询，在 `READ COMMITTED` 下可能看到不同的已提交结果。

### 2.2 Transaction-Level Read Consistency

事务级读一致性主要对应：

- `SERIALIZABLE`
- `READ ONLY`

在这些模式下，一个事务内多条查询看到的视图更稳定，通常以事务开始时的时间点为一致性基础。

例子：

```sql
SET TRANSACTION READ ONLY;
SELECT COUNT(*) FROM orders;
SELECT SUM(amount) FROM orders;
COMMIT;
```

这类事务适合报表和长查询，但要注意 undo 保留时间以及 `ORA-01555` 风险。

### 2.3 Undo 与 Consistent Read

Oracle 使用 undo 保存被修改数据的旧版本信息。当查询需要看到旧版本时，Oracle 可以利用 undo 构造 consistent read clone。

关键概念：

- Undo segment：保存回滚和一致性读所需信息。
- SCN：System Change Number，用于标识数据库变化顺序。
- Consistent read：根据查询需要构造过去某个时间点的数据视图。
- CR clone：consistent read clone，即为一致性读构造的数据块版本。

### 2.4 `ORA-01555: snapshot too old`

`ORA-01555` 通常和长查询、一致性读、undo 保留不足有关。

典型原因：

- 查询运行时间过长。
- 查询需要的旧版本 undo 已被覆盖或不可用。
- undo retention 设置不足。
- 高并发写入导致 undo 压力大。

它不是普通锁等待错误，但和并发控制密切相关。排查长报表、批处理查询时要把它放在读一致性章节理解。

### 2.5 读写不互相阻塞的边界

普通读不阻塞写，写也不阻塞普通读，但下面这些情况会进入锁语义：

- `SELECT ... FOR UPDATE`
- `UPDATE`
- `DELETE`
- `MERGE`
- 约束检查
- DDL 修改对象定义
- 显式 `LOCK TABLE`

所以不要把“Oracle 读写不阻塞”理解成“Oracle 没有锁等待”。它只是普通一致性读和普通写之间尽量解耦。

## 3. Oracle DML 锁体系

### 3.1 DML Lock 总览

Oracle DML 锁主要包括：

- Row lock：行锁，常和 `TX` enqueue 相关。
- Table lock：表级 DML 锁，常和 `TM` enqueue 相关。

DML 语句包括：

- `INSERT`
- `UPDATE`
- `DELETE`
- `MERGE`
- `SELECT ... FOR UPDATE`

### 3.2 Row Lock 与 TX

Oracle 修改某行时，会锁住该行。其他事务如果也要修改同一行，就会等待。

典型场景：

```sql
-- session 1
UPDATE accounts SET balance = balance - 100 WHERE id = 1;

-- session 2
UPDATE accounts SET balance = balance + 50 WHERE id = 1;
-- 等待 session 1 提交或回滚
```

常见等待事件：

```text
enq: TX - row lock contention
```

特点：

- 行锁持有到事务提交或回滚。
- Oracle 行锁通常是排他性质的行级锁。
- 普通 `SELECT` 不等待这个行锁。
- 另一个 `UPDATE` / `DELETE` / `SELECT ... FOR UPDATE` 会等待。

### 3.3 Table Lock 与 TM

Oracle DML 语句通常也会在表上获得 TM 锁。TM 锁的作用不是简单地“锁整张表不让别人改”，而是协调 DML 与 DDL、约束维护等表级资源。

例如：

```sql
UPDATE orders SET status = 'DONE' WHERE id = 100;
```

这类语句除了行锁外，也会在 `orders` 上持有表级 DML 锁。其他事务仍然可以修改不同的行，但冲突 DDL 可能被阻塞。

常见等待事件：

```text
enq: TM - contention
```

### 3.4 TX 与 TM 的关系

可以这样理解：

- TX：解决事务层面的行级写写冲突、唯一性等待、ITL 等事务相关等待。
- TM：解决表级 DML/DDL 协调、外键相关表级等待等问题。

排查时不要只看到 `V$LOCK` 里有 TM 就以为“整表被锁不能 DML”。需要看锁模式、持有者、等待者、SQL 语句、对象和约束。

## 4. Oracle 表锁模式

Oracle 支持多种表锁模式。常见模式如下：

| 模式 | 缩写 | 常见来源 | 语义概览 |
| --- | --- | --- | --- |
| Row Share | RS / SS | `LOCK TABLE ... IN ROW SHARE MODE` | 较弱表锁 |
| Row Exclusive | RX / SX | 常见 DML | 表示将修改表中行 |
| Share | S | `LOCK TABLE ... IN SHARE MODE` | 允许读，限制写 |
| Share Row Exclusive | SRX / SSX | 显式锁 | 更强表锁 |
| Exclusive | X | `LOCK TABLE ... IN EXCLUSIVE MODE` | 最强表锁 |

### 4.1 Row Share

Row Share 允许多个事务并发持有。它表示事务可能要锁定表中的某些行。

示例：

```sql
LOCK TABLE orders IN ROW SHARE MODE;
```

### 4.2 Row Exclusive

Row Exclusive 是 DML 常见表锁模式。`INSERT`、`UPDATE`、`DELETE`、`SELECT ... FOR UPDATE` 通常会涉及这种类型的表级 DML 锁。

它允许其他事务并发修改表中不同的行，但会阻止某些冲突表锁或 DDL。

### 4.3 Share

Share 锁允许查询，但限制其他事务做某些修改。它比 Row Share / Row Exclusive 更强。

```sql
LOCK TABLE orders IN SHARE MODE;
```

### 4.4 Share Row Exclusive

Share Row Exclusive 比 Share 更强。它通常用于需要更强表级排他语义的场景。

```sql
LOCK TABLE orders IN SHARE ROW EXCLUSIVE MODE;
```

### 4.5 Exclusive

Exclusive 是最强表锁模式。

```sql
LOCK TABLE orders IN EXCLUSIVE MODE;
```

它会阻止其他事务对该表执行大多数 DML 或加锁操作。

### 4.6 `NOWAIT` 与 `WAIT`

显式表锁可以控制等待行为：

```sql
LOCK TABLE orders IN EXCLUSIVE MODE NOWAIT;
LOCK TABLE orders IN EXCLUSIVE MODE WAIT 5;
```

- `NOWAIT`：拿不到锁立即失败。
- `WAIT n`：等待最多 n 秒。
- 不指定时按默认等待策略。

## 5. 行锁存储：数据块、ITL 与 Row Lock

### 5.1 行锁信息存储在数据块中

Oracle 行锁模型和 MySQL/InnoDB 很不同。Oracle 的行锁信息与数据块中的事务信息相关，不是把所有行锁都集中记录在一个全局行锁表里。

当事务修改数据块中的行时，块头中的事务信息会记录相关事务，行本身也会和这些事务信息建立关联。

### 5.2 ITL

ITL 是 Interested Transaction List。每个数据块头部有 ITL entries，用于记录对该块中行感兴趣或正在修改的事务。

需要关注：

- `INITRANS`：块中预留的初始 ITL slot 数。
- 块中可用空间：影响能否扩展更多 ITL slot。
- 高并发更新同一数据块：可能出现 ITL 竞争。

ITL 不足时，事务可能等待可用 ITL slot。这类等待不是“行被别人锁住”那么简单，而是块级事务槽资源不足。

### 5.3 ITL 等待

可能出现 ITL 等待的场景：

- 热点块上大量并发更新。
- 表或索引块 `INITRANS` 太小。
- 块空间不足，无法扩展新的 ITL entry。
- 高并发更新集中在同一批相邻记录。

业务处理方向：

- 分散热点写入。
- 调整 `INITRANS`。
- 重建对象以应用新的存储参数。
- 优化索引设计和访问路径。
- 避免过度集中更新同一数据块。

### 5.4 行锁与索引维护

Oracle 业务语义中的行锁主语是数据行。索引当然会参与执行计划、唯一性检查、索引维护和内部同步，但不要用 MySQL/InnoDB 的“二级索引记录锁 + 聚簇索引记录锁”模型直接理解 Oracle。

需要区分：

- 更新行：锁住目标行。
- 更新索引列：需要维护索引结构。
- 插入唯一键：可能等待其他未提交事务的唯一性结果。
- 热索引块：可能表现为 buffer/latch 等内部竞争。

### 5.5 为什么这一章重要

很多从 MySQL 迁移到 Oracle 的开发者会问：“Oracle 的 `SELECT ... FOR UPDATE` 会不会锁二级索引记录？”

更合适的回答是：Oracle 的业务锁模型不按 InnoDB index record lock 来组织。你应该关注行锁、TX/TM、ITL、约束检查和等待事件，而不是套用 InnoDB 的索引记录锁术语。

## 6. `SELECT ... FOR UPDATE`

### 6.1 基本语义

普通 `SELECT` 不锁行：

```sql
SELECT * FROM jobs WHERE id = 10;
```

`SELECT ... FOR UPDATE` 锁定查询返回的行：

```sql
SELECT * FROM jobs WHERE id = 10 FOR UPDATE;
```

锁持有到事务提交或回滚。

### 6.2 默认等待

如果目标行已被其他事务锁住，`SELECT ... FOR UPDATE` 默认会等待。

```sql
SELECT * FROM jobs WHERE id = 10 FOR UPDATE;
```

### 6.3 `NOWAIT`

`NOWAIT` 表示如果无法立即获得锁，就直接报错。

```sql
SELECT * FROM jobs WHERE id = 10 FOR UPDATE NOWAIT;
```

常见错误：

```text
ORA-00054: resource busy and acquire with NOWAIT specified or timeout expired
```

适合场景：

- 用户交互请求不希望长时间卡住。
- 需要快速失败然后重试或返回提示。

### 6.4 `WAIT n`

`WAIT n` 表示最多等待 n 秒：

```sql
SELECT * FROM jobs WHERE id = 10 FOR UPDATE WAIT 5;
```

适合需要有限等待的业务流程。

### 6.5 `SKIP LOCKED`

`SKIP LOCKED` 会跳过已经被其他事务锁住的行：

```sql
SELECT *
FROM jobs
WHERE status = 'READY'
ORDER BY id
FETCH FIRST 1 ROW ONLY
FOR UPDATE SKIP LOCKED;
```

适合队列、任务领取等场景。

风险：

- 返回的是不完整视图。
- 结果可能跳过本来符合条件的锁定行。
- 不适合要求完整一致结果的业务查询。
- 要配合合适索引和短事务。

### 6.6 大范围加锁读风险

避免：

```sql
SELECT * FROM orders WHERE status = 'PENDING' FOR UPDATE;
```

如果匹配大量行，会持有大量行锁，并造成长时间写写冲突。更好的做法通常是：

- 精确条件。
- 分批处理。
- 按主键稳定排序。
- 使用 `SKIP LOCKED` 做队列领取。
- 缩短事务。

## 7. 隔离级别与锁行为

### 7.1 `READ COMMITTED`

Oracle 默认隔离级别。

特点：

- 每条语句看到语句开始时的一致性视图。
- 普通读不等待未提交写。
- 写同一行会等待。
- 同一事务内两条普通查询可能看到不同已提交结果。

### 7.2 `SERIALIZABLE`

`SERIALIZABLE` 提供事务级一致性视图，但并不是通过把所有相关写都阻塞住来实现。

并发冲突下可能出现：

```text
ORA-08177: can't serialize access for this transaction
```

业务代码需要把它视为可重试事务错误。

### 7.3 `READ ONLY`

`READ ONLY` 事务提供稳定一致视图，适合报表查询：

```sql
SET TRANSACTION READ ONLY;
SELECT ...;
COMMIT;
```

限制：

- 不允许执行 DML 修改。
- 长事务可能增加 undo 压力。
- 仍需关注 `ORA-01555`。

### 7.4 Oracle 不支持脏读

Oracle 不提供真正意义上的 dirty read。普通查询不会读到其他事务未提交的数据。

这点对从 MySQL 迁移过来的开发者很重要：不要试图用脏读规避等待。Oracle 的并发读主要依赖 read consistency。

### 7.5 隔离级别与锁不是一回事

隔离级别决定普通读看到什么版本，以及并发冲突如何处理；锁决定写写冲突、加锁读、DDL/DML 协调。

分析时要同时看：

- SQL 是普通读还是加锁读。
- 是否 DML。
- 是否 DDL。
- 是否涉及约束。
- 是否事务长时间未提交。
- 是否处于 `SERIALIZABLE` 或 `READ ONLY`。

## 8. DDL Locks 与对象定义保护

### 8.1 DDL Lock 的作用

DDL lock 用于保护 schema object 的定义，防止对象在被使用时被破坏性修改。

涉及对象：

- table
- view
- procedure
- package
- trigger
- index
- synonym

### 8.2 Exclusive DDL Lock

很多 DDL 需要 exclusive DDL lock。例如：

```sql
ALTER TABLE orders ADD ext VARCHAR2(100);
DROP TABLE orders;
```

如果对象上存在未提交 DML、正在执行的 SQL 或其他依赖锁，DDL 可能等待或失败。

### 8.3 Share DDL Lock

Share DDL lock 用于防止对象定义在某些操作期间被破坏性改变，同时允许一定程度并发。

例如编译过程、依赖对象访问等场景可能涉及共享 DDL 保护。

### 8.4 Breakable Parse Lock

SQL 解析和共享游标依赖对象定义。Oracle 可能使用 parse lock 来保护依赖关系；当对象定义变化时，相关 parse lock 可被打破，导致游标失效和重新解析。

这类锁通常不是普通业务行锁等待，但会影响 DDL、解析和 library cache 行为。

### 8.5 DDL 与 DML 冲突

典型场景：

```sql
-- session 1
UPDATE orders SET status = 'DONE' WHERE id = 1;
-- 不提交

-- session 2
ALTER TABLE orders ADD ext VARCHAR2(100);
-- 等待或失败
```

DML 未提交时，DDL 可能无法获得所需对象锁。

### 8.6 DDL 隐式提交

Oracle DDL 通常在执行前后发生隐式提交。这和事务控制关系很大：

- DDL 前会提交当前事务。
- DDL 成功后会提交。
- DDL 失败时也可能已经提交了 DDL 前的事务。

因此不要在一个普通业务事务中随意混入 DDL。

## 9. 外键、唯一约束与锁

### 9.1 外键索引的重要性

Oracle 中未索引外键是锁问题高发点。

如果子表外键列没有索引，当父表主键或唯一键被删除/更新时，Oracle 可能需要对子表做更重的检查和锁定，从而影响并发。

### 9.2 Unindexed Foreign Key

例子：

```sql
CREATE TABLE parent (
  id NUMBER PRIMARY KEY
);

CREATE TABLE child (
  id NUMBER PRIMARY KEY,
  parent_id NUMBER REFERENCES parent(id)
);
```

如果 `child(parent_id)` 没有索引，删除父表记录时：

```sql
DELETE FROM parent WHERE id = 10;
```

Oracle 需要确认是否有子表记录引用它。没有合适索引时，检查成本和锁影响都会扩大，可能导致 TM 等待或更大范围阻塞。

### 9.3 Indexed Foreign Key

建议：

```sql
CREATE INDEX idx_child_parent_id ON child(parent_id);
```

索引外键的好处：

- 快速定位子表引用。
- 降低父表删除/更新对子表并发的影响。
- 降低死锁风险。
- 改善约束检查性能。

不是所有外键都绝对必须建索引，但高并发 OLTP 系统中，父表键会被更新/删除或子表并发写入时，外键索引通常非常重要。

### 9.4 唯一约束并发插入

并发插入相同唯一键：

```sql
INSERT INTO users(email) VALUES ('a@example.com');
```

如果另一个事务已经插入相同 email 但未提交，当前事务可能等待它结束：

- 对方提交：当前事务报唯一约束错误。
- 对方回滚：当前事务可能继续成功。

这类等待常和 TX enqueue 相关。

### 9.5 约束检查与等待

约束不是纯粹的“语法规则”。唯一约束、外键约束在并发 DML 下会影响等待行为。

排查时要把约束元数据纳入分析：

- `DBA_CONSTRAINTS`
- `DBA_CONS_COLUMNS`
- `DBA_INDEXES`
- `DBA_IND_COLUMNS`

## 10. Enqueue、Latch、Mutex 与 System Locks

### 10.1 Enqueue

Enqueue 是 Oracle 中一种可排队的锁机制。很多用户可见等待都以 `enq:` 开头。

常见 enqueue：

| 类型 | 含义 | 常见等待 |
| --- | --- | --- |
| TX | Transaction | row lock contention、唯一约束等待、ITL 等 |
| TM | DML enqueue | 表级 DML/DDL 协调、外键相关等待 |
| UL | User lock | `DBMS_LOCK` 用户锁 |
| HW | High water mark | 段高水位相关 |
| SQ | Sequence cache | 序列相关 |

### 10.2 Latch

Latch 是保护 SGA 内部共享结构的轻量同步机制。它通常持有时间很短，没有事务语义。

典型 latch 相关等待：

- `latch free`
- `latch: cache buffers chains`
- `latch: shared pool`
- `latch: library cache`

业务上不要把 latch 当成行锁。它通常说明内部热点、共享结构争用或 SQL 解析/缓存/热点块问题。

### 10.3 Mutex

Mutex 是比传统 latch 更细粒度的内部同步机制，常出现在 cursor、library cache 等路径。

可能看到的等待：

- `cursor: pin S wait on X`
- library cache mutex 相关等待
- cursor mutex 相关等待

这类问题常和 SQL 解析、游标共享、硬解析、对象失效、执行计划抖动有关。

### 10.4 System Locks

System locks 保护数据库内部资源，例如：

- 数据文件。
- 控制文件。
- redo 相关结构。
- buffer cache。
- library cache。
- dictionary cache。

普通业务代码不能直接获取这些锁，但系统等待事件和性能报告会暴露相关竞争。

### 10.5 业务锁等待和内部同步等待

区分方法：

- TX/TM：往往能关联到具体业务事务、表、行或约束。
- DDL lock：往往关联对象定义变更。
- Latch/mutex：更多反映内部资源竞争。
- Buffer busy / cache buffers chains：可能是热点块或热点索引问题。

排查时先定位等待事件，再决定看业务事务还是内部性能路径。

## 11. Lock Conversion 与 Lock Escalation

### 11.1 Lock Conversion

Lock conversion 是锁模式从一种模式转换为另一种模式。例如事务先持有较弱表锁，后续操作需要更强锁，就可能发生转换。

这是正常机制，不等于锁升级问题。

### 11.2 Oracle 通常不做行锁到表锁的升级

Oracle 官方文档强调：Oracle 不会因为一个事务锁住很多行，就自动把行锁升级为表锁。

这点和 SQL Server 常见 lock escalation 心智模型不同。

大量行更新时，Oracle 通常仍然是行级锁，只是事务持有很多行锁，undo、redo、buffer、ITL 和等待成本都会增加。

### 11.3 容易误判为锁升级的场景

常见误判来源：

- 未索引外键导致子表 TM 等待。
- 显式 `LOCK TABLE`。
- DDL lock 阻塞 DML。
- 大批量 DML 锁住大量行。
- ITL slot 不足。
- 热块 latch 竞争。
- 唯一约束并发冲突。

更准确的描述通常是：

- 表级 DML/DDL 协调。
- 约束检查导致等待。
- 行锁数量多。
- 热块或内部同步竞争。
- 显式表锁。

## 12. 死锁、锁等待与错误码

### 12.1 `enq: TX - row lock contention`

常见原因：

- 两个事务更新同一行。
- `SELECT ... FOR UPDATE` 锁住目标行。
- 唯一约束并发插入等待。
- ITL 相关等待。

处理方向：

- 找阻塞会话。
- 看持锁 SQL 和事务开始时间。
- 确认是否长事务。
- 确认是否热点行或热点键。

### 12.2 `enq: TM - contention`

常见原因：

- DML 与 DDL 冲突。
- 未索引外键。
- 显式表锁。
- 表级约束维护。

处理方向：

- 定位对象。
- 检查外键索引。
- 检查是否有 DDL。
- 检查阻塞事务是否未提交。

### 12.3 `ORA-00060`

错误：

```text
ORA-00060: deadlock detected while waiting for resource
```

Oracle 会自动检测死锁。通常会回滚造成死锁的语句，但事务可能仍处于打开状态。

应用侧建议：

- 捕获错误。
- 回滚整个事务。
- 按事务级别重试。
- 固定访问顺序，减少死锁。

### 12.4 `ORA-08177`

错误：

```text
ORA-08177: can't serialize access for this transaction
```

主要和 `SERIALIZABLE` 隔离级别相关。它表示 Oracle 无法保证该事务继续执行后仍满足可串行化要求。

处理方式：

- 回滚事务。
- 重试。
- 缩短事务。
- 降低冲突范围。
- 评估是否必须使用 `SERIALIZABLE`。

### 12.5 `ORA-01555`

错误：

```text
ORA-01555: snapshot too old
```

和一致性读所需 undo 不可用相关。

处理方向：

- 增加 undo retention。
- 优化长查询。
- 减少长事务。
- 分批处理报表。
- 检查 undo 表空间压力。

### 12.6 `ORA-00054`

错误：

```text
ORA-00054: resource busy and acquire with NOWAIT specified or timeout expired
```

常见于：

- `SELECT ... FOR UPDATE NOWAIT`
- `LOCK TABLE ... NOWAIT`
- DDL 设置了超时或无法获取对象锁

处理方式：

- 使用有限重试。
- 改用 `WAIT n`。
- 找出阻塞会话。
- 避免高峰期 DDL。

## 13. 锁问题排查工具

### 13.1 会话与阻塞

常用视图：

```sql
V$SESSION
V$LOCK
V$LOCKED_OBJECT
DBA_BLOCKERS
DBA_WAITERS
```

关注字段：

- `SID`
- `SERIAL#`
- `USERNAME`
- `STATUS`
- `EVENT`
- `BLOCKING_SESSION`
- `WAIT_CLASS`
- `SECONDS_IN_WAIT`
- `SQL_ID`

### 13.2 事务

常用视图：

```sql
V$TRANSACTION
```

关注：

- 事务开始时间。
- undo 使用。
- 事务关联 session。
- 是否长时间未提交。

### 13.3 等待事件

常用视图：

```sql
V$SESSION_WAIT
V$SESSION_EVENT
V$SYSTEM_EVENT
V$ACTIVE_SESSION_HISTORY
```

如果有授权和许可，还可以看：

- ASH
- AWR
- ADDM

等待事件是 Oracle 排查的入口。先看 session 在等什么，再决定查 TX/TM、DDL、latch、mutex 还是 I/O。

### 13.4 对象与约束定位

常用数据字典：

```sql
DBA_OBJECTS
DBA_TABLES
DBA_INDEXES
DBA_IND_COLUMNS
DBA_CONSTRAINTS
DBA_CONS_COLUMNS
```

外键问题排查时尤其要看：

- 约束名。
- 父表。
- 子表。
- 外键列。
- 外键列是否有匹配索引。

### 13.5 典型排查 SQL 思路

排查“谁阻塞谁”：

```sql
SELECT
  s.sid,
  s.serial#,
  s.username,
  s.event,
  s.blocking_session,
  s.sql_id
FROM v$session s
WHERE s.blocking_session IS NOT NULL;
```

排查当前锁：

```sql
SELECT
  l.sid,
  l.type,
  l.id1,
  l.id2,
  l.lmode,
  l.request,
  l.block
FROM v$lock l
WHERE l.type IN ('TX', 'TM');
```

排查被锁对象：

```sql
SELECT
  s.sid,
  s.serial#,
  o.owner,
  o.object_name,
  o.object_type,
  lo.locked_mode
FROM v$locked_object lo
JOIN dba_objects o ON o.object_id = lo.object_id
JOIN v$session s ON s.sid = lo.session_id;
```

这些 SQL 是诊断起点，不是完整脚本。实际生产还需要结合权限、RAC、多租户、SQL_ID、ASH/AWR 等上下文。

### 13.6 排查顺序建议

1. 看等待事件。
2. 如果是 `enq: TX`，查行锁、唯一约束、ITL、阻塞事务。
3. 如果是 `enq: TM`，查表锁、DDL、外键索引。
4. 如果是 `library cache`，查 DDL、对象失效、硬解析。
5. 如果是 latch/mutex，查热点 SQL、热点块、解析、共享池。
6. 如果是 `ORA-01555`，查 undo 和长查询。
7. 最后回到业务事务设计。

## 14. 业务开发最佳实践

### 14.1 事务要短

事务越长，行锁、TM 锁、undo、redo、阻塞链风险越高。

事务中避免：

- 用户交互。
- 远程 RPC。
- HTTP 调用。
- 大文件处理。
- 长时间计算。
- 人工审批。

### 14.2 固定多行更新顺序

多行更新要固定顺序，降低死锁概率。

例如转账场景，应统一按账户 ID 排序锁定：

```sql
SELECT *
FROM accounts
WHERE id IN (:from_id, :to_id)
ORDER BY id
FOR UPDATE;
```

### 14.3 外键建索引

高并发 OLTP 系统中，外键列通常应建索引，尤其是：

- 父表记录可能被删除。
- 父表主键/唯一键可能被更新。
- 子表并发写入频繁。
- 曾经出现 `enq: TM - contention`。

### 14.4 谨慎使用 `SELECT ... FOR UPDATE`

适合：

- 读后立即更新。
- 状态流转。
- 任务领取。
- 防止并发修改关键行。

避免：

- 大范围加锁。
- 长事务中加锁。
- 用户操作前先锁住数据。
- 报表查询加锁。

### 14.5 队列场景使用 `SKIP LOCKED`

任务领取可以考虑：

```sql
SELECT id
FROM jobs
WHERE status = 'READY'
ORDER BY id
FETCH FIRST 1 ROW ONLY
FOR UPDATE SKIP LOCKED;
```

但必须接受：

- 结果不完整。
- 跳过锁定行。
- 需要幂等和重试。
- 需要合适索引。

### 14.6 对可重试错误做事务级重试

建议重试：

- `ORA-00060`
- `ORA-08177`
- 部分 `ORA-00054`
- 部分锁等待超时场景

重试原则：

- 回滚整个事务。
- 短暂退避。
- 限制次数。
- 保证业务幂等。

### 14.7 避免大事务

大批量 DML 风险：

- 持有大量行锁。
- undo 压力大。
- redo 压力大。
- 回滚成本高。
- 影响 DDL。
- 增加死锁和等待链风险。

建议分批、可恢复、可重入。

### 14.8 DDL 前检查活动事务

DDL 变更前：

- 检查长事务。
- 检查目标对象上的 DML。
- 检查对象依赖。
- 设置合适 DDL lock timeout。
- 避免业务高峰。

### 14.9 区分业务锁与内部同步等待

不要把所有等待都叫“锁表”。

- `enq: TX`：多半是事务/行级问题。
- `enq: TM`：多半是表级 DML/DDL/外键问题。
- `library cache`：可能是解析、对象定义、游标。
- `latch/mutex`：可能是内部热点。
- `ORA-01555`：是 undo 一致性读问题。

### 14.10 管理 undo retention

长查询和报表系统要关注：

- undo 表空间。
- undo retention。
- 查询运行时间。
- 批处理写入压力。
- 报表和 OLTP 混跑影响。

## 15. 实验案例库

这些实验后续可以拆成可执行 SQL 用例。

### 15.1 普通 `SELECT` 不阻塞 `UPDATE`

目标：验证普通读不持有阻塞写的行锁。

流程：

- session 1 普通 `SELECT`。
- session 2 `UPDATE` 同一行。
- 观察 session 2 不被 session 1 阻塞。

### 15.2 `UPDATE` 阻塞另一个 `UPDATE`

目标：验证写写冲突。

流程：

- session 1 更新某行但不提交。
- session 2 更新同一行。
- 观察 `enq: TX - row lock contention`。

### 15.3 `SELECT ... FOR UPDATE` 阻塞写

目标：验证加锁读持有行锁。

流程：

- session 1 `SELECT ... FOR UPDATE`。
- session 2 `UPDATE` 同一行。
- 观察等待。

### 15.4 `NOWAIT` / `WAIT n` / `SKIP LOCKED`

目标：理解锁等待控制。

流程：

- session 1 锁住行。
- session 2 分别测试 `NOWAIT`、`WAIT 5`、`SKIP LOCKED`。
- 观察错误、超时和跳过行为。

### 15.5 未索引外键导致锁问题

目标：观察未索引外键对父表删除/更新的影响。

流程：

- 创建父子表。
- 子表外键不建索引。
- 并发删除父表记录和修改子表。
- 观察 TM 等待。
- 增加外键索引后对比。

### 15.6 反向更新触发 `ORA-00060`

目标：复现死锁。

流程：

- session 1 更新 A 后更新 B。
- session 2 更新 B 后更新 A。
- 观察 `ORA-00060`。

### 15.7 `SERIALIZABLE` 触发 `ORA-08177`

目标：理解可串行化冲突。

流程：

- session 1 设置 `SERIALIZABLE`。
- session 2 修改 session 1 后续要修改的数据。
- session 1 再尝试修改。
- 观察 `ORA-08177`。

### 15.8 长查询触发 `ORA-01555`

目标：理解 undo 与长查询。

流程：

- 运行长时间一致性查询。
- 并发大量修改相关数据。
- undo 保留不足时可能触发 `ORA-01555`。

### 15.9 DML 阻塞 DDL

目标：理解 DDL lock。

流程：

- session 1 更新表不提交。
- session 2 `ALTER TABLE`。
- 观察等待或失败。

### 15.10 观察 `V$LOCK` 中 TX/TM

目标：把业务阻塞和动态性能视图关联起来。

流程：

- 构造行锁等待。
- 查询 `V$LOCK`。
- 观察 TX/TM、`LMODE`、`REQUEST`。

### 15.11 观察 latch/mutex 等待事件

目标：知道内部同步等待在哪里看。

流程：

- 构造高并发热点访问或硬解析压力。
- 查看 `V$SESSION`、ASH/AWR 等等待事件。
- 区分 TX/TM 和 latch/mutex。

## 16. 后续对比文档索引

本章不展开三库差异，只记录后续 `database-locks-comparison.md` 应覆盖的主题：

1. MVCC 实现差异。
2. 行锁存储差异。
3. 加锁读语法与语义差异。
4. 表锁、元数据锁、DDL 锁差异。
5. 外键与唯一约束锁差异。
6. 锁升级与锁范围扩大差异。
7. 内部同步机制差异。
8. 死锁检测、错误码和事务重试差异。
9. 锁问题排查视图和工具差异。

## 参考官方文档

- [Oracle Database 19c Concepts: Data Concurrency and Consistency](https://docs.oracle.com/en/database/oracle/oracle-database/19/cncpt/data-concurrency-and-consistency.html)
- [Oracle Database 19c SQL Language Reference: SELECT](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/SELECT.html)
- [Oracle Database 19c SQL Language Reference: LOCK TABLE](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/LOCK-TABLE.html)
- [Oracle Database 19c Database Reference: V$LOCK](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/V-LOCK.html)
- [Oracle Database 19c Database Reference: V$LOCKED_OBJECT](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/V-LOCKED_OBJECT.html)
- [Oracle Database 19c Database Reference: V$SESSION](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/V-SESSION.html)
- [Oracle Database 19c Database Reference: V$TRANSACTION](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/V-TRANSACTION.html)
- [Oracle Database 19c Database Reference: DBA_BLOCKERS](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/DBA_BLOCKERS.html)
- [Oracle Database 19c Database Reference: DBA_WAITERS](https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/DBA_WAITERS.html)
- [Oracle Database Error Help: ORA-00060](https://docs.oracle.com/error-help/db/ora-00060/)
- [Oracle Database Error Help: ORA-00054](https://docs.oracle.com/error-help/db/ora-00054/)
- [Oracle Database Error Help: ORA-08177](https://docs.oracle.com/error-help/db/ora-08177/)
- [Oracle Database Error Help: ORA-01555](https://docs.oracle.com/error-help/db/ora-01555/)
