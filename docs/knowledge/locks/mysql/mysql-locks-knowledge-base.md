# MySQL 锁知识库

本文档面向已经熟悉 MySQL、正在迁移或学习 PostgreSQL / Oracle 的开发者。目标不是罗列所有锁名，而是建立一套可迁移的理解框架：MySQL 的锁分在哪几层、SQL 到底锁住什么对象、隔离级别怎样改变锁行为、为什么看起来像“锁表”、以及业务代码应该如何规避锁风险。

本文主要依据 MySQL 8.4 官方文档整理。个别版本差异较大的特性，应以目标线上版本的官方文档为准。

## 1. MySQL 锁体系总览

MySQL 的锁不能只按“行锁、表锁”理解。更实用的分层是：

| 层次 | 代表机制 | 主要保护对象 | 面向业务可见性 |
| --- | --- | --- | --- |
| Server 层锁 | MDL、`LOCK TABLES`、用户级命名锁 | 元数据、表、应用自定义资源 | 高 |
| InnoDB 事务锁 | record lock、gap lock、next-key lock、insert intention lock | 索引记录、索引间隙、事务可见性 | 高 |
| InnoDB 内部同步 | latch、mutex、rw-lock、spin wait | 内存结构、buffer pool、redo、内部队列 | 中低，主要通过性能诊断观察 |
| 外部锁 | 文件锁等 | 非 InnoDB 表文件或外部程序协作 | 低 |

学习时建议始终问四个问题：

1. 这是 Server 层锁还是 InnoDB 事务锁？
2. 锁住的是表、元数据、索引记录、索引间隙，还是内部内存结构？
3. 锁生命周期由事务控制、语句控制、session 控制，还是内部临界区控制？
4. 业务现象是行锁等待、MDL 等待、表锁等待、死锁，还是 latch 竞争？

这四个问题能避免把不同层次的等待混在一起。例如：

- `ALTER TABLE` 被长事务阻塞，通常要怀疑 MDL。
- `SELECT ... FOR UPDATE` 阻塞更新，通常是 InnoDB 行锁或索引范围锁。
- CPU 高、吞吐上不去，但看不到明显行锁等待，可能需要看内部 latch / mutex 等待。
- 大量行被锁住看起来像“锁表”，不等于 InnoDB 发生了传统意义上的锁升级。

## 2. Server 层锁

### 2.1 Metadata Lock

Metadata Lock 简称 MDL，用于保护数据库对象的元数据一致性。表、schema、视图、存储过程、触发器等对象都可能涉及 MDL。

MDL 的典型特点：

- DML、查询、DDL 都可能持有或等待 MDL。
- 事务中的语句访问过表后，相关 MDL 可能持续到事务结束。
- DDL 需要更强的元数据锁，因此容易被长事务阻塞。
- 一个等待中的 DDL 还可能挡住后续 DML，造成阻塞扩散。

典型事故链路：

```sql
-- session 1
START TRANSACTION;
SELECT * FROM orders WHERE id = 1;
-- 长时间不提交

-- session 2
ALTER TABLE orders ADD COLUMN ext JSON;
-- 等待 session 1 释放 MDL

-- session 3
SELECT * FROM orders WHERE id = 2;
-- 可能被 session 2 的 pending DDL 阻塞
```

排查入口：

- `performance_schema.metadata_locks`
- `SHOW PROCESSLIST`
- `sys.schema_table_lock_waits`，如果启用了 sys schema

业务上要记住：很多 DDL 阻塞事故不是 InnoDB 行锁问题，而是 MDL 问题。

### 2.2 显式表锁

MySQL 提供显式表锁：

```sql
LOCK TABLES t READ;
LOCK TABLES t WRITE;
UNLOCK TABLES;
```

对于 InnoDB，绝大多数业务场景不应该优先使用 `LOCK TABLES`。InnoDB 已经提供事务和行级锁，显式表锁通常会降低并发，并且容易和事务边界、连接池、隐式提交行为混在一起。

需要区分：

- `LOCK TABLES` 是显式表级锁。
- MDL 是 Server 层元数据锁。
- InnoDB 意向锁是表级锁，但它只是多粒度锁协议的一部分。
- AUTO-INC lock 是自增插入路径上的特殊表级机制。

这些都不能简单叫作“行锁升级成表锁”。

### 2.3 用户级命名锁

MySQL 提供用户级命名锁：

```sql
SELECT GET_LOCK('job:daily-report', 10);
SELECT RELEASE_LOCK('job:daily-report');
SELECT RELEASE_ALL_LOCKS();
```

命名锁的特点：

- 锁名由应用定义。
- 锁属于 session，而不是事务。
- `COMMIT` / `ROLLBACK` 不会自动释放命名锁。
- 连接断开时释放。
- 同一连接被连接池复用时，容易产生隐藏风险。

适合场景：

- 简单互斥任务。
- 单实例定时任务防重。
- 轻量级应用协调。

风险：

