# MVCC-SNAPSHOT-NO-DIRTY-READ

## 来源
- source_test_point: docs/test-points/chapter-13-concurrency-control/13.1-introduction/mvcc-snapshot-no-dirty-read.md
- official_chapter: 13.1 Introduction
- source_factor_matrix: docs/test-factors/chapter-13-concurrency-control/13.1-introduction/factor-matrix.md
- factor_values: F01-V04,F02-V04,F03-V03,F04-V01
- combination_strategy: concurrency-directed

## 测试目标
验证并发未提交变更对其他事务不可见

## 测试类型
并发 / 正向

## 会话数量
2

## 前置条件
- PostgreSQL 16.x。
- 当前用户有创建普通表、序列和视图查询权限。
- 两个会话均使用 READ COMMITTED。

## 表结构设计
- 表名使用 tab_131_mvcc_snapshot_no_dirty_read，列类型按 MVCC 场景选择文本、数值或时间戳字段。

## 测试数据
- 插入单行确定性数据，用于观察提交前后版本变化。

## 执行设计
S1 更新目标行保持未提交；S2 第一次 SELECT 验证不可见未提交版本；S1 提交后 S2 再次 SELECT 验证新语句可见已提交版本。

## 预期结果
- S2 第一次读取返回旧值。
- S1 提交后，S2 第二次读取返回新值。
- 不出现 dirty read。

## SQL 生成约束
- 使用 pg-ab-regression，输出 _001A.sql 和 _001B.sql。
- 不使用 pg_sleep。
- 小数据量验证查询优先使用 SELECT * FROM 表 ORDER BY 主键。
- 只在 setup 阶段清理上次残留对象，不在末尾重复 DROP TABLE。
- 使用 commonScript 同步点协调两个会话。

## 清理策略
setup 阶段清理上次残留对象；用例末尾保留最终状态用于 regression 输出审查。

## 需要 pg-sql 确认的事实
- MVCC visibility
- READ COMMITTED
- UPDATE row lock

## 生成状态
ready
