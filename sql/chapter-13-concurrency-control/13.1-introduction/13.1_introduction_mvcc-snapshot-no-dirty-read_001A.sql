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

\! sh commonScript/del_sync_points.sh mvcc_snapshot_no_dirty_read

\! echo "-- 1. 创建测试表并插入初始数据"
DROP TABLE IF EXISTS tab_131_mvcc_snapshot_no_dirty_read;
CREATE TABLE tab_131_mvcc_snapshot_no_dirty_read (
    id int PRIMARY KEY,
    visible_value text NOT NULL,
    changed_at timestamp NOT NULL DEFAULT TIMESTAMP '2026-01-01 00:00:00'
);
INSERT INTO tab_131_mvcc_snapshot_no_dirty_read(id, visible_value) VALUES (1, 'committed_value');

\! echo "-- 2. S1 更新目标行但保持未提交"
BEGIN;
UPDATE tab_131_mvcc_snapshot_no_dirty_read
SET visible_value = 'uncommitted_value', changed_at = TIMESTAMP '2026-01-01 00:00:01'
WHERE id = 1;

\! sh commonScript/set_sync_point.sh mvcc_snapshot_no_dirty_read_s1_to_s2_01
\! sh commonScript/get_sync_point.sh mvcc_snapshot_no_dirty_read_s2_to_s1_01

\! echo "-- 3. S1 提交前确认自身可见未提交版本"
SELECT * FROM tab_131_mvcc_snapshot_no_dirty_read ORDER BY id;
COMMIT;

\! echo "-- 4. S1 提交后确认最终状态"
SELECT * FROM tab_131_mvcc_snapshot_no_dirty_read ORDER BY id;
\! sh commonScript/set_sync_point.sh mvcc_snapshot_no_dirty_read_s1_to_s2_02