- 事务已经结束，但命名锁仍然持有。
- 连接池把持锁连接交给下一个业务请求。
- 业务异常路径未释放锁。
- 命名粒度过粗导致串行化。

如果要在业务中使用，建议封装为统一工具，明确超时、释放、异常处理和连接池隔离策略。

## 3. InnoDB 事务、MVCC 与读机制

### 3.1 InnoDB 事务模型

InnoDB 同时使用 MVCC 和两阶段锁。普通一致性读依赖 MVCC，写入、删除、加锁读依赖锁。

一个很重要的心智模型：

- 普通 `SELECT` 通常是快照读，不主动加行锁。
- `SELECT ... FOR UPDATE` / `FOR SHARE` 是加锁读。
- `UPDATE`、`DELETE` 是当前读，并且会对扫描到的索引记录加锁。
- `INSERT` 需要插入意向、唯一性检查、自增等路径上的锁。

### 3.2 一致性非锁定读

一致性非锁定读是 InnoDB 普通查询的默认行为。它通过 undo log 重构旧版本，让查询看到符合隔离级别要求的版本。

常见表现：

- 普通 `SELECT` 不等待其他事务的行锁。
- 普通 `SELECT` 也不会阻塞其他事务更新同一行。
- 在 `REPEATABLE READ` 下，同一事务内普通 `SELECT` 通常看到同一 read view。
- 在 `READ COMMITTED` 下，每条一致性读语句通常使用新的 read view。

这点和业务锁设计关系很大：如果你读完后要依赖这个结果做后续写入，普通 `SELECT` 不提供“保留修改权”的保护。

### 3.3 加锁读

加锁读包括：

```sql
SELECT ... FOR SHARE;
SELECT ... FOR UPDATE;
```

`FOR SHARE` 获取共享锁，允许其他事务读取，但阻止其他事务修改相关记录。

`FOR UPDATE` 获取排他锁，语义上类似对读到的行准备执行 `UPDATE`。其他事务不能修改这些记录，也不能获取冲突的加锁读。

注意点：

- 加锁读通常要求显式事务环境，例如 `START TRANSACTION` 或关闭 autocommit。
- 外层查询的锁定子句不会自动作用到子查询里的表，子查询需要自己写锁定子句。
- `NOWAIT` 和 `SKIP LOCKED` 只作用于行级锁，不适合随意用在一般事务逻辑中。

### 3.4 当前读与快照读

MySQL 学习中经常用“当前读”和“快照读”来区分：

| 类型 | 典型语句 | 是否看 read view | 是否加锁 |
| --- | --- | --- | --- |
| 快照读 | 普通 `SELECT` | 是 | 通常不加行锁 |
| 当前读 | `SELECT ... FOR UPDATE`、`UPDATE`、`DELETE` | 否，读取最新可用版本 | 会加锁 |

当前读需要面对正在被其他事务修改的记录，因此可能等待、重查、加锁或发生死锁。

### 3.5 半一致性读

半一致性读，semi-consistent read，是 MySQL / InnoDB 容易被忽略但很重要的细节。

它主要出现在 `READ COMMITTED` 下的 `UPDATE` 场景：

1. `UPDATE` 扫描到一行。
2. 该行被其他事务锁住。
3. InnoDB 可以先把该行最新已提交版本返回给 MySQL Server 层。
4. Server 层判断该行是否满足 `WHERE` 条件。
5. 如果不满足条件，就不必等待这行锁。
6. 如果满足条件，后续真正要更新时再等待锁并重新读取。

它解决的是“扫描到锁住的行，但这行其实不需要更新”的无谓等待。

例子：

```sql
CREATE TABLE t (
  id BIGINT PRIMARY KEY,
  status INT,
  amount INT,
  KEY idx_status(status)
) ENGINE=InnoDB;

-- session 1
START TRANSACTION;
UPDATE t SET amount = amount + 1 WHERE id = 1;

-- session 2, READ COMMITTED
UPDATE t SET amount = amount + 10 WHERE status = 9;
```

如果 session 2 扫描路径碰到 session 1 锁住的行，但该行最新已提交版本并不满足 `status = 9`，半一致性读可以减少等待。

要注意：

- 半一致性读不是普通 `SELECT` 的一致性快照读。
- 它是 `UPDATE` 执行过程中的优化机制。
- 它不意味着 `UPDATE` 不加锁。
- 它不消除真正匹配行上的写冲突。

## 4. InnoDB 加锁对象：索引记录

### 4.1 行锁不是抽象逻辑行锁

InnoDB 里的 record lock 锁的是索引记录。即使业务上说“锁住一行”，底层也更接近“锁住某个索引上的记录”。

官方文档明确说明：record lock 是 index record 上的锁；如果表没有显式索引，InnoDB 会创建隐藏聚簇索引并在其上加锁。

这带来几个结论：

- SQL 使用哪个索引，直接影响锁对象。
- 没有合适索引时，锁范围可能远大于预期。
- 二级索引路径下，可能同时涉及二级索引记录和聚簇索引记录。

