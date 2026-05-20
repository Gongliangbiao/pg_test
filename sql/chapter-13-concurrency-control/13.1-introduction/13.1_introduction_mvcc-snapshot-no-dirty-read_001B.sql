-- --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
--
-- --
--  author    : NAME ID
--  create at : 2026-05-20
-- ++
-- --------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------
-- source_md  : docs/case-designs/chapter-13-concurrency-control/13.1-introduction/mvcc-snapshot-no-dirty-read.md
-- factor_md  : docs/test-factors/chapter-13-concurrency-control/13.1-introduction/factor-matrix.md
-- factor_values : F01-V04,F02-V04,F03-V03,F04-V01
-- combination_strategy : concurrency-directed
-- case_id    : MVCC-SNAPSHOT-NO-DIRTY-READ
-- official_chapter : 13.1 Introduction
-- description : 验证并发未提交变更对其他事务不可见
-- version     : 16.x
-- bug         : FEATURE
-- local_or_remote : remote
-- -- restriction  :
-- scheduling  : 9
-- (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
-- -----------------------------------------------------------------------------------------------------------
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET client_min_messages TO warning;

\! echo "-- 1. 等待 S1 持有未提交更新"
\! sh commonScript/get_sync_point.sh mvcc_snapshot_no_dirty_read_s1_to_s2_01
BEGIN;

\! echo "-- 2. S2 读取时不能看到 S1 未提交版本"
SELECT * FROM tab_131_mvcc_snapshot_no_dirty_read ORDER BY id;
\! sh commonScript/set_sync_point.sh mvcc_snapshot_no_dirty_read_s2_to_s1_01

\! echo "-- 3. S1 提交后新语句看到提交后的版本"
\! sh commonScript/get_sync_point.sh mvcc_snapshot_no_dirty_read_s1_to_s2_02
SELECT * FROM tab_131_mvcc_snapshot_no_dirty_read ORDER BY id;
COMMIT;
