--  --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
-- --
--  author      : NAME ID
--  create at   : 2026-05-20
--  feature     : FEATURE
--  version     : 16.x
--  description : 未显式开启事务时，单条失败 SQL 自动作为单语句事务回滚。
--  local_or_remote : local or remote
--  -- restriction :
--  scheduling : 9
--  (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
--  -------------------------------------------------------
-- source_md: docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-implicit-single-stmt-rollback.md
-- factor_md: docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values: F01-V04,F02-V02,F03-V02,F04-V02
-- combination_strategy: state-transition
-- case_id: TXID-IMPLICIT-SINGLE-STMT-ROLLBACK
-- official_chapter: 74.1 Transactions and Identifiers
-- naming: pg-sql-case-naming/v1

SET client_min_messages TO warning;
SET DateStyle TO 'ISO, YMD';

-- 1. 单条失败 SQL 作为单语句事务回滚
DROP TABLE IF EXISTS tab_741_txid_implicit_single_stmt_rollback;
CREATE TABLE tab_741_txid_implicit_single_stmt_rollback (
    id int PRIMARY KEY,
    marker text NOT NULL,
    amount numeric(8,2) DEFAULT 0,
    created_on date DEFAULT DATE '2026-05-20'
);
INSERT INTO tab_741_txid_implicit_single_stmt_rollback(id, marker, amount) VALUES (1, 'kept', 14.00);
SELECT * FROM tab_741_txid_implicit_single_stmt_rollback ORDER BY id;
INSERT INTO tab_741_txid_implicit_single_stmt_rollback(id, marker, amount) VALUES (1, 'duplicate_error', 99.00);
SELECT * FROM tab_741_txid_implicit_single_stmt_rollback ORDER BY id;
