# Lab 4 · Oracle DBA Workflow I — Respuestas

- Nombre y apellidos: Vicente Losana Moreno
- Usuario en GitHub: vLosana
- Issue: Oracle DBA Workflow I: back up, fix and x-ray the Oracle instance #6
- Fecha: 25 Octubre de 2026

## Punto de control — Parte B

En el paso 3 del backup salieron 0 archivos FUERA y en el paso 6 aparece «ninguno»; además, el manifiesto indica archivos_fuera_del_volumen=0. Los datafiles de negocio, el SPFILE y el password file aparecen con ruta $ORACLE_HOME/dbs/..., pero esa carpeta es un enlace simbólico a /opt/oracle/oradata/dbconfig/FREE/dbs, que está en el volumen. readlink -f resuelve el enlace y por eso salen «dentro». Aun así, estaban en una carpeta que no es la estándar y dependían de ese enlace, por eso se movieron igualmente en la Parte C. Evidencia: script/20261025T172709Z_00-backup-lab3.script.log (apartado 3 y paso 6), manifiesto.txt de la copia y script/20261025T173443Z_01-diagnostico.script.log (última línea).

## Preguntas de comprobación

### 8.1.1. Respaldo

**1. ¿Por qué la copia de la Parte B es consistente? ¿Qué pasaría si se tomara con la base abierta?**

La copia es consistente porque la base se cerró limpiamente antes de copiar el volumen. backup-estado.sh ejecuta SHUTDOWN IMMEDIATE, realiza el checkpoint final y después se detiene el contenedor; luego se copia el volumen, por lo que los datafiles quedan con el mismo SCN y no hace falta aplicar redo. La evidencia está en 00-backup-lab3.script.log, pasos 4 y 5. Si se copiara con la base abierta, Oracle podría estar escribiendo en los archivos y la copia podría quedar inconsistente; necesitaría recuperación y no bastaría con copiar el volumen tal cual.

**2. ¿Para qué sirven manifiesto.txt y SHA256SUMS? ¿Qué comprueba restaurar-estado.sh antes de tocar nada?**

manifiesto.txt describe la copia: etiqueta, fecha, contenedor, volumen, imagen, commit de Git y tipo de copia. SHA256SUMS contiene las huellas de los archivos para comprobar que no se han alterado; en la prueba B.3 los cuatro archivos dieron OK. Antes de restaurar, restaurar-estado.sh ejecuta sha256sum --check y, después, pide confirmar el nombre del volumen antes de borrarlo. Evidencia: manifiesto de la copia y prueba B.3; script restaurar-estado.sh.

**3. Define RPO y RTO con los datos de tu propia copia.**

El RPO indica hasta qué momento se pueden recuperar los datos y, por tanto, cuánto trabajo posterior se podría perder. Si restauro backups/20261025T172711Z_lab3-final, vuelvo al estado de las 17:27 UTC y pierdo los cambios posteriores, como la reubicación de datafiles, V003, V002 y la cuenta C##OPS_RO. El RTO es el tiempo necesario para volver a dar servicio; en este laboratorio la restauración no se ejecutó, así que no tengo una medición exacta. Como referencia, la base estuvo parada unos dos minutos durante la copia y quedó saludable a los 10 segundos del arranque. Evidencia: manifiesto.txt de la copia y 00-backup-lab3.script.log.

### 8.1.2. Diagnóstico y correcciones

**4. ¿Dónde creó Oracle los datafiles de V000 y por qué? ¿Qué parámetro habría evitado el problema?**

