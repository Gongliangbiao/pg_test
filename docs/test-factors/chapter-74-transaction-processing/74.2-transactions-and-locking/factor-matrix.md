# 74.2 Transactions and Locking 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节结构
- Chapter 74 Transaction Processing
  - 74.2 Transactions and Locking

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 74 Transaction Processing 中 74.2 Transactions and Locking 的测试点。测试点来自事务处理测试点计划，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 12 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | xid / vxid / diagnostic view、LOCK / xid / vxid / diagnostic view、LOCK / diagnostic view、SELECT / LOCK / diagnostic view、LOCK、LOCK / xid、UPDATE / LOCK、LOCK / PREPARE TRANSACTION / COMMIT / ROLLBACK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、只读事务状态、等待/阻塞状态、同一行并发访问、提交后状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 诊断观测、常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE: 当前执行事务可在 pg_locks.virtualxid 中观测到事务 vxid。 | normal | P0 | 当前执行事务可在 pg_locks.virtualxid 中观测到事务 vxid。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL: 只读事务在 pg_locks 中有 virtualxid，但 transactionid 为 NULL。 | normal | P0 | 只读事务在 pg_locks 中有 virtualxid，但 transactionid 为 NULL。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET: 读写事务在 pg_locks 中同时具有 virtualxid 和 transactionid。 | normal | P0 | 读写事务在 pg_locks 中同时具有 virtualxid 和 transactionid。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | TXLOCK-WAIT-ON-VIRTUALXID: 某些锁等待目标为 virtualxid，可通过 pg_locks 的等待记录确认。 | normal | P1 | 某些锁等待目标为 virtualxid，可通过 pg_locks 的等待记录确认。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | TXLOCK-WAIT-ON-TRANSACTIONID: 某些锁等待目标为 transactionid，可通过 pg_locks 的等待记录确认。 | normal | P1 | 某些锁等待目标为 transactionid，可通过 pg_locks 的等待记录确认。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW: 行级读写锁记录在被锁行上，不能简单按每行锁从 pg_locks 直接读取。 | normal | P1 | 行级读写锁记录在被锁行上，不能简单按每行锁从 pg_locks 直接读取。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT: 使用 pgrowlocks 扩展检查被锁行的行级锁信息。 | normal | P1 | 使用 pgrowlocks 扩展检查被锁行的行级锁信息。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE: 行级读锁可能需要分配 multixact ID。 | normal | P1 | 行级读锁可能需要分配 multixact ID。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE: 多个事务对同一行持有兼容读锁时，可形成 multixact 观测场景。 | normal | P1 | 多个事务对同一行持有兼容读锁时，可形成 multixact 观测场景。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK: 只读事务可以持有事务锁观测项，但不因此分配非虚拟 xid。 | normal | P0 | 只读事务可以持有事务锁观测项，但不因此分配非虚拟 xid。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | TXLOCK-READWRITE-XID-AFTER-DML-LOCK: DML 写入后事务锁观测中出现非空 transactionid。 | normal | P0 | DML 写入后事务锁观测中出现非空 transactionid。 | 单一测试点，不与其他主场景合并。 |
| F01-V12 | TXLOCK-PREPARED-XACT-LOCK-RETAINED: prepared transaction 继续持有其已获取锁，直到 COMMIT PREPARED 或 ROLLBACK PREPARED。 | normal | P1 | prepared transaction 继续持有其已获取锁，直到 COMMIT PREPARED 或 ROLLBACK PREPARED。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | xid / vxid / diagnostic view | normal | P0 | 来自 TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | LOCK / xid / vxid / diagnostic view | normal | P1 | 来自 TXLOCK-WAIT-ON-VIRTUALXID 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | LOCK / diagnostic view | normal | P1 | 来自 TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | SELECT / LOCK / diagnostic view | normal | P1 | 来自 TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | LOCK | normal | P1 | 来自 TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | LOCK / xid | normal | P0 | 来自 TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | UPDATE / LOCK | normal | P0 | 来自 TXLOCK-READWRITE-XID-AFTER-DML-LOCK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | LOCK / PREPARE TRANSACTION / COMMIT / ROLLBACK | normal | P1 | 来自 TXLOCK-PREPARED-XACT-LOCK-RETAINED 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 TXLOCK-READWRITE-XID-AFTER-DML-LOCK 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 只读事务状态 | normal/boundary | P0 | 来自 TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 等待/阻塞状态 | normal/boundary | P1 | 来自 TXLOCK-WAIT-ON-TRANSACTIONID 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 同一行并发访问 | normal/boundary | P1 | 来自 TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V05 | 提交后状态 | normal/boundary | P1 | 来自 TXLOCK-PREPARED-XACT-LOCK-RETAINED 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 诊断观测 | boundary/exception/diagnostic | P0 | 来自 TXLOCK-READWRITE-XID-AFTER-DML-LOCK 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 常规核心路径 | boundary/exception/diagnostic | P1 | 来自 TXLOCK-PREPARED-XACT-LOCK-RETAINED 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE、TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL、TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET、TXLOCK-WAIT-ON-VIRTUALXID、TXLOCK-WAIT-ON-TRANSACTIONID、TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW、TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT、TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE、TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK、TXLOCK-READWRITE-XID-AFTER-DML-LOCK |
| C02 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE |
| C03 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | TXLOCK-PREPARED-XACT-LOCK-RETAINED |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| TXLOCK-PGLOCKS-VIRTUALXID-VISIBLE | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 当前执行事务可在 pg_locks.virtualxid 中观测到事务 vxid。 | `txlock-pglocks-virtualxid-visible.md` |
| TXLOCK-PGLOCKS-READONLY-TRANSACTIONID-NULL | C01 | P0 | F01-V02,F02-V01,F03-V02,F04-V01 | 只读事务在 pg_locks 中有 virtualxid，但 transactionid 为 NULL。 | `txlock-pglocks-readonly-transactionid-null.md` |
| TXLOCK-PGLOCKS-READWRITE-TRANSACTIONID-SET | C01 | P0 | F01-V03,F02-V01,F03-V01,F04-V01 | 读写事务在 pg_locks 中同时具有 virtualxid 和 transactionid。 | `txlock-pglocks-readwrite-transactionid-set.md` |
| TXLOCK-WAIT-ON-VIRTUALXID | C01 | P1 | F01-V04,F02-V02,F03-V03,F04-V01 | 某些锁等待目标为 virtualxid，可通过 pg_locks 的等待记录确认。 | `txlock-wait-on-virtualxid.md` |
| TXLOCK-WAIT-ON-TRANSACTIONID | C01 | P1 | F01-V05,F02-V03,F03-V03,F04-V01 | 某些锁等待目标为 transactionid，可通过 pg_locks 的等待记录确认。 | `txlock-wait-on-transactionid.md` |
| TXLOCK-ROW-LOCK-NOT-IN-PGLOCKS-PER-ROW | C01 | P1 | F01-V06,F02-V04,F03-V01,F04-V01 | 行级读写锁记录在被锁行上，不能简单按每行锁从 pg_locks 直接读取。 | `txlock-row-lock-not-in-pglocks-per-row.md` |
| TXLOCK-PGROWLOCKS-ROWLOCK-INSPECT | C01 | P1 | F01-V07,F02-V03,F03-V01,F04-V01 | 使用 pgrowlocks 扩展检查被锁行的行级锁信息。 | `txlock-pgrowlocks-rowlock-inspect.md` |
| TXLOCK-ROW-READ-LOCK-MULTIXACT-POSSIBLE | C02 | P1 | F01-V08,F02-V05,F03-V01,F04-V02 | 行级读锁可能需要分配 multixact ID。 | `txlock-row-read-lock-multixact-possible.md` |
| TXLOCK-MULTIXACT-MULTIPLE-KEYSHARE | C01 | P1 | F01-V09,F02-V05,F03-V04,F04-V01 | 多个事务对同一行持有兼容读锁时，可形成 multixact 观测场景。 | `txlock-multixact-multiple-keyshare.md` |
| TXLOCK-READONLY-NO-XID-BUT-HAS-LOCK | C01 | P0 | F01-V10,F02-V06,F03-V02,F04-V01 | 只读事务可以持有事务锁观测项，但不因此分配非虚拟 xid。 | `txlock-readonly-no-xid-but-has-lock.md` |
| TXLOCK-READWRITE-XID-AFTER-DML-LOCK | C01 | P0 | F01-V11,F02-V07,F03-V01,F04-V01 | DML 写入后事务锁观测中出现非空 transactionid。 | `txlock-readwrite-xid-after-dml-lock.md` |
| TXLOCK-PREPARED-XACT-LOCK-RETAINED | C03 | P1 | F01-V12,F02-V08,F03-V05,F04-V02 | prepared transaction 继续持有其已获取锁，直到 COMMIT PREPARED 或 ROLLBACK PREPARED。 | `txlock-prepared-xact-lock-retained.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：12。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。