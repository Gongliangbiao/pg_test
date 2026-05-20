# PostgreSQL 16 并发控制相关系统参数整理

## 1. 文档定位

本文档整理 PostgreSQL 16 官方文档中与并发控制、事务隔离、锁等待、Serializable SSI 和并发测试观测直接相关的用户可设置参数。

范围说明：

- 包含可通过 `SET`、`SET TRANSACTION`、`SET SESSION CHARACTERISTICS` 设置的会话级或事务级参数。
- 包含需要通过 `ALTER SYSTEM`、`postgresql.conf` 或服务器启动参数设置的集群级参数。
- 不展开 PostgreSQL Chapter 20 中全部运行时参数，只保留并发控制测试设计中后续会直接用到的参数。

主要官方来源：

- PostgreSQL 16 Documentation: Chapter 13 Concurrency Control
- PostgreSQL 16 Documentation: `SET`
- PostgreSQL 16 Documentation: `SHOW`
- PostgreSQL 16 Documentation: `SET TRANSACTION`
- PostgreSQL 16 Documentation: Runtime Config - Client Connection Defaults
- PostgreSQL 16 Documentation: Runtime Config - Lock Management
- PostgreSQL 16 Documentation: Runtime Config - Error Reporting and Logging
- PostgreSQL 16 Documentation: `ALTER SYSTEM`

## 2. 通用设置和确认方式

### 2.1 会话级设置

```sql
SET parameter_name TO value;
SET SESSION parameter_name TO value;
SHOW parameter_name;
SELECT current_setting('parameter_name');
```

说明：

- `SET` 默认等价于 `SET SESSION`。
- 设置只影响当前会话。
- 如果 `SET` 在事务中执行且事务回滚，则该设置也会回滚。

### 2.2 事务级临时设置

```sql
BEGIN;
SET LOCAL parameter_name TO value;
SHOW parameter_name;
COMMIT;
```

说明：

- `SET LOCAL` 只在当前事务内有效。
- 事务提交或回滚后恢复为会话级设置。
- 在事务块外执行 `SET LOCAL` 会产生 warning，且没有实际效果。

### 2.3 当前事务特性设置

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET TRANSACTION READ ONLY;
SET TRANSACTION DEFERRABLE;
SHOW transaction_isolation;
SHOW transaction_read_only;
SHOW transaction_deferrable;
COMMIT;
```

说明：

- `SET TRANSACTION` 只影响当前事务，不影响后续事务。
- 必须在当前事务的第一条查询或数据修改语句之前执行。
- 也可以在 `BEGIN` 中直接指定事务特性。

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE READ ONLY DEFERRABLE;
SHOW transaction_isolation;
SHOW transaction_read_only;
SHOW transaction_deferrable;
COMMIT;
```

### 2.4 后续事务默认特性设置

```sql
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION CHARACTERISTICS AS TRANSACTION READ ONLY;
SET SESSION CHARACTERISTICS AS TRANSACTION DEFERRABLE;
```

等价形式：

```sql
SET default_transaction_isolation TO 'repeatable read';
SET default_transaction_read_only TO on;
SET default_transaction_deferrable TO on;
```

确认方式：

```sql
SHOW default_transaction_isolation;
SHOW default_transaction_read_only;
SHOW default_transaction_deferrable;

BEGIN;
SHOW transaction_isolation;
SHOW transaction_read_only;
SHOW transaction_deferrable;
ROLLBACK;
```

### 2.5 集群级设置

```sql
ALTER SYSTEM SET parameter_name TO value;
SELECT pg_reload_conf();
```

确认方式：

```sql
SHOW parameter_name;

SELECT name, setting, unit, source, context, pending_restart
FROM pg_settings
WHERE name = 'parameter_name';
```

说明：

- `ALTER SYSTEM` 写入 `postgresql.auto.conf`。
- 可 reload 的参数在 `pg_reload_conf()` 后生效。
- 只能在服务器启动时确定的参数需要重启，确认时重点看 `pg_settings.pending_restart`。
- `ALTER SYSTEM` 不能在事务块或函数中执行。

