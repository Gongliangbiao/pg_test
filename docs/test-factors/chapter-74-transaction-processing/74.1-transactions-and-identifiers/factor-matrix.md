# 74.1 Transactions and Identifiers 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 74 Transaction Processing
- source_note: 来源于 PostgreSQL 官方文档 Chapter 74 的测试点计划。


## 官方章节结构
- Chapter 74 Transaction Processing
  - 74.1 Transactions and Identifiers

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 74 Transaction Processing 中 74.1 Transactions and Identifiers 的测试点。测试点来自事务处理测试点计划，并按 pg-doc-extract 规则补充因子、因子值、组合策略和 no-test 说明。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | behavior | 测试行为目标 | 本章节 20 个单一测试点 | P0/P1/P2 | 来自官方章节及已有测试点计划。 | 每个值对应一个最终测试点。 |
| F02 | object | 被测对象或语句 | COMMIT、ROLLBACK、vxid、xid / vxid / diagnostic view、xid、UPDATE / xid、xid8 / xid、COMMIT / xid、PREPARE TRANSACTION / xid / vxid、PREPARE TRANSACTION / xid / diagnostic view | P0/P1/P2 | 从测试点中的 SQL 入口、对象或系统视图抽取。 | 用于确认覆盖对象维度。 |
| F03 | state/condition | 触发状态或条件 | 提交后状态、回滚状态、只读事务状态、常规事务状态转换、首次写入边界 | P0/P1/P2 | 从提交前后、等待、回滚、只读、首次写入等条件抽取。 | 用于组合状态转换。 |
| F04 | boundary/exception/diagnostic | 边界、异常或诊断项 | 常规核心路径、错误/禁止场景、诊断观测、边界值 | P0/P1/P2 | 从错误码、上限、超时、系统视图和高成本环境边界抽取。 | 避免边界被主路径吞并。 |
| F05 | no-test | 不单独生成测试点的说明 | 概念背景、实现解释、重复覆盖或环境成本过高内容 | P3 | 官方章节中不适合独立自动化的描述。 | 记录在“不生成测试点的因子或组合”。 |

## 因子值细化