### 4.2 聚簇索引与二级索引

InnoDB 表数据按聚簇索引组织：

- 如果有主键，主键就是聚簇索引。
- 如果没有主键，InnoDB 选择第一个合适的唯一非空索引。
- 如果都没有，InnoDB 创建隐藏聚簇索引。

二级索引叶子记录中保存二级索引键值以及对应的主键值。通过二级索引查找完整行时，通常要回到聚簇索引。

### 4.3 `SELECT ... FOR UPDATE` 的二级索引加锁

考虑：

```sql
CREATE TABLE orders (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  status INT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  KEY idx_status(status)
) ENGINE=InnoDB;

START TRANSACTION;
SELECT * FROM orders WHERE status = 1 FOR UPDATE;
```

如果执行计划走 `idx_status`，需要理解为：

1. 扫描 `idx_status` 上 `status = 1` 的索引范围。
2. 对扫描遇到的二级索引记录加锁。
3. 根据二级索引记录中的主键值回到聚簇索引。
4. 对对应的聚簇索引记录加锁。
5. 如果是 `REPEATABLE READ`，并且条件不是唯一索引唯一等值查询，还可能涉及 next-key lock。

这就是你提到的关键点：`SELECT ... FOR UPDATE` 不只是对聚簇索引上的“行”加锁，也可能对访问路径中的索引记录加锁。

### 4.4 覆盖索引场景

覆盖索引能减少回表读取数据的成本，但不能把“加锁读”简单理解成只读索引就结束。

对于加锁读，InnoDB 需要锁定将来可能被更新或删除的实际记录。即使查询列被二级索引覆盖，锁语义也不同于普通一致性读。分析时不能只看“是否覆盖索引”，还要看：

- 是否是 locking read。
- 是否需要锁住对应聚簇记录。
- 是否扫描了范围。
- 是否涉及 gap / next-key。

业务排查时，以执行计划、`performance_schema.data_locks` 和复现实验为准。

## 5. InnoDB 锁类型

### 5.1 Shared Lock 与 Exclusive Lock

InnoDB 行级锁有两类基础锁：

- `S` lock：共享锁，允许持有者读取。
- `X` lock：排他锁，允许持有者更新或删除。

兼容关系：

| 已持有 | 请求 S | 请求 X |
| --- | --- | --- |
| S | 兼容 | 冲突 |
| X | 冲突 | 冲突 |

### 5.2 意向锁

意向锁是表级锁，用于协调表级锁和行级锁：

- `IS`：事务打算在表中某些行上获取共享锁。
- `IX`：事务打算在表中某些行上获取排他锁。

例子：

- `SELECT ... FOR SHARE` 会设置 `IS`。
- `SELECT ... FOR UPDATE` 会设置 `IX`。

意向锁的重点：

- 它不是锁升级。
- 它通常不阻塞普通行级读写。
- 它主要阻塞冲突的完整表级锁请求。
- 它告诉系统“这个表里有行级锁或即将有行级锁”。

### 5.3 Record Lock

Record lock 是索引记录锁。它锁住具体 index record。

例子：

```sql
SELECT * FROM t WHERE id = 10 FOR UPDATE;
```

如果 `id` 是主键，通常锁住主键索引中 `id = 10` 的记录。

### 5.4 Gap Lock

Gap lock 锁住两个索引记录之间的间隙，或者第一条记录之前、最后一条记录之后的间隙。

它的作用主要是阻止其他事务向这个 gap 插入新记录。

例子：

```sql
SELECT * FROM t WHERE c1 BETWEEN 10 AND 20 FOR UPDATE;
```

即使当前没有 `c1 = 15` 的记录，也可能阻止其他事务插入 `c1 = 15`。

Gap lock 的难点：

- 它锁的是“位置”，不一定是已有记录。
- 不同事务的 gap lock 之间可能不互斥。
- 它主要服务于防止幻读、唯一性检查、外键检查等场景。

### 5.5 Next-Key Lock

Next-key lock 可以理解为 record lock + gap lock，锁住一个索引记录以及它前面的 gap。

在 MySQL 默认的 `REPEATABLE READ` 下，范围查询加锁经常表现为 next-key lock。

它是理解“为什么范围查询阻止插入”的核心。

### 5.6 Insert Intention Lock

Insert intention lock 是插入前在 gap 上表达插入意图的锁。

它的特点：

- 多个事务向同一 gap 中不同位置插入时，不一定互相阻塞。
- 如果 gap 被其他事务的 gap lock / next-key lock 保护，则插入意向可能等待。
- 它是高并发插入场景中分析等待的重要线索。

### 5.7 AUTO-INC Lock

AUTO-INC lock 与自增列插入有关。它不是普通 record lock。

关注点：

- `innodb_autoinc_lock_mode` 会影响自增锁策略。
- 单行插入、批量插入、`INSERT ... SELECT` 的并发特性不同。
- 高并发写入自增主键表时，如果等待集中在自增路径，需要单独排查。