## 3. 事务隔离与事务特性参数

| 参数或特性 | 类型 | 有效值 | 默认值 | 设置 SQL | 确认 SQL | 备注 |
|---|---|---|---|---|---|---|
| `default_transaction_isolation` | enum | `read uncommitted`、`read committed`、`repeatable read`、`serializable` | `read committed` | `SET default_transaction_isolation TO 'serializable';` | `SHOW default_transaction_isolation;` | 控制每个新事务的默认隔离级别。PostgreSQL 中 `read uncommitted` 表现为 `read committed`。 |
| `transaction_isolation` | enum | `read uncommitted`、`read committed`、`repeatable read`、`serializable` | 继承 `default_transaction_isolation` | `BEGIN; SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | `SHOW transaction_isolation;` | 反映当前事务隔离级别。设置时等价于对应的 `SET TRANSACTION`，必须在第一条查询或数据修改语句前执行。 |
| `default_transaction_read_only` | boolean | `on`、`off` | `off` | `SET default_transaction_read_only TO on;` | `SHOW default_transaction_read_only;` | 控制新事务默认是否只读。只读事务不能修改非临时表。 |
| `transaction_read_only` | boolean | `on`、`off` | 继承 `default_transaction_read_only` | `BEGIN; SET TRANSACTION READ ONLY;` | `SHOW transaction_read_only;` | 反映当前事务 read-only 状态。设置时等价于 `SET TRANSACTION READ ONLY`。 |
| `default_transaction_deferrable` | boolean | `on`、`off` | `off` | `SET default_transaction_deferrable TO on;` | `SHOW default_transaction_deferrable;` | 控制新事务默认是否 deferrable。只对 `SERIALIZABLE READ ONLY` 事务有实际意义。 |
| `transaction_deferrable` | boolean | `on`、`off` | 继承 `default_transaction_deferrable` | `BEGIN; SET TRANSACTION DEFERRABLE;` | `SHOW transaction_deferrable;` | 反映当前事务 deferrable 状态。只有同时为 `SERIALIZABLE` 和 `READ ONLY` 时才有实际效果。 |

## 4. `SET TRANSACTION` 可设置的事务模式

| 事务模式 | 有效值 | 设置 SQL | 确认 SQL | 测试用途 |
|---|---|---|---|---|
| 隔离级别 | `READ UNCOMMITTED`、`READ COMMITTED`、`REPEATABLE READ`、`SERIALIZABLE` | `SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;` | `SHOW transaction_isolation;` | M2-M5 隔离级别、快照和 SSI 用例。 |
| 访问模式 | `READ WRITE`、`READ ONLY` | `SET TRANSACTION READ ONLY;` | `SHOW transaction_read_only;` | Serializable 只读优化、只读事务限制。 |
| 延迟模式 | `DEFERRABLE`、`NOT DEFERRABLE` | `SET TRANSACTION DEFERRABLE;` | `SHOW transaction_deferrable;` | `SERIALIZABLE READ ONLY DEFERRABLE` 等待安全快照。 |
| 导入快照 | snapshot id 字符串 | `SET TRANSACTION SNAPSHOT '00000003-0000001B-1';` | 通过后续可见性查询确认 | 需要先由其他事务调用 `pg_export_snapshot()`。导入事务必须为 `REPEATABLE READ` 或 `SERIALIZABLE`。 |

示例：

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE READ ONLY DEFERRABLE;
SHOW transaction_isolation;
SHOW transaction_read_only;
SHOW transaction_deferrable;
COMMIT;
```

## 5. 锁等待、超时与会话清理参数

