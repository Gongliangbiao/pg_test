# 13.8.2 Constraints And Key Locks 测试因子矩阵

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 扩展目录结构
- Chapter 13 Concurrency Control 本地知识补充
  - 13.8.2 Constraints And Key Locks

## 范围摘要
本矩阵覆盖项目本地知识补充目录 13.8.2 Constraints And Key Locks 的扩展测试点。测试点来源于本地知识补充与用户扩展测试点，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 来源依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 5 个单一测试点 | P0/P1/P2 | 来自本地知识补充目录及已有扩展测试点。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | INSERT、DELETE / INSERT / LOCK、DELETE、INSERT / COMMIT、INSERT / ROLLBACK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态、并发事务提交前 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | SQLSTATE 23P01、常规核心路径、SQLSTATE 23505 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 本地知识补充中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01: 并发插入违反排除约束时返回 23P01 exclusion_violation，并按业务判断是否可重试。 | normal | P0 | 并发插入违反排除约束时返回 23P01 exclusion_violation，并按业务判断是否可重试。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE: 子表插入外键引用时，需要确认父表 key 存在，并与父表 key 的删除/修改形成锁协调。 | normal | P0 | 子表插入外键引用时，需要确认父表 key 存在，并与父表 key 的删除/修改形成锁协调。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK: 删除或修改父表被引用 key 时，应与并发子表外键检查产生等待或冲突。 | normal | P0 | 删除或修改父表被引用 key 时，应与并发子表外键检查产生等待或冲突。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505: 两个事务插入相同唯一键时，后发事务等待先发事务；先发提交后，后发返回 23505 unique_violation。 | normal | P0 | 两个事务插入相同唯一键时，后发事务等待先发事务；先发提交后，后发返回 23505 unique_violation。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS: 两个事务插入相同唯一键时，后发事务等待先发事务；先发回滚后，后发继续成功。 | normal | P0 | 两个事务插入相同唯一键时，后发事务等待先发事务；先发回滚后，后发继续成功。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | INSERT | normal | P0 | 来自 LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | DELETE / INSERT / LOCK | normal | P0 | 来自 LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | DELETE | normal | P0 | 来自 LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | INSERT / COMMIT | normal | P0 | 来自 LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | INSERT / ROLLBACK | normal | P0 | 来自 LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 并发事务提交前 | normal/boundary | P0 | 来自 LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | SQLSTATE 23P01 | boundary/exception/diagnostic | P0 | 来自 LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | SQLSTATE 23505 | boundary/exception/diagnostic | P0 | 来自 LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 本地知识补充或扩展说明中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01、LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505 |
| C02 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE |
| C03 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK |
| C04 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-EXCLUSION-CONSTRAINT-CONCURRENT-23P01 | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 并发插入违反排除约束时返回 23P01 exclusion_violation，并按业务判断是否可重试。 | `lock-exclusion-constraint-concurrent-23p01.md` |
| LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE | C02 | P0 | F01-V02,F02-V02,F03-V01,F04-V02 | 子表插入外键引用时，需要确认父表 key 存在，并与父表 key 的删除/修改形成锁协调。 | `lock-fk-child-insert-parent-key-share.md` |
| LOCK-FK-PARENT-DELETE-WAITS-CHILD-CHECK | C03 | P0 | F01-V03,F02-V03,F03-V02,F04-V02 | 删除或修改父表被引用 key 时，应与并发子表外键检查产生等待或冲突。 | `lock-fk-parent-delete-waits-child-check.md` |
| LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-COMMIT-23505 | C01 | P0 | F01-V04,F02-V04,F03-V03,F04-V03 | 两个事务插入相同唯一键时，后发事务等待先发事务；先发提交后，后发返回 23505 unique_violation。 | `lock-unique-insert-waits-uncommitted-commit-23505.md` |
| LOCK-UNIQUE-INSERT-WAITS-UNCOMMITTED-ROLLBACK-SUCCESS | C04 | P0 | F01-V05,F02-V05,F03-V03,F04-V02 | 两个事务插入相同唯一键时，后发事务等待先发事务；先发回滚后，后发继续成功。 | `lock-unique-insert-waits-uncommitted-rollback-success.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：本地知识补充中的概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：5。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。