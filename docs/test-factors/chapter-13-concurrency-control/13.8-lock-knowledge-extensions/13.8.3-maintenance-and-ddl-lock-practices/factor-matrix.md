# 13.8.3 Maintenance And Ddl Lock Practices 测试因子矩阵

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 扩展目录结构
- Chapter 13 Concurrency Control 本地知识补充
  - 13.8.3 Maintenance And Ddl Lock Practices

## 范围摘要
本矩阵覆盖项目本地知识补充目录 13.8.3 Maintenance And Ddl Lock Practices 的扩展测试点。测试点来源于本地知识补充与用户扩展测试点，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 来源依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 6 个单一测试点 | P0/P1/P2 | 来自本地知识补充目录及已有扩展测试点。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | UPDATE / LOCK / INDEX、INDEX、LOCK、SELECT / LOCK / VACUUM、VACUUM | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、等待/阻塞状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、诊断观测 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 本地知识补充中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | LOCK-CREATE-INDEX-CONCURRENTLY-ALLOWS-WRITES: 相对普通 CREATE INDEX，CREATE INDEX CONCURRENTLY 应允许更多并发写入，只持有更温和的锁。 | normal | P0 | 相对普通 CREATE INDEX，CREATE INDEX CONCURRENTLY 应允许更多并发写入，只持有更温和的锁。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | LOCK-CREATE-INDEX-CONCURRENTLY-NOT-IN-TXN-BLOCK: CREATE INDEX CONCURRENTLY 不能在普通事务块中执行。 | normal | P0 | CREATE INDEX CONCURRENTLY 不能在普通事务块中执行。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | LOCK-DDL-PREFLIGHT-CHECK-LONG-TXN: 执行强 DDL 前应检查长事务、idle in transaction 和目标表锁，避免 ACCESS EXCLUSIVE 阻塞事故。 | normal | P0 | 执行强 DDL 前应检查长事务、idle in transaction 和目标表锁，避免 ACCESS EXCLUSIVE 阻塞事故。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS: REFRESH MATERIALIZED VIEW CONCURRENTLY 允许更多并发访问，但需要满足唯一索引等前置条件。 | normal | P0 | REFRESH MATERIALIZED VIEW CONCURRENTLY 允许更多并发访问，但需要满足唯一索引等前置条件。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | LOCK-VACUUM-ANALYZE-DO-NOT-BLOCK-NORMAL-READ-WRITE: 普通 VACUUM 和 ANALYZE 使用相对温和的锁，通常不阻塞普通读写。 | normal | P0 | 普通 VACUUM 和 ANALYZE 使用相对温和的锁，通常不阻塞普通读写。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL: VACUUM FULL 重写表并获取 ACCESS EXCLUSIVE，会阻塞所有访问。 | normal | P0 | VACUUM FULL 重写表并获取 ACCESS EXCLUSIVE，会阻塞所有访问。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | UPDATE / LOCK / INDEX | normal | P0 | 来自 LOCK-CREATE-INDEX-CONCURRENTLY-ALLOWS-WRITES 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | INDEX | normal | P0 | 来自 LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | LOCK | normal | P0 | 来自 LOCK-DDL-PREFLIGHT-CHECK-LONG-TXN 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | SELECT / LOCK / VACUUM | normal | P0 | 来自 LOCK-VACUUM-ANALYZE-DO-NOT-BLOCK-NORMAL-READ-WRITE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | VACUUM | normal | P0 | 来自 LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 诊断观测 | boundary/exception/diagnostic | P0 | 来自 LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 本地知识补充或扩展说明中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | LOCK-CREATE-INDEX-CONCURRENTLY-ALLOWS-WRITES、LOCK-CREATE-INDEX-CONCURRENTLY-NOT-IN-TXN-BLOCK、LOCK-DDL-PREFLIGHT-CHECK-LONG-TXN、LOCK-VACUUM-ANALYZE-DO-NOT-BLOCK-NORMAL-READ-WRITE、LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL |
| C02 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| LOCK-CREATE-INDEX-CONCURRENTLY-ALLOWS-WRITES | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 相对普通 CREATE INDEX，CREATE INDEX CONCURRENTLY 应允许更多并发写入，只持有更温和的锁。 | `lock-create-index-concurrently-allows-writes.md` |
| LOCK-CREATE-INDEX-CONCURRENTLY-NOT-IN-TXN-BLOCK | C01 | P0 | F01-V02,F02-V02,F03-V02,F04-V01 | CREATE INDEX CONCURRENTLY 不能在普通事务块中执行。 | `lock-create-index-concurrently-not-in-txn-block.md` |
| LOCK-DDL-PREFLIGHT-CHECK-LONG-TXN | C01 | P0 | F01-V03,F02-V03,F03-V02,F04-V01 | 执行强 DDL 前应检查长事务、idle in transaction 和目标表锁，避免 ACCESS EXCLUSIVE 阻塞事故。 | `lock-ddl-preflight-check-long-txn.md` |
| LOCK-REFRESH-MVIEW-CONCURRENTLY-PRECONDITIONS | C02 | P0 | F01-V04,F02-V02,F03-V01,F04-V02 | REFRESH MATERIALIZED VIEW CONCURRENTLY 允许更多并发访问，但需要满足唯一索引等前置条件。 | `lock-refresh-materialized-view-concurrently-preconditions.md` |
| LOCK-VACUUM-ANALYZE-DO-NOT-BLOCK-NORMAL-READ-WRITE | C01 | P0 | F01-V05,F02-V04,F03-V02,F04-V01 | 普通 VACUUM 和 ANALYZE 使用相对温和的锁，通常不阻塞普通读写。 | `lock-vacuum-analyze-do-not-block-normal-read-write.md` |
| LOCK-VACUUM-FULL-ACCESS-EXCLUSIVE-BLOCKS-ALL | C01 | P0 | F01-V06,F02-V05,F03-V02,F04-V01 | VACUUM FULL 重写表并获取 ACCESS EXCLUSIVE，会阻塞所有访问。 | `lock-vacuum-full-access-exclusive-blocks-all.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：本地知识补充中的概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：6。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。