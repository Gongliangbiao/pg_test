# 13.8.4 Diagnostics And Wait Events 测试因子矩阵

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 扩展目录结构
- Chapter 13 Concurrency Control 本地知识补充
  - 13.8.4 Diagnostics And Wait Events

## 范围摘要
本矩阵覆盖项目本地知识补充目录 13.8.4 Diagnostics And Wait Events 的扩展测试点。测试点来源于本地知识补充与用户扩展测试点，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 来源依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 6 个单一测试点 | P0/P1/P2 | 来自本地知识补充目录及已有扩展测试点。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | SELECT / diagnostic view、事务/并发控制行为、LOCK / diagnostic view、VACUUM、LOCK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 等待/阻塞状态、常规事务状态转换 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 诊断观测、常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 本地知识补充中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-DIAGNOSE-BLOCKING-CHAIN-QUERY: 使用 pg_stat_activity + pg_blocking_pids 查询阻塞链，定位 blocker query 与 blocked query。 | normal | P0 | 使用 pg_stat_activity + pg_blocking_pids 查询阻塞链，定位 blocker query 与 blocked query。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-DIAGNOSE-BLOCKING-PIDS-BASIC: 构造阻塞后，通过 pg_blocking_pids(pid) 定位 blocker 和 blocked。 | normal | P0 | 构造阻塞后，通过 pg_blocking_pids(pid) 定位 blocker 和 blocked。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-DIAGNOSE-PG-STAT-ACTIVITY-WAIT-EVENT-LOCK: 行锁或表锁等待时，pg_stat_activity.wait_event_type 应能体现 Lock 类等待。 | normal | P0 | 行锁或表锁等待时，pg_stat_activity.wait_event_type 应能体现 Lock 类等待。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS: 使用 pg_locks.relation::regclass 将 relation oid 转成表名，辅助定位被锁对象。 | normal | P0 | 使用 pg_locks.relation::regclass 将 relation oid 转成表名，辅助定位被锁对象。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-WAIT-EVENT-BUFFERPIN-OBSERVE: 某些 vacuum 或 DDL 可能等待其他 backend 释放 buffer pin，需通过 wait event 观察 BufferPin。 | normal | P0 | 某些 vacuum 或 DDL 可能等待其他 backend 释放 buffer pin，需通过 wait event 观察 BufferPin。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK: LWLock 等待属于内部共享结构竞争，不应误判为 SQL 级表锁或行锁。 | normal | P0 | LWLock 等待属于内部共享结构竞争，不应误判为 SQL 级表锁或行锁。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | SELECT / diagnostic view | normal | P0 | 来自 LOCK-DIAGNOSE-BLOCKING-CHAIN-QUERY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | 事务/并发控制行为 | normal | P0 | 来自 LOCK-DIAGNOSE-BLOCKING-PIDS-BASIC 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | LOCK / diagnostic view | normal | P0 | 来自 LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | VACUUM | normal | P0 | 来自 LOCK-WAIT-EVENT-BUFFERPIN-OBSERVE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | LOCK | normal | P0 | 来自 LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 常规事务状态转换 | normal/boundary | P0 | 来自 LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 诊断观测 | boundary/exception/diagnostic | P0 | 来自 LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 本地知识补充或扩展说明中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | LOCK-DIAGNOSE-BLOCKING-CHAIN-QUERY、LOCK-DIAGNOSE-PG-STAT-ACTIVITY-WAIT-EVENT-LOCK、LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS |
| C02 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | LOCK-DIAGNOSE-BLOCKING-PIDS-BASIC |
| C03 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | LOCK-WAIT-EVENT-BUFFERPIN-OBSERVE、LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-DIAGNOSE-BLOCKING-CHAIN-QUERY | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 使用 pg_stat_activity + pg_blocking_pids 查询阻塞链，定位 blocker query 与 blocked query。 | `lock-diagnose-blocking-chain-query.md` |
| LOCK-DIAGNOSE-BLOCKING-PIDS-BASIC | C02 | P0 | F01-V02,F02-V02,F03-V01,F04-V02 | 构造阻塞后，通过 pg_blocking_pids(pid) 定位 blocker 和 blocked。 | `lock-diagnose-blocking-pids-basic.md` |
| LOCK-DIAGNOSE-PG-STAT-ACTIVITY-WAIT-EVENT-LOCK | C01 | P0 | F01-V03,F02-V03,F03-V01,F04-V01 | 行锁或表锁等待时，pg_stat_activity.wait_event_type 应能体现 Lock 类等待。 | `lock-diagnose-pg-stat-activity-wait-event-lock.md` |
| LOCK-DIAGNOSE-RELATION-OID-TO-REGCLASS | C01 | P0 | F01-V04,F02-V03,F03-V02,F04-V01 | 使用 pg_locks.relation::regclass 将 relation oid 转成表名，辅助定位被锁对象。 | `lock-diagnose-relation-oid-to-regclass.md` |
| LOCK-WAIT-EVENT-BUFFERPIN-OBSERVE | C03 | P0 | F01-V05,F02-V04,F03-V01,F04-V02 | 某些 vacuum 或 DDL 可能等待其他 backend 释放 buffer pin，需通过 wait event 观察 BufferPin。 | `lock-wait-event-bufferpin-observe.md` |
| LOCK-WAIT-EVENT-LWLOCK-NOT-BUSINESS-LOCK | C03 | P0 | F01-V06,F02-V05,F03-V01,F04-V02 | LWLock 等待属于内部共享结构竞争，不应误判为 SQL 级表锁或行锁。 | `lock-wait-event-lwlock-not-business-lock.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：本地知识补充中的概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：6。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。