### F01 测试行为目标
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | TXID-EXPLICIT-BEGIN-COMMIT: BEGIN 或 START TRANSACTION 显式创建事务，COMMIT 正常结束事务。 | normal | P0 | BEGIN 或 START TRANSACTION 显式创建事务，COMMIT 正常结束事务。 | 单一测试点，不与其他主场景合并。 |
| F01-V02 | TXID-EXPLICIT-BEGIN-ROLLBACK: BEGIN 或 START TRANSACTION 显式创建事务，ROLLBACK 放弃事务变更。 | normal | P0 | BEGIN 或 START TRANSACTION 显式创建事务，ROLLBACK 放弃事务变更。 | 单一测试点，不与其他主场景合并。 |
| F01-V03 | TXID-IMPLICIT-SINGLE-STMT-COMMIT: 未显式开启事务时，单条成功 SQL 自动作为单语句事务提交。 | normal | P0 | 未显式开启事务时，单条成功 SQL 自动作为单语句事务提交。 | 单一测试点，不与其他主场景合并。 |
| F01-V04 | TXID-IMPLICIT-SINGLE-STMT-ROLLBACK: 未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。 | normal | P0 | 未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。 | 单一测试点，不与其他主场景合并。 |
| F01-V05 | TXID-VXID-ASSIGNED-FOR-READONLY: 只读事务也具有唯一 VirtualTransactionId。 | normal | P0 | 只读事务也具有唯一 VirtualTransactionId。 | 单一测试点，不与其他主场景合并。 |
| F01-V06 | TXID-VXID-FORMAT-BACKEND-LOCALXID: VirtualTransactionId 由 backendID/localXID 组成，格式可通过 pg_locks.virtualxid 观测。 | normal | P1 | VirtualTransactionId 由 backendID/localXID 组成，格式可通过 pg_locks.virtualxid 观测。 | 单一测试点，不与其他主场景合并。 |
| F01-V07 | TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND: 同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。 | normal | P1 | 同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。 | 单一测试点，不与其他主场景合并。 |
| F01-V08 | TXID-XID-NOT-ASSIGNED-BEFORE-WRITE: 事务只执行读操作时不分配非虚拟 xid。 | normal | P0 | 事务只执行读操作时不分配非虚拟 xid。 | 单一测试点，不与其他主场景合并。 |
| F01-V09 | TXID-XID-ASSIGNED-ON-FIRST-WRITE: 事务第一次写数据库时才分配非虚拟 xid。 | normal | P0 | 事务第一次写数据库时才分配非虚拟 xid。 | 单一测试点，不与其他主场景合并。 |
| F01-V10 | TXID-XID-WRITE-ORDER-NOT-START-ORDER: xid 编号顺序反映首次写入顺序，而不一定反映事务开始顺序。 | normal | P0 | xid 编号顺序反映首次写入顺序，而不一定反映事务开始顺序。 | 单一测试点，不与其他主场景合并。 |
| F01-V11 | TXID-XID-LOWER-WRITES-EARLIER: 较小 xid 的事务先完成首次数据库写入。 | normal | P1 | 较小 xid 的事务先完成首次数据库写入。 | 单一测试点，不与其他主场景合并。 |
| F01-V12 | TXID-XID-GLOBAL-CLUSTER-COUNTER: 非虚拟 xid 来自整个 PostgreSQL cluster 的全局计数器，而不是单库局部计数器。 | normal | P1 | 非虚拟 xid 来自整个 PostgreSQL cluster 的全局计数器，而不是单库局部计数器。 | 单一测试点，不与其他主场景合并。 |
| F01-V13 | TXID-XID-32BIT-TYPE-BOUNDARY: 内部 xid 是 32 位类型，测试设计需覆盖接近 32 位上界的显示、比较或转换边界。 | normal | P1 | 内部 xid 是 32 位类型，测试设计需覆盖接近 32 位上界的显示、比较或转换边界。 | 单一测试点，不与其他主场景合并。 |
| F01-V14 | TXID-XID-WRAPAROUND-EPOCH-INCREMENT: 普通 xid 是 32 位循环空间，超过 2^32 次分配后低 32 位数值会 wraparound 并再次出现；每次 wraparound 时 32 位 epoch 递增，完整逻辑顺序应结合 epoch/xid8 理解。 | normal | P2 | 普通 xid 是 32 位循环空间，超过 2^32 次分配后低 32 位数值会 wraparound 并再次出现；每次 wraparound 时 32 位 epoch 递增，完整逻辑顺序应结合 epoch/xid8 理解。 | 单一测试点，不与其他主场景合并。 |
| F01-V15 | TXID-XID8-NO-INSTALLATION-WRAP: xid8 包含 epoch，在单个 installation 生命周期内不发生 xid 式 wraparound。 | normal | P1 | xid8 包含 epoch，在单个 installation 生命周期内不发生 xid 式 wraparound。 | 单一测试点，不与其他主场景合并。 |
| F01-V16 | TXID-XID8-CAST-TO-XID: xid8 可转换为 xid，测试转换后低 32 位语义和边界表现。 | normal | P1 | xid8 可转换为 xid，测试转换后低 32 位语义和边界表现。 | 单一测试点，不与其他主场景合并。 |
| F01-V17 | TXID-PG-XACT-COMMITTED-MARK: 带非虚拟 xid 的顶层事务提交后，在 pg_xact 中记录 committed 状态。 | normal | P1 | 带非虚拟 xid 的顶层事务提交后，在 pg_xact 中记录 committed 状态。 | 单一测试点，不与其他主场景合并。 |
| F01-V18 | TXID-COMMIT-TS-WHEN-TRACK-ENABLED: track_commit_timestamp=on 时，提交事务额外在 pg_commit_ts 记录提交时间信息。 | normal | P1 | track_commit_timestamp=on 时，提交事务额外在 pg_commit_ts 记录提交时间信息。 | 单一测试点，不与其他主场景合并。 |
| F01-V19 | TXID-GID-ASSIGNED-FOR-PREPARED: prepared transaction 除 vxid、xid 外，还具有 GID。 | normal | P0 | prepared transaction 除 vxid、xid 外，还具有 GID。 | 单一测试点，不与其他主场景合并。 |
| F01-V20 | TXID-GID-MAPPED-IN-PG-PREPARED-XACTS: pg_prepared_xacts 可查看 GID 到 xid 的映射关系。 | normal | P0 | pg_prepared_xacts 可查看 GID 到 xid 的映射关系。 | 单一测试点，不与其他主场景合并。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | COMMIT | normal | P1 | 来自 TXID-COMMIT-TS-WHEN-TRACK-ENABLED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V02 | ROLLBACK | normal | P0 | 来自 TXID-IMPLICIT-SINGLE-STMT-ROLLBACK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V03 | vxid | normal | P0 | 来自 TXID-VXID-ASSIGNED-FOR-READONLY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V04 | xid / vxid / diagnostic view | normal | P1 | 来自 TXID-VXID-FORMAT-BACKEND-LOCALXID 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V05 | xid | normal | P1 | 来自 TXID-XID-32BIT-TYPE-BOUNDARY 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V06 | UPDATE / xid | normal | P1 | 来自 TXID-XID-LOWER-WRITES-EARLIER 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V07 | xid8 / xid | normal | P1 | 来自 TXID-XID8-CAST-TO-XID 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V08 | COMMIT / xid | normal | P1 | 来自 TXID-PG-XACT-COMMITTED-MARK 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V09 | PREPARE TRANSACTION / xid / vxid | normal | P0 | 来自 TXID-GID-ASSIGNED-FOR-PREPARED 的被测对象。 | 作为测试点对象维度参与组合。 |
| F02-V10 | PREPARE TRANSACTION / xid / diagnostic view | normal | P0 | 来自 TXID-GID-MAPPED-IN-PG-PREPARED-XACTS 的被测对象。 | 作为测试点对象维度参与组合。 |

