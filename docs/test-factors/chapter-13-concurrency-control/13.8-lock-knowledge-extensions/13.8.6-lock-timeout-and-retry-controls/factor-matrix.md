# 13.8.6 Lock Timeout And Retry Controls 测试因子矩阵

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 扩展目录结构
- Chapter 13 Concurrency Control 本地知识补充
  - 13.8.6 Lock Timeout And Retry Controls

## 范围摘要
本矩阵覆盖项目本地知识补充目录 13.8.6 Lock Timeout And Retry Controls 的扩展测试点。测试点来源于本地知识补充与用户扩展测试点，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 来源依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 3 个单一测试点 | P0/P1/P2 | 来自本地知识补充目录及已有扩展测试点。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | LOCK、事务/并发控制行为 | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 边界值、SQLSTATE 40001/40P01 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 本地知识补充中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-DEADLOCK-TIMEOUT-DETECTION-WINDOW: deadlock_timeout 影响死锁检测启动时机，不等同于普通 lock wait timeout。 | normal | P0 | deadlock_timeout 影响死锁检测启动时机，不等同于普通 lock wait timeout。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY: 区分 lock_timeout 只控制锁等待时长，statement_timeout 控制语句总执行时长。 | normal | P0 | 区分 lock_timeout 只控制锁等待时长，statement_timeout 控制语句总执行时长。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | RETRY-40001-40P01-WITH-BACKOFF: 高争用场景重试 40001/40P01 时应加入有限次数和退避策略。 | normal | P0 | 高争用场景重试 40001/40P01 时应加入有限次数和退避策略。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | LOCK | normal | P0 | 来自 LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | 事务/并发控制行为 | normal | P0 | 来自 RETRY-40001-40P01-WITH-BACKOFF 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 RETRY-40001-40P01-WITH-BACKOFF 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 边界值 | boundary/exception/diagnostic | P0 | 来自 LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | SQLSTATE 40001/40P01 | boundary/exception/diagnostic | P0 | 来自 RETRY-40001-40P01-WITH-BACKOFF 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 本地知识补充或扩展说明中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | LOCK-DEADLOCK-TIMEOUT-DETECTION-WINDOW、LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY、RETRY-40001-40P01-WITH-BACKOFF |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-DEADLOCK-TIMEOUT-DETECTION-WINDOW | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | deadlock_timeout 影响死锁检测启动时机，不等同于普通 lock wait timeout。 | `lock-deadlock-timeout-detection-window.md` |
| LOCK-TIMEOUT-VS-STATEMENT-TIMEOUT-BOUNDARY | C01 | P0 | F01-V02,F02-V01,F03-V02,F04-V01 | 区分 lock_timeout 只控制锁等待时长，statement_timeout 控制语句总执行时长。 | `lock-timeout-vs-statement-timeout-boundary.md` |
| RETRY-40001-40P01-WITH-BACKOFF | C01 | P0 | F01-V03,F02-V02,F03-V01,F04-V02 | 高争用场景重试 40001/40P01 时应加入有限次数和退避策略。 | `retry-40001-40p01-with-backoff.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：本地知识补充中的概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：3。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。