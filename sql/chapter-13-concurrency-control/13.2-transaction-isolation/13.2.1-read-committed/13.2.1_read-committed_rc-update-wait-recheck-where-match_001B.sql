-- --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
--
-- --
--  author    : NAME ID
--  create at : 2026-05-18
-- ++
-- --------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------
-- source_md  : docs/case-designs/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/rc-update-wait-recheck-where-match.md
-- factor_md  : docs/test-factors/chapter-13-concurrency-control/13.2-transaction-isolation/13.2.1-read-committed/factor-matrix.md
-- factor_values : F01-V01,F02-V01,F03-V01,F04-V01,F05-V01,F06-V01,F07-V01,F07-V02
-- combination_strategy : state-transition + diagnostic
-- case_id    : RC-UPDATE-WAIT-RECHECK-WHERE-MATCH
-- official_chapter : 13.2.1 Read Committed Isolation Level
-- description : 验证 READ COMMITTED 下 UPDATE 等待后重检 WHERE 且匹配继续更新
-- version     : 16.x
-- bug         : FEATURE
-- local_or_remote : remote
-- -- restriction  :
-- scheduling  : 9
-- (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
-- -----------------------------------------------------------------------------------------------------------
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET client_min_messages TO warning;

\! echo "-- 1. 等待 S1 持有目标行锁"
\! sh commonScript/get_sync_point.sh rc_update_wait_recheck_where_match_s1_to_s2_01
SHOW transaction_isolation;
BEGIN;
\! sh commonScript/set_sync_point.sh rc_update_wait_recheck_where_match_s2_to_s1_01

\! echo "-- 2. 执行 UPDATE，等待 S1 提交后重检 WHERE"
UPDATE tab_1321_rc_update_wait_recheck_where_match
SET note = 's2_rechecked',
    hit_count = hit_count + 1
WHERE flag IS TRUE;

\! echo "-- 3. S2 提交前确认自身更新结果"
SELECT *
FROM tab_1321_rc_update_wait_recheck_where_match
ORDER BY id;

\! echo "-- 4. S2 提交并验证最终状态"
COMMIT;

SELECT *
FROM tab_1321_rc_update_wait_recheck_where_match
ORDER BY id;

\! sh commonScript/set_sync_point.sh rc_update_wait_recheck_where_match_s2_to_s1_02
