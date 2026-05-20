# 13.2 Transaction Isolation 测试因子矩阵

## 来源声明
- source_type: official-doc
- source_ref: PostgreSQL 16 Chapter 13 Concurrency Control
- source_note: 来源于 PostgreSQL 官方文档 Chapter 13 的 13.2 Transaction Isolation 章节内容；历史测试点仅作为迁移参考，因子按官方语义空间重新建模。

## 官方章节结构
- Chapter 13 Concurrency Control
  - 13.2 Transaction Isolation

## 官方范围摘要
本矩阵覆盖 PostgreSQL Chapter 13 中 13.2 Transaction Isolation 的总述部分：事务隔离级别、SQL 标准隔离现象、PostgreSQL 对隔离级别的实现差异、默认隔离级别、SET TRANSACTION 的生效边界，以及 sequence/serial 计数器不随事务回滚的特殊行为。13.2.1、13.2.2、13.2.3 子章节的细节由各自矩阵覆盖。

## 因子清单
| 因子ID | 因子类型 | 因子名称 | 有效值/状态/边界 | 优先级 | 官方依据摘要 | 备注 |
|---|---|---|---|---|---|---|
| F01 | parameter | 隔离级别参数 | READ COMMITTED、READ UNCOMMITTED、所有 PostgreSQL 隔离级别 | mixed，详见因子值细化 | 13.2 描述 PostgreSQL 支持的事务隔离级别、默认级别以及 READ UNCOMMITTED 的兼容映射。 | 作为隔离语义和映射类测试点的主维度。 |
| F02 | object | 被测对象或语句 | SELECT、SET TRANSACTION、sequence/serial 计数器 | mixed，详见因子值细化 | 13.2 通过查询可见性、事务模式设置和 sequence/serial 特例说明隔离行为。 | 用于区分普通表可见性、事务配置和非事务对象。 |
| F03 | state/condition | 事务状态或触发条件 | 未显式设置隔离级别、并发事务未提交、事务首条语句前、事务回滚后 | mixed，详见因子值细化 | 13.2 的行为依赖默认事务状态、并发提交状态、SET TRANSACTION 调用时机和 abort/rollback 后状态。 | 用于控制状态转换和边界时机。 |
| F04 | behavior | 隔离语义或行为结果 | 默认 READ COMMITTED、禁止 dirty read、READ UNCOMMITTED 表现为 READ COMMITTED、sequence 变化立即可见且不回滚、SET TRANSACTION 生效边界 | mixed，详见因子值细化 | 13.2 明确描述 PostgreSQL 的隔离级别行为、标准差异和 sequence 特例。 | 每个行为值可与对象、参数、状态组合成测试点。 |
| F05 | boundary/exception | 边界或例外 | dirty read 不可发生、sequence/serial 不遵循事务回滚、SET TRANSACTION 必须在事务内查询或数据修改前设置 | mixed，详见因子值细化 | 官方说明包含禁止现象、非事务对象例外和事务特征设置时机边界。 | 边界/例外必须单独进入测试点或 no-test。 |
| F06 | no-test | 不单独生成测试点的说明 | SQL 标准隔离级别表中由 13.2.1、13.2.2、13.2.3 细化覆盖的现象 | P3 | 13.2 总述中的表格和概念背景部分在子章节中有更具体可测试语义。 | 主节只保留总述和跨级别行为；细节下沉到子章节。 |

## 因子值细化

### F01 隔离级别参数
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F01-V01 | READ COMMITTED | normal | P0 | PostgreSQL 默认事务隔离级别为 READ COMMITTED。 | 默认值和显式值都可用于确认。 |
| F01-V02 | READ UNCOMMITTED | normal/compatibility | P0 | PostgreSQL 中 READ UNCOMMITTED 行为等同 READ COMMITTED。 | 兼容语法与实际语义不同，需要单独验证。 |
| F01-V03 | 所有 PostgreSQL 隔离级别 | normal | P0 | PostgreSQL 所有隔离级别都不允许 dirty read。 | 用于验证禁止 dirty read 的全局语义。 |

### F02 被测对象或语句
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F02-V01 | SELECT 可见性查询 | normal | P0 | 隔离级别通过查询可见性体现。 | 用于 default、dirty read、READ UNCOMMITTED 映射场景。 |
| F02-V02 | SET TRANSACTION | normal/boundary | P1 | SET TRANSACTION 影响当前事务隔离级别等事务特征。 | 必须覆盖调用时机边界。 |
| F02-V03 | sequence/serial 计数器 | special | P0 | sequence 或 serial 计数器变化立即对其他事务可见，且事务 abort 后不回滚。 | 属于非事务对象例外。 |

### F03 事务状态或触发条件
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F03-V01 | 未显式设置隔离级别的新事务 | normal | P0 | 默认事务隔离级别用于未显式设置的事务。 | 默认状态必须单独确认。 |
| F03-V02 | 并发事务存在未提交写入 | condition | P0 | dirty read 关注读取另一个未提交事务写入的可能性。 | 需要两个会话构造提交前可见性。 |
| F03-V03 | 事务内首条查询或数据修改前 | boundary | P1 | SET TRANSACTION 必须在事务中的第一个查询或数据修改语句前执行。 | 是明确时机边界。 |
| F03-V04 | 调用 nextval 后事务回滚 | boundary/special | P0 | sequence/serial 变化不会因事务 abort 回滚。 | 验证回滚后的最终状态。 |

