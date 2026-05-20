# 74.3 Subtransactions 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节结构
- Chapter 74 Transaction Processing
  - 74.3 Subtransactions

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 74 Transaction Processing 中 74.3 Subtransactions 的测试点。测试点来自事务处理测试点计划，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 24 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | SAVEPOINT、subtransaction、COMMIT、ROLLBACK、xid、UPDATE / xid、COMMIT / xid、SAVEPOINT / ROLLBACK | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 常规事务状态转换、提交后状态、回滚状态、只读事务状态 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、边界值 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION: SAVEPOINT 在顶层事务内部显式启动 subtransaction。 | normal | P0 | SAVEPOINT 在顶层事务内部显式启动 subtransaction。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION: PL/pgSQL EXCEPTION 块可隐式启动 subtransaction。 | normal | P1 | PL/pgSQL EXCEPTION 块可隐式启动 subtransaction。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION: PL/Python 显式 subtransaction 能进入同一内部模型。 | normal | P2 | PL/Python 显式 subtransaction 能进入同一内部模型。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION: PL/Tcl 显式 subtransaction 能进入同一内部模型。 | normal | P2 | PL/Tcl 显式 subtransaction 能进入同一内部模型。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | SUBXACT-NESTED-SAVEPOINT-TREE: subtransaction 可以在其他 subtransaction 内部继续启动，形成层级树。 | normal | P0 | subtransaction 可以在其他 subtransaction 内部继续启动，形成层级树。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT: 子事务提交不结束父事务，父事务可继续执行。 | normal | P0 | 子事务提交不结束父事务，父事务可继续执行。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT: 子事务回滚不影响父事务继续执行。 | normal | P0 | 子事务回滚不影响父事务继续执行。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | SUBXACT-READONLY-NO-SUBXID: 只读 subtransaction 不分配 subxid。 | normal | P0 | 只读 subtransaction 不分配 subxid。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | SUBXACT-WRITE-ASSIGNS-SUBXID: subtransaction 第一次写入时分配非虚拟 transaction ID，称为 subxid。 | normal | P0 | subtransaction 第一次写入时分配非虚拟 transaction ID，称为 subxid。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | SUBXACT-WRITE-ASSIGNS-PARENTS-XID: 子事务写入导致其所有父级直到顶层事务都分配非虚拟 transaction ID。 | normal | P0 | 子事务写入导致其所有父级直到顶层事务都分配非虚拟 transaction ID。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | SUBXACT-PARENT-XID-LOWER-THAN-CHILD: 父级 xid 总是小于任一子级 subxid。 | normal | P0 | 父级 xid 总是小于任一子级 subxid。 | 单一测试点，不与其他主场景合并。 |
| F01-V12 | SUBXACT-PG-SUBTRANS-PARENT-MAPPING: 每个 subxid 的直接父级 xid 记录在 pg_subtrans。 | normal | P1 | 每个 subxid 的直接父级 xid 记录在 pg_subtrans。 | 单一测试点，不与其他主场景合并。 |
| F01-V13 | SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY: 顶层 xid 没有父级，不在 pg_subtrans 建父映射项。 | normal | P1 | 顶层 xid 没有父级，不在 pg_subtrans 建父映射项。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY: 只读 subtransaction 不分配 subxid，因此不在 pg_subtrans 建映射项。 | normal | P1 | 只读 subtransaction 不分配 subxid，因此不在 pg_subtrans 建映射项。 | 单一测试点，不与其他主场景合并。 |
| F01-V15 | SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED: subtransaction 提交时，其已提交且有 subxid 的子事务被视为 subcommitted。 | normal | P0 | subtransaction 提交时，其已提交且有 subxid 的子事务被视为 subcommitted。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | SUBXACT-ABORT-CHILDREN-ABORTED: subtransaction 回滚时，其所有子 subtransaction 也被视为 aborted。 | normal | P0 | subtransaction 回滚时，其所有子 subtransaction 也被视为 aborted。 | 单一测试点，不与其他主场景合并。 |
| F01-V17 | SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN: 带 xid 的顶层事务提交时，其 subcommitted 子事务在 pg_xact 中持久记录为 committed。 | normal | P0 | 带 xid 的顶层事务提交时，其 subcommitted 子事务在 pg_xact 中持久记录为 committed。 | 单一测试点，不与其他主场景合并。 |
| F01-V18 | SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED: 顶层事务回滚时，已 subcommitted 的子事务也最终回滚。 | normal | P0 | 顶层事务回滚时，已 subcommitted 的子事务也最终回滚。 | 单一测试点，不与其他主场景合并。 |
| F01-V19 | SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO: ROLLBACK TO SAVEPOINT 只撤销保存点之后的变更，并允许事务继续。 | normal | P0 | ROLLBACK TO SAVEPOINT 只撤销保存点之后的变更，并允许事务继续。 | 单一测试点，不与其他主场景合并。 |
| F01-V20 | SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS: RELEASE SAVEPOINT 不撤销变更，而是释放保存点并合并未回滚变更。 | normal | P0 | RELEASE SAVEPOINT 不撤销变更，而是释放保存点并合并未回滚变更。 | 单一测试点，不与其他主场景合并。 |
| F01-V21 | SUBXACT-SAME-NAME-SAVEPOINT-LATEST: 同名保存点存在时，最近定义且未释放的保存点优先生效。 | normal | P1 | 同名保存点存在时，最近定义且未释放的保存点优先生效。 | 单一测试点，不与其他主场景合并。 |
| F01-V22 | SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS: ROLLBACK TO SAVEPOINT 隐式销毁目标保存点之后创建的保存点。 | normal | P0 | ROLLBACK TO SAVEPOINT 隐式销毁目标保存点之后创建的保存点。 | 单一测试点，不与其他主场景合并。 |
| F01-V23 | SUBXACT-OPEN-SUBXID-CACHE-64: 每个 backend 最多缓存 64 个 open subxids 到共享内存。 | normal | P1 | 每个 backend 最多缓存 64 个 open subxids 到共享内存。 | 单一测试点，不与其他主场景合并。 |
| F01-V24 | SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO: open subxids 超过 64 后，因额外 pg_subtrans 查找导致事务管理 I/O 开销显著增加。 | normal | P2 | open subxids 超过 64 后，因额外 pg_subtrans 查找导致事务管理 I/O 开销显著增加。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | SAVEPOINT | normal | P1 | 来自 SUBXACT-SAME-NAME-SAVEPOINT-LATEST 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | subtransaction | normal | P0 | 来自 SUBXACT-NESTED-SAVEPOINT-TREE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | COMMIT | normal | P0 | 来自 SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | ROLLBACK | normal | P0 | 来自 SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | xid | normal | P2 | 来自 SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | UPDATE / xid | normal | P0 | 来自 SUBXACT-WRITE-ASSIGNS-PARENTS-XID 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | COMMIT / xid | normal | P0 | 来自 SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | SAVEPOINT / ROLLBACK | normal | P0 | 来自 SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P2 | 来自 SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 提交后状态 | normal/boundary | P0 | 来自 SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 回滚状态 | normal/boundary | P0 | 来自 SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 只读事务状态 | normal/boundary | P1 | 来自 SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 边界值 | boundary/exception/diagnostic | P2 | 来自 SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION、SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION、SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION、SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION、SUBXACT-NESTED-SAVEPOINT-TREE、SUBXACT-READONLY-NO-SUBXID、SUBXACT-WRITE-ASSIGNS-SUBXID、SUBXACT-WRITE-ASSIGNS-PARENTS-XID、SUBXACT-PARENT-XID-LOWER-THAN-CHILD、SUBXACT-PG-SUBTRANS-PARENT-MAPPING、SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY、SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY、SUBXACT-SAME-NAME-SAVEPOINT-LATEST |
| C02 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT、SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT、SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED、SUBXACT-ABORT-CHILDREN-ABORTED、SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN、SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED、SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO、SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS、SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS |
| C03 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | SUBXACT-OPEN-SUBXID-CACHE-64、SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| SUBXACT-SAVEPOINT-STARTS-SUBTRANSACTION | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | SAVEPOINT 在顶层事务内部显式启动 subtransaction。 | `subxact-savepoint-starts-subtransaction.md` |
| SUBXACT-PLPGSQL-EXCEPTION-STARTS-SUBTRANSACTION | C01 | P1 | F01-V02,F02-V02,F03-V01,F04-V01 | PL/pgSQL EXCEPTION 块可隐式启动 subtransaction。 | `subxact-plpgsql-exception-starts-subtransaction.md` |
| SUBXACT-PLPYTHON-EXPLICIT-SUBTRANSACTION | C01 | P2 | F01-V03,F02-V02,F03-V01,F04-V01 | PL/Python 显式 subtransaction 能进入同一内部模型。 | `subxact-plpython-explicit-subtransaction.md` |
| SUBXACT-PLTCL-EXPLICIT-SUBTRANSACTION | C01 | P2 | F01-V04,F02-V02,F03-V01,F04-V01 | PL/Tcl 显式 subtransaction 能进入同一内部模型。 | `subxact-pltcl-explicit-subtransaction.md` |
| SUBXACT-NESTED-SAVEPOINT-TREE | C01 | P0 | F01-V05,F02-V02,F03-V01,F04-V01 | subtransaction 可以在其他 subtransaction 内部继续启动，形成层级树。 | `subxact-nested-savepoint-tree.md` |
| SUBXACT-PARENT-CONTINUES-AFTER-SUBCOMMIT | C02 | P0 | F01-V06,F02-V03,F03-V02,F04-V01 | 子事务提交不结束父事务，父事务可继续执行。 | `subxact-parent-continues-after-subcommit.md` |
| SUBXACT-PARENT-CONTINUES-AFTER-SUBABORT | C02 | P0 | F01-V07,F02-V04,F03-V03,F04-V01 | 子事务回滚不影响父事务继续执行。 | `subxact-parent-continues-after-subabort.md` |
| SUBXACT-READONLY-NO-SUBXID | C01 | P0 | F01-V08,F02-V05,F03-V04,F04-V01 | 只读 subtransaction 不分配 subxid。 | `subxact-readonly-no-subxid.md` |
| SUBXACT-WRITE-ASSIGNS-SUBXID | C01 | P0 | F01-V09,F02-V06,F03-V01,F04-V01 | subtransaction 第一次写入时分配非虚拟 transaction ID，称为 subxid。 | `subxact-write-assigns-subxid.md` |
| SUBXACT-WRITE-ASSIGNS-PARENTS-XID | C01 | P0 | F01-V10,F02-V06,F03-V01,F04-V01 | 子事务写入导致其所有父级直到顶层事务都分配非虚拟 transaction ID。 | `subxact-write-assigns-parents-xid.md` |
| SUBXACT-PARENT-XID-LOWER-THAN-CHILD | C01 | P0 | F01-V11,F02-V05,F03-V01,F04-V02 | 父级 xid 总是小于任一子级 subxid。 | `subxact-parent-xid-lower-than-child.md` |
| SUBXACT-PG-SUBTRANS-PARENT-MAPPING | C01 | P1 | F01-V12,F02-V05,F03-V01,F04-V01 | 每个 subxid 的直接父级 xid 记录在 pg_subtrans。 | `subxact-pg-subtrans-parent-mapping.md` |
| SUBXACT-PG-SUBTRANS-NO-TOPLEVEL-ENTRY | C01 | P1 | F01-V13,F02-V05,F03-V01,F04-V01 | 顶层 xid 没有父级，不在 pg_subtrans 建父映射项。 | `subxact-pg-subtrans-no-toplevel-entry.md` |
| SUBXACT-PG-SUBTRANS-NO-READONLY-ENTRY | C01 | P1 | F01-V14,F02-V05,F03-V04,F04-V01 | 只读 subtransaction 不分配 subxid，因此不在 pg_subtrans 建映射项。 | `subxact-pg-subtrans-no-readonly-entry.md` |
| SUBXACT-COMMIT-CHILDREN-SUBCOMMITTED | C02 | P0 | F01-V15,F02-V07,F03-V02,F04-V01 | subtransaction 提交时，其已提交且有 subxid 的子事务被视为 subcommitted。 | `subxact-commit-children-subcommitted.md` |
| SUBXACT-ABORT-CHILDREN-ABORTED | C02 | P0 | F01-V16,F02-V04,F03-V03,F04-V01 | subtransaction 回滚时，其所有子 subtransaction 也被视为 aborted。 | `subxact-abort-children-aborted.md` |
| SUBXACT-TOPLEVEL-COMMIT-PERSISTS-CHILDREN | C02 | P0 | F01-V17,F02-V07,F03-V02,F04-V01 | 带 xid 的顶层事务提交时，其 subcommitted 子事务在 pg_xact 中持久记录为 committed。 | `subxact-toplevel-commit-persists-children.md` |
| SUBXACT-TOPLEVEL-ABORT-ABORTS-SUBCOMMITTED | C02 | P0 | F01-V18,F02-V04,F03-V02,F04-V01 | 顶层事务回滚时，已 subcommitted 的子事务也最终回滚。 | `subxact-toplevel-abort-aborts-subcommitted.md` |
| SUBXACT-ROLLBACK-TO-SAVEPOINT-PARTIAL-UNDO | C02 | P0 | F01-V19,F02-V08,F03-V03,F04-V01 | ROLLBACK TO SAVEPOINT 只撤销保存点之后的变更，并允许事务继续。 | `subxact-rollback-to-savepoint-partial-undo.md` |
| SUBXACT-RELEASE-SAVEPOINT-MERGE-EFFECTS | C02 | P0 | F01-V20,F02-V08,F03-V03,F04-V01 | RELEASE SAVEPOINT 不撤销变更，而是释放保存点并合并未回滚变更。 | `subxact-release-savepoint-merge-effects.md` |
| SUBXACT-SAME-NAME-SAVEPOINT-LATEST | C01 | P1 | F01-V21,F02-V01,F03-V01,F04-V01 | 同名保存点存在时，最近定义且未释放的保存点优先生效。 | `subxact-same-name-savepoint-latest.md` |
| SUBXACT-ROLLBACK-DESTROYS-LATER-SAVEPOINTS | C02 | P0 | F01-V22,F02-V08,F03-V03,F04-V01 | ROLLBACK TO SAVEPOINT 隐式销毁目标保存点之后创建的保存点。 | `subxact-rollback-destroys-later-savepoints.md` |
| SUBXACT-OPEN-SUBXID-CACHE-64 | C03 | P1 | F01-V23,F02-V05,F03-V01,F04-V02 | 每个 backend 最多缓存 64 个 open subxids 到共享内存。 | `subxact-open-subxid-cache-64.md` |
| SUBXACT-OPEN-SUBXID-OVER-64-PG-SUBTRANS-IO | C03 | P2 | F01-V24,F02-V05,F03-V01,F04-V02 | open subxids 超过 64 后，因额外 pg_subtrans 查找导致事务管理 I/O 开销显著增加。 | `subxact-open-subxid-over-64-pg-subtrans-io.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：24。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。