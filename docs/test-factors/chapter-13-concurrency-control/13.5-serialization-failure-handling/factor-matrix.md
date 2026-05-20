# 13.5 Serialization Failure Handling 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.5 Serialization Failure Handling

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.5 Serialization Failure Handling 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 9 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | 事务/并发控制行为、SELECT、PREPARE TRANSACTION / COMMIT / ROLLBACK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | SQLSTATE 23505、SQLSTATE 23P01、SQLSTATE 40001、SQLSTATE 40P01、常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | RETRY-23505-SERIALIZABLE-INSERT-RACE: 某些 unique_violation SQLSTATE 23505 可按场景谨慎重试。 | normal | P0 | 某些 unique_violation SQLSTATE 23505 可按场景谨慎重试。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | RETRY-23P01-EXCLUSION-RACE: 某些 exclusion_violation SQLSTATE 23P01 可按场景谨慎重试。 | normal | P0 | 某些 exclusion_violation SQLSTATE 23P01 可按场景谨慎重试。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | RETRY-40001-RR: REPEATABLE READ 下 serialization_failure 需要完整事务重试。 | normal | P0 | REPEATABLE READ 下 serialization_failure 需要完整事务重试。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | RETRY-40001-SER: SERIALIZABLE 下 serialization_failure 需要完整事务重试。 | normal | P0 | SERIALIZABLE 下 serialization_failure 需要完整事务重试。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | RETRY-40P01-DEADLOCK: Deadlock SQLSTATE 40P01 建议纳入重试策略。 | normal | P0 | Deadlock SQLSTATE 40P01 建议纳入重试策略。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | RETRY-HIGH-CONTENTION-MULTIPLE-ATTEMPTS: 高竞争下可能需要多次重试。 | normal | P0 | 高竞争下可能需要多次重试。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | RETRY-NO-AUTO-RETRY-BY-SERVER: PostgreSQL 不提供自动重试能力。 | normal | P0 | PostgreSQL 不提供自动重试能力。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | RETRY-PREPARED-TRANSACTION-BLOCKING: 与 prepared transaction 冲突时，可能直到 prepared transaction commit 或 rollback 后才有进展。 | normal | P0 | 与 prepared transaction 冲突时，可能直到 prepared transaction commit 或 rollback 后才有进展。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | RETRY-WHOLE-TRANSACTION-DECISION-LOGIC: 重试必须包含决定 SQL 和决定值的全部事务逻辑。 | normal | P0 | 重试必须包含决定 SQL 和决定值的全部事务逻辑。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | 事务/并发控制行为 | normal | P0 | 来自 RETRY-WHOLE-TRANSACTION-DECISION-LOGIC 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | SELECT | normal | P0 | 来自 RETRY-40001-RR 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | PREPARE TRANSACTION / COMMIT / ROLLBACK | normal | P0 | 来自 RETRY-PREPARED-TRANSACTION-BLOCKING 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 RETRY-WHOLE-TRANSACTION-DECISION-LOGIC 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 RETRY-PREPARED-TRANSACTION-BLOCKING 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | SQLSTATE 23505 | boundary/exception/diagnostic | P0 | 来自 RETRY-23505-SERIALIZABLE-INSERT-RACE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | SQLSTATE 23P01 | boundary/exception/diagnostic | P0 | 来自 RETRY-23P01-EXCLUSION-RACE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | SQLSTATE 40001 | boundary/exception/diagnostic | P0 | 来自 RETRY-40001-SER 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V04 | SQLSTATE 40P01 | boundary/exception/diagnostic | P0 | 来自 RETRY-40P01-DEADLOCK 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V05 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 RETRY-WHOLE-TRANSACTION-DECISION-LOGIC 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | RETRY-23505-SERIALIZABLE-INSERT-RACE、RETRY-23P01-EXCLUSION-RACE、RETRY-40001-RR、RETRY-40001-SER |
| C02 | risk-based | F01,F02,F03,F04 | 覆盖 risk-based 类型测试点 | RETRY-40P01-DEADLOCK |
| C03 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | RETRY-HIGH-CONTENTION-MULTIPLE-ATTEMPTS、RETRY-NO-AUTO-RETRY-BY-SERVER、RETRY-WHOLE-TRANSACTION-DECISION-LOGIC |
| C04 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | RETRY-PREPARED-TRANSACTION-BLOCKING |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| RETRY-23505-SERIALIZABLE-INSERT-RACE | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 某些 unique_violation SQLSTATE 23505 可按场景谨慎重试。 | `retry-23505-serializable-insert-race.md` |
| RETRY-23P01-EXCLUSION-RACE | C01 | P0 | F01-V02,F02-V01,F03-V01,F04-V02 | 某些 exclusion_violation SQLSTATE 23P01 可按场景谨慎重试。 | `retry-23p01-exclusion-race.md` |
| RETRY-40001-RR | C01 | P0 | F01-V03,F02-V02,F03-V01,F04-V03 | REPEATABLE READ 下 serialization_failure 需要完整事务重试。 | `retry-40001-rr.md` |
| RETRY-40001-SER | C01 | P0 | F01-V04,F02-V01,F03-V01,F04-V03 | SERIALIZABLE 下 serialization_failure 需要完整事务重试。 | `retry-40001-ser.md` |
| RETRY-40P01-DEADLOCK | C02 | P0 | F01-V05,F02-V01,F03-V01,F04-V04 | Deadlock SQLSTATE 40P01 建议纳入重试策略。 | `retry-40p01-deadlock.md` |
| RETRY-HIGH-CONTENTION-MULTIPLE-ATTEMPTS | C03 | P0 | F01-V06,F02-V01,F03-V01,F04-V05 | 高竞争下可能需要多次重试。 | `retry-high-contention-multiple-attempts.md` |
| RETRY-NO-AUTO-RETRY-BY-SERVER | C03 | P0 | F01-V07,F02-V01,F03-V01,F04-V05 | PostgreSQL 不提供自动重试能力。 | `retry-no-auto-retry-by-server.md` |
| RETRY-PREPARED-TRANSACTION-BLOCKING | C04 | P0 | F01-V08,F02-V03,F03-V02,F04-V05 | 与 prepared transaction 冲突时，可能直到 prepared transaction commit 或 rollback 后才有进展。 | `retry-prepared-transaction-blocking.md` |
| RETRY-WHOLE-TRANSACTION-DECISION-LOGIC | C03 | P0 | F01-V09,F02-V01,F03-V01,F04-V05 | 重试必须包含决定 SQL 和决定值的全部事务逻辑。 | `retry-whole-transaction-decision-logic.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：9。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。