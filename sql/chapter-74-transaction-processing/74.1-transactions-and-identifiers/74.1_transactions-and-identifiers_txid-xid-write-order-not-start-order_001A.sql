-- --------------------------------------------------------
--  版权所有(C)  2021-2030 XXX有限公司
--
-- --
--  author    : NAME ID
--  create at : 2026-05-20
-- ++
-- --------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------
-- source_md  : docs/case-designs/chapter-74-transaction-processing/74.1-transactions-and-identifiers/txid-xid-write-order-not-start-order.md
-- factor_md  : docs/test-factors/chapter-74-transaction-processing/74.1-transactions-and-identifiers/factor-matrix.md
-- factor_values : F01-V10,F02-V06,F03-V05,F04-V01
-- combination_strategy : state-transition
-- case_id    : TXID-XID-WRITE-ORDER-NOT-START-ORDER
-- official_chapter : 74.1 Transactions and Identifiers
-- description : xid 编号顺序反映首次写入顺序，而不一定反映事务开始顺序。
-- version     : 16.x
-- bug         : FEATURE
-- local_or_remote : remote
-- -- restriction  :
-- scheduling  : 9
-- (must be serial(1), feature internal serial(3), feature internal parallel(5), unlimited(9); sync point only decided by AB)
-- -----------------------------------------------------------------------------------------------------------
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET client_min_messages TO warning;

\! sh commonScript/del_sync_points.sh txid_xid_write_order_not_start_order
DROP TABLE IF EXISTS tab_741_txid_xid_write_order_not_start_order;
CREATE TABLE tab_741_txid_xid_write_order_not_start_order (id int PRIMARY KEY, writer text NOT NULL, xid_text text);
BEGIN;
\! sh commonScript/set_sync_point.sh txid_xid_write_order_not_start_order_s1_to_s2_01
\! sh commonScript/get_sync_point.sh txid_xid_write_order_not_start_order_s2_to_s1_01
INSERT INTO tab_741_txid_xid_write_order_not_start_order(id, writer, xid_text)
VALUES (1, 's1_first_write', pg_current_xact_id()::text);
SELECT * FROM tab_741_txid_xid_write_order_not_start_order ORDER BY id;
COMMIT;
\! sh commonScript/set_sync_point.sh txid_xid_write_order_not_start_order_s1_to_s2_02