### 5.8 Predicate Lock for Spatial Indexes

空间索引相关 predicate lock 属于低频进阶内容。一般业务锁知识库可以先知道它存在，不作为第一轮重点。

## 6. 隔离级别对锁的影响

### 6.1 `READ UNCOMMITTED`

允许脏读，业务中通常不建议使用。它适合理解隔离级别边界，但不适合作为常规事务策略。

### 6.2 `READ COMMITTED`

特点：

- 每条一致性读语句通常使用自己的 read view。
- 相比 `REPEATABLE READ`，gap lock 使用更少。
- 对于搜索和索引扫描，InnoDB 只对索引记录加锁，不匹配 `WHERE` 条件的记录在 Server 判断后会释放。
- `UPDATE` 可使用半一致性读减少无谓等待。

业务影响：

- 锁等待可能减少。
- 幻读现象更容易出现。
- 死锁概率可能下降，但不会消失。
- 同一事务内两次普通 `SELECT` 可能看到不同已提交结果。

### 6.3 `REPEATABLE READ`

MySQL InnoDB 默认隔离级别通常是 `REPEATABLE READ`。

特点：

- 普通一致性读使用事务级 read view。
- 加锁读、`UPDATE`、`DELETE` 是当前读。
- 范围条件常涉及 next-key lock。
- 可以防止很多幻读场景，但语义和 PostgreSQL 的 `REPEATABLE READ` 不完全等价。

业务影响：

- 范围更新、范围加锁读可能锁住 gap。
- 插入可能被已有范围锁阻塞。
- “我只查了一个范围，为什么别人不能插入范围内不存在的值”通常要从 next-key lock 解释。

### 6.4 `SERIALIZABLE`

`SERIALIZABLE` 会进一步增强隔离，普通 `SELECT` 在某些事务环境中可能被当作加锁读处理。

业务中一般很少长期使用该级别，因为并发性下降明显。它更适合：

- 极少数强一致性业务。
- 复现并发异常。
- 理解隔离级别边界。

### 6.5 隔离级别不是唯一变量

不要只问“什么隔离级别会加什么锁”。还要同时看：

- SQL 类型。
- 是否加锁读。
- 是否命中唯一索引。
- 是否范围扫描。
- 是否二级索引。
- 是否有外键或唯一性检查。
- 执行计划实际扫描了什么。

## 7. 不同 SQL 语句的加锁行为

### 7.1 普通 `SELECT`

普通 `SELECT` 通常是一致性非锁定读。

```sql
SELECT * FROM orders WHERE id = 1;
```

它通常：

- 不等待其他事务在该行上的行锁。
- 不阻塞其他事务更新该行。
- 不保证读完后该行不会被其他事务修改。

如果读后要更新，应该考虑加锁读、乐观锁版本号、唯一约束或其他业务协议。

### 7.2 `SELECT ... FOR SHARE`

```sql
SELECT * FROM parent WHERE id = 1 FOR SHARE;
```

适合场景：

- 确认父记录存在，并短时间阻止别人删除或修改。
- 多个事务可以共同读取，但不能被其他事务修改。

### 7.3 `SELECT ... FOR UPDATE`

```sql
SELECT * FROM orders WHERE id = 1 FOR UPDATE;
```

适合场景：

- 读后马上更新。
- 状态机流转。
- 库存扣减。
- 任务领取。

注意点：

- 它锁的是搜索遇到的索引记录及相关索引项。
- 二级索引路径可能同时锁二级索引记录和聚簇索引记录。
- 范围条件可能触发 next-key lock。
- `SKIP LOCKED` 可用于队列类场景，但会得到不完整视图。

### 7.4 `UPDATE`

```sql
UPDATE orders SET status = 2 WHERE status = 1;
```

`UPDATE` 通常对扫描过程中遇到的索引记录加锁。重要的是：InnoDB 记住的是扫描过的索引范围，不是完整 SQL `WHERE` 谓词。

因此：

- 条件是否有索引非常关键。
- 非唯一索引可能锁住多个记录和 gap。
- 复杂条件中，即使最终不匹配的行，也可能在扫描判断阶段被短暂锁住。
- `READ COMMITTED` 下不匹配记录可能较早释放，并可能使用半一致性读。

### 7.5 `DELETE`

`DELETE` 和 `UPDATE` 类似，尤其要注意范围删除：

```sql
DELETE FROM orders WHERE created_at < '2026-01-01';
```

如果条件范围大，可能锁住大量索引记录和 gap。大批量删除建议：

- 分批。
- 每批稳定排序。
- 控制事务大小。
- 确认走合适索引。

### 7.6 `INSERT`

`INSERT` 涉及：

- 插入意向锁。
- 唯一键检查。
- 外键检查。
- AUTO-INC lock，如果有自增列。

常见等待：

- 插入位置被 gap / next-key lock 阻塞。
- 唯一键冲突等待另一个未提交事务。
- 父表或子表外键检查等待。