| 参数 | 类型 | 有效值 | 默认值 | 设置 SQL | 确认 SQL | 备注 |
|---|---|---|---|---|---|---|
| `statement_timeout` | integer/time | 非负时间值；不带单位时按毫秒；`0` 表示禁用 | `0` | `SET statement_timeout TO '5s';` | `SHOW statement_timeout;` | 超过指定执行时间的语句会被取消。用于避免测试阻塞过久。 |
| `lock_timeout` | integer/time | 非负时间值；不带单位时按毫秒；`0` 表示禁用 | `0` | `SET lock_timeout TO '1s';` | `SHOW lock_timeout;` | 只在等待锁时触发。若 `statement_timeout` 非零且小于等于它，会先触发 statement timeout。 |
| `idle_in_transaction_session_timeout` | integer/time | 非负时间值；不带单位时按毫秒；`0` 表示禁用 | `0` | `SET idle_in_transaction_session_timeout TO '10min';` | `SHOW idle_in_transaction_session_timeout;` | 会终止在打开事务中 idle 超时的会话，避免长期持锁和阻碍 vacuum。 |
| `deadlock_timeout` | integer/time | 时间值；不带单位时按毫秒 | `1s` | `SET deadlock_timeout TO '200ms';` | `SHOW deadlock_timeout;` | 等待锁超过该时间后检查死锁。只有 superuser 或被授予相应 `SET` 权限的用户可修改。 |

测试建议：

```sql
SET lock_timeout TO '500ms';
SHOW lock_timeout;

SET statement_timeout TO '5s';
SHOW statement_timeout;

SET idle_in_transaction_session_timeout TO '30s';
SHOW idle_in_transaction_session_timeout;
```

## 6. 锁和 Serializable 谓词锁容量参数

这些参数主要用于 M5 Serializable / SSI、M6 显式锁、M8 prepared transaction 冲突和高并发压力场景。它们通常不是普通用例中每个会话临时设置的参数。

| 参数 | 类型 | 有效值 | 默认值 | 设置 SQL | 确认 SQL | 生效方式 |
|---|---|---|---|---|---|---|
| `max_locks_per_transaction` | integer | 正整数 | `64` | `ALTER SYSTEM SET max_locks_per_transaction = 128;` | 查询 `pg_settings` | 只能服务器启动时生效；需重启。控制每个事务平均可用对象锁数量，不是行锁数量上限。 |
| `max_pred_locks_per_transaction` | integer | 正整数 | `64` | `ALTER SYSTEM SET max_pred_locks_per_transaction = 128;` | 查询 `pg_settings` | 只能服务器启动时生效；需重启。控制 Serializable 谓词锁表按事务分配的平均对象锁数量。 |
| `max_pred_locks_per_relation` | integer | `>= 0` 表示绝对上限；负数表示 `max_pred_locks_per_transaction / abs(value)` | `-2` | `ALTER SYSTEM SET max_pred_locks_per_relation = -2;` | 查询 `pg_settings` | 需配置 reload 或按 `pg_settings.pending_restart` 判断是否重启。控制单个 relation 上 page/tuple predicate lock 晋升为 relation lock 的阈值。 |
| `max_pred_locks_per_page` | integer | 整数 | `2` | `ALTER SYSTEM SET max_pred_locks_per_page = 2;` | 查询 `pg_settings` | 需配置 reload 或按 `pg_settings.pending_restart` 判断是否重启。控制单页 tuple predicate lock 晋升为 page lock 的阈值。 |

确认模板：

```sql
SELECT name, setting, unit, source, context, pending_restart
FROM pg_settings
WHERE name IN (
  'max_locks_per_transaction',
  'max_pred_locks_per_transaction',
  'max_pred_locks_per_relation',
  'max_pred_locks_per_page'
)
ORDER BY name;
```

如果 `pending_restart = on`，说明配置已经记录但当前运行实例尚未使用新值，需要重启 PostgreSQL 后再确认。

## 7. 锁等待日志观测参数

| 参数 | 类型 | 有效值 | 默认值 | 设置 SQL | 确认 SQL | 备注 |
|---|---|---|---|---|---|---|
| `log_lock_waits` | boolean | `on`、`off` | `off` | `SET log_lock_waits TO on;` | `SHOW log_lock_waits;` | 会在会话等待锁超过 `deadlock_timeout` 时输出日志。只有 superuser 或被授予相应 `SET` 权限的用户可修改。 |

