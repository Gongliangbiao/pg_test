# 13.2.1 Read Committed 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的 13.2.1 Read Committed 章节内容；历史测试点仅作为迁移参考，因子按官方 Read Committed 语义空间重新建模。


## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.2.1 Read Committed

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 Concurrency Control 中 13.2.1 Read Committed 的语义空间：每条语句使用语句级快照、普通 SELECT 不等待并发事务、同一事务可见自身写入、后续语句可见其他事务新提交、UPDATE/DELETE/SELECT FOR UPDATE/SELECT FOR SHARE 的等待并重检规则、INSERT ON CONFLICT 与 MERGE 的并发差异，以及 Read Committed 下允许的不可重复读和幻读现象。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | Read Committed 行为语义 | 语句级快照、等待并重检、同事务写入可见、后续语句可见新提交、不可重复读、幻读、ON CONFLICT/MERGE 并发语义 | mixed，详见因子值细化 | 13.2.1 描述 Read Committed 下查询、DML 和行锁语句的可见性与并发处理规则。 | 作为本节核心语义维度。 |
| F02 | object | 被测语句类型 | SELECT、UPDATE、DELETE、INSERT ON CONFLICT、MERGE、SELECT FOR UPDATE、SELECT FOR SHARE | mixed，详见因子值细化 | 官方按普通查询、更新/删除、行锁、ON CONFLICT 和 MERGE 描述 Read Committed 行为。 | 用于区分语句入口和对象行为。 |
| F03 | state/condition | 并发状态或快照时机 | 语句开始时、同一事务后续语句、并发事务未提交、并发事务提交后、并发事务回滚后、等待解除后 | mixed，详见因子值细化 | Read Committed 行为高度依赖语句快照和并发事务提交/回滚状态。 | 用于组合可见性和等待场景。 |
| F04 | boundary/exception/diagnostic | 结果边界或异常 | WHERE 重检匹配、WHERE 重检不匹配、目标行删除后跳过、唯一键冲突、MERGE 不提供 upsert 保证 | mixed，详见因子值细化 | 官方明确描述等待后重检、跳过、冲突和 MERGE 与 UPSERT 差异。 | 边界/异常必须独立覆盖。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 Read Committed 行为语义
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT: 复杂搜索条件下，单条更新命令可能看到不一致快照。 | normal | P0 | 复杂搜索条件下，单条更新命令可能看到不一致快照。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | RC-DELETE-WAIT-RECHECK: DELETE 对并发更新行等待并重检条件。 | normal | P0 | DELETE 对并发更新行等待并重检条件。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION: MERGE 目标行并发删除或更新导致 join condition 失败时，转入 NOT MATCHED action 评估。 | normal | P0 | If a target row is concurrently updated or deleted so the join condition fails, MERGE evaluates NOT MATCHED actions. | 单一测试点，不与其他主场景合并。 |
| F01-V04 | RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION: MERGE 并发插入唯一键冲突时，不像 upsert 那样重启匹配评估，而是返回 unique violation。 | normal | P0 | If MERGE attempts INSERT and a duplicate row is concurrently inserted, a uniqueness violation is raised. | 单一测试点，不与其他主场景合并。 |
| F01-V05 | RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE: MERGE 并发更新时重新评估 action，但不提供同等 upsert 保证。 | normal | P0 | MERGE 并发更新时重新评估 action，但不提供同等 upsert 保证。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | RC-NONREPEATABLE-READ: READ COMMITTED 允许同事务多次 SELECT 看到不同结果。 | normal | P0 | READ COMMITTED 允许同事务多次 SELECT 看到不同结果。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | RC-ON-CONFLICT-DO-NOTHING-INVISIBLE-CONFLICT: INSERT ... ON CONFLICT DO NOTHING 可因不可见并发事务结果跳过插入。 | normal | P0 | INSERT ... ON CONFLICT DO NOTHING 可因不可见并发事务结果跳过插入。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | RC-ON-CONFLICT-DO-UPDATE-GUARANTEE: INSERT ... ON CONFLICT DO UPDATE 每行保证 insert 或 update 之一发生。 | normal | P0 | INSERT ... ON CONFLICT DO UPDATE 每行保证 insert 或 update 之一发生。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | RC-OWN-WRITES-VISIBLE: 同一事务内未提交写入对本事务后续 SELECT 可见。 | normal | P0 | SELECT sees the effects of previous updates executed within its own transaction. | 单一测试点，不与其他主场景合并。 |
| F01-V10 | RC-PHANTOM-READ: READ COMMITTED 下新提交行可被后续语句看到。 | normal | P0 | READ COMMITTED 下新提交行可被后续语句看到。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | RC-SAME-TXN-NEW-SNAPSHOT: 同一事务后续语句看到其他事务新提交数据。 | normal | P0 | 同一事务后续语句看到其他事务新提交数据。 | 单一测试点，不与其他主场景合并。 |
| F01-V12 | RC-SELECT-FOR-SHARE-WAIT-RECHECK: SELECT FOR SHARE 等待并发更新结束后重新检查目标行。 | normal | P0 | SELECT FOR SHARE follows the same wait-and-recheck target-row rule as SELECT FOR UPDATE in Read Committed. | 单一测试点，不与其他主场景合并。 |
| F01-V13 | RC-SELECT-FOR-UPDATE-WAIT-RECHECK: SELECT FOR UPDATE 等待并发更新结束后重检目标行。 | normal | P0 | SELECT FOR UPDATE 等待并发更新结束后重检目标行。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | RC-SELECT-IGNORE-INPROGRESS: 普通 SELECT 不看未提交并发变更。 | normal | P0 | 普通 SELECT 不看未提交并发变更。 | 单一测试点，不与其他主场景合并。 |
| F01-V15 | RC-STATEMENT-SNAPSHOT-BASIC: 每条语句使用语句开始时快照。 | normal | P0 | 每条语句使用语句开始时快照。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE: 先事务删除并提交后，等待中的 UPDATE 忽略该目标行。 | normal | P0 | If the first updater commits and deleted the row, the second updater ignores the row. | 单一测试点，不与其他主场景合并。 |
| F01-V17 | RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED: 并发更新同一行时，先更新事务回滚后，等待中的 UPDATE 使用原始目标行继续执行。 | normal | P0 | If the first updater rolls back, the second updater can proceed with the originally found row. | 单一测试点，不与其他主场景合并。 |
| F01-V18 | RC-UPDATE-WAIT-RECHECK-WHERE-MATCH: UPDATE 等待并发事务结束后重检 WHERE，匹配则继续更新。 | normal | P0 | UPDATE 等待并发事务结束后重检 WHERE，匹配则继续更新。 | 单一测试点，不与其他主场景合并。 |
| F01-V19 | RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH: UPDATE 等待并发事务结束后重检 WHERE，不匹配则跳过。 | normal | P0 | UPDATE 等待并发事务结束后重检 WHERE，不匹配则跳过。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | UPDATE / snapshot | normal | P0 | 来自 RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | UPDATE / DELETE | normal | P0 | 来自 RC-DELETE-WAIT-RECHECK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | UPDATE / DELETE / MERGE | normal | P0 | 来自 RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | INSERT / MERGE | normal | P0 | 来自 RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | UPDATE / MERGE | normal | P0 | 来自 RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | SELECT | normal | P0 | 来自 RC-NONREPEATABLE-READ 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | INSERT | normal | P0 | 来自 RC-ON-CONFLICT-DO-NOTHING-INVISIBLE-CONFLICT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | UPDATE / INSERT | normal | P0 | 来自 RC-ON-CONFLICT-DO-UPDATE-GUARANTEE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V09 | SELECT / UPDATE / COMMIT | normal | P0 | 来自 RC-OWN-WRITES-VISIBLE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V10 | SELECT / COMMIT | normal | P0 | 来自 RC-SELECT-IGNORE-INPROGRESS 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V11 | COMMIT | normal | P0 | 来自 RC-SAME-TXN-NEW-SNAPSHOT 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V12 | SELECT / UPDATE / LOCK | normal | P0 | 来自 RC-SELECT-FOR-UPDATE-WAIT-RECHECK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V13 | snapshot | normal | P0 | 来自 RC-STATEMENT-SNAPSHOT-BASIC 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V14 | UPDATE / DELETE / COMMIT | normal | P0 | 来自 RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V15 | UPDATE / ROLLBACK | normal | P0 | 来自 RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V16 | UPDATE | normal | P0 | 来自 RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 常规事务状态转换 | normal/boundary | P0 | 来自 RC-STATEMENT-SNAPSHOT-BASIC 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 等待/阻塞状态 | normal/boundary | P0 | 来自 RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 提交后状态 | normal/boundary | P0 | 来自 RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 并发事务提交前 | normal/boundary | P0 | 来自 RC-SELECT-IGNORE-INPROGRESS 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 错误/禁止场景 | boundary/exception/diagnostic | P0 | 来自 RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT、RC-ON-CONFLICT-DO-UPDATE-GUARANTEE、RC-STATEMENT-SNAPSHOT-BASIC |
| C02 | concurrency-directed | F01,F02,F03,F04 | 覆盖 concurrency-directed 类型测试点 | RC-DELETE-WAIT-RECHECK、RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION、RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION、RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE、RC-ON-CONFLICT-DO-NOTHING-INVISIBLE-CONFLICT、RC-SELECT-FOR-SHARE-WAIT-RECHECK、RC-SELECT-FOR-UPDATE-WAIT-RECHECK、RC-SELECT-IGNORE-INPROGRESS、RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED、RC-UPDATE-WAIT-RECHECK-WHERE-MATCH、RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH |
| C03 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | RC-NONREPEATABLE-READ、RC-OWN-WRITES-VISIBLE、RC-PHANTOM-READ、RC-SAME-TXN-NEW-SNAPSHOT、RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| RC-COMPLEX-PREDICATE-INCONSISTENT-SNAPSHOT | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | 复杂搜索条件下，单条更新命令可能看到不一致快照。 | `rc-complex-predicate-inconsistent-snapshot.md` |
| RC-DELETE-WAIT-RECHECK | C02 | P0 | F01-V02,F02-V02,F03-V02,F04-V01 | DELETE 对并发更新行等待并重检条件。 | `rc-delete-wait-recheck.md` |
| RC-MERGE-CONCURRENT-DELETE-NOT-MATCHED-ACTION | C02 | P0 | F01-V03,F02-V03,F03-V01,F04-V02 | MERGE 目标行并发删除或更新导致 join condition 失败时，转入 NOT MATCHED action 评估。 | `rc-merge-concurrent-delete-not-matched-action.md` |
| RC-MERGE-CONCURRENT-INSERT-UNIQUE-VIOLATION | C02 | P0 | F01-V04,F02-V04,F03-V01,F04-V01 | MERGE 并发插入唯一键冲突时，不像 upsert 那样重启匹配评估，而是返回 unique violation。 | `rc-merge-concurrent-insert-unique-violation.md` |
| RC-MERGE-RECHECK-ACTION-NO-UPSERT-GUARANTEE | C02 | P0 | F01-V05,F02-V05,F03-V01,F04-V01 | MERGE 并发更新时重新评估 action，但不提供同等 upsert 保证。 | `rc-merge-recheck-action-no-upsert-guarantee.md` |
| RC-NONREPEATABLE-READ | C03 | P0 | F01-V06,F02-V06,F03-V03,F04-V01 | READ COMMITTED 允许同事务多次 SELECT 看到不同结果。 | `rc-nonrepeatable-read.md` |
| RC-ON-CONFLICT-DO-NOTHING-INVISIBLE-CONFLICT | C02 | P0 | F01-V07,F02-V07,F03-V01,F04-V01 | INSERT ... ON CONFLICT DO NOTHING 可因不可见并发事务结果跳过插入。 | `rc-on-conflict-do-nothing-invisible-conflict.md` |
| RC-ON-CONFLICT-DO-UPDATE-GUARANTEE | C01 | P0 | F01-V08,F02-V08,F03-V01,F04-V01 | INSERT ... ON CONFLICT DO UPDATE 每行保证 insert 或 update 之一发生。 | `rc-on-conflict-do-update-guarantee.md` |
| RC-OWN-WRITES-VISIBLE | C03 | P0 | F01-V09,F02-V09,F03-V04,F04-V01 | 同一事务内未提交写入对本事务后续 SELECT 可见。 | `rc-own-writes-visible.md` |
| RC-PHANTOM-READ | C03 | P0 | F01-V10,F02-V10,F03-V03,F04-V01 | READ COMMITTED 下新提交行可被后续语句看到。 | `rc-phantom-read.md` |
| RC-SAME-TXN-NEW-SNAPSHOT | C03 | P0 | F01-V11,F02-V11,F03-V01,F04-V01 | 同一事务后续语句看到其他事务新提交数据。 | `rc-same-txn-new-snapshot.md` |
| RC-SELECT-FOR-SHARE-WAIT-RECHECK | C02 | P0 | F01-V12,F02-V12,F03-V02,F04-V01 | SELECT FOR SHARE 等待并发更新结束后重新检查目标行。 | `rc-select-for-share-wait-recheck.md` |
| RC-SELECT-FOR-UPDATE-WAIT-RECHECK | C02 | P0 | F01-V13,F02-V12,F03-V02,F04-V01 | SELECT FOR UPDATE 等待并发更新结束后重检目标行。 | `rc-select-for-update-wait-recheck.md` |
| RC-SELECT-IGNORE-INPROGRESS | C02 | P0 | F01-V14,F02-V10,F03-V04,F04-V01 | 普通 SELECT 不看未提交并发变更。 | `rc-select-ignore-inprogress.md` |
| RC-STATEMENT-SNAPSHOT-BASIC | C01 | P0 | F01-V15,F02-V13,F03-V01,F04-V01 | 每条语句使用语句开始时快照。 | `rc-statement-snapshot-basic.md` |
| RC-UPDATE-FIRST-UPDATER-DELETE-COMMIT-IGNORE | C03 | P0 | F01-V16,F02-V14,F03-V03,F04-V01 | 先事务删除并提交后，等待中的 UPDATE 忽略该目标行。 | `rc-update-first-updater-delete-commit-ignore.md` |
| RC-UPDATE-FIRST-UPDATER-ROLLBACK-PROCEED | C02 | P0 | F01-V17,F02-V15,F03-V02,F04-V01 | 并发更新同一行时，先更新事务回滚后，等待中的 UPDATE 使用原始目标行继续执行。 | `rc-update-first-updater-rollback-proceed.md` |
| RC-UPDATE-WAIT-RECHECK-WHERE-MATCH | C02 | P0 | F01-V18,F02-V16,F03-V02,F04-V01 | UPDATE 等待并发事务结束后重检 WHERE，匹配则继续更新。 | `rc-update-wait-recheck-where-match.md` |
| RC-UPDATE-WAIT-RECHECK-WHERE-NOMATCH | C02 | P0 | F01-V19,F02-V16,F03-V02,F04-V01 | UPDATE 等待并发事务结束后重检 WHERE，不匹配则跳过。 | `rc-update-wait-recheck-where-nomatch.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：19。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。
