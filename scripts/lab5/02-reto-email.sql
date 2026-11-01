-- scripts/lab5/02-reto-email.sql — reto de la Parte C: altura de UX_CLI_EMAIL, calculada frente a medida
ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 200 PAGESIZE 100
ANALYZE INDEX tiendasur.ux_cli_email VALIDATE STRUCTURE;
SELECT name, height, lf_rows, lf_blks, br_rows, br_blks,
       ROUND(lf_rows_len / lf_rows, 1) AS bytes_entrada_hoja,
       ROUND(br_rows_len / br_rows, 1) AS bytes_entrada_rama,
       lf_blk_len, br_blk_len, pct_used
  FROM index_stats;
EXIT