### F03 触发状态或条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 提交后状态 | normal/boundary | P1 | 来自 TXID-COMMIT-TS-WHEN-TRACK-ENABLED 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V02 | 回滚状态 | normal/boundary | P0 | 来自 TXID-IMPLICIT-SINGLE-STMT-ROLLBACK 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V03 | 只读事务状态 | normal/boundary | P0 | 来自 TXID-VXID-ASSIGNED-FOR-READONLY 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V04 | 常规事务状态转换 | normal/boundary | P0 | 来自 TXID-GID-MAPPED-IN-PG-PREPARED-XACTS 的触发条件或状态。 | 作为状态或条件维度参与组合。 |
| F03-V05 | 首次写入边界 | normal/boundary | P0 | 来自 TXID-XID-WRITE-ORDER-NOT-START-ORDER 的触发条件或状态。 | 作为状态或条件维度参与组合。 |

### F04 边界、异常或诊断项
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 常规核心路径 | boundary/exception/diagnostic | P0 | 来自 TXID-GID-MAPPED-IN-PG-PREPARED-XACTS 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V02 | 错误/禁止场景 | boundary/exception/diagnostic | P0 | 来自 TXID-IMPLICIT-SINGLE-STMT-ROLLBACK 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V03 | 诊断观测 | boundary/exception/diagnostic | P1 | 来自 TXID-VXID-FORMAT-BACKEND-LOCALXID 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |
| F04-V04 | 边界值 | boundary/exception/diagnostic | P1 | 来自 TXID-XID8-CAST-TO-XID 的边界、异常或诊断关注项。 | 边界、异常或诊断不合并到主路径描述中。 |

