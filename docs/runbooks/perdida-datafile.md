# Runbook: pérdida de un datafile de aplicación (base en ARCHIVELOG)

## Síntoma
- ORA-01116 / ORA-01110 / ORA-27041: ORA-01116 dice que Oracle no puede abrir el archivo n, ORA-01110 dice cuál es y su ruta, y ORA-27041 con "Linux Error 2" dice la causa: el archivo no existe en el disco.
- Posible ORA-63999 en el alert log: un proceso de fondo detectó el fallo de medio y Oracle cerró solo esa PDB (queda MOUNTED); la CDB y las demás PDB siguen funcionando.

## Comprobaciones previas
- ¿ARCHIVELOG? `ARCHIVE LOG LIST`. Sin ARCHIVELOG no hay redo archivado: RECOVER no puede rehacer lo ocurrido desde la copia, y solo se podría restaurar la base entera perdiendo todo lo posterior.
- ¿Hay copia del archivo? `RMAN> LIST BACKUP OF DATAFILE n;`
- ¿Estado de la PDB? `SELECT name, open_mode FROM v$pdbs;`
- n es el número de archivo que aparece en ORA-01110.

## Camino 1: la PDB sigue en READ WRITE
    ALTER SESSION SET CONTAINER = FREEPDB1;
    ALTER DATABASE DATAFILE n OFFLINE;
    RMAN> RESTORE DATAFILE n;
    RMAN> RECOVER DATAFILE n;
    ALTER DATABASE DATAFILE n ONLINE;

## Camino 2: la PDB está MOUNTED (ORA-63999)
Antes de lanzar RMAN hay que esperar a que v$pdbs diga MOUNTED: si se restaura mientras la PDB se está cerrando, falla con ORA-01089 y luego las consultas dan ORA-01219.

    RMAN> RESTORE DATAFILE n;
    RMAN> RECOVER DATAFILE n;
    ALTER SESSION SET CONTAINER = FREEPDB1;
    ALTER DATABASE DATAFILE n ONLINE;
    ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;

## Cómo verificar que funcionó
- `v$pdbs` en READ WRITE: hasta entonces la aplicación sigue sin servicio; RESTORE y RECOVER sin el OPEN final dejan la PDB cerrada.
- Una fila de control modificada después de la copia sigue ahí: demuestra que RECOVER aplicó el redo posterior y no se perdió nada (RPO 0); en el simulacro fue la fila 104.

## A quién avisar
Al responsable de la aplicación (el servicio estuvo caído y ya está restablecido) y al equipo de sistemas, porque el disco dañado hay que revisarlo o sustituirlo.

## Referencia: simulacro del Lab 5
RTO medido: 9 s desde el fallo (camino 2). RPO: 0.