### 7.7 `INSERT ... ON DUPLICATE KEY UPDATE`

这是高并发下容易死锁的语句，因为它同时具有：

- 插入路径。
- 唯一键冲突检查。
- 更新路径。
- 可能更新多个唯一索引。

业务上如果高频 upsert，建议特别关注：

- 唯一索引设计。
- 多事务访问顺序。
- 是否能拆分插入和更新。
- 是否有事务重试。

### 7.8 外键检查

外键会引入父表和子表之间的锁关系：

- 插入子表要检查父表记录存在。
- 删除或更新父表主键/唯一键要检查子表引用。
- 这些检查可能产生额外锁等待。

外键不是“只影响约束校验”，它也影响并发行为。

## 8. 锁范围扩大与执行计划

### 8.1 主键唯一等值查询

```sql
SELECT * FROM orders WHERE id = 100 FOR UPDATE;
```

如果 `id` 是主键，且条件是唯一等值，一般锁范围最小，主要锁定目标索引记录。

### 8.2 唯一二级索引等值查询

```sql
CREATE UNIQUE INDEX uk_order_no ON orders(order_no);

SELECT * FROM orders WHERE order_no = 'A001' FOR UPDATE;
```

如果使用唯一索引唯一等值查询，锁范围也相对明确。但仍要注意二级索引和聚簇索引的关系。

### 8.3 非唯一二级索引等值查询

```sql
SELECT * FROM orders WHERE status = 1 FOR UPDATE;
```

如果 `status` 是非唯一索引：

- 可能匹配多行。
- 可能涉及 next-key lock。
- 可能锁住相邻 gap。
- 插入新的 `status = 1` 或相邻索引值可能被阻塞。

### 8.4 范围查询

```sql
SELECT * FROM orders
WHERE created_at >= '2026-05-01'
  AND created_at < '2026-06-01'
FOR UPDATE;
```

范围查询是 next-key lock 的高发场景。排查时要看：

- 范围起点和终点。
- 是否包含不存在的位置。
- 是否使用联合索引。
- 是否扫描了比想象更多的记录。

### 8.5 无索引扫描

```sql
UPDATE orders SET status = 9 WHERE remark = 'manual-fix';
```

如果 `remark` 没有索引，InnoDB 可能扫描大量记录。表现上可能像“锁了全表”，但这通常不是锁升级，而是访问路径导致锁范围扩大。

### 8.6 错误索引选择

即使有索引，优化器也可能因为统计信息、条件选择性、排序需求等选择不符合预期的索引。

排查时必须看：

```sql
EXPLAIN SELECT ... FOR UPDATE;
EXPLAIN UPDATE ...;
```

必要时结合：

- `ANALYZE TABLE`
- 优化索引
- 改写 SQL
- 小心使用 optimizer hint

### 8.7 `ORDER BY` / `LIMIT`

`ORDER BY` / `LIMIT` 会影响扫描路径和停止条件。

例如队列领取：

```sql
SELECT *
FROM jobs
WHERE status = 'ready'
ORDER BY id
LIMIT 1
FOR UPDATE SKIP LOCKED;
```

这种写法常用于多 worker 并发领取任务，但要理解：

- `SKIP LOCKED` 返回的是不完整视图。
- 结果不是严格一致性快照。
- 需要业务接受跳过锁定行。
- 索引应匹配 `WHERE + ORDER BY`。

### 8.8 临时表、派生表、`UNION`

某些查询形态中，MySQL 可能先产生临时结果，导致结果行和原表行的关系不再简单。官方文档提醒过：如果扫描行和结果行关系丢失，锁可能不会立即释放。

业务建议：

- 避免复杂查询直接加 `FOR UPDATE`。
- 先用简单、可索引、可解释的条件锁定主键。
- 再按主键读取或更新详细数据。

## 9. 锁升级与常见误区

### 9.1 锁升级的通用定义

锁升级通常指数据库把大量细粒度锁自动转换为更粗粒度锁，例如从行锁升级为表锁，以减少锁管理开销。

这个概念在 SQL Server 中更典型。

### 9.2 InnoDB 通常不做传统锁升级

InnoDB 的锁信息存储较节省，官方文档明确提到不需要 lock escalation。即使一个事务锁住大量行，InnoDB 通常也不会自动把行锁升级成表锁。

所以在 MySQL / InnoDB 中，遇到大范围阻塞时，不要第一反应就是“锁升级了”。

### 9.3 “看起来像锁表”的真实原因

常见原因：

- SQL 没有合适索引。
- 扫描了大量索引记录。
- 范围查询触发 next-key lock。
- 非唯一索引等值查询锁住多个记录和 gap。
- DDL 等待或持有 MDL。
- 显式 `LOCK TABLES`。
- AUTO-INC lock 影响并发插入。
- 外键检查导致父子表等待。
- 长事务迟迟不提交。

### 9.4 哪些不是锁升级

以下概念都不应简单叫锁升级：

