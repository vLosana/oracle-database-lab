-- scripts/lab5/01-reto-bfr.sql — reto de la Parte B: filas por bloque de PEDIDO, medidas con DBMS_ROWID
ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 200 PAGESIZE 100
PROMPT ===== 1. Filas por bloque de PEDIDO, contadas bloque a bloque (DBMS_ROWID) =====
SELECT COUNT(*)             AS bloques_con_filas,
       MIN(filas)           AS minimo,
       ROUND(AVG(filas), 1) AS media,
       MAX(filas)           AS maximo
  FROM (SELECT DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE') AS bloque, COUNT(*) AS filas
          FROM tiendasur.pedido
         GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'));
PROMPT ===== 2. Los recuentos mas frecuentes: cuantos bloques tienen N filas =====
SELECT filas, COUNT(*) AS bloques
  FROM (SELECT COUNT(*) AS filas
          FROM tiendasur.pedido
         GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'))
 GROUP BY filas
 ORDER BY bloques DESC FETCH FIRST 6 ROWS ONLY;
PROMPT ===== 3. Lo que dice el diccionario (DBMS_STATS) =====
SELECT num_rows, blocks, ROUND(num_rows / blocks, 1) AS bfr_diccionario, avg_row_len
  FROM dba_tables
 WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO';
PROMPT ===== 4. Que pedidos viven en los bloques con 196 filas o mas =====
SELECT MIN(id_pedido) AS primer_id, MAX(id_pedido) AS ultimo_id, COUNT(*) AS filas
  FROM tiendasur.pedido
 WHERE DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE') IN
       (SELECT DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE') FROM tiendasur.pedido
         GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE') HAVING COUNT(*) >= 196);
EXIT
