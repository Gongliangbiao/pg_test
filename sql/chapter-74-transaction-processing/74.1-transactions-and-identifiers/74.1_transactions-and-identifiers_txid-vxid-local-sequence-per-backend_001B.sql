-- --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
--
-- --
--  author    : NAME ID
--  create at : 2026-05-20
-- ++
-- --------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------
-- source_md  : docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-vxid-local-sequence-per-backend.md
-- factor_md  : docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values : F01-V07,F02-V05,F03-V04,F04-V01
-- combination_strategy : single-factor
-- case_id    : TXID-VXID-LOCAL-SEQUENCE-PER-BACKEND
-- official_chapter : 74.1 Transactions and Identifiers
-- description : 同一 backend 内 localXID 顺序递增，不同 backend 的本地序列彼此独立。
-- version     : 16.x
-- bug         : FEATURE
-- local_or_remote : remote
-- -- restriction  :
-- scheduling  : 9
-- (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
-- -----------------------------------------------------------------------------------------------------------
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET client_min_messages TO warning;

\! sh commonScript/get_sync_point.sh txid_vxid_local_sequence_per_backend_s1_to_s2_01
BEGIN;
SELECT virtualtransaction AS s2_virtualxid
FROM pg_locks WHERE pid = pg_backend_pid() AND locktype = 'virtualxid'
ORDER BY virtualtransaction LIMIT 1;
\! sh commonScript/set_sync_point.sh txid_vxid_local_sequence_per_backend_s2_to_s1_01
COMMIT;
