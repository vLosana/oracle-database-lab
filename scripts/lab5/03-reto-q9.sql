-- scripts/lab5/03-reto-q9.sql — reto de la Parte D: ¿haría cubriente IX_PED_FECHA para Q9?
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED
SET LINESIZE 200 PAGESIZE 100
EXEC lab_tools.medir.consulta('Q9 ultimos 20', q'[SELECT * FROM tiendasur.pedido ORDER BY fecha_pedido DESC FETCH FIRST 20 ROWS ONLY]')
SELECT segment_name, ROUND(bytes / 1048576, 1) AS mb FROM dba_segments
 WHERE owner = 'TIENDASUR' AND segment_name IN ('PEDIDO', 'IX_PED_FECHA');
EXIT
