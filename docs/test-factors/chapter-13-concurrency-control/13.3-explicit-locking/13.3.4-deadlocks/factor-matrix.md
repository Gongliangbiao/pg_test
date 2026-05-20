# 13.3.4 Deadlocks 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的章节内容或其历史测试点迁移。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.3.4 Deadlocks

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.3.4 Deadlocks 的测试点。测试点来源于已有官方章节化文本用例，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 5 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | LOCK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、SQLSTATE 40P01 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-DEADLOCK-PREVENT-FIXED-ORDER: 按固定顺序获取多个对象锁可避免死锁。 | normal | P0 | 按固定顺序获取多个对象锁可避免死锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-DEADLOCK-ROW-40P01: 行锁死锁检测，SQLSTATE 为 40P01。 | normal | P0 | 行锁死锁检测，SQLSTATE 为 40P01。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-DEADLOCK-STRICTEST-FIRST: 首个锁使用所需最严格模式可避免升级锁死锁。 | normal | P0 | 首个锁使用所需最严格模式可避免升级锁死锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-DEADLOCK-TABLE-40P01: 表锁死锁检测，SQLSTATE 为 40P01。 | normal | P0 | 表锁死锁检测，SQLSTATE 为 40P01。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-DEADLOCK-VICTIM-UNPREDICTABLE: 死锁中被中止的事务不可依赖固定选择。 | normal | P0 | 死锁中被中止的事务不可依赖固定选择。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | LOCK | normal | P0 | 来自 LOCK-DEADLOCK-VICTIM-UNPREDICTABLE 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 LOCK-DEADLOCK-VICTIM-UNPREDICTABLE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 LOCK-DEADLOCK-VICTIM-UNPREDICTABLE 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | SQLSTATE 40P01 | boundary/exception/diagnostic | P0 | 来自 LOCK-DEADLOCK-TABLE-40P01 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | LOCK-DEADLOCK-PREVENT-FIXED-ORDER、LOCK-DEADLOCK-STRICTEST-FIRST、LOCK-DEADLOCK-VICTIM-UNPREDICTABLE |
| C02 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | LOCK-DEADLOCK-ROW-40P01、LOCK-DEADLOCK-TABLE-40P01 |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-DEADLOCK-PREVENT-FIXED-ORDER | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 按固定顺序获取多个对象锁可避免死锁。 | `lock-deadlock-prevent-fixed-order.md` |
| LOCK-DEADLOCK-ROW-40P01 | C02 | P0 | F01-V02,F02-V01,F03-V01,F04-V02 | 行锁死锁检测，SQLSTATE 为 40P01。 | `lock-deadlock-row-40p01.md` |
| LOCK-DEADLOCK-STRICTEST-FIRST | C01 | P0 | F01-V03,F02-V01,F03-V01,F04-V01 | 首个锁使用所需最严格模式可避免升级锁死锁。 | `lock-deadlock-strictest-first.md` |
| LOCK-DEADLOCK-TABLE-40P01 | C02 | P0 | F01-V04,F02-V01,F03-V01,F04-V02 | 表锁死锁检测，SQLSTATE 为 40P01。 | `lock-deadlock-table-40p01.md` |
| LOCK-DEADLOCK-VICTIM-UNPREDICTABLE | C01 | P0 | F01-V05,F02-V01,F03-V01,F04-V01 | 死锁中被中止的事务不可依赖固定选择。 | `lock-deadlock-victim-unpredictable.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：5。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。