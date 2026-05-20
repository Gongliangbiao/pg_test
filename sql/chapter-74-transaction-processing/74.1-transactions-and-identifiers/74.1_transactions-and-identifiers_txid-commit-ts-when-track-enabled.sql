--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : track_commit_timestamp=on 时，提交事务额外在 pg_commit_ts 记录提交时间信息。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-commit-ts-when-track-enabled.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V18,F02-V01,F03-V01,F04-V01
-- combination_strategy: state-transition
-- case_id: TXID-COMMIT-TS-WHEN-TRACK-ENABLED
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. track_commit_timestamp 开启时可查询提交时间；未开启时保留配置观测
DROP TABLE IF EXISTS tab_741_txid_commit_ts_when_track_enabled;
CREATE TABLE tab_741_txid_commit_ts_when_track_enabled (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
SHOW track_commit_timestamp;
BEGIN;
INSERT INTO tab_741_txid_commit_ts_when_track_enabled(id, marker) VALUES (1, 'commit_ts_probe');
SELECT pg_current_xact_id() AS captured_xid \gset
COMMIT;
SELECT current_setting('track_commit_timestamp') AS track_commit_timestamp_setting;
SELECT CASE WHEN current_setting('track_commit_timestamp') = 'on'
            THEN pg_xact_commit_timestamp(:'captured_xid'::xid)
            ELSE NULL
       END AS commit_timestamp_if_enabled;
SELECT * FROM tab_741_txid_commit_ts_when_track_enabled ORDER BY id;
