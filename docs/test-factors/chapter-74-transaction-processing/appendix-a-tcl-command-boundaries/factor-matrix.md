# 附录 A 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节结构
- Chapter 74 Transaction Processing
  - 附录 A

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 74 Transaction Processing 中 附录 A 的测试点。测试点来自事务处理测试点计划，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 18 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | SAVEPOINT、SELECT、transaction control command、COMMIT、ROLLBACK、SELECT / snapshot、snapshot | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、提交后状态、回滚状态、并发事务提交前、只读事务状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 错误/禁止场景、常规核心路径 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | TCL-BEGIN-INSIDE-TXN-WARNING: 已在事务块内再次执行 BEGIN 只产生 warning，不影响事务状态；嵌套事务应使用 savepoint。 | normal | P0 | 已在事务块内再次执行 BEGIN 只产生 warning，不影响事务状态；嵌套事务应使用 savepoint。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION: BEGIN 指定 isolation/read write/deferrable 模式时，效果等同事务开始时执行 SET TRANSACTION。 | normal | P0 | BEGIN 指定 isolation/read write/deferrable 模式时，效果等同事务开始时执行 SET TRANSACTION。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | TCL-START-TRANSACTION-EQUIVALENT-BEGIN: START TRANSACTION 与 BEGIN 功能等价。 | normal | P0 | START TRANSACTION 与 BEGIN 功能等价。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | TCL-START-TRANSACTION-MODE-COMMA-OMIT: PostgreSQL 为兼容历史允许 transaction modes 之间省略逗号。 | normal | P1 | PostgreSQL 为兼容历史允许 transaction modes 之间省略逗号。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | TCL-COMMIT-OUTSIDE-TXN-WARNING: 不在事务块内执行 COMMIT 无实际影响但产生 warning。 | normal | P0 | 不在事务块内执行 COMMIT 无实际影响但产生 warning。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR: 不在事务块内执行 COMMIT AND CHAIN 是错误。 | normal | P0 | 不在事务块内执行 COMMIT AND CHAIN 是错误。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | TCL-COMMIT-AND-CHAIN-KEEPS-MODES: COMMIT AND CHAIN 立即开启新事务，并继承刚结束事务的 transaction characteristics。 | normal | P0 | COMMIT AND CHAIN 立即开启新事务，并继承刚结束事务的 transaction characteristics。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | TCL-ROLLBACK-OUTSIDE-TXN-WARNING: 不在事务块内执行 ROLLBACK 产生 warning 且无其他效果。 | normal | P0 | 不在事务块内执行 ROLLBACK 产生 warning 且无其他效果。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR: 不在事务块内执行 ROLLBACK AND CHAIN 是错误。 | normal | P0 | 不在事务块内执行 ROLLBACK AND CHAIN 是错误。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES: ROLLBACK AND CHAIN 立即开启新的非 aborted 事务，并继承刚结束事务的 transaction characteristics。 | normal | P0 | ROLLBACK AND CHAIN 立即开启新的非 aborted 事务，并继承刚结束事务的 transaction characteristics。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | TCL-SET-TRANSACTION-NO-BEGIN-WARNING: 未先 BEGIN 或 START TRANSACTION 时执行 SET TRANSACTION 产生 warning 且无效果。 | normal | P0 | 未先 BEGIN 或 START TRANSACTION 时执行 SET TRANSACTION 产生 warning 且无效果。 | 单一测试点，不与其他主场景合并。 |
| F01-V12 | TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR: 事务执行第一个查询或数据修改语句后，不允许再改变 isolation level。 | normal | P0 | 事务执行第一个查询或数据修改语句后，不允许再改变 isolation level。 | 单一测试点，不与其他主场景合并。 |
| F01-V13 | TCL-SET-SESSION-DEFAULT-MODES: SET SESSION CHARACTERISTICS 只影响后续事务默认特征，可被单个事务 SET TRANSACTION 覆盖。 | normal | P1 | SET SESSION CHARACTERISTICS 只影响后续事务默认特征，可被单个事务 SET TRANSACTION 覆盖。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED: PostgreSQL 中 READ UNCOMMITTED 按 READ COMMITTED 处理。 | normal | P0 | PostgreSQL 中 READ UNCOMMITTED 按 READ COMMITTED 处理。 | 单一测试点，不与其他主场景合并。 |
| F01-V15 | TCL-READONLY-DISALLOW-DML-DDL: READ ONLY 事务禁止对非临时表执行写 DML，并禁止 DDL、权限、truncate 等修改类命令。 | normal | P0 | READ ONLY 事务禁止对非临时表执行写 DML，并禁止 DDL、权限、truncate 等修改类命令。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY: DEFERRABLE 只有在 SERIALIZABLE READ ONLY 事务中才有实际效果。 | normal | P0 | DEFERRABLE 只有在 SERIALIZABLE READ ONLY 事务中才有实际效果。 | 单一测试点，不与其他主场景合并。 |
| F01-V17 | TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE: SET TRANSACTION SNAPSHOT 只能在事务开始处，且事务隔离级别已为 REPEATABLE READ 或 SERIALIZABLE。 | normal | P0 | SET TRANSACTION SNAPSHOT 只能在事务开始处，且事务隔离级别已为 REPEATABLE READ 或 SERIALIZABLE。 | 单一测试点，不与其他主场景合并。 |
| F01-V18 | TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY: 导入方若为 SERIALIZABLE，导出 snapshot 的事务也必须为 SERIALIZABLE；非只读 serializable 事务不能从只读事务导入 snapshot。 | normal | P1 | 导入方若为 SERIALIZABLE，导出 snapshot 的事务也必须为 SERIALIZABLE；非只读 serializable 事务不能从只读事务导入 snapshot。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | SAVEPOINT | normal | P0 | 来自 TCL-BEGIN-INSIDE-TXN-WARNING 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | SELECT | normal | P0 | 来自 TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | transaction control command | normal | P1 | 来自 TCL-SET-SESSION-DEFAULT-MODES 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | COMMIT | normal | P0 | 来自 TCL-COMMIT-AND-CHAIN-KEEPS-MODES 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | ROLLBACK | normal | P0 | 来自 TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | SELECT / snapshot | normal | P0 | 来自 TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | snapshot | normal | P1 | 来自 TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 提交后状态 | normal/boundary | P0 | 来自 TCL-COMMIT-AND-CHAIN-KEEPS-MODES 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 回滚状态 | normal/boundary | P0 | 来自 TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 并发事务提交前 | normal/boundary | P0 | 来自 TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V05 | 只读事务状态 | normal/boundary | P1 | 来自 TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 错误/禁止场景 | boundary/exception/diagnostic | P0 | 来自 TCL-READONLY-DISALLOW-DML-DDL 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 常规核心路径 | boundary/exception/diagnostic | P1 | 来自 TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | TCL-BEGIN-INSIDE-TXN-WARNING、TCL-COMMIT-OUTSIDE-TXN-WARNING、TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR、TCL-ROLLBACK-OUTSIDE-TXN-WARNING、TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR、TCL-SET-TRANSACTION-NO-BEGIN-WARNING、TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR |
| C02 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION、TCL-START-TRANSACTION-EQUIVALENT-BEGIN、TCL-START-TRANSACTION-MODE-COMMA-OMIT、TCL-SET-SESSION-DEFAULT-MODES、TCL-READONLY-DISALLOW-DML-DDL、TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY、TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE、TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY |
| C03 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | TCL-COMMIT-AND-CHAIN-KEEPS-MODES、TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES、TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| TCL-BEGIN-INSIDE-TXN-WARNING | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 已在事务块内再次执行 BEGIN 只产生 warning，不影响事务状态；嵌套事务应使用 savepoint。 | `tcl-begin-inside-txn-warning.md` |
| TCL-BEGIN-MODES-EQUIVALENT-SET-TRANSACTION | C02 | P0 | F01-V02,F02-V02,F03-V01,F04-V02 | BEGIN 指定 isolation/read write/deferrable 模式时，效果等同事务开始时执行 SET TRANSACTION。 | `tcl-begin-modes-equivalent-set-transaction.md` |
| TCL-START-TRANSACTION-EQUIVALENT-BEGIN | C02 | P0 | F01-V03,F02-V03,F03-V01,F04-V02 | START TRANSACTION 与 BEGIN 功能等价。 | `tcl-start-transaction-equivalent-begin.md` |
| TCL-START-TRANSACTION-MODE-COMMA-OMIT | C02 | P1 | F01-V04,F02-V03,F03-V01,F04-V02 | PostgreSQL 为兼容历史允许 transaction modes 之间省略逗号。 | `tcl-start-transaction-mode-comma-omit.md` |
| TCL-COMMIT-OUTSIDE-TXN-WARNING | C01 | P0 | F01-V05,F02-V04,F03-V02,F04-V01 | 不在事务块内执行 COMMIT 无实际影响但产生 warning。 | `tcl-commit-outside-txn-warning.md` |
| TCL-COMMIT-AND-CHAIN-OUTSIDE-TXN-ERROR | C01 | P0 | F01-V06,F02-V04,F03-V02,F04-V01 | 不在事务块内执行 COMMIT AND CHAIN 是错误。 | `tcl-commit-and-chain-outside-txn-error.md` |
| TCL-COMMIT-AND-CHAIN-KEEPS-MODES | C03 | P0 | F01-V07,F02-V04,F03-V02,F04-V02 | COMMIT AND CHAIN 立即开启新事务，并继承刚结束事务的 transaction characteristics。 | `tcl-commit-and-chain-keeps-modes.md` |
| TCL-ROLLBACK-OUTSIDE-TXN-WARNING | C01 | P0 | F01-V08,F02-V05,F03-V03,F04-V01 | 不在事务块内执行 ROLLBACK 产生 warning 且无其他效果。 | `tcl-rollback-outside-txn-warning.md` |
| TCL-ROLLBACK-AND-CHAIN-OUTSIDE-TXN-ERROR | C01 | P0 | F01-V09,F02-V05,F03-V03,F04-V01 | 不在事务块内执行 ROLLBACK AND CHAIN 是错误。 | `tcl-rollback-and-chain-outside-txn-error.md` |
| TCL-ROLLBACK-AND-CHAIN-KEEPS-MODES | C03 | P0 | F01-V10,F02-V05,F03-V03,F04-V02 | ROLLBACK AND CHAIN 立即开启新的非 aborted 事务，并继承刚结束事务的 transaction characteristics。 | `tcl-rollback-and-chain-keeps-modes.md` |
| TCL-SET-TRANSACTION-NO-BEGIN-WARNING | C01 | P0 | F01-V11,F02-V03,F03-V01,F04-V01 | 未先 BEGIN 或 START TRANSACTION 时执行 SET TRANSACTION 产生 warning 且无效果。 | `tcl-set-transaction-no-begin-warning.md` |
| TCL-SET-TRANSACTION-AFTER-FIRST-STMT-ERROR | C01 | P0 | F01-V12,F02-V02,F03-V01,F04-V01 | 事务执行第一个查询或数据修改语句后，不允许再改变 isolation level。 | `tcl-set-transaction-after-first-stmt-error.md` |
| TCL-SET-SESSION-DEFAULT-MODES | C02 | P1 | F01-V13,F02-V03,F03-V01,F04-V02 | SET SESSION CHARACTERISTICS 只影响后续事务默认特征，可被单个事务 SET TRANSACTION 覆盖。 | `tcl-set-session-default-modes.md` |
| TCL-READ-UNCOMMITTED-MAPS-READ-COMMITTED | C03 | P0 | F01-V14,F02-V02,F03-V04,F04-V02 | PostgreSQL 中 READ UNCOMMITTED 按 READ COMMITTED 处理。 | `tcl-read-uncommitted-maps-read-committed.md` |
| TCL-READONLY-DISALLOW-DML-DDL | C02 | P0 | F01-V15,F02-V02,F03-V05,F04-V01 | READ ONLY 事务禁止对非临时表执行写 DML，并禁止 DDL、权限、truncate 等修改类命令。 | `tcl-readonly-disallow-dml-ddl.md` |
| TCL-DEFERRABLE-EFFECTIVE-ONLY-SERIALIZABLE-READONLY | C02 | P0 | F01-V16,F02-V02,F03-V05,F04-V02 | DEFERRABLE 只有在 SERIALIZABLE READ ONLY 事务中才有实际效果。 | `tcl-deferrable-effective-only-serializable-readonly.md` |
| TCL-SET-SNAPSHOT-REQUIRES-RR-OR-SERIALIZABLE | C02 | P0 | F01-V17,F02-V06,F03-V01,F04-V02 | SET TRANSACTION SNAPSHOT 只能在事务开始处，且事务隔离级别已为 REPEATABLE READ 或 SERIALIZABLE。 | `tcl-set-snapshot-requires-rr-or-serializable.md` |
| TCL-SET-SNAPSHOT-SERIALIZABLE-COMPATIBILITY | C02 | P1 | F01-V18,F02-V07,F03-V05,F04-V02 | 导入方若为 SERIALIZABLE，导出 snapshot 的事务也必须为 SERIALIZABLE；非只读 serializable 事务不能从只读事务导入 snapshot。 | `tcl-set-snapshot-serializable-compatibility.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：18。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。