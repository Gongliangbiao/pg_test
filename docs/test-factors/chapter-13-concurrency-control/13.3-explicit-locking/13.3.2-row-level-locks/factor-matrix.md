# 13.3.2 Row Level Locks 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.3.2 Row Level Locks

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.3.2 Row Level Locks 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 13 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | UPDATE / LOCK、LOCK、SELECT / UPDATE / DELETE / LOCK、UPDATE / LOCK / INDEX、SELECT / UPDATE / LOCK、LOCK / SAVEPOINT / ROLLBACK、UPDATE / DELETE / LOCK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态、同一行并发访问、回滚状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 边界值、常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-ROW-DISK-WRITE-SIDE-EFFECT: 行级锁可能导致磁盘写入，但不受内存中锁数量上限限制。 | normal | P0 | 行级锁可能导致磁盘写入，但不受内存中锁数量上限限制。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-ROW-FOR-KEY-SHARE-MATRIX: FOR KEY SHARE 行级锁冲突矩阵。 | normal | P0 | FOR KEY SHARE 行级锁冲突矩阵。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-ROW-FOR-NO-KEY-UPDATE-MATRIX: FOR NO KEY UPDATE 行级锁冲突矩阵。 | normal | P0 | FOR NO KEY UPDATE 行级锁冲突矩阵。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-ROW-FOR-SHARE-MATRIX: FOR SHARE 行级锁冲突矩阵。 | normal | P0 | FOR SHARE 行级锁冲突矩阵。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-ROW-FOR-UPDATE-MATRIX: FOR UPDATE 行级锁冲突矩阵。 | normal | P0 | FOR UPDATE 行级锁冲突矩阵。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE: SELECT FOR UPDATE 等待并发事务后，返回更新后的行，若行被删除则不返回。 | normal | P0 | SELECT FOR UPDATE waits for a concurrent transaction and then locks and returns the updated row, or returns no row if it was deleted. | 单一测试点，不与其他主场景合并。 |
| F01-V07 | LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY: 修改 key 列触发 FOR UPDATE 的边界应排除 partial index 和 expression index。 | normal | P1 | For deciding whether an UPDATE acquires FOR UPDATE, key columns are those with a unique index usable in a foreign key; partial and expression indexes are not considered. | 单一测试点，不与其他主场景合并。 |
| F01-V08 | LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS: PostgreSQL 不因内存记录限制而限制单事务锁定行数。 | normal | P1 | PostgreSQL does not remember modified rows in memory, so there is no memory-tracking limit on the number of rows locked at one time. | 单一测试点，不与其他主场景合并。 |
| F01-V09 | LOCK-ROW-NORMAL-SELECT-NONBLOCKING: 行级锁只阻塞同一行上的写入和加锁，不影响普通查询。 | normal | P0 | 行级锁只阻塞同一行上的写入和加锁，不影响普通查询。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS: 同一事务甚至不同子事务可在同一行持有彼此冲突的行锁。 | normal | P0 | A transaction can hold conflicting locks on the same row, even in different subtransactions. | 单一测试点，不与其他主场景合并。 |
| F01-V11 | LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE: savepoint 后获取的行锁在 ROLLBACK TO SAVEPOINT 时释放。 | normal | P0 | Row-level locks are released at transaction end or during savepoint rollback, like table-level locks. | 单一测试点，不与其他主场景合并。 |
| F01-V12 | LOCK-ROW-UPDATE-KEY-COLUMN: DELETE 和修改 key 列的 UPDATE 获取 FOR UPDATE。 | normal | P0 | DELETE 和修改 key 列的 UPDATE 获取 FOR UPDATE。 | 单一测试点，不与其他主场景合并。 |
| F01-V13 | LOCK-ROW-UPDATE-NONKEY-COLUMN: 不修改 key 的 UPDATE 获取 FOR NO KEY UPDATE。 | normal | P0 | 不修改 key 的 UPDATE 获取 FOR NO KEY UPDATE。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | UPDATE / LOCK | normal | P0 | 来自 LOCK-ROW-UPDATE-NONKEY-COLUMN 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | LOCK | normal | P0 | 来自 LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | SELECT / UPDATE / DELETE / LOCK | normal | P0 | 来自 LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | UPDATE / LOCK / INDEX | normal | P1 | 来自 LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | SELECT / UPDATE / LOCK | normal | P0 | 来自 LOCK-ROW-NORMAL-SELECT-NONBLOCKING 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | LOCK / SAVEPOINT / ROLLBACK | normal | P0 | 来自 LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | UPDATE / DELETE / LOCK | normal | P0 | 来自 LOCK-ROW-UPDATE-KEY-COLUMN 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 LOCK-ROW-UPDATE-NONKEY-COLUMN 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-ROW-NORMAL-SELECT-NONBLOCKING 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 同一行并发访问 | normal/boundary | P0 | 来自 LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 回滚状态 | normal/boundary | P0 | 来自 LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 边界值 | boundary/exception/diagnostic | P1 | 来自 LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 LOCK-ROW-UPDATE-NONKEY-COLUMN 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | LOCK-ROW-DISK-WRITE-SIDE-EFFECT、LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY |
| C02 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | LOCK-ROW-FOR-KEY-SHARE-MATRIX、LOCK-ROW-FOR-NO-KEY-UPDATE-MATRIX、LOCK-ROW-FOR-SHARE-MATRIX、LOCK-ROW-FOR-UPDATE-MATRIX、LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE、LOCK-ROW-NORMAL-SELECT-NONBLOCKING、LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS |
| C03 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS、LOCK-ROW-UPDATE-KEY-COLUMN、LOCK-ROW-UPDATE-NONKEY-COLUMN |
| C04 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-ROW-DISK-WRITE-SIDE-EFFECT | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 行级锁可能导致磁盘写入，但不受内存中锁数量上限限制。 | `lock-row-disk-write-side-effect.md` |
| LOCK-ROW-FOR-KEY-SHARE-MATRIX | C02 | P0 | F01-V02,F02-V02,F03-V01,F04-V02 | FOR KEY SHARE 行级锁冲突矩阵。 | `lock-row-for-key-share-matrix.md` |
| LOCK-ROW-FOR-NO-KEY-UPDATE-MATRIX | C02 | P0 | F01-V03,F02-V01,F03-V01,F04-V02 | FOR NO KEY UPDATE 行级锁冲突矩阵。 | `lock-row-for-no-key-update-matrix.md` |
| LOCK-ROW-FOR-SHARE-MATRIX | C02 | P0 | F01-V04,F02-V02,F03-V01,F04-V02 | FOR SHARE 行级锁冲突矩阵。 | `lock-row-for-share-matrix.md` |
| LOCK-ROW-FOR-UPDATE-MATRIX | C02 | P0 | F01-V05,F02-V01,F03-V01,F04-V02 | FOR UPDATE 行级锁冲突矩阵。 | `lock-row-for-update-matrix.md` |
| LOCK-ROW-FOR-UPDATE-RETURN-UPDATED-OR-NONE | C02 | P0 | F01-V06,F02-V03,F03-V02,F04-V02 | SELECT FOR UPDATE 等待并发事务后，返回更新后的行，若行被删除则不返回。 | `lock-row-for-update-return-updated-or-none.md` |
| LOCK-ROW-KEY-COLUMN-INDEX-BOUNDARY | C01 | P1 | F01-V07,F02-V04,F03-V01,F04-V01 | 修改 key 列触发 FOR UPDATE 的边界应排除 partial index 和 expression index。 | `lock-row-key-column-index-boundary.md` |
| LOCK-ROW-NO-MEMORY-LIMIT-ON-LOCKED-ROWS | C03 | P1 | F01-V08,F02-V02,F03-V01,F04-V02 | PostgreSQL 不因内存记录限制而限制单事务锁定行数。 | `lock-row-no-memory-limit-on-locked-rows.md` |
| LOCK-ROW-NORMAL-SELECT-NONBLOCKING | C02 | P0 | F01-V09,F02-V05,F03-V02,F04-V02 | 行级锁只阻塞同一行上的写入和加锁，不影响普通查询。 | `lock-row-normal-select-nonblocking.md` |
| LOCK-ROW-SAME-TXN-CONFLICTING-LOCKS | C02 | P0 | F01-V10,F02-V02,F03-V03,F04-V02 | 同一事务甚至不同子事务可在同一行持有彼此冲突的行锁。 | `lock-row-same-txn-conflicting-locks.md` |
| LOCK-ROW-SAVEPOINT-ROLLBACK-RELEASE | C04 | P0 | F01-V11,F02-V06,F03-V04,F04-V02 | savepoint 后获取的行锁在 ROLLBACK TO SAVEPOINT 时释放。 | `lock-row-savepoint-rollback-release.md` |
| LOCK-ROW-UPDATE-KEY-COLUMN | C03 | P0 | F01-V12,F02-V07,F03-V01,F04-V02 | DELETE 和修改 key 列的 UPDATE 获取 FOR UPDATE。 | `lock-row-update-key-column.md` |
| LOCK-ROW-UPDATE-NONKEY-COLUMN | C03 | P0 | F01-V13,F02-V01,F03-V01,F04-V02 | 不修改 key 的 UPDATE 获取 FOR NO KEY UPDATE。 | `lock-row-update-nonkey-column.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：13。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。