- 意向锁：多粒度锁协议需要。
- MDL：Server 层元数据锁。
- `LOCK TABLES`：显式表锁。
- AUTO-INC lock：自增插入相关特殊机制。
- next-key lock：索引记录与 gap 的组合锁。

更准确的表达通常是“锁范围扩大”或“阻塞扩散”。

## 10. 死锁、锁等待与超时

### 10.1 锁等待

当一个事务请求的锁与其他事务已持有锁冲突，就进入等待。

排查时关心：

- 谁在等待？
- 谁阻塞它？
- 等待的是 record、gap、table、metadata，还是内部 synch？
- 等待语句是什么？
- 阻塞事务多久没提交？

### 10.2 死锁

死锁是事务之间形成循环等待。InnoDB 可以检测死锁，并回滚其中一个事务。

典型死锁：

```sql
-- session 1
START TRANSACTION;
UPDATE account SET balance = balance - 100 WHERE id = 1;
UPDATE account SET balance = balance + 100 WHERE id = 2;

-- session 2
START TRANSACTION;
UPDATE account SET balance = balance - 100 WHERE id = 2;
UPDATE account SET balance = balance + 100 WHERE id = 1;
```

如果两个事务交叉执行，就可能互相等待。

### 10.3 锁等待超时

`innodb_lock_wait_timeout` 控制 InnoDB 行锁等待超时。

注意：

- 默认情况下，锁等待超时通常回滚当前语句，不一定回滚整个事务。
- 死锁检测启用时，死锁通常会被立即检测并回滚一个事务，不等超时。
- 该参数不适用于所有类型的锁等待，例如 Server 层表锁或 MDL 要另外分析。

### 10.4 应用层必须能重试

死锁不是“数据库坏了”，而是并发系统中的正常现象。业务代码应该对可重试错误做事务级重试。

建议：

- 固定多行、多表访问顺序。
- 缩短事务。
- 不在事务中做 RPC、用户交互、长时间计算。
- 用索引缩小扫描范围。
- 大批量写入分批提交。
- 捕获死锁和锁等待异常，并做有限次数重试。

## 11. 锁问题排查

### 11.1 `SHOW ENGINE INNODB STATUS`

适合看：

- 最近一次死锁。
- 当前事务。
- 锁等待。
- InnoDB 内部状态。

重点阅读：

- `LATEST DETECTED DEADLOCK`
- `TRANSACTIONS`
- lock mode
- index name
- waiting / holding 信息

### 11.2 Performance Schema 行锁表

常用表：

```sql
performance_schema.data_locks
performance_schema.data_lock_waits
```

`data_locks` 展示持有或等待中的数据锁，`data_lock_waits` 展示谁阻塞谁。

可以从这些字段入手：

- `ENGINE_TRANSACTION_ID`
- `OBJECT_SCHEMA`
- `OBJECT_NAME`
- `INDEX_NAME`
- `LOCK_TYPE`
- `LOCK_MODE`
- `LOCK_STATUS`
- `LOCK_DATA`

### 11.3 MDL 排查

常用表：

```sql
performance_schema.metadata_locks
```

关注：

- 哪个对象被锁。
- 锁类型。
- granted 还是 pending。
- 哪个线程持有。
- 哪个线程等待。

### 11.4 Latch / Mutex 等待排查

常用入口：

```sql
performance_schema.events_waits_summary_global_by_event_name
performance_schema.events_waits_current
performance_schema.mutex_instances
performance_schema.rwlock_instances
```

常见事件名前缀：

```text
wait/synch/mutex/innodb/...
wait/synch/rwlock/innodb/...
wait/synch/cond/innodb/...
```

如果行锁、MDL 都不明显，但系统吞吐下降、CPU 消耗高、等待集中在 `wait/synch/...`，就要考虑内部同步竞争。

### 11.5 排查顺序建议

1. 先确认是单条 SQL 慢，还是整个实例阻塞。
2. 看 `SHOW PROCESSLIST` 或 processlist 视图，找到等待线程。
3. 如果是 DDL 或大量 DML 阻塞，查 MDL。
4. 如果是事务写冲突，查 `data_locks` / `data_lock_waits`。
5. 如果报死锁，查 `SHOW ENGINE INNODB STATUS`。
6. 如果没有明显行锁但性能异常，查 Performance Schema wait/synch。
7. 最后回到 SQL 执行计划和索引设计。

## 12. Latch：内部同步机制

### 12.1 Latch 和 Lock 的区别

| 对比项 | Lock | Latch |
| --- | --- | --- |
| 保护对象 | 逻辑数据对象 | 内部内存结构 |
| 生命周期 | 可能持续到事务结束 | 通常极短 |
| 是否事务语义 | 是 | 否 |
| 用户能否直接控制 | 部分可以 | 通常不能 |
| 典型等待 | 行锁、MDL、表锁 | mutex、rw-lock、spin |

Latch 不是业务 SQL 语义的一部分，而是数据库内核保护共享内存结构的同步机制。

### 12.2 常见 latch 形态

