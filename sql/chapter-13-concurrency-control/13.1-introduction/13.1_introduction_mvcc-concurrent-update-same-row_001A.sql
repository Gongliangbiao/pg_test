-- --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
--
-- --
--  author    : NAME ID
--  create at : 2026-05-20
-- ++
-- --------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------
-- source_md  : docs/case-designs/chapter-13-concurrency-control/13.1-introduction/mvcc-concurrent-update-same-row.md
-- factor_md  : docs/test-factors/chapter-13-concurrency-control/13.1-introduction/factor-matrix.md
-- factor_values : F01-V01,F02-V01,F03-V01,F04-V01
-- combination_strategy : concurrency-directed
-- case_id    : MVCC-CONCURRENT-UPDATE-SAME-ROW
-- official_chapter : 13.1 Introduction
-- description : 验证同一行并发更新最终只暴露一致版本
-- version     : 16.x
-- bug         : FEATURE
-- local_or_remote : remote
-- -- restriction  :
-- scheduling  : 9
-- (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
-- -----------------------------------------------------------------------------------------------------------
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET client_min_messages TO warning;

\! sh commonScript/del_sync_points.sh mvcc_concurrent_update_same_row
DROP TABLE IF EXISTS tab_131_mvcc_concurrent_update_same_row;
CREATE TABLE tab_131_mvcc_concurrent_update_same_row (id int PRIMARY KEY, version_no int NOT NULL, owner_note text NOT NULL);
INSERT INTO tab_131_mvcc_concurrent_update_same_row VALUES (1, 0, 'initial');
BEGIN;
UPDATE tab_131_mvcc_concurrent_update_same_row SET version_no = 1, owner_note = 's1_uncommitted' WHERE id = 1;
\! sh commonScript/set_sync_point.sh mvcc_concurrent_update_same_row_s1_to_s2_01
\! sh commonScript/replica_query_simple.sh "select count(*) from pg_stat_activity where query like 'UPDATE tab_131_mvcc_concurrent_update_same_row%' and state = 'active' and wait_event_type is not null and query not like '%pg_stat_activity%'" 1 1
COMMIT;
\! sh commonScript/set_sync_point.sh mvcc_concurrent_update_same_row_s1_to_s2_02