### F05 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 概念性背景、实现解释、重复覆盖或环境成本过高内容 | no-test | P3 | 官方文档中存在但不适合独立自动化的描述。 | 保留不测理由；必要时后续升级为 special 测试点。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | state-transition | F01,F02,F03,F04 | 覆盖 state-transition 类型测试点 | TXID-EXPLICIT-BEGIN-COMMIT、TXID-EXPLICIT-BEGIN-ROLLBACK、TXID-IMPLICIT-SINGLE-STMT-COMMIT、TXID-IMPLICIT-SINGLE-STMT-ROLLBACK、TXID-XID-WRITE-ORDER-NOT-START-ORDER、TXID-XID-LOWER-WRITES-EARLIER、TXID-PG-XACT-COMMITTED-MARK、TXID-COMMIT-TS-WHEN-TRACK-ENABLED、TXID-GID-ASSIGNED-FOR-PREPARED、TXID-GID-MAPPED-IN-PG-PREPARED-XACTS |
| C02 | single-factor | F01,F02,F03,F04 | 覆盖 single-factor 类型测试点 | TXID-VXID-ASSIGNED-FOR-READONLY、TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND、TXID-XID-NOT-ASSIGNED-BEFORE-WRITE、TXID-XID-ASSIGNED-ON-FIRST-WRITE、TXID-XID-GLOBAL-CLUSTER-COUNTER |
| C03 | diagnostic-directed | F01,F02,F03,F04 | 覆盖 diagnostic-directed 类型测试点 | TXID-VXID-FORMAT-BACKEND-LOCALXID |
| C04 | boundary-directed | F01,F02,F03,F04 | 覆盖 boundary-directed 类型测试点 | TXID-XID-32BIT-TYPE-BOUNDARY、TXID-XID-WRAPAROUND-EPOCH-INCREMENT、TXID-XID8-NO-INSTALLATION-WRAP、TXID-XID8-CAST-TO-XID |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| TXID-EXPLICIT-BEGIN-COMMIT | C01 | P0 | F01-V01,F02-V01,F03-V01,F04-V01 | BEGIN 或 START TRANSACTION 显式创建事务，COMMIT 正常结束事务。 | `txid-explicit-begin-commit.md` |
| TXID-EXPLICIT-BEGIN-ROLLBACK | C01 | P0 | F01-V02,F02-V02,F03-V02,F04-V01 | BEGIN 或 START TRANSACTION 显式创建事务，ROLLBACK 放弃事务变更。 | `txid-explicit-begin-rollback.md` |
| TXID-IMPLICIT-SINGLE-STMT-COMMIT | C01 | P0 | F01-V03,F02-V01,F03-V01,F04-V01 | 未显式开启事务时，单条成功 SQL 自动作为单语句事务提交。 | `txid-implicit-single-stmt-commit.md` |
| TXID-IMPLICIT-SINGLE-STMT-ROLLBACK | C01 | P0 | F01-V04,F02-V02,F03-V02,F04-V02 | 未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。 | `txid-implicit-single-stmt-rollback.md` |
| TXID-VXID-ASSIGNED-FOR-READONLY | C02 | P0 | F01-V05,F02-V03,F03-V03,F04-V01 | 只读事务也具有唯一 VirtualTransactionId。 | `txid-vxid-assigned-for-readonly.md` |
| TXID-VXID-FORMAT-BACKEND-LOCALXID | C03 | P1 | F01-V06,F02-V04,F03-V04,F04-V03 | VirtualTransactionId 由 backendID/localXID 组成，格式可通过 pg_locks.virtualxid 观测。 | `txid-vxid-format-backend-localxid.md` |
| TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND | C02 | P1 | F01-V07,F02-V05,F03-V04,F04-V01 | 同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。 | `txid-vxid-local-sequence-per-backend.md` |
| TXID-XID-NOT-ASSIGNED-BEFORE-WRITE | C02 | P0 | F01-V08,F02-V05,F03-V04,F04-V01 | 事务只执行读操作时不分配非虚拟 xid。 | `txid-xid-not-assigned-before-write.md` |
| TXID-XID-ASSIGNED-ON-FIRST-WRITE | C02 | P0 | F01-V09,F02-V05,F03-V04,F04-V01 | 事务第一次写数据库时才分配非虚拟 xid。 | `txid-xid-assigned-on-first-write.md` |
| TXID-XID-WRITE-ORDER-NOT-START-ORDER | C01 | P0 | F01-V10,F02-V06,F03-V05,F04-V01 | xid 编号顺序反映首次写入顺序，而不一定反映事务开始顺序。 | `txid-xid-write-order-not-start-order.md` |
| TXID-XID-LOWER-WRITES-EARLIER | C01 | P1 | F01-V11,F02-V06,F03-V04,F04-V01 | 较小 xid 的事务先完成首次数据库写入。 | `txid-xid-lower-writes-earlier.md` |
| TXID-XID-GLOBAL-CLUSTER-COUNTER | C02 | P1 | F01-V12,F02-V05,F03-V04,F04-V01 | 非虚拟 xid 来自整个 PostgreSQL cluster 的全局计数器，而不是单库局部计数器。 | `txid-xid-global-cluster-counter.md` |
| TXID-XID-32BIT-TYPE-BOUNDARY | C04 | P1 | F01-V13,F02-V05,F03-V04,F04-V04 | 内部 xid 是 32 位类型，测试设计需覆盖接近 32 位上界的显示、比较或转换边界。 | `txid-xid-32bit-type-boundary.md` |
| TXID-XID-WRAPAROUND-EPOCH-INCREMENT | C04 | P2 | F01-V14,F02-V07,F03-V04,F04-V04 | 普通 xid 是 32 位循环空间，超过 2^32 次分配后低 32 位数值会 wraparound 并再次出现；每次 wraparound 时 32 位 epoch 递增，完整逻辑顺序应结合 epoch/xid8 理解。 | `txid-xid-wraparound-epoch-increment.md` |
| TXID-XID8-NO-INSTALLATION-WRAP | C04 | P1 | F01-V15,F02-V07,F03-V04,F04-V04 | xid8 包含 epoch，在单个 installation 生命周期内不发生 xid 式 wraparound。 | `txid-xid8-no-installation-wrap.md` |
| TXID-XID8-CAST-TO-XID | C04 | P1 | F01-V16,F02-V07,F03-V04,F04-V04 | xid8 可转换为 xid，测试转换后低 32 位语义和边界表现。 | `txid-xid8-cast-to-xid.md` |
| TXID-PG-XACT-COMMITTED-MARK | C01 | P1 | F01-V17,F02-V08,F03-V01,F04-V01 | 带非虚拟 xid 的顶层事务提交后，在 pg_xact 中记录 committed 状态。 | `txid-pg-xact-committed-mark.md` |
| TXID-COMMIT-TS-WHEN-TRACK-ENABLED | C01 | P1 | F01-V18,F02-V01,F03-V01,F04-V01 | track_commit_timestamp=on 时，提交事务额外在 pg_commit_ts 记录提交时间信息。 | `txid-commit-ts-when-track-enabled.md` |
| TXID-GID-ASSIGNED-FOR-PREPARED | C01 | P0 | F01-V19,F02-V09,F03-V04,F04-V01 | prepared transaction 除 vxid、xid 外，还具有 GID。 | `txid-gid-assigned-for-prepared.md` |
| TXID-GID-MAPPED-IN-PG-PREPARED-XACTS | C01 | P0 | F01-V20,F02-V10,F03-V04,F04-V01 | pg_prepared_xacts 可查看 GID 到 xid 的映射关系。 | `txid-gid-mapped-in-pg-prepared-xacts.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F05-V01 | no-test：概念性背景、实现解释、重复覆盖或环境成本过高内容不单独生成测试点。 | 保留追溯说明；如后续需要，可转为 special 测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：20。
- 每个测试点均回链到 F01-F04 的因子值和组合策略。
- P0/P1 行为、边界、异常和诊断项均进入计划测试点或 no-test 说明。
- 不使用全组合堆叠测试点；按 single-factor、state-transition、boundary-directed、pairwise、risk-based 或 diagnostic-directed 选择组合。