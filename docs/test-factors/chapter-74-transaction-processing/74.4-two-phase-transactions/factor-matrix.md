# 74.4 Two-Phase Transactions 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节结构
- Chapter 74 Transaction Processing
  - 74.4 Two-Phase Transactions

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 74 Transaction Processing 中 74.4 Two-Phase Transactions 的测试点。测试点来自事务处理测试点计划，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 30 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | PREPARE TRANSACTION、COMMIT、ROLLBACK、COMMIT / ROLLBACK、SELECT / PREPARE TRANSACTION / diagnostic view、PREPARE TRANSACTION / COMMIT / ROLLBACK、LOCK / PREPARE TRANSACTION、LOCK / COMMIT、LOCK / ROLLBACK、PREPARE TRANSACTION / ROLLBACK、two-phase transaction | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态、提交后状态、回滚状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、诊断观测、边界值、错误/禁止场景 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | 2PC-PREPARE-BASIC: 事务内执行 PREPARE TRANSACTION 后进入 prepared state。 | normal | P0 | 事务内执行 PREPARE TRANSACTION 后进入 prepared state。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | 2PC-PREPARE-REQUIRES-TXN-BLOCK: PREPARE TRANSACTION 必须在事务块内执行。 | normal | P0 | PREPARE TRANSACTION 必须在事务块内执行。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | 2PC-PREPARE-ENDS-CURRENT-SESSION-XACT: 从发起会话视角看，PREPARE TRANSACTION 后当前会话不再有关联的活动事务。 | normal | P0 | 从发起会话视角看，PREPARE TRANSACTION 后当前会话不再有关联的活动事务。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | 2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED: prepared 后变更暂不作为已提交结果对其他事务可见。 | normal | P0 | prepared 后变更暂不作为已提交结果对其他事务可见。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | 2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE: COMMIT PREPARED 后 prepared 事务变更对其他事务可见。 | normal | P0 | COMMIT PREPARED 后 prepared 事务变更对其他事务可见。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | 2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS: ROLLBACK PREPARED 后 prepared 事务变更被放弃。 | normal | P0 | ROLLBACK PREPARED 后 prepared 事务变更被放弃。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | 2PC-COMMIT-FROM-DIFFERENT-SESSION: COMMIT PREPARED 可由非原始会话执行。 | normal | P0 | COMMIT PREPARED 可由非原始会话执行。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | 2PC-ROLLBACK-FROM-DIFFERENT-SESSION: ROLLBACK PREPARED 可由非原始会话执行。 | normal | P0 | ROLLBACK PREPARED 可由非原始会话执行。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | 2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK: 进入 prepared state 后，事务本身只允许后续被 commit prepared 或 rollback prepared 终结。 | normal | P0 | 进入 prepared state 后，事务本身只允许后续被 commit prepared 或 rollback prepared 终结。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | 2PC-PREPARED-XACTS-VIEW-LISTING: 当前 prepared transactions 可通过 pg_prepared_xacts 查询。 | normal | P0 | 当前 prepared transactions 可通过 pg_prepared_xacts 查询。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | 2PC-GID-STRING-LITERAL: GID 必须以字符串字面量形式提供。 | normal | P0 | GID 必须以字符串字面量形式提供。 | 单一测试点，不与其他主场景合并。 |
| F01-V12 | 2PC-GID-LENGTH-199-BYTES: GID 长度 199 bytes 可作为小于 200 bytes 的有效边界。 | normal | P0 | GID 长度 199 bytes 可作为小于 200 bytes 的有效边界。 | 单一测试点，不与其他主场景合并。 |
| F01-V13 | 2PC-GID-LENGTH-200-BYTES-ERROR: GID 长度达到 200 bytes 时违反“小于 200 bytes”限制。 | normal | P0 | GID 长度达到 200 bytes 时违反“小于 200 bytes”限制。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | 2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR: 与当前 prepared transaction 已使用 GID 重复时应失败。 | normal | P0 | 与当前 prepared transaction 已使用 GID 重复时应失败。 | 单一测试点，不与其他主场景合并。 |
| F01-V15 | 2PC-GID-REUSE-AFTER-RESOLVE: 原 GID 的 prepared transaction 被 commit/rollback 后，该 GID 不再属于当前 prepared 集合，可验证复用边界。 | normal | P1 | 原 GID 的 prepared transaction 被 commit/rollback 后，该 GID 不再属于当前 prepared 集合，可验证复用边界。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | 2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED: max_prepared_transactions=0 时禁用 prepared transaction。 | normal | P0 | max_prepared_transactions=0 时禁用 prepared transaction。 | 单一测试点，不与其他主场景合并。 |
| F01-V17 | 2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY: prepared transaction 数达到 max_prepared_transactions 上限时，新的 prepare 应失败。 | normal | P1 | prepared transaction 数达到 max_prepared_transactions 上限时，新的 prepare 应失败。 | 单一测试点，不与其他主场景合并。 |
| F01-V18 | 2PC-LOCKS-HELD-WHILE-PREPARED: prepared transaction 持续持有已获取锁。 | normal | P0 | prepared transaction 持续持有已获取锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V19 | 2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED: COMMIT PREPARED 后锁释放。 | normal | P0 | COMMIT PREPARED 后锁释放。 | 单一测试点，不与其他主场景合并。 |
| F01-V20 | 2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED: ROLLBACK PREPARED 后锁释放。 | normal | P0 | ROLLBACK PREPARED 后锁释放。 | 单一测试点，不与其他主场景合并。 |
| F01-V21 | 2PC-SHORT-LIVED-IN-SHMEM-WAL: 短时间 prepared transaction 存储在 shared memory 和 WAL 中。 | normal | P2 | 短时间 prepared transaction 存储在 shared memory 和 WAL 中。 | 单一测试点，不与其他主场景合并。 |
| F01-V22 | 2PC-SPAN-CHECKPOINT-PG-TWOPHASE: prepared transaction 跨 checkpoint 后在 pg_twophase 目录记录状态文件。 | normal | P1 | prepared transaction 跨 checkpoint 后在 pg_twophase 目录记录状态文件。 | 单一测试点，不与其他主场景合并。 |
| F01-V23 | 2PC-PERSIST-ACROSS-CRASH-RECOVERY: prepared transaction 在数据库崩溃恢复后仍可通过 commit/rollback prepared 处理。 | normal | P1 | prepared transaction 在数据库崩溃恢复后仍可通过 commit/rollback prepared 处理。 | 单一测试点，不与其他主场景合并。 |
| F01-V24 | 2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT: PREPARE TRANSACTION 因任何原因失败时，当前事务被取消，效果等同 rollback。 | normal | P0 | PREPARE TRANSACTION 因任何原因失败时，当前事务被取消，效果等同 rollback。 | 单一测试点，不与其他主场景合并。 |
| F01-V25 | 2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED: 涉及临时表或 session 临时 namespace 的事务不允许 prepare。 | normal | P0 | 涉及临时表或 session 临时 namespace 的事务不允许 prepare。 | 单一测试点，不与其他主场景合并。 |
| F01-V26 | 2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED: 创建 WITH HOLD cursor 的事务不允许 prepare。 | normal | P0 | 创建 WITH HOLD cursor 的事务不允许 prepare。 | 单一测试点，不与其他主场景合并。 |
| F01-V27 | 2PC-PREPARE-LISTEN-NOT-ALLOWED: 执行过 LISTEN 的事务不允许 prepare。 | normal | P0 | 执行过 LISTEN 的事务不允许 prepare。 | 单一测试点，不与其他主场景合并。 |
| F01-V28 | 2PC-PREPARE-UNLISTEN-NOT-ALLOWED: 执行过 UNLISTEN 的事务不允许 prepare。 | normal | P0 | 执行过 UNLISTEN 的事务不允许 prepare。 | 单一测试点，不与其他主场景合并。 |
| F01-V29 | 2PC-PREPARE-NOTIFY-NOT-ALLOWED: 执行过 NOTIFY 的事务不允许 prepare。 | normal | P0 | 执行过 NOTIFY 的事务不允许 prepare。 | 单一测试点，不与其他主场景合并。 |
| F01-V30 | 2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE: 事务内 SET 非 LOCAL 修改的运行时参数在 prepare 后保留，不受后续 commit/rollback prepared 影响。 | normal | P1 | 事务内 SET 非 LOCAL 修改的运行时参数在 prepare 后保留，不受后续 commit/rollback prepared 影响。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | PREPARE TRANSACTION | normal | P1 | 来自 2PC-SPAN-CHECKPOINT-PG-TWOPHASE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | COMMIT | normal | P0 | 来自 2PC-COMMIT-FROM-DIFFERENT-SESSION 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | ROLLBACK | normal | P0 | 来自 2PC-ROLLBACK-FROM-DIFFERENT-SESSION 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | COMMIT / ROLLBACK | normal | P1 | 来自 2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | SELECT / PREPARE TRANSACTION / diagnostic view | normal | P0 | 来自 2PC-PREPARED-XACTS-VIEW-LISTING 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | PREPARE TRANSACTION / COMMIT / ROLLBACK | normal | P1 | 来自 2PC-PERSIST-ACROSS-CRASH-RECOVERY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | LOCK / PREPARE TRANSACTION | normal | P0 | 来自 2PC-LOCKS-HELD-WHILE-PREPARED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | LOCK / COMMIT | normal | P0 | 来自 2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V09 | LOCK / ROLLBACK | normal | P0 | 来自 2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V10 | PREPARE TRANSACTION / ROLLBACK | normal | P0 | 来自 2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V11 | two-phase transaction | normal | P0 | 来自 2PC-PREPARE-NOTIFY-NOT-ALLOWED 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P1 | 来自 2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 2PC-PREPARE-REQUIRES-TXN-BLOCK 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 提交后状态 | normal/boundary | P0 | 来自 2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 回滚状态 | normal/boundary | P0 | 来自 2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P1 | 来自 2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 诊断观测 | boundary/exception/diagnostic | P0 | 来自 2PC-PREPARED-XACTS-VIEW-LISTING 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | 边界值 | boundary/exception/diagnostic | P1 | 来自 2PC-GID-REUSE-AFTER-RESOLVE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V04 | 错误/禁止场景 | boundary/exception/diagnostic | P0 | 来自 2PC-PREPARE-NOTIFY-NOT-ALLOWED 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | 2PC-PREPARE-BASIC、2PC-PREPARE-REQUIRES-TXN-BLOCK、2PC-PREPARE-ENDS-CURRENT-SESSION-XACT、2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED、2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE、2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS、2PC-COMMIT-FROM-DIFFERENT-SESSION、2PC-ROLLBACK-FROM-DIFFERENT-SESSION、2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK、2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED、2PC-LOCKS-HELD-WHILE-PREPARED、2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED、2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED、2PC-SHORT-LIVED-IN-SHMEM-WAL、2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT、2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED、2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED、2PC-PREPARE-LISTEN-NOT-ALLOWED、2PC-PREPARE-UNLISTEN-NOT-ALLOWED、2PC-PREPARE-NOTIFY-NOT-ALLOWED、2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE |
| C02 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | 2PC-PREPARED-XACTS-VIEW-LISTING |
| C03 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | 2PC-GID-STRING-LITERAL |
| C04 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | 2PC-GID-LENGTH-199-BYTES、2PC-GID-LENGTH-200-BYTES-ERROR、2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR、2PC-GID-REUSE-AFTER-RESOLVE、2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY |
| C05 | risk-based | F01,F02,F03,F04 | 覆盖 risk-based 类型测试点 | 2PC-SPAN-CHECKPOINT-PG-TWOPHASE、2PC-PERSIST-ACROSS-CRASH-RECOVERY |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| 2PC-PREPARE-BASIC | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 事务内执行 PREPARE TRANSACTION 后进入 prepared state。 | `2pc-prepare-basic.md` |
| 2PC-PREPARE-REQUIRES-TXN-BLOCK | C01 | P0 | F01-V02,F02-V01,F03-V02,F04-V01 | PREPARE TRANSACTION 必须在事务块内执行。 | `2pc-prepare-requires-txn-block.md` |
| 2PC-PREPARE-ENDS-CURRENT-SESSION-XACT | C01 | P0 | F01-V03,F02-V01,F03-V01,F04-V01 | 从发起会话视角看，PREPARE TRANSACTION 后当前会话不再有关联的活动事务。 | `2pc-prepare-ends-current-session-xact.md` |
| 2PC-PREPARE-EFFECTS-NOT-VISIBLE-BEFORE-COMMIT-PREPARED | C01 | P0 | F01-V04,F02-V02,F03-V03,F04-V01 | prepared 后变更暂不作为已提交结果对其他事务可见。 | `2pc-prepare-effects-not-visible-before-commit-prepared.md` |
| 2PC-COMMIT-PREPARED-MAKES-EFFECTS-VISIBLE | C01 | P0 | F01-V05,F02-V02,F03-V03,F04-V01 | COMMIT PREPARED 后 prepared 事务变更对其他事务可见。 | `2pc-commit-prepared-makes-effects-visible.md` |
| 2PC-ROLLBACK-PREPARED-DISCARDS-EFFECTS | C01 | P0 | F01-V06,F02-V03,F03-V04,F04-V01 | ROLLBACK PREPARED 后 prepared 事务变更被放弃。 | `2pc-rollback-prepared-discards-effects.md` |
| 2PC-COMMIT-FROM-DIFFERENT-SESSION | C01 | P0 | F01-V07,F02-V02,F03-V03,F04-V01 | COMMIT PREPARED 可由非原始会话执行。 | `2pc-commit-from-different-session.md` |
| 2PC-ROLLBACK-FROM-DIFFERENT-SESSION | C01 | P0 | F01-V08,F02-V03,F03-V04,F04-V01 | ROLLBACK PREPARED 可由非原始会话执行。 | `2pc-rollback-from-different-session.md` |
| 2PC-AFTER-PREPARE-ONLY-COMMIT-OR-ROLLBACK | C01 | P0 | F01-V09,F02-V04,F03-V03,F04-V01 | 进入 prepared state 后，事务本身只允许后续被 commit prepared 或 rollback prepared 终结。 | `2pc-after-prepare-only-commit-or-rollback.md` |
| 2PC-PREPARED-XACTS-VIEW-LISTING | C02 | P0 | F01-V10,F02-V05,F03-V01,F04-V02 | 当前 prepared transactions 可通过 pg_prepared_xacts 查询。 | `2pc-prepared-xacts-view-listing.md` |
| 2PC-GID-STRING-LITERAL | C03 | P0 | F01-V11,F02-V01,F03-V01,F04-V01 | GID 必须以字符串字面量形式提供。 | `2pc-gid-string-literal.md` |
| 2PC-GID-LENGTH-199-BYTES | C04 | P0 | F01-V12,F02-V01,F03-V01,F04-V03 | GID 长度 199 bytes 可作为小于 200 bytes 的有效边界。 | `2pc-gid-length-199-bytes.md` |
| 2PC-GID-LENGTH-200-BYTES-ERROR | C04 | P0 | F01-V13,F02-V01,F03-V01,F04-V04 | GID 长度达到 200 bytes 时违反“小于 200 bytes”限制。 | `2pc-gid-length-200-bytes-error.md` |
| 2PC-GID-DUPLICATE-CURRENT-PREPARED-ERROR | C04 | P0 | F01-V14,F02-V01,F03-V01,F04-V04 | 与当前 prepared transaction 已使用 GID 重复时应失败。 | `2pc-gid-duplicate-current-prepared-error.md` |
| 2PC-GID-REUSE-AFTER-RESOLVE | C04 | P1 | F01-V15,F02-V06,F03-V01,F04-V03 | 原 GID 的 prepared transaction 被 commit/rollback 后，该 GID 不再属于当前 prepared 集合，可验证复用边界。 | `2pc-gid-reuse-after-resolve.md` |
| 2PC-MAX-PREPARED-TRANSACTIONS-ZERO-DISABLED | C01 | P0 | F01-V16,F02-V01,F03-V01,F04-V01 | max_prepared_transactions=0 时禁用 prepared transaction。 | `2pc-max-prepared-transactions-zero-disabled.md` |
| 2PC-MAX-PREPARED-TRANSACTIONS-CAPACITY | C04 | P1 | F01-V17,F02-V01,F03-V01,F04-V04 | prepared transaction 数达到 max_prepared_transactions 上限时，新的 prepare 应失败。 | `2pc-max-prepared-transactions-capacity.md` |
| 2PC-LOCKS-HELD-WHILE-PREPARED | C01 | P0 | F01-V18,F02-V07,F03-V01,F04-V01 | prepared transaction 持续持有已获取锁。 | `2pc-locks-held-while-prepared.md` |
| 2PC-LOCKS-RELEASED-AFTER-COMMIT-PREPARED | C01 | P0 | F01-V19,F02-V08,F03-V03,F04-V01 | COMMIT PREPARED 后锁释放。 | `2pc-locks-released-after-commit-prepared.md` |
| 2PC-LOCKS-RELEASED-AFTER-ROLLBACK-PREPARED | C01 | P0 | F01-V20,F02-V09,F03-V04,F04-V01 | ROLLBACK PREPARED 后锁释放。 | `2pc-locks-released-after-rollback-prepared.md` |
| 2PC-SHORT-LIVED-IN-SHMEM-WAL | C01 | P2 | F01-V21,F02-V01,F03-V01,F04-V01 | 短时间 prepared transaction 存储在 shared memory 和 WAL 中。 | `2pc-short-lived-in-shmem-wal.md` |
| 2PC-SPAN-CHECKPOINT-PG-TWOPHASE | C05 | P1 | F01-V22,F02-V01,F03-V01,F04-V01 | prepared transaction 跨 checkpoint 后在 pg_twophase 目录记录状态文件。 | `2pc-span-checkpoint-pg-twophase.md` |
| 2PC-PERSIST-ACROSS-CRASH-RECOVERY | C05 | P1 | F01-V23,F02-V06,F03-V01,F04-V01 | prepared transaction 在数据库崩溃恢复后仍可通过 commit/rollback prepared 处理。 | `2pc-persist-across-crash-recovery.md` |
| 2PC-PREPARE-FAILURE-ROLLS-BACK-CURRENT-XACT | C01 | P0 | F01-V24,F02-V10,F03-V01,F04-V04 | PREPARE TRANSACTION 因任何原因失败时，当前事务被取消，效果等同 rollback。 | `2pc-prepare-failure-rolls-back-current-xact.md` |
| 2PC-PREPARE-TEMP-TABLE-OPERATION-NOT-ALLOWED | C01 | P0 | F01-V25,F02-V11,F03-V01,F04-V04 | 涉及临时表或 session 临时 namespace 的事务不允许 prepare。 | `2pc-prepare-temp-table-operation-not-allowed.md` |
| 2PC-PREPARE-CURSOR-WITH-HOLD-NOT-ALLOWED | C01 | P0 | F01-V26,F02-V11,F03-V01,F04-V04 | 创建 WITH HOLD cursor 的事务不允许 prepare。 | `2pc-prepare-cursor-with-hold-not-allowed.md` |
| 2PC-PREPARE-LISTEN-NOT-ALLOWED | C01 | P0 | F01-V27,F02-V11,F03-V01,F04-V04 | 执行过 LISTEN 的事务不允许 prepare。 | `2pc-prepare-listen-not-allowed.md` |
| 2PC-PREPARE-UNLISTEN-NOT-ALLOWED | C01 | P0 | F01-V28,F02-V11,F03-V01,F04-V04 | 执行过 UNLISTEN 的事务不允许 prepare。 | `2pc-prepare-unlisten-not-allowed.md` |
| 2PC-PREPARE-NOTIFY-NOT-ALLOWED | C01 | P0 | F01-V29,F02-V11,F03-V01,F04-V04 | 执行过 NOTIFY 的事务不允许 prepare。 | `2pc-prepare-notify-not-allowed.md` |
| 2PC-SET-NONLOCAL-PERSISTS-AFTER-PREPARE | C01 | P1 | F01-V30,F02-V04,F03-V01,F04-V01 | 事务内 SET 非 LOCAL 修改的运行时参数在 prepare 后保留，不受后续 commit/rollback prepared 影响。 | `2pc-set-nonlocal-persists-after-prepare.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：30。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。