建议与 `deadlock_timeout` 联合使用：

```sql
SET deadlock_timeout TO '200ms';
SET log_lock_waits TO on;

SHOW deadlock_timeout;
SHOW log_lock_waits;
```

## 8. 推荐测试初始化片段

### 8.1 普通并发测试会话

```sql
SET lock_timeout TO '2s';
SET statement_timeout TO '30s';
SET idle_in_transaction_session_timeout TO '60s';

SHOW lock_timeout;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;
```

### 8.2 Repeatable Read 用例

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;
SHOW transaction_read_only;
SHOW transaction_deferrable;
```

### 8.3 Serializable 普通读写用例

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE READ WRITE NOT DEFERRABLE;
SHOW transaction_isolation;
SHOW transaction_read_only;
SHOW transaction_deferrable;
```

### 8.4 Serializable 只读安全快照用例

```sql
BEGIN ISOLATION LEVEL SERIALIZABLE READ ONLY DEFERRABLE;
SHOW transaction_isolation;
SHOW transaction_read_only;
SHOW transaction_deferrable;
```

## 9. 参数与用例模块映射

| 参数或特性 | 主要用例模块 |
|---|---|
| `default_transaction_isolation` | M2、M7 |
| `transaction_isolation` / `SET TRANSACTION ISOLATION LEVEL` | M2、M3、M4、M5、M7、M8 |
| `transaction_read_only` / `READ ONLY` | M4、M5、M7 |
| `transaction_deferrable` / `DEFERRABLE` | M5 |
| `lock_timeout` | M6、M8 |
| `statement_timeout` | 所有多会话阻塞测试 |
| `idle_in_transaction_session_timeout` | M5、M6、M7 |
| `deadlock_timeout` | M6、M8 |
| `log_lock_waits` | M6 观测类用例 |
| `max_locks_per_transaction` | M6、Advisory lock 压力或对象锁容量类用例 |
| `max_pred_locks_per_transaction` | M5 Serializable SSI |
| `max_pred_locks_per_relation` | M5 relation-level predicate lock 观测 |
| `max_pred_locks_per_page` | M5 page-level predicate lock 观测 |

## 10. 成功设置的判定标准

后续测试步骤中建议按以下规则判断设置是否成功：

1. 对会话级参数，执行 `SET` 后立即 `SHOW parameter_name`，返回值与预期一致即为成功。
2. 对事务级参数，必须在 `BEGIN` 后、第一条查询或数据修改语句前设置，并用 `SHOW transaction_*` 确认。
3. 对 `SET LOCAL`，需要在事务内确认；事务结束后再次 `SHOW`，应恢复会话级值。
4. 对 `ALTER SYSTEM` 设置的 reload 参数，执行 `SELECT pg_reload_conf();` 后用 `pg_settings.source` 和 `setting` 确认。
5. 对需要重启的参数，用 `pg_settings.pending_restart` 判断是否已等待重启；重启后再用 `SHOW` 或 `pg_settings.setting` 确认运行值。
6. 对需要权限的参数，如果设置失败，应记录 SQLSTATE 和错误消息，不应把失败当作用例环境异常静默跳过。

## 11. 官方文档链接

- [PostgreSQL 16 SET](https://www.postgresql.org/docs/16/sql-set.html)
- [PostgreSQL 16 SHOW](https://www.postgresql.org/docs/16/sql-show.html)
- [PostgreSQL 16 SET TRANSACTION](https://www.postgresql.org/docs/16/sql-set-transaction.html)
- [PostgreSQL 16 Client Connection Defaults](https://www.postgresql.org/docs/16/runtime-config-client.html)
- [PostgreSQL 16 Lock Management](https://www.postgresql.org/docs/16/runtime-config-locks.html)
- [PostgreSQL 16 Error Reporting and Logging](https://www.postgresql.org/docs/16/runtime-config-logging.html)
- [PostgreSQL 16 ALTER SYSTEM](https://www.postgresql.org/docs/16/sql-altersystem.html)