- Mutex：互斥锁，一次只允许一个线程进入。
- RW-lock：读写锁，多个读者或一个写者。
- Spin wait：短暂自旋，避免频繁睡眠和唤醒。
- Condition wait：等待某个条件变化。

### 12.3 常见热点

可能出现内部同步竞争的位置：

- buffer pool。
- adaptive hash index。
- redo log / flush 路径。
- lock system。
- data dictionary。
- table cache。
- change buffer。

不同版本中内部实现会变化，因此具体事件名要以当前版本 Performance Schema 输出为准。

### 12.4 业务上如何理解 latch

业务代码无法像 `SELECT ... FOR UPDATE` 那样直接获取 latch。它更像性能诊断概念。

如果你看到：

- 无明显行锁等待。
- 无明显 MDL。
- CPU 高。
- 并发增加后吞吐不升反降。
- Performance Schema 显示大量 `wait/synch/...`。

这时才把 latch 作为重点分析方向。

## 13. 业务开发最佳实践

### 13.1 事务要短

事务中不要做：

- 用户交互。
- RPC。
- HTTP 调用。
- 大文件处理。
- 长时间计算。
- 人工确认。

事务越长，锁和 MDL 持有越久。

### 13.2 用索引控制锁范围

锁范围很大程度由访问路径决定。高并发写 SQL 必须确认：

- `WHERE` 条件有合适索引。
- 联合索引顺序匹配查询。
- 范围条件位置合理。
- `ORDER BY` / `LIMIT` 能利用索引。
- 执行计划稳定。

### 13.3 固定访问顺序

多行、多表更新要固定顺序：

```sql
-- 好：统一按 id 升序锁定
SELECT * FROM account WHERE id IN (1, 2) ORDER BY id FOR UPDATE;
```

不要让不同业务路径以相反顺序锁同一批资源。

### 13.4 谨慎使用 `SELECT ... FOR UPDATE`

`FOR UPDATE` 是强工具，但不是默认选项。

适合：

- 读后立即更新。
- 任务领取。
- 状态机转换。
- 需要防止并发修改的关键资源。

不适合：

- 只读展示。
- 长事务中的大范围查询。
- 没有合适索引的查询。
- 用户操作前置校验。

### 13.5 死锁重试

业务代码应支持事务级重试：

- 捕获死锁错误。
- 捕获必要的锁等待超时。
- 回滚整个事务。
- 随机短暂退避。
- 限制重试次数。

不要只重试失败语句而保留原事务上下文。

### 13.6 DDL 前检查长事务

上线 DDL 前：

- 检查长事务。
- 检查当前是否有大查询。
- 检查 MDL 等待。
- 优先使用在线 DDL 能力。
- 对大表变更加超时和回滚预案。

### 13.7 命名锁要封装

如果使用 `GET_LOCK()`：

- 必须设置超时。
- 必须有 finally 释放。
- 必须处理连接池。
- 锁名要有命名规范。
- 不要让命名锁跨越不受控业务流程。

## 14. 实验案例库

下面这些实验建议后续单独拆成可执行 SQL 用例。

### 14.1 普通快照读不阻塞写

目标：证明普通 `SELECT` 不持有阻塞写入的行锁。

实验：

- session 1 开事务普通 `SELECT`。
- session 2 更新同一行。
- 观察 session 2 不被 session 1 阻塞。

### 14.2 `SELECT ... FOR UPDATE` 阻塞更新

目标：证明加锁读持有排他锁。

实验：

- session 1 `SELECT ... FOR UPDATE`。
- session 2 `UPDATE` 同一行。
- 观察 session 2 等待。

### 14.3 二级索引加锁

目标：观察二级索引路径下的锁对象。

实验：

- 创建主键和二级索引。
- 使用二级索引条件 `FOR UPDATE`。
- 查询 `performance_schema.data_locks`。
- 观察 index name 和 lock mode。

### 14.4 Gap Lock / Next-Key Lock

目标：理解不存在的值也可能被锁。

实验：

- session 1 范围 `SELECT ... FOR UPDATE`。
- session 2 插入范围内不存在的值。
- 在 `REPEATABLE READ` 下观察阻塞。

### 14.5 半一致性读

目标：理解 `READ COMMITTED` 下 `UPDATE` 碰到被锁行时如何减少无谓等待。

实验：

- session 1 锁住某行但不提交。
- session 2 执行条件不匹配该行的 `UPDATE`。
- 对比 `READ COMMITTED` 和 `REPEATABLE READ` 行为。

### 14.6 无索引更新导致锁范围扩大

目标：证明“看起来像锁表”可能是扫描路径问题。

实验：

- 使用无索引条件执行 `UPDATE`。
- 另一个 session 更新不同逻辑行。
- 观察等待范围。
- 添加索引后对比。

### 14.7 MDL 阻塞 DDL

目标：证明长事务访问表后可能阻塞 DDL。

实验：

- session 1 开事务查询表不提交。
- session 2 `ALTER TABLE`。
- session 3 查询同一表。
- 观察 MDL 等待链。

