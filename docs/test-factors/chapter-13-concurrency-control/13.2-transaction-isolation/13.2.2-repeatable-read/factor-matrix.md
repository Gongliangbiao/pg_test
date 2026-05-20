# 13.2.2 Repeatable Read 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的 13.2.2 Repeatable Read 章节内容；历史测试点仅作为迁移参考，因子按官方 Repeatable Read 语义空间重新建模。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.2.2 Repeatable Read

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.2.2 Repeatable Read 的语义空间：事务级稳定快照、不看到事务开始后其他事务提交、不出现不可重复读和幻读、可见本事务自身写入、UPDATE/DELETE/MERGE/SELECT FOR UPDATE/SHARE 遇到已改变目标行时返回 serialization failure，以及只读 Repeatable Read 的稳定视图边界。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | Repeatable Read 行为语义 | 事务级稳定快照、不看后续提交、无不可重复读、无幻读、自身写入可见、目标行变化触发 40001、只读稳定视图 | mixed，详见因子值细化 | 13.2.2 描述 Repeatable Read 的快照隔离行为和目标行并发变化处理。 | 作为本节核心语义维度。 |
| F02 | object | 被测语句类型 | SELECT、UPDATE、DELETE、MERGE、SELECT FOR UPDATE、SELECT FOR SHARE、snapshot | mixed，详见因子值细化 | 官方按查询、DML、行锁和快照固定时机说明 Repeatable Read。 | 用于区分语句入口和对象行为。 |
| F03 | state/condition | 并发状态或快照时机 | 事务开始后、首个非事务控制语句、并发事务提交后、并发事务回滚后、只读事务状态、等待解除后 | mixed，详见因子值细化 | Repeatable Read 的关键边界是事务快照和并发目标行变化时机。 | 用于组合稳定视图和冲突场景。 |
| F04 | boundary/exception/diagnostic | 结果边界或异常 | SQLSTATE 40001、稳定视图、只读视图不必然等价串行顺序、锁定但未更新不触发 40001 | mixed，详见因子值细化 | 官方明确区分 serialization failure、稳定视图与只读控制细节。 | 边界/异常必须独立覆盖。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 Repeatable Read 行为语义
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | RR-CONCURRENT-LOCK-ONLY-NO-40001: 并发事务只锁定目标行但未更新/删除并提交后，REPEATABLE READ 事务不应因该锁定本身返回 40001。 | normal | P0 | The serialization failure condition depends on the first updater actually updating or deleting the row, not merely locking it. | 单一测试点，不与其他主场景合并。 |
| F01-V02 | RR-DELETE-CONCURRENT-UPDATE-40001: 并发修改或删除目标行后，当前事务 DELETE 失败。 | normal | P0 | 并发修改或删除目标行后，当前事务 DELETE 失败。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | RR-FIRST-UPDATER-ROLLBACK-PROCEED: 等待并发更新时，先事务回滚后，REPEATABLE READ 事务继续处理原始目标行。 | normal | P0 | If the first updater rolls back, its effects are negated and the repeatable read transaction can proceed. | 单一测试点，不与其他主场景合并。 |
| F01-V04 | RR-MERGE-CONCURRENT-UPDATE-40001: MERGE 遇到事务开始后已被其他事务更新或删除的目标行时返回 serialization failure。 | normal | P0 | MERGE follows the same changed-row serialization failure rule as UPDATE, DELETE, SELECT FOR UPDATE, and SELECT FOR SHARE. | 单一测试点，不与其他主场景合并。 |
| F01-V05 | RR-NO-NONREPEATABLE-READ: REPEATABLE READ 下不出现不可重复读。 | normal | P0 | REPEATABLE READ 下不出现不可重复读。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | RR-NO-PHANTOM-READ: PostgreSQL REPEATABLE READ 不出现 phantom read。 | normal | P0 | PostgreSQL REPEATABLE READ 不出现 phantom read。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | RR-NOT-SEE-LATER-COMMIT: 不看到事务开始后其他事务提交的变更。 | normal | P0 | 不看到事务开始后其他事务提交的变更。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | RR-OWN-WRITES-VISIBLE: REPEATABLE READ 下本事务前序未提交写入对后续查询可见。 | normal | P0 | Each query sees the effects of previous updates executed within its own transaction. | 单一测试点，不与其他主场景合并。 |
| F01-V09 | RR-READONLY-NO-SERIALIZATION-CONFLICT: 只读 REPEATABLE READ 事务不会产生 serialization conflicts。 | normal | P0 | 只读 REPEATABLE READ 事务不会产生 serialization conflicts。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL: 只读 REPEATABLE READ 有稳定视图，但可能不对应任何串行执行顺序，不能单独支撑业务一致性。 | normal | P1 | A read-only repeatable read transaction can see a stable view that is not necessarily consistent with any serial execution. | 单一测试点，不与其他主场景合并。 |
| F01-V11 | RR-REPEATABLE-SELECT-STABLE: 同一事务内连续查询看到稳定视图。 | normal | P0 | 同一事务内连续查询看到稳定视图。 | 单一测试点，不与其他主场景合并。 |
| F01-V12 | RR-SELECT-FOR-SHARE-CONFLICT-40001: SELECT FOR SHARE 遇到事务开始后已被其他事务更新或删除的目标行时返回 40001。 | normal | P0 | SELECT FOR SHARE errors if the row to be locked has changed since the repeatable read transaction began. | 单一测试点，不与其他主场景合并。 |
| F01-V13 | RR-SELECT-FOR-UPDATE-CONFLICT-40001: SELECT FOR UPDATE 遇到并发修改目标行时失败。 | normal | P0 | SELECT FOR UPDATE 遇到并发修改目标行时失败。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | RR-SNAPSHOT-FIRST-NON-TCL-STMT: 事务快照固定在第一个非事务控制语句开始时。 | normal | P0 | 事务快照固定在第一个非事务控制语句开始时。 | 单一测试点，不与其他主场景合并。 |
| F01-V15 | RR-SNAPSHOT-ISOLATION-WRITE-SKEW: REPEATABLE READ 是 Snapshot Isolation，稳定视图不必然等价于某个串行顺序。 | normal | P0 | REPEATABLE READ 是 Snapshot Isolation，稳定视图不必然等价于某个串行顺序。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | RR-UPDATE-CONCURRENT-UPDATE-40001: 并发更新目标行后，当前事务 UPDATE 失败并返回 serialization failure。 | normal | P0 | 并发更新目标行后，当前事务 UPDATE 失败并返回 serialization failure。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | SELECT / UPDATE / DELETE / LOCK / COMMIT | normal | P0 | 来自 RR-CONCURRENT-LOCK-ONLY-NO-40001 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | DELETE | normal | P0 | 来自 RR-DELETE-CONCURRENT-UPDATE-40001 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | SELECT / UPDATE / ROLLBACK | normal | P0 | 来自 RR-FIRST-UPDATER-ROLLBACK-PROCEED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | UPDATE / DELETE / MERGE | normal | P0 | 来自 RR-MERGE-CONCURRENT-UPDATE-40001 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | SELECT | normal | P0 | 来自 RR-REPEATABLE-SELECT-STABLE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | COMMIT | normal | P0 | 来自 RR-NOT-SEE-LATER-COMMIT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | SELECT / UPDATE / COMMIT | normal | P0 | 来自 RR-OWN-WRITES-VISIBLE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | SELECT / UPDATE / DELETE / LOCK | normal | P0 | 来自 RR-SELECT-FOR-SHARE-CONFLICT-40001 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V09 | SELECT / UPDATE / LOCK | normal | P0 | 来自 RR-SELECT-FOR-UPDATE-CONFLICT-40001 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V10 | snapshot | normal | P0 | 来自 RR-SNAPSHOT-FIRST-NON-TCL-STMT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V11 | SELECT / snapshot | normal | P0 | 来自 RR-SNAPSHOT-ISOLATION-WRITE-SKEW 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V12 | UPDATE | normal | P0 | 来自 RR-UPDATE-CONCURRENT-UPDATE-40001 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 提交后状态 | normal/boundary | P0 | 来自 RR-NOT-SEE-LATER-COMMIT 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 常规事务状态转换 | normal/boundary | P0 | 来自 RR-UPDATE-CONCURRENT-UPDATE-40001 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 等待/阻塞状态 | normal/boundary | P0 | 来自 RR-FIRST-UPDATER-ROLLBACK-PROCEED 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 并发事务提交前 | normal/boundary | P0 | 来自 RR-OWN-WRITES-VISIBLE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V05 | 只读事务状态 | normal/boundary | P1 | 来自 RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | SQLSTATE 40001 | boundary/exception/diagnostic | P0 | 来自 RR-UPDATE-CONCURRENT-UPDATE-40001 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 RR-SNAPSHOT-FIRST-NON-TCL-STMT 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | 诊断观测 | boundary/exception/diagnostic | P0 | 来自 RR-SNAPSHOT-ISOLATION-WRITE-SKEW 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | RR-CONCURRENT-LOCK-ONLY-NO-40001、RR-DELETE-CONCURRENT-UPDATE-40001、RR-MERGE-CONCURRENT-UPDATE-40001、RR-SELECT-FOR-SHARE-CONFLICT-40001、RR-SELECT-FOR-UPDATE-CONFLICT-40001、RR-UPDATE-CONCURRENT-UPDATE-40001 |
| C02 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | RR-FIRST-UPDATER-ROLLBACK-PROCEED |
| C03 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | RR-NO-NONREPEATABLE-READ、RR-NO-PHANTOM-READ、RR-READONLY-NO-SERIALIZATION-CONFLICT、RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL、RR-REPEATABLE-SELECT-STABLE、RR-SNAPSHOT-FIRST-NON-TCL-STMT、RR-SNAPSHOT-ISOLATION-WRITE-SKEW |
| C04 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | RR-NOT-SEE-LATER-COMMIT、RR-OWN-WRITES-VISIBLE |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| RR-CONCURRENT-LOCK-ONLY-NO-40001 | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 并发事务只锁定目标行但未更新/删除并提交后，REPEATABLE READ 事务不应因该锁定本身返回 40001。 | `rr-concurrent-lock-only-no-40001.md` |
| RR-DELETE-CONCURRENT-UPDATE-40001 | C01 | P0 | F01-V02,F02-V02,F03-V02,F04-V01 | 并发修改或删除目标行后，当前事务 DELETE 失败。 | `rr-delete-concurrent-update-40001.md` |
| RR-FIRST-UPDATER-ROLLBACK-PROCEED | C02 | P0 | F01-V03,F02-V03,F03-V03,F04-V02 | 等待并发更新时，先事务回滚后，REPEATABLE READ 事务继续处理原始目标行。 | `rr-first-updater-rollback-proceed.md` |
| RR-MERGE-CONCURRENT-UPDATE-40001 | C01 | P0 | F01-V04,F02-V04,F03-V02,F04-V01 | MERGE 遇到事务开始后已被其他事务更新或删除的目标行时返回 serialization failure。 | `rr-merge-concurrent-update-40001.md` |
| RR-NO-NONREPEATABLE-READ | C03 | P0 | F01-V05,F02-V05,F03-V02,F04-V02 | REPEATABLE READ 下不出现不可重复读。 | `rr-no-nonrepeatable-read.md` |
| RR-NO-PHANTOM-READ | C03 | P0 | F01-V06,F02-V05,F03-V02,F04-V02 | PostgreSQL REPEATABLE READ 不出现 phantom read。 | `rr-no-phantom-read.md` |
| RR-NOT-SEE-LATER-COMMIT | C04 | P0 | F01-V07,F02-V06,F03-V01,F04-V02 | 不看到事务开始后其他事务提交的变更。 | `rr-not-see-later-commit.md` |
| RR-OWN-WRITES-VISIBLE | C04 | P0 | F01-V08,F02-V07,F03-V04,F04-V02 | REPEATABLE READ 下本事务前序未提交写入对后续查询可见。 | `rr-own-writes-visible.md` |
| RR-READONLY-NO-SERIALIZATION-CONFLICT | C03 | P0 | F01-V09,F02-V05,F03-V05,F04-V02 | 只读 REPEATABLE READ 事务不会产生 serialization conflicts。 | `rr-readonly-no-serialization-conflict.md` |
| RR-READONLY-STABLE-BUT-NOT-SERIAL-CONTROL-DETAIL | C03 | P1 | F01-V10,F02-V05,F03-V05,F04-V03 | 只读 REPEATABLE READ 有稳定视图，但可能不对应任何串行执行顺序，不能单独支撑业务一致性。 | `rr-readonly-stable-but-not-serial-control-detail.md` |
| RR-REPEATABLE-SELECT-STABLE | C03 | P0 | F01-V11,F02-V05,F03-V02,F04-V03 | 同一事务内连续查询看到稳定视图。 | `rr-repeatable-select-stable.md` |
| RR-SELECT-FOR-SHARE-CONFLICT-40001 | C01 | P0 | F01-V12,F02-V08,F03-V02,F04-V01 | SELECT FOR SHARE 遇到事务开始后已被其他事务更新或删除的目标行时返回 40001。 | `rr-select-for-share-conflict-40001.md` |
| RR-SELECT-FOR-UPDATE-CONFLICT-40001 | C01 | P0 | F01-V13,F02-V09,F03-V02,F04-V01 | SELECT FOR UPDATE 遇到并发修改目标行时失败。 | `rr-select-for-update-conflict-40001.md` |
| RR-SNAPSHOT-FIRST-NON-TCL-STMT | C03 | P0 | F01-V14,F02-V10,F03-V02,F04-V02 | 事务快照固定在第一个非事务控制语句开始时。 | `rr-snapshot-first-non-tcl-stmt.md` |
| RR-SNAPSHOT-ISOLATION-WRITE-SKEW | C03 | P0 | F01-V15,F02-V11,F03-V02,F04-V03 | REPEATABLE READ 是 Snapshot Isolation，稳定视图不必然等价于某个串行顺序。 | `rr-snapshot-isolation-write-skew.md` |
| RR-UPDATE-CONCURRENT-UPDATE-40001 | C01 | P0 | F01-V16,F02-V12,F03-V02,F04-V01 | 并发更新目标行后，当前事务 UPDATE 失败并返回 serialization failure。 | `rr-update-concurrent-update-40001.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：16。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。
