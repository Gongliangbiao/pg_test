# 13.2.3 Serializable 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的 13.2.3 Serializable 章节内容；历史测试点仅作为迁移参考，因子按官方 Serializable/SSI 语义空间重新建模。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.2.3 Serializable

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.2.3 Serializable 的语义空间：成功事务等价于某个串行顺序、危险结构导致 serialization failure、SQLSTATE 40001、predicate/SIReadLock 的观测和非阻塞特性、只读/deferrable 安全快照、唯一约束并发边界，以及官方给出的性能和配置建议。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | Serializable/SSI 行为语义 | 串行等价、危险读写依赖、write skew abort、serialization failure、predicate lock、只读安全快照、unique violation 边界、性能建议 | mixed，详见因子值细化 | 13.2.3 描述 Serializable Snapshot Isolation 的冲突检测、predicate lock、只读优化和性能边界。 | 作为本节核心语义维度。 |
| F02 | object | 被测对象或语句 | SELECT、COMMIT、ROLLBACK、INSERT、predicate/SIReadLock、snapshot、diagnostic view | mixed，详见因子值细化 | 官方行为通过读写事务、提交结果、predicate lock 观测和唯一约束插入体现。 | 用于区分语句入口和诊断对象。 |
| F03 | state/condition | 并发状态或事务模式 | 读后写依赖、只读事务、READ ONLY DEFERRABLE、提交后、回滚后、等待/非阻塞状态、并发插入 | mixed，详见因子值细化 | Serializable 行为依赖事务模式、并发依赖图和提交/回滚结果。 | 用于组合 SSI 冲突和只读优化场景。 |
| F04 | boundary/exception/diagnostic | 结果边界或诊断项 | SQLSTATE 40001、SIReadLock 观测、非阻塞/不参与死锁、提交后保留、predicate lock 升级、连接数/超时/内存参数边界 | mixed，详见因子值细化 | 官方明确描述错误码、诊断视图和性能配置边界。 | 边界/诊断必须独立覆盖。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 Serializable/SSI 行为语义
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | SER-AGGREGATE-READ-THEN-WRITE: 聚合读后写模式触发危险读写依赖。 | normal | P0 | 聚合读后写模式触发危险读写依赖。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | SER-PERF-ACTIVE-CONNECTION-BOUNDARY: 高并发 serializable 场景下，控制 active connections 数量是性能边界。 | normal | P1 | For optimal serializable performance, control the number of active connections, using a connection pool if needed. | 单一测试点，不与其他主场景合并。 |
| F01-V03 | SER-PERF-DECLARE-READ-ONLY: 可声明只读的 serializable 事务应使用 READ ONLY，降低 SSI 负担。 | normal | P1 | For optimal serializable performance, declare transactions as READ ONLY when possible. | 单一测试点，不与其他主场景合并。 |
| F01-V04 | SER-PERF-IDLE-IN-TXN-TIMEOUT: 长时间 idle in transaction 可用 idle_in_transaction_session_timeout 自动断开。 | normal | P1 | idle_in_transaction_session_timeout can be used to disconnect lingering idle-in-transaction sessions. | 单一测试点，不与其他主场景合并。 |
| F01-V05 | SER-PERF-SHORT-TRANSACTION-SCOPE: Serializable 事务范围越大，冲突监控与重试成本越高，应验证最小事务范围策略。 | normal | P1 | For optimal serializable performance, do not put more into a single transaction than needed for integrity purposes. | 单一测试点，不与其他主场景合并。 |
| F01-V06 | SER-PREDICATE-LOCK-ESCALATION-OBSERVE: 顺序扫描可能增加 relation-level predicate lock。 | normal | P2 | 顺序扫描可能增加 relation-level predicate lock。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | SER-PREDICATE-LOCK-MEMORY-PARAMETERS: predicate lock 内存不足导致粗粒度锁和失败率增加时，相关参数是边界配置。 | normal | P1 | Increasing max_pred_locks_per_transaction, max_pred_locks_per_relation, and/or max_pred_locks_per_page can reduce relation-level predicate lock promotion. | 单一测试点，不与其他主场景合并。 |
| F01-V08 | SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT: SERIALIZABLE READ ONLY DEFERRABLE 会等待安全快照。 | normal | P0 | SERIALIZABLE READ ONLY DEFERRABLE 会等待安全快照。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | SER-READ-ONLY-PERFORMANCE-SETTING: Serializable 只读事务声明 READ ONLY 可降低 SSI 开销。 | normal | P0 | Serializable 只读事务声明 READ ONLY 可降低 SSI 开销。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | SER-READ-ONLY-REDUCE-PREDICATE-LOCKS: 安全只读事务可减少或释放 predicate locks。 | normal | P0 | 安全只读事务可减少或释放 predicate locks。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | SER-READ-RESULT-VALID-AFTER-COMMIT: 非 deferrable serializable 事务读取结果只有在事务成功提交后才可作为有效业务判断。 | normal | P0 | Data read from a permanent user table should not be considered valid until the reading transaction has successfully committed. | 单一测试点，不与其他主场景合并。 |
| F01-V12 | SER-READONLY-DEFERRABLE-READ-VALID-AT-READ: SERIALIZABLE READ ONLY DEFERRABLE 取得安全快照后，读取结果在读取时即可视为有效。 | normal | P0 | In a deferrable read-only serializable transaction, data is known to be valid as soon as it is read. | 单一测试点，不与其他主场景合并。 |
| F01-V13 | SER-SIREADLOCK-NONBLOCKING: Predicate locks 不造成阻塞。 | normal | P0 | Predicate locks 不造成阻塞。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | SER-SIREADLOCK-NOT-DEADLOCK-PARTICIPANT: Predicate locks 不参与死锁检测。 | normal | P0 | Predicate locks 不参与死锁检测。 | 单一测试点，不与其他主场景合并。 |
| F01-V15 | SER-SIREADLOCK-PG-LOCKS: Predicate locking 在 pg_locks 中以 SIReadLock 出现。 | normal | P0 | Predicate locking 在 pg_locks 中以 SIReadLock 出现。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | SER-SIREADLOCK-RETAIN-AFTER-COMMIT: SIReadLock 可能在事务提交后保留，直到重叠读写事务完成。 | normal | P0 | SIReadLock 可能在事务提交后保留，直到重叠读写事务完成。 | 单一测试点，不与其他主场景合并。 |
| F01-V17 | SER-SQLSTATE-40001: Serialization failure SQLSTATE 为 40001。 | normal | P0 | Serialization failure SQLSTATE 为 40001。 | 单一测试点，不与其他主场景合并。 |
| F01-V18 | SER-SUCCESS-EQUIVALENT-SERIAL-ORDER: 成功提交的 Serializable 并发事务结果等价于某个串行顺序。 | normal | P0 | 成功提交的 Serializable 并发事务结果等价于某个串行顺序。 | 单一测试点，不与其他主场景合并。 |
| F01-V19 | SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION: 所有可能插入冲突 key 的 serializable 事务都先执行一致的显式检查时，避免原文描述的异常 unique violation 场景。 | normal | P1 | Unique violations caused by overlapping serializable inserts can be avoided if all such transactions explicitly check first. | 单一测试点，不与其他主场景合并。 |
| F01-V20 | SER-UNIQUE-VIOLATION-CONCURRENT-INSERT: 并发 Serializable 下仍可能出现 unique constraint violation。 | normal | P0 | 并发 Serializable 下仍可能出现 unique constraint violation。 | 单一测试点，不与其他主场景合并。 |
| F01-V21 | SER-WRITE-SKEW-ABORT-ONE: Write skew 模式下回滚其中一个事务。 | normal | P0 | Write skew 模式下回滚其中一个事务。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | SERIALIZABLE behavior | normal | P0 | 来自 SER-UNIQUE-VIOLATION-CONCURRENT-INSERT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | SELECT | normal | P0 | 来自 SER-READ-ONLY-PERFORMANCE-SETTING 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | LOCK | normal | P0 | 来自 SER-SIREADLOCK-NOT-DEADLOCK-PARTICIPANT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | SELECT / snapshot | normal | P0 | 来自 SER-READONLY-DEFERRABLE-READ-VALID-AT-READ 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | SELECT / COMMIT | normal | P0 | 来自 SER-SIREADLOCK-RETAIN-AFTER-COMMIT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | SELECT / diagnostic view | normal | P0 | 来自 SER-SIREADLOCK-PG-LOCKS 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | COMMIT | normal | P0 | 来自 SER-SUCCESS-EQUIVALENT-SERIAL-ORDER 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | INSERT | normal | P1 | 来自 SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V09 | ROLLBACK | normal | P0 | 来自 SER-WRITE-SKEW-ABORT-ONE 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 SER-UNIQUE-VIOLATION-CONCURRENT-INSERT 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 只读事务状态 | normal/boundary | P0 | 来自 SER-READONLY-DEFERRABLE-READ-VALID-AT-READ 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 等待/阻塞状态 | normal/boundary | P0 | 来自 SER-SIREADLOCK-NONBLOCKING 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 提交后状态 | normal/boundary | P0 | 来自 SER-SIREADLOCK-RETAIN-AFTER-COMMIT 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V05 | 回滚状态 | normal/boundary | P0 | 来自 SER-WRITE-SKEW-ABORT-ONE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 SER-WRITE-SKEW-ABORT-ONE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 边界值 | boundary/exception/diagnostic | P1 | 来自 SER-PERF-IDLE-IN-TXN-TIMEOUT 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | 错误/禁止场景 | boundary/exception/diagnostic | P1 | 来自 SER-PREDICATE-LOCK-MEMORY-PARAMETERS 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V04 | 诊断观测 | boundary/exception/diagnostic | P0 | 来自 SER-SIREADLOCK-PG-LOCKS 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V05 | SQLSTATE 40001 | boundary/exception/diagnostic | P0 | 来自 SER-SQLSTATE-40001 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | SER-AGGREGATE-READ-THEN-WRITE、SER-PREDICATE-LOCK-ESCALATION-OBSERVE、SER-READ-ONLY-REDUCE-PREDICATE-LOCKS、SER-READONLY-DEFERRABLE-READ-VALID-AT-READ |
| C02 | risk-based | F01,F02,F03,F04 | 覆盖 risk-based 类型测试点 | SER-PERF-ACTIVE-CONNECTION-BOUNDARY、SER-PERF-DECLARE-READ-ONLY、SER-PERF-IDLE-IN-TXN-TIMEOUT、SER-PERF-SHORT-TRANSACTION-SCOPE、SER-READ-ONLY-PERFORMANCE-SETTING |
| C03 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | SER-PREDICATE-LOCK-MEMORY-PARAMETERS、SER-SQLSTATE-40001 |
| C04 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT、SER-READ-RESULT-VALID-AFTER-COMMIT、SER-SIREADLOCK-RETAIN-AFTER-COMMIT、SER-WRITE-SKEW-ABORT-ONE |
| C05 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | SER-SIREADLOCK-NONBLOCKING、SER-SIREADLOCK-NOT-DEADLOCK-PARTICIPANT、SER-SUCCESS-EQUIVALENT-SERIAL-ORDER、SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION、SER-UNIQUE-VIOLATION-CONCURRENT-INSERT |
| C06 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | SER-SIREADLOCK-PG-LOCKS |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| SER-AGGREGATE-READ-THEN-WRITE | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 聚合读后写模式触发危险读写依赖。 | `ser-aggregate-read-then-write.md` |
| SER-PERF-ACTIVE-CONNECTION-BOUNDARY | C02 | P1 | F01-V02,F02-V01,F03-V01,F04-V02 | 高并发 serializable 场景下，控制 active connections 数量是性能边界。 | `ser-perf-active-connection-boundary.md` |
| SER-PERF-DECLARE-READ-ONLY | C02 | P1 | F01-V03,F02-V02,F03-V02,F04-V01 | 可声明只读的 serializable 事务应使用 READ ONLY，降低 SSI 负担。 | `ser-perf-declare-read-only.md` |
| SER-PERF-IDLE-IN-TXN-TIMEOUT | C02 | P1 | F01-V04,F02-V01,F03-V01,F04-V02 | 长时间 idle in transaction 可用 idle_in_transaction_session_timeout 自动断开。 | `ser-perf-idle-in-txn-timeout.md` |
| SER-PERF-SHORT-TRANSACTION-SCOPE | C02 | P1 | F01-V05,F02-V01,F03-V01,F04-V01 | Serializable 事务范围越大，冲突监控与重试成本越高，应验证最小事务范围策略。 | `ser-perf-short-transaction-scope.md` |
| SER-PREDICATE-LOCK-ESCALATION-OBSERVE | C01 | P2 | F01-V06,F02-V03,F03-V01,F04-V01 | 顺序扫描可能增加 relation-level predicate lock。 | `ser-predicate-lock-escalation-observe.md` |
| SER-PREDICATE-LOCK-MEMORY-PARAMETERS | C03 | P1 | F01-V07,F02-V03,F03-V01,F04-V03 | predicate lock 内存不足导致粗粒度锁和失败率增加时，相关参数是边界配置。 | `ser-predicate-lock-memory-parameters.md` |
| SER-READ-ONLY-DEFERRABLE-SAFE-SNAPSHOT | C04 | P0 | F01-V08,F02-V04,F03-V03,F04-V01 | SERIALIZABLE READ ONLY DEFERRABLE 会等待安全快照。 | `ser-read-only-deferrable-safe-snapshot.md` |
| SER-READ-ONLY-PERFORMANCE-SETTING | C02 | P0 | F01-V09,F02-V02,F03-V02,F04-V01 | Serializable 只读事务声明 READ ONLY 可降低 SSI 开销。 | `ser-read-only-performance-setting.md` |
| SER-READ-ONLY-REDUCE-PREDICATE-LOCKS | C01 | P0 | F01-V10,F02-V01,F03-V02,F04-V01 | 安全只读事务可减少或释放 predicate locks。 | `ser-read-only-reduce-predicate-locks.md` |
| SER-READ-RESULT-VALID-AFTER-COMMIT | C04 | P0 | F01-V11,F02-V05,F03-V04,F04-V01 | 非 deferrable serializable 事务读取结果只有在事务成功提交后才可作为有效业务判断。 | `ser-read-result-valid-after-commit.md` |
| SER-READONLY-DEFERRABLE-READ-VALID-AT-READ | C01 | P0 | F01-V12,F02-V04,F03-V02,F04-V01 | SERIALIZABLE READ ONLY DEFERRABLE 取得安全快照后，读取结果在读取时即可视为有效。 | `ser-readonly-deferrable-read-valid-at-read.md` |
| SER-SIREADLOCK-NONBLOCKING | C05 | P0 | F01-V13,F02-V01,F03-V03,F04-V01 | Predicate locks 不造成阻塞。 | `ser-sireadlock-nonblocking.md` |
| SER-SIREADLOCK-NOT-DEADLOCK-PARTICIPANT | C05 | P0 | F01-V14,F02-V03,F03-V01,F04-V01 | Predicate locks 不参与死锁检测。 | `ser-sireadlock-not-deadlock-participant.md` |
| SER-SIREADLOCK-PG-LOCKS | C06 | P0 | F01-V15,F02-V06,F03-V01,F04-V04 | Predicate locking 在 pg_locks 中以 SIReadLock 出现。 | `ser-sireadlock-pg-locks.md` |
| SER-SIREADLOCK-RETAIN-AFTER-COMMIT | C04 | P0 | F01-V16,F02-V05,F03-V04,F04-V01 | SIReadLock 可能在事务提交后保留，直到重叠读写事务完成。 | `ser-sireadlock-retain-after-commit.md` |
| SER-SQLSTATE-40001 | C03 | P0 | F01-V17,F02-V01,F03-V01,F04-V05 | Serialization failure SQLSTATE 为 40001。 | `ser-sqlstate-40001.md` |
| SER-SUCCESS-EQUIVALENT-SERIAL-ORDER | C05 | P0 | F01-V18,F02-V07,F03-V01,F04-V01 | 成功提交的 Serializable 并发事务结果等价于某个串行顺序。 | `ser-success-equivalent-serial-order.md` |
| SER-UNIQUE-CHECK-PROTOCOL-AVOIDS-VIOLATION | C05 | P1 | F01-V19,F02-V08,F03-V01,F04-V01 | 所有可能插入冲突 key 的 serializable 事务都先执行一致的显式检查时，避免原文描述的异常 unique violation 场景。 | `ser-unique-check-protocol-avoids-violation.md` |
| SER-UNIQUE-VIOLATION-CONCURRENT-INSERT | C05 | P0 | F01-V20,F02-V01,F03-V01,F04-V01 | 并发 Serializable 下仍可能出现 unique constraint violation。 | `ser-unique-violation-concurrent-insert.md` |
| SER-WRITE-SKEW-ABORT-ONE | C04 | P0 | F01-V21,F02-V09,F03-V05,F04-V01 | Write skew 模式下回滚其中一个事务。 | `ser-write-skew-abort-one.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：21。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。
