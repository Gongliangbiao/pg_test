# 13.4.2 Enforcing Consistency With Explicit Blocking Locks 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.4.2 Enforcing Consistency With Explicit Blocking Locks

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.4.2 Enforcing Consistency With Explicit Blocking Locks 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 6 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | LOCK、SELECT / UPDATE / LOCK、LOCK / COMMIT、SELECT / LOCK / snapshot、UPDATE / DELETE | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 等待/阻塞状态、并发事务提交前、常规事务状态转换 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE: 非 serializable 写存在时，LOCK TABLE 保护全表而不是单行。 | normal | P0 | LOCK TABLE locks the whole table for explicit consistency checks. | 单一测试点，不与其他主场景合并。 |
| F01-V02 | APP-BLOCKING-SELECT-FOR-SHARE: 非 serializable 写存在时，单独验证 SELECT FOR SHARE 保护返回行免受并发更新。 | normal | P0 | When non-serializable writes are possible, SELECT FOR SHARE can be used to ensure current row validity and protect rows against concurrent updates. | 单一测试点，不与其他主场景合并。 |
| F01-V03 | APP-BLOCKING-SELECT-FOR-UPDATE: 非 Serializable 写存在时，使用 SELECT FOR UPDATE 或 SELECT FOR SHARE 阻塞冲突事务。 | normal | P0 | 非 Serializable 写存在时，使用 SELECT FOR UPDATE 或 SELECT FOR SHARE 阻塞冲突事务。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | APP-GLOBAL-CHECK-LOCK-ALL-TABLES: 全局一致性检查可能需要锁定所有相关表，SHARE 或更高锁保证无其他未提交变更。 | normal | P0 | 全局一致性检查可能需要锁定所有相关表，SHARE 或更高锁保证无其他未提交变更。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | APP-RR-LOCK-BEFORE-SNAPSHOT: Repeatable Read 下依赖显式锁时，应在快照冻结前获取锁。 | normal | P0 | Repeatable Read 下依赖显式锁时，应在快照冻结前获取锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW: 如需确保一行不被后续更新或删除，应实际更新该行，即使值不变。 | normal | P0 | 如需确保一行不被后续更新或删除，应实际更新该行，即使值不变。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | LOCK | normal | P0 | 来自 APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | SELECT / UPDATE / LOCK | normal | P0 | 来自 APP-BLOCKING-SELECT-FOR-UPDATE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | LOCK / COMMIT | normal | P0 | 来自 APP-GLOBAL-CHECK-LOCK-ALL-TABLES 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | SELECT / LOCK / snapshot | normal | P0 | 来自 APP-RR-LOCK-BEFORE-SNAPSHOT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | UPDATE / DELETE | normal | P0 | 来自 APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 等待/阻塞状态 | normal/boundary | P0 | 来自 APP-BLOCKING-SELECT-FOR-UPDATE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 并发事务提交前 | normal/boundary | P0 | 来自 APP-GLOBAL-CHECK-LOCK-ALL-TABLES 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 常规事务状态转换 | normal/boundary | P0 | 来自 APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE、APP-RR-LOCK-BEFORE-SNAPSHOT、APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW |
| C02 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | APP-BLOCKING-SELECT-FOR-SHARE、APP-BLOCKING-SELECT-FOR-UPDATE |
| C03 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | APP-GLOBAL-CHECK-LOCK-ALL-TABLES |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| APP-BLOCKING-LOCK-TABLE-WHOLE-TABLE | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 非 serializable 写存在时，LOCK TABLE 保护全表而不是单行。 | `app-blocking-lock-table-whole-table.md` |
| APP-BLOCKING-SELECT-FOR-SHARE | C02 | P0 | F01-V02,F02-V02,F03-V01,F04-V01 | 非 serializable 写存在时，单独验证 SELECT FOR SHARE 保护返回行免受并发更新。 | `app-blocking-select-for-share.md` |
| APP-BLOCKING-SELECT-FOR-UPDATE | C02 | P0 | F01-V03,F02-V02,F03-V01,F04-V01 | 非 Serializable 写存在时，使用 SELECT FOR UPDATE 或 SELECT FOR SHARE 阻塞冲突事务。 | `app-blocking-select-for-update.md` |
| APP-GLOBAL-CHECK-LOCK-ALL-TABLES | C03 | P0 | F01-V04,F02-V03,F03-V02,F04-V01 | 全局一致性检查可能需要锁定所有相关表，SHARE 或更高锁保证无其他未提交变更。 | `app-global-check-lock-all-tables.md` |
| APP-RR-LOCK-BEFORE-SNAPSHOT | C01 | P0 | F01-V05,F02-V04,F03-V03,F04-V01 | Repeatable Read 下依赖显式锁时，应在快照冻结前获取锁。 | `app-rr-lock-before-snapshot.md` |
| APP-UPDATE-SAME-VALUE-TO-PROTECT-ROW | C01 | P0 | F01-V06,F02-V05,F03-V03,F04-V01 | 如需确保一行不被后续更新或删除，应实际更新该行，即使值不变。 | `app-update-same-value-to-protect-row.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：6。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。