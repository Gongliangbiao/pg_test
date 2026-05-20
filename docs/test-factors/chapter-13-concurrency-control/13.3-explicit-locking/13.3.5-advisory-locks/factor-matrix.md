# 13.3.5 Advisory Locks 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.3.5 Advisory Locks

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.3.5 Advisory Locks 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 10 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | LOCK / advisory lock、LOCK / advisory lock / diagnostic view、advisory lock | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、诊断观测、错误/禁止场景 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-ADVISORY-LIMIT-ORDER-BY-RISK: Advisory lock 函数与 ORDER BY / LIMIT 组合存在求值顺序风险。 | normal | P1 | Advisory lock 函数与 ORDER BY / LIMIT 组合存在求值顺序风险。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-ADVISORY-NOT-ROW-BOUND: Advisory lock 不绑定具体数据行。 | normal | P1 | Advisory lock 不绑定具体数据行。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-ADVISORY-PG-LOCKS-VISIBLE: Advisory lock 在 pg_locks 中可见。 | normal | P1 | Advisory lock 在 pg_locks 中可见。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-ADVISORY-REENTRANT-ACQUIRE: 同一会话可重复获取同一 advisory lock，需匹配释放。 | normal | P1 | 同一会话可重复获取同一 advisory lock，需匹配释放。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-ADVISORY-REENTRANT-WHILE-OTHERS-WAITING: 已持有 advisory lock 的会话再次获取同一锁，即使其他会话正在等待，也应立即成功。 | normal | P1 | If a session already holds an advisory lock, additional requests by it always succeed, even if other sessions are waiting. | 单一测试点，不与其他主场景合并。 |
| F01-V06 | LOCK-ADVISORY-SESSION-LEVEL: Session-level advisory lock 跨事务保持，需显式释放。 | normal | P1 | Session-level advisory lock 跨事务保持，需显式释放。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL: session-level advisory unlock 即使所在事务后续失败也立即生效。 | normal | P0 | A session-level advisory unlock is effective even if the calling transaction fails later. | 单一测试点，不与其他主场景合并。 |
| F01-V08 | LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK: session-level 和 transaction-level advisory lock 使用同一 identifier 时会互相阻塞。 | normal | P0 | Session-level and transaction-level advisory lock requests for the same identifier block each other in the expected way. | 单一测试点，不与其他主场景合并。 |
| F01-V09 | LOCK-ADVISORY-SHARED-MEMORY-LIMIT: Advisory lock 受共享内存锁表容量限制。 | normal | P1 | Advisory lock 受共享内存锁表容量限制。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | LOCK-ADVISORY-TRANSACTION-LEVEL: Transaction-level advisory lock 在事务结束时自动释放。 | normal | P1 | Transaction-level advisory lock 在事务结束时自动释放。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | LOCK / advisory lock | normal | P1 | 来自 LOCK-ADVISORY-TRANSACTION-LEVEL 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | LOCK / advisory lock / diagnostic view | normal | P1 | 来自 LOCK-ADVISORY-PG-LOCKS-VISIBLE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | advisory lock | normal | P0 | 来自 LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P1 | 来自 LOCK-ADVISORY-TRANSACTION-LEVEL 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P1 | 来自 LOCK-ADVISORY-TRANSACTION-LEVEL 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 诊断观测 | boundary/exception/diagnostic | P1 | 来自 LOCK-ADVISORY-PG-LOCKS-VISIBLE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | 错误/禁止场景 | boundary/exception/diagnostic | P0 | 来自 LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | risk-based | F01,F02,F03,F04 | 覆盖 risk-based 类型测试点 | LOCK-ADVISORY-LIMIT-ORDER-BY-RISK |
| C02 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | LOCK-ADVISORY-NOT-ROW-BOUND、LOCK-ADVISORY-REENTRANT-ACQUIRE、LOCK-ADVISORY-SESSION-LEVEL、LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL、LOCK-ADVISORY-SHARED-MEMORY-LIMIT、LOCK-ADVISORY-TRANSACTION-LEVEL |
| C03 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | LOCK-ADVISORY-PG-LOCKS-VISIBLE |
| C04 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | LOCK-ADVISORY-REENTRANT-WHILE-OTHERS-WAITING |
| C05 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-ADVISORY-LIMIT-ORDER-BY-RISK | C01 | P1 | F01-V01,F02-V01,F03-V01,F04-V01 | Advisory lock 函数与 ORDER BY / LIMIT 组合存在求值顺序风险。 | `lock-advisory-limit-order-by-risk.md` |
| LOCK-ADVISORY-NOT-ROW-BOUND | C02 | P1 | F01-V02,F02-V01,F03-V01,F04-V01 | Advisory lock 不绑定具体数据行。 | `lock-advisory-not-row-bound.md` |
| LOCK-ADVISORY-PG-LOCKS-VISIBLE | C03 | P1 | F01-V03,F02-V02,F03-V01,F04-V02 | Advisory lock 在 pg_locks 中可见。 | `lock-advisory-pg-locks-visible.md` |
| LOCK-ADVISORY-REENTRANT-ACQUIRE | C02 | P1 | F01-V04,F02-V01,F03-V01,F04-V01 | 同一会话可重复获取同一 advisory lock，需匹配释放。 | `lock-advisory-reentrant-acquire.md` |
| LOCK-ADVISORY-REENTRANT-WHILE-OTHERS-WAITING | C04 | P1 | F01-V05,F02-V01,F03-V02,F04-V01 | 已持有 advisory lock 的会话再次获取同一锁，即使其他会话正在等待，也应立即成功。 | `lock-advisory-reentrant-while-others-waiting.md` |
| LOCK-ADVISORY-SESSION-LEVEL | C02 | P1 | F01-V06,F02-V01,F03-V01,F04-V01 | Session-level advisory lock 跨事务保持，需显式释放。 | `lock-advisory-session-level.md` |
| LOCK-ADVISORY-SESSION-UNLOCK-EFFECTIVE-AFTER-TXN-FAIL | C02 | P0 | F01-V07,F02-V03,F03-V01,F04-V03 | session-level advisory unlock 即使所在事务后续失败也立即生效。 | `lock-advisory-session-unlock-effective-after-txn-fail.md` |
| LOCK-ADVISORY-SESSION-XACT-SAME-ID-BLOCK | C05 | P0 | F01-V08,F02-V01,F03-V02,F04-V01 | session-level 和 transaction-level advisory lock 使用同一 identifier 时会互相阻塞。 | `lock-advisory-session-xact-same-id-block.md` |
| LOCK-ADVISORY-SHARED-MEMORY-LIMIT | C02 | P1 | F01-V09,F02-V01,F03-V01,F04-V01 | Advisory lock 受共享内存锁表容量限制。 | `lock-advisory-shared-memory-limit.md` |
| LOCK-ADVISORY-TRANSACTION-LEVEL | C02 | P1 | F01-V10,F02-V01,F03-V01,F04-V01 | Transaction-level advisory lock 在事务结束时自动释放。 | `lock-advisory-transaction-level.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：10。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。