Oracle creó los datafiles de V000 en $ORACLE_HOME/dbs, concretamente en /opt/oracle/product/26ai/dbhomeFree/dbs/academia01.dbf (FILE# 16 a 20). La ruta indicada en V000 era relativa (academia01.dbf) y db_create_file_dest estaba vacío, así que Oracle resolvió la ruta desde ese directorio. Se habría evitado configurando DB_CREATE_FILE_DEST para usar OMF o indicando una ruta absoluta dentro del volumen. Evidencia: 01-diagnostico.script.log, apartados 4 y 5.

**5. ¿Por qué ALTER TABLESPACE ... RENAME DATAFILE no basta para mover un archivo?**

Porque la sentencia solo cambia la ruta que Oracle guarda en el control file; no mueve los bytes del archivo en el sistema operativo. Primero hay que poner el tablespace OFFLINE, copiar el archivo, ejecutar RENAME DATAFILE, volver a ponerlo ONLINE y comprobar que Oracle lo reconoce. En Oracle Free no está disponible el movimiento online mediante ALTER DATABASE MOVE DATAFILE. Evidencia: 03-reubicar-datafiles.script.log.

**6. ¿Por qué no se edita V000 y se crea V003? ¿Por qué invalidar una contraseña es mejor que borrarla del archivo?**

No se edita V000 porque una migración ya aplicada forma parte del historial; modificarla impediría reproducir exactamente lo que se ejecutó. Además, borrar una contraseña del archivo no la elimina del historial de Git. Por eso V003 cambia las cuentas a NO AUTHENTICATION, haciendo que la contraseña antigua deje de servir; la prueba devolvió ORA-01017. Evidencia: V000, línea 7, y spool/20261025T173756Z_04-V003__cuentas_esquema_sin_password.spool.log, donde las cinco cuentas ADMIN_* aparecen con AUTHENTICATION_TYPE = NONE.

**7. ¿Qué demuestra la prueba de persistencia y por qué se ejecuta después de reubicar?**

Demuestra que la base sigue funcionando después de borrar y recrear el contenedor, porque los archivos importantes están guardados en el volumen y no en la capa del contenedor. Antes y después aparecen los mismos cinco tablespaces ONLINE y las mismas tablas, aunque cambió el ID del contenedor de 7104f99a8e29 a 9fed918b8b34. Se hace después de reubicar para comprobar que los datafiles están en el volumen y no se pierden al eliminar el contenedor. Evidencia: 03-prueba-persistencia.script.log.

### 8.1.3. Instancia y arranque

**8. Con tus evidencias: tres datos que pertenecen a la instancia y tres que pertenecen a la base de datos.**

De la instancia puedo señalar el HOST_NAME (9fed918b8b34), el STARTUP_TIME (2026-10-25 17:43:02) y sus procesos y memoria en uso (62 procesos de background y 2,09 GiB según docker stats). De la base de datos, el DBID es 1509902213, la fecha CREATED es 2026-07-05 y tiene 16 datafiles, 3 tempfiles, 3 miembros de redo y 2 control files; está en modo ARCHIVELOG. Evidencia: spool/20261025T175440Z_05-instancia-y-base.spool.log y 05-instancia-so.script.log.

**9. ¿Qué lee Oracle en NOMOUNT, en MOUNT y en OPEN? Relaciónalo con ORA-01507 y ORA-01219.**

En NOMOUNT, Oracle lee el SPFILE, reserva la SGA y arranca los procesos; por eso se puede consultar v$parameter, pero v$database devuelve ORA-01507 porque necesita el control file, que todavía no se ha leído. En MOUNT, abre los control files y conoce los datafiles y el modo de archivo, pero las vistas del diccionario como DBA_TABLES dan ORA-01219 porque el diccionario está en el tablespace SYSTEM, cuyo datafile todavía está cerrado. En OPEN, abre los datafiles y los redo online y la base queda disponible. Evidencia: 06-arranque-por-etapas.script.log.

**10. ¿Por qué FREEPDB1 se abre sola tras ALTER DATABASE OPEN? ¿Qué harías si no lo hiciera?**

FREEPDB1 se abre sola porque tiene guardado su estado de apertura: DBA_PDB_SAVED_STATES muestra FREEPDB1 / FREE / OPEN. Si no se abriera, ejecutaría ALTER PLUGGABLE DATABASE FREEPDB1 OPEN; y después ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE; para conservar ese estado en futuros arranques. La evidencia está en 06-arranque-por-etapas.script.log, bloque 4.

**11. Clasifica ORA-00800 y ORA-20013 del alert log: ¿alerta real o ruido conocido? Justifícalo.**

ORA-00800 [Set Priority Failed] para VKTM y LGWR es un aviso conocido del contenedor: Oracle intenta subir la prioridad de los procesos, pero no puede porque falta CAP_SYS_NICE. Aparece en los dos arranques y la base abre con normalidad, así que en este caso se documenta como ruido conocido, sin ignorarlo sin más. ORA-20013 de DBMS_QOPATCH no aparece en la ventana del alert log revisada. También se registraron ORA-27300 a ORA-27303 una sola vez antes del arranque del contenedor recreado y no volvieron a aparecer. Evidencia: script/20261025T180210Z_06-alert-log.script.log.

### 8.1.4. Parámetros

**12. Diferencia entre v$parameter y v$spparameter con el ejemplo de db_files de tu evidencia.**

v$parameter muestra el valor que está usando la instancia en ese momento, mientras que v$spparameter muestra lo guardado en el SPFILE para el arranque. En la prueba, cambiar db_files a 300 con SCOPE=MEMORY falló con ORA-02095 porque es un parámetro estático. Con SCOPE=SPFILE, el valor 200 siguió activo en memoria y 300 quedó guardado para el próximo arranque; después, RESET dejó el parámetro sin especificar en el SPFILE. Evidencia: script/20261025T180452Z_07-parametros-cambios.script.log.

**13. ¿Qué hace SCOPE=BOTH y cuál es el SCOPE por defecto con SPFILE?**

SCOPE=BOTH cambia el parámetro tanto en memoria como en el SPFILE, así que el cambio se aplica y además se conserva tras reiniciar. En la prueba, open_cursors quedó en 500 en ambos sitios. Si la instancia arranca con SPFILE, el valor por defecto es BOTH; si arranca con PFILE, es MEMORY. Evidencia: 07-parametros-cambios.script.log y spool/20261025T180423Z_07-parametros-lectura.spool.log.

**14. ¿Por qué PROCESSES rechaza el cambio en memoria aunque v$parameter lo marque IMMEDIATE?**

Aunque processes aparece con SYS_MOD = IMMEDIATE, el intento de cambiarlo en memoria falla con ORA-02097 y ORA-02095. En la práctica, este parámetro necesita reiniciar la instancia porque dimensiona estructuras que se reservan al arrancar. Por eso se cambia con SCOPE=SPFILE y se reinicia. Evidencia: 07-parametros-lectura.spool.log y 07-parametros-cambios.script.log.

**15. ¿Para qué sirve versionar el PFILE? Explica «configuration drift».**

Versionar el PFILE permite tener una copia legible de la configuración y comparar cambios con git diff. La configuration drift o deriva de configuración ocurre cuando el estado real cambia y deja de coincidir con lo documentado o versionado. Además, si un cambio guardado en el SPFILE impide arrancar, se puede iniciar con un PFILE conocido mediante STARTUP PFILE=... y volver a crear el SPFILE con CREATE SPFILE FROM PFILE. Evidencia: config/initFREE_lab4.ora, config/initFREE_lab4_memoria.ora y 07-pfile.script.log.

### 8.1.5. Memoria y procesos

**16. ¿Qué modelo de gestión de memoria usa tu instancia? Justifícalo con tres parámetros.**

La instancia usa ASMM (Automatic Shared Memory Management). MEMORY_TARGET = 0 indica que no está usando AMM; SGA_TARGET = 1536M permite a Oracle distribuir la memoria de la SGA; y PGA_AGGREGATE_TARGET = 512M configura por separado el objetivo de memoria PGA. Además, PGA_AGGREGATE_LIMIT = 2G marca el límite de la PGA. Evidencia: 08-memoria.spool.log.

**17. Explica las cifras de tu experimento de caché: lecturas lógicas, físicas y tasa de acierto.**

En frío hubo 245 lecturas físicas: 244 bloques de la tabla y uno de cabecera del segmento. En caliente hubo 0 lecturas físicas. En las dos rondas hubo 247 lecturas lógicas; en la segunda ronda, la tasa de acierto fue del 100 % porque los bloques ya estaban en caché. La primera ejecución también tuvo el coste del hard parse, con 463 lecturas lógicas y 258 físicas. Evidencia: script/20261025T181034Z_08-experimento-cache.script.log y script/20261025T181216Z_08-experimento-cache.script.log.

**18. ¿Por qué no se suma el RSS de los procesos para saber la memoria de la instancia?**

No se debe sumar el RSS de los procesos porque cada proceso muestra también memoria de la SGA que comparte con los demás, así que se contaría varias veces. En 09-procesos-so.script.log, cada proceso de background tiene entre 84 y 260 MB de RSS; sumarlos daría más de 5 GB, aunque docker stats muestra 2,09 GiB para todo el contenedor. Para medirlo mejor se usan v$sgainfo/v$sga, v$pgastat o docker stats. Evidencia: 09-procesos-so.script.log y 05-instancia-so.script.log.

**19. Relaciona el SPID de LGWR de v$process con el PID de /proc. ¿Por qué docker top muestra otro número?**

El SPID de LGWR en v$process es 1639; al ejecutar 09-procesos-so.sh 1639, /proc dentro del contenedor muestra ese mismo proceso, db_lgwr_FREE. docker top muestra el PID visto desde el sistema anfitrión, que es diferente por los espacios de nombres de PID. Por ejemplo, PMON aparece con el PID 1589 dentro de Oracle y 21688 en docker top. Evidencia: 09-procesos.spool.log, 09-procesos-so.script.log y 05-instancia-so.script.log.

**20. ¿Qué hace PMON y qué hace SMON? Pon un ejemplo de cada uno.**

PMON (SPID 1589) limpia procesos de usuario que han fallado, deshace su transacción y libera los bloqueos; por ejemplo, si una sesión se cae durante un UPDATE, permite que otras sesiones dejen de esperar por esas filas. SMON (SPID 1645) se encarga, entre otras tareas, de la recuperación de la instancia después de una caída y de limpiar segmentos temporales; por ejemplo, tras un cierre anormal puede intervenir en la recuperación al arrancar. Evidencia: 09-procesos.spool.log.

### 8.1.6. Seguridad y trabajo profesional

**21. ¿Por qué C##OPS_RO y no SYSTEM para observar? ¿Qué no puede hacer C##OPS_RO?**

Uso C##OPS_RO por el principio de mínimo privilegio: para observar el estado de la base no hace falta una cuenta administrativa como SYSTEM. La cuenta tiene CREATE SESSION, SET CONTAINER y SELECT_CATALOG_ROLE, además de CONTAINER_DATA = ALL para consultar información de las PDB desde la raíz. Puede leer vistas del diccionario y vistas V$, pero no puede modificar datos, crear objetos, ejecutar ALTER SYSTEM ni detener la base. Evidencia: 02-cuenta-observabilidad.script.log.

**22. ¿Qué dos vías de exposición de contraseñas corrige este laboratorio respecto al Lab 3?**

La primera es que las contraseñas de los cinco propietarios de esquema estaban escritas literalmente en V000 y permanecían en el historial de Git; V003 las invalida al cambiar las cuentas a NO AUTHENTICATION. La segunda es la contraseña de SYS escrita en la línea de comandos de 08-aplicar-migraciones.sh, donde podía quedar expuesta mediante ps o el historial de la shell; la versión nueva usa autenticación del sistema operativo con / as sysdba. Además, el script de creación ya no pasa ORACLE_PWD al reutilizar el volumen y la contraseña de C##OPS_RO se lee desde config/.env, que no se versiona. Evidencia: V000, línea 7; spool/20261025T173756Z_04-V003__cuentas_esquema_sin_password.spool.log; y las versiones corregidas de 08-aplicar-migraciones.sh y 05-crear-contenedor.sh.

## Preguntas tipo examen

**P1.** A y D. Tras un cierre limpio, todos los archivos tienen el mismo SCN del checkpoint final, no hace falta hacer redo y se abre directamente con STARTUP, también en NOARCHIVELOG.

**P2.** B. En Standard Edition no existe el movimiento online; el método es OFFLINE, copiar, RENAME y ONLINE.

**P3.** A y C. STARTUP_TIME cambia con cada arranque, mientras que CREATED indica cuándo se creó la base de datos.

**P4.** A y C. En NOMOUNT los parámetros ya están en memoria y se puede recrear el control file. Activar ARCHIVELOG y renombrar SYSTEM requieren MOUNT, mientras que consultar DBA_USERS necesita OPEN.

**P5.** B. ALTER DATABASE ARCHIVELOG se ejecuta en estado MOUNT.

**P6.** B. Con SPFILE, el SCOPE por defecto es BOTH.

**P7.** C. PROCESSES es un parámetro de instancia y, desde una PDB, da el error ORA-65040.

**P8.** A y C. STARTUP PFILE arranca con una copia buena y CREATE SPFILE FROM PFILE repara el SPFILE.

**P9.** B. Usa ASMM; DB_CACHE_SIZE funciona como mínimo del buffer cache.

**P10.** A y D. El área de ordenación y la memoria de sesión son privadas. Lo demás está en la SGA.

**P11.** C. LGWR escribe el redo antes de que el COMMIT devuelva el control.

**P12.** B y D. PMON y SMON son obligatorios en cualquier instancia, ARC0 solo existe en modo ARCHIVELOG y RECO arranca siempre.
