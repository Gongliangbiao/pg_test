# LOCK-FK-CHILD-INSERT-PARENT-KEY-SHARE

## 来源声明
- source_type: local-knowledge
- source_ref: 本地锁知识目录与用户补充的 PostgreSQL 锁相关扩展测试点
- source_note: 该目录不是 PostgreSQL 官方 Chapter 13 章节；13.8 是项目内扩展编号，用于承载本地知识补充测试点。


## 所属扩展目录
本地知识补充：13.8.2 Constraints And Key Locks

## 来源依据摘要
子表插入外键引用时，需要确认父表 key 存在，并与父表 key 的删除/修改形成锁协调。

## 来源因子
- factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.8-lock-knowledge-extensions/13.8.2-constraints-and-key-locks/factor-matrix.md
- factor_values: F01-V02,F02-V02,F03-V01,F04-V02
- combination_strategy: single-factor

## 测试点
子表插入外键引用时，需要确认父表 key 存在，并与父表 key 的删除/修改形成锁协调。

## 覆盖类型
正向

## 重要边界
- 被测对象/语句：DELETE / INSERT / LOCK。
- 触发状态/条件：常规事务状态转换。
- 边界或异常：常规核心路径。
- 本测试点只验证一个主要并发语义，不与相邻章节测试点合并。

## 测试必要性
core

## 标记理由
P0 测试点；用于覆盖本地知识补充 13.8.2 Constraints And Key Locks 中的 子表插入外键引用时，需要确认父表 key 存在，并与父表 key 的删除/修改形成锁协调。

## 备注
来源：docs/archive/concurrency-control-by-official-chapter/13.8-lock-knowledge-extensions/13.8.2-constraints-and-key-locks/lock-fk-child-insert-parent-key-share.md