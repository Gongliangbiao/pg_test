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

\! sh commonScript/del_sync_points.sh rc_update_wait_recheck_where_match

\! echo "-- 1. 创建测试表并插入初始数据"
DROP TABLE IF EXISTS tab_1321_rc_update_wait_recheck_where_match;
CREATE TABLE tab_1321_rc_update_wait_recheck_where_match (
    id int PRIMARY KEY,
    flag boolean NOT NULL,
    note text NOT NULL,
    hit_count int NOT NULL DEFAULT 0,
    CONSTRAINT cons_1321_rc_update_wait_recheck_where_match_hit_nonneg CHECK (hit_count >= 0)
);
INSERT INTO tab_1321_rc_update_wait_recheck_where_match(id, flag, note, hit_count)
VALUES (1, true, 'base', 0);

\! echo "-- 2. S1 更新目标行并持有行锁，但保持 WHERE 条件仍匹配"
SHOW transaction_isolation;
BEGIN;
UPDATE tab_1321_rc_update_wait_recheck_where_match
SET note = 's1_locked'
WHERE id = 1;

\! sh commonScript/set_sync_point.sh rc_update_wait_recheck_where_match_s1_to_s2_01
\! sh commonScript/get_sync_point.sh rc_update_wait_recheck_where_match_s2_to_s1_01

\! echo "-- 3. 等待 S2 的 UPDATE 进入锁等待状态"
\! sh commonScript/replica_query_simple.sh "select count(*) from pg_stat_activity where query like 'UPDATE tab_1321_rc_update_wait_recheck_where_match%' and state = 'active' and wait_event_type is not null and query not like '%pg_stat_activity%'" 1 1

\! echo "-- 4. S1 提交前确认 WHERE 条件仍匹配"
SELECT *
FROM tab_1321_rc_update_wait_recheck_where_match
ORDER BY id;

\! echo "-- 5. 提交 S1，释放行锁"
COMMIT;

\! sh commonScript/get_sync_point.sh rc_update_wait_recheck_where_match_s2_to_s1_02

\! echo "-- 6. S2 完成后确认最终状态"
SELECT *
FROM tab_1321_rc_update_wait_recheck_where_match
ORDER BY id;
