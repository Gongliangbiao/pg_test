-- --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
--
-- --
--  author    : NAME ID
--  create at : 2026-05-20
-- ++
-- --------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------
-- source_md  : docs/case-designs/chapter-13-concurrency-control/13.1-introduction/mvcc-read-write-nonblocking-update-select.md
-- factor_md  : docs/test-factors/chapter-13-concurrency-control/13.1-introduction/factor-matrix.md
-- factor_values : F01-V03,F02-V03,F03-V02,F04-V01
-- combination_strategy : concurrency-directed
-- case_id    : MVCC-READ-WRITE-NONBLOCKING-UPDATE-SELECT
-- official_chapter : 13.1 Introduction
-- description : 验证写事务不阻塞普通 SELECT
-- version     : 16.x
-- bug         : FEATURE
-- local_or_remote : remote
-- -- restriction  :
-- scheduling  : 9
-- (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
-- -----------------------------------------------------------------------------------------------------------
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET client_min_messages TO warning;

\! sh commonScript/get_sync_point.sh mvcc_read_write_nonblocking_update_select_s1_to_s2_01
BEGIN;
\! echo "-- 普通 SELECT 不等待 S1 的未提交 UPDATE"
SELECT * FROM tab_131_mvcc_read_write_nonblocking_update_select ORDER BY id;
\! sh commonScript/set_sync_point.sh mvcc_read_write_nonblocking_update_select_s2_to_s1_01
\! sh commonScript/get_sync_point.sh mvcc_read_write_nonblocking_update_select_s1_to_s2_02
SELECT * FROM tab_131_mvcc_read_write_nonblocking_update_select ORDER BY id;
COMMIT;