### 14.8 死锁复现

目标：理解访问顺序不一致导致死锁。

实验：

- 两个事务按相反顺序更新两行。
- 观察其中一个事务被回滚。
- 查看 `SHOW ENGINE INNODB STATUS`。

### 14.9 Latch 观察

目标：知道 latch 等待在哪里看。

实验：

- 打开 Performance Schema waits instrument。
- 执行高并发写入或热点更新压测。
- 查看 `events_waits_summary_global_by_event_name` 中 `wait/synch/...` 事件。

## 15. 后续与 PostgreSQL / Oracle 的对照点

后续写 PostgreSQL 和 Oracle 时，可以按本文件结构对照。

### 15.1 MySQL 与 PostgreSQL

重点差异：

- MySQL InnoDB 默认 `REPEATABLE READ` 与 PostgreSQL `REPEATABLE READ` 语义不同。
- MySQL 使用 gap / next-key lock 处理很多范围加锁问题。
- PostgreSQL 使用 MVCC、行锁模式、predicate lock / SSI 来处理更高隔离级别问题。
- MySQL record lock 基于索引记录；PostgreSQL 行锁直接标记 tuple，并可能产生磁盘写。
- MySQL MDL 与 PostgreSQL relation lock / DDL lock 需要单独对照。
- MySQL `GET_LOCK()` 与 PostgreSQL advisory lock 可对照，但生命周期语义不同。

### 15.2 MySQL 与 Oracle

重点差异：

- Oracle 一致性读也基于 undo，但锁和等待模型不同。
- Oracle 普通读不阻塞写，写不阻塞普通读。
- Oracle 没有 MySQL 这种 gap lock / next-key lock 心智模型。
- Oracle 有 enqueue、latch、ITL 等概念，需要单独建模。
- Oracle DDL 隐式提交和锁行为需要专门学习。

### 15.3 迁移学习建议

不要直接把 MySQL 术语搬到 PG / Oracle。建议按问题映射：

1. 普通读是否阻塞写？
2. 写是否阻塞普通读？
3. 加锁读有哪些模式？
4. 范围查询如何防幻读？
5. DDL 如何阻塞 DML？
6. 应用级锁如何实现？
7. 死锁如何检测和返回？
8. 内部 latch 如何观测？

## 参考官方文档

- [MySQL 8.4 Reference Manual: InnoDB Locking](https://dev.mysql.com/doc/refman/8.4/en/innodb-locking.html)
- [MySQL 8.4 Reference Manual: InnoDB Transaction Model](https://dev.mysql.com/doc/refman/8.4/en/innodb-transaction-model.html)
- [MySQL 8.4 Reference Manual: Transaction Isolation Levels](https://dev.mysql.com/doc/refman/8.4/en/innodb-transaction-isolation-levels.html)
- [MySQL 8.4 Reference Manual: Consistent Nonlocking Reads](https://dev.mysql.com/doc/refman/8.4/en/innodb-consistent-read.html)
- [MySQL 8.4 Reference Manual: Locking Reads](https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html)
- [MySQL 8.4 Reference Manual: Locks Set by Different SQL Statements in InnoDB](https://dev.mysql.com/doc/refman/8.4/en/innodb-locks-set.html)
- [MySQL 8.4 Reference Manual: Metadata Locking](https://dev.mysql.com/doc/refman/8.4/en/metadata-locking.html)
- [MySQL 8.4 Reference Manual: Internal Locking Methods](https://dev.mysql.com/doc/refman/8.4/en/internal-locking.html)
- [MySQL 8.4 Reference Manual: Table Locking Issues](https://dev.mysql.com/doc/refman/8.4/en/table-locking.html)
- [MySQL 8.4 Reference Manual: Locking Functions](https://dev.mysql.com/doc/refman/8.4/en/locking-functions.html)
- [MySQL 8.4 Reference Manual: Deadlocks in InnoDB](https://dev.mysql.com/doc/refman/8.4/en/innodb-deadlocks.html)
- [MySQL 8.4 Reference Manual: Deadlock Detection](https://dev.mysql.com/doc/refman/8.4/en/innodb-deadlock-detection.html)
- [MySQL 8.4 Reference Manual: How to Minimize and Handle Deadlocks](https://dev.mysql.com/doc/refman/8.4/en/innodb-deadlocks-handling.html)
- [MySQL 8.4 Reference Manual: Performance Schema Lock Tables](https://dev.mysql.com/doc/refman/8.4/en/performance-schema-lock-tables.html)
- [MySQL 8.4 Reference Manual: Monitoring InnoDB Mutex Waits Using Performance Schema](https://dev.mysql.com/doc/refman/8.4/en/monitor-innodb-mutex-waits-performance-schema.html)
- [MySQL 8.4 Reference Manual: Configuring Spin Lock Polling](https://dev.mysql.com/doc/refman/8.4/en/innodb-performance-spin_lock_polling.html)
