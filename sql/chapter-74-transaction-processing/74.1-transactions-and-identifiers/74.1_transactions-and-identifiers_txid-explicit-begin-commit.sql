--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : BEGIN 或 START TRANSACTION 显式创建事务，COMMIT 正常结束事务。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-explicit-begin-commit.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V01,F02-V01,F03-V01,F04-V01
-- combination_strategy: state-transition
-- case_id: TXID-EXPLICIT-BEGIN-COMMIT
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 显式事务提交
DROP TABLE IF EXISTS tab_741_txid_explicit_begin_commit;
CREATE TABLE tab_741_txid_explicit_begin_commit (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
BEGIN;
INSERT INTO tab_741_txid_explicit_begin_commit(id, marker, amount) VALUES (1, 'explicit_commit', 11.00);
SELECT * FROM tab_741_txid_explicit_begin_commit ORDER BY id;
COMMIT;
SELECT * FROM tab_741_txid_explicit_begin_commit ORDER BY id;
