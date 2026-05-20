# 13.3 Explicit Locking 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.3 Explicit Locking

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.3 Explicit Locking 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 5 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | LOCK、LOCK / diagnostic view、LOCK / SAVEPOINT / ROLLBACK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态、回滚状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、诊断观测、边界值 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-EXPLICIT-LOCK-COMMAND-BASIC: 显式 LOCK 命令可获取表级锁。 | normal | P0 | 显式 LOCK 命令可获取表级锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-HELD-UNTIL-TXN-END: 事务中获取的锁通常保持到事务结束。 | normal | P0 | 事务中获取的锁通常保持到事务结束。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-PG-LOCKS-OBSERVE: pg_locks 可观测当前锁、锁模式与等待状态。 | normal | P2 | pg_locks 可观测当前锁、锁模式与等待状态。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-SAVEPOINT-ROLLBACK-RELEASE: Savepoint rollback 释放 savepoint 后获取的锁。 | normal | P0 | Savepoint rollback 释放 savepoint 后获取的锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-TIMEOUT-WAIT-BOUNDARY: 未检测到死锁时锁等待可持续，lock_timeout 可限制等待时间。 | normal | P0 | 未检测到死锁时锁等待可持续，lock_timeout 可限制等待时间。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | LOCK | normal | P0 | 来自 LOCK-TIMEOUT-WAIT-BOUNDARY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | LOCK / diagnostic view | normal | P2 | 来自 LOCK-PG-LOCKS-OBSERVE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | LOCK / SAVEPOINT / ROLLBACK | normal | P0 | 来自 LOCK-SAVEPOINT-ROLLBACK-RELEASE 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 LOCK-HELD-UNTIL-TXN-END 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-TIMEOUT-WAIT-BOUNDARY 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 回滚状态 | normal/boundary | P0 | 来自 LOCK-SAVEPOINT-ROLLBACK-RELEASE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 LOCK-SAVEPOINT-ROLLBACK-RELEASE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 诊断观测 | boundary/exception/diagnostic | P2 | 来自 LOCK-PG-LOCKS-OBSERVE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | 边界值 | boundary/exception/diagnostic | P0 | 来自 LOCK-TIMEOUT-WAIT-BOUNDARY 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | LOCK-EXPLICIT-LOCK-COMMAND-BASIC、LOCK-HELD-UNTIL-TXN-END |
| C02 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | LOCK-PG-LOCKS-OBSERVE |
| C03 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | LOCK-SAVEPOINT-ROLLBACK-RELEASE |
| C04 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | LOCK-TIMEOUT-WAIT-BOUNDARY |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-EXPLICIT-LOCK-COMMAND-BASIC | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 显式 LOCK 命令可获取表级锁。 | `lock-explicit-lock-command-basic.md` |
| LOCK-HELD-UNTIL-TXN-END | C01 | P0 | F01-V02,F02-V01,F03-V01,F04-V01 | 事务中获取的锁通常保持到事务结束。 | `lock-held-until-txn-end.md` |
| LOCK-PG-LOCKS-OBSERVE | C02 | P2 | F01-V03,F02-V02,F03-V02,F04-V02 | pg_locks 可观测当前锁、锁模式与等待状态。 | `lock-pg-locks-observe.md` |
| LOCK-SAVEPOINT-ROLLBACK-RELEASE | C03 | P0 | F01-V04,F02-V03,F03-V03,F04-V01 | Savepoint rollback 释放 savepoint 后获取的锁。 | `lock-savepoint-rollback-release.md` |
| LOCK-TIMEOUT-WAIT-BOUNDARY | C04 | P0 | F01-V05,F02-V01,F03-V02,F04-V03 | 未检测到死锁时锁等待可持续，lock_timeout 可限制等待时间。 | `lock-timeout-wait-boundary.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：5。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。