### F04 隔离语义或行为结果
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F04-V01 | 默认隔离级别为 READ COMMITTED | normal | P0 | PostgreSQL 默认隔离级别为 READ COMMITTED。 | 作为后续隔离级别用例入口。 |
| F04-V02 | dirty read 被禁止 | exception/behavior | P0 | PostgreSQL 所有隔离级别都不允许 dirty read。 | 读取未提交数据应不可见。 |
| F04-V03 | READ UNCOMMITTED 表现为 READ COMMITTED | compatibility | P0 | PostgreSQL 中 READ UNCOMMITTED 的行为等同 READ COMMITTED。 | 兼容级别映射。 |
| F04-V04 | sequence/serial 变化立即可见且不回滚 | special | P0 | sequence/serial 变化立即对其他事务可见，且事务 abort 后不回滚。 | 非事务对象例外。 |
| F04-V05 | SET TRANSACTION 的隔离级别生效边界 | boundary | P1 | SET TRANSACTION 对事务隔离级别有调用时机要求。 | 需要验证边界而非只测成功路径。 |

### F05 边界或例外
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F05-V01 | 未提交写入不可被其他事务读取 | exception | P0 | dirty read 不允许发生。 | 反向可见性边界。 |
| F05-V02 | 事务回滚不回退 sequence/serial 计数器 | boundary/special | P0 | sequence/serial 不遵循普通事务回滚语义。 | 回滚后仍能观察到计数器前进。 |
| F05-V03 | SET TRANSACTION 必须在事务内查询或数据修改前设置 | boundary | P1 | SET TRANSACTION 调用时机受限。 | 超过时机后应作为后续设计阶段的异常或边界检查。 |

### F06 不单独生成测试点的说明
| 值ID | 值 | 类型 | 优先级 | 依据 | 边界/异常说明 |
|---|---|---|---|---|---|
| F06-V01 | SQL 标准隔离级别表中的 nonrepeatable read、phantom read、serialization anomaly 细节 | no-test | P3 | 这些现象在 13.2.1、13.2.2、13.2.3 子章节中按更具体语义覆盖。 | 主节不重复生成测试点，避免和子章节交叉。 |

## 组合策略
| 策略ID | 组合方法 | 适用因子 | 目的 | 生成规则 |
|---|---|---|---|---|
| C01 | default-value | F01,F03,F04 | 覆盖默认隔离级别 | READ COMMITTED + 未显式设置隔离级别 + 默认行为。 |
| C02 | boundary-directed | F01,F02,F03,F04,F05 | 覆盖 dirty read 禁止边界 | 所有隔离级别 + SELECT + 并发未提交写入 + 不可见边界。 |
| C03 | equivalence-class | F01,F02,F03,F04 | 覆盖 READ UNCOMMITTED 兼容映射 | READ UNCOMMITTED 作为 READ COMMITTED 等价类代表。 |
| C04 | exception-directed | F02,F03,F04,F05 | 覆盖 sequence/serial 非事务例外 | sequence/serial + nextval 后回滚 + 计数器不回退。 |
| C05 | boundary-directed | F02,F03,F04,F05 | 覆盖 SET TRANSACTION 时机边界 | SET TRANSACTION + 首条查询或数据修改前 + 生效边界。 |

## 计划测试点
| 测试点ID | 来源组合 | 优先级 | 覆盖因子值 | 生成原因 | 输出 test-point 文件 |
|---|---|---|---|---|---|
| ISO-DEFAULT-READ-COMMITTED | C01 | P0 | F01-V01,F03-V01,F04-V01 | 验证未显式设置时默认隔离级别为 READ COMMITTED。 | `iso-default-read-committed.md` |
| ISO-PHENOMENA-DIRTY-READ-PREVENTED | C02 | P0 | F01-V03,F02-V01,F03-V02,F04-V02,F05-V01 | 验证 PostgreSQL 所有隔离级别均不允许读取未提交写入。 | `iso-phenomena-dirty-read-prevented.md` |
| ISO-RU-MAPS-TO-RC | C03 | P0 | F01-V02,F02-V01,F03-V02,F04-V03 | 验证 READ UNCOMMITTED 在 PostgreSQL 中表现为 READ COMMITTED。 | `iso-ru-maps-to-rc.md` |
| ISO-SEQUENCE-NONTRANSACTIONAL | C04 | P0 | F02-V03,F03-V04,F04-V04,F05-V02 | 验证 sequence/serial 计数器变化立即可见，且事务 abort 后不回滚。 | `iso-sequence-nontransactional.md` |
| ISO-SET-TRANSACTION-BEFORE-FIRST-STMT | C05 | P1 | F02-V02,F03-V03,F04-V05,F05-V03 | 验证 SET TRANSACTION 对事务隔离级别的生效时机边界。 | `iso-set-transaction-before-first-stmt.md` |

## 不生成测试点的因子或组合
| 因子/组合 | 原因 | 后续动作 |
|---|---|---|
| F06-V01 | duplicate-covered：SQL 标准隔离现象在 13.2 子章节中已有更细粒度测试点，主节重复生成会造成交叉覆盖。 | 保留追溯说明；在 13.2.1、13.2.2、13.2.3 中继续维护具体测试点。 |

## 覆盖检查
- 本矩阵计划测试点数量：5。
- 每个测试点均回链到真实因子维度，不再使用 `F01 测试行为目标` 作为核心因子。
- P0 覆盖默认隔离级别、dirty read 禁止、READ UNCOMMITTED 映射和 sequence/serial 非事务例外。
- P1 覆盖 SET TRANSACTION 的时机边界。
- SQL 标准隔离现象的细节下沉到 13.2.1、13.2.2、13.2.3，主节通过 no-test 记录避免重复覆盖。
