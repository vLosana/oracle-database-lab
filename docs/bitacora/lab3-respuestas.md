# Lab 3 — Respuestas de comprobación

Autor: Vicente Losana Moreno · Issue #4

## Docker

### 1. ¿Qué diferencia hay entre una imagen y un contenedor? Usa como ejemplo lo que hiciste en los ejercicios G2 y G4.

La imagen es la plantilla (solo lectura) y el contenedor es lo que se crea y se ejecuta a partir de ella. En G2, al hacer `docker run hello-world`, Docker se bajó la imagen y creó un contenedor (a mí me salió con el nombre `brave_goldberg`) que imprimió el mensaje y se paró; la imagen seguía igual en `docker images`. En G4 hice lo mismo con `alpine:3.20` y el contenedor `prueba`, y luego saqué `prueba2` de la misma imagen, o sea que de una imagen salen los contenedores que quieras.

### 2. En el Ejercicio G5 el archivo nota.txt desapareció y en el G6 no. Explica por qué.

En G5 el archivo lo guardé en `/tmp` dentro del contenedor `prueba`, y eso es temporal: al hacer `docker rm prueba` se fue con el contenedor. Por eso en `prueba2` el `cat` me dio "No such file or directory". En G6 lo guardé en `/datos`, que era el volumen `datos-prueba` montado con `-v`. El volumen está fuera del contenedor, así que aunque el primero se borró (iba con `--rm`), el segundo contenedor seguía viendo "dato importante".

### 3. ¿Qué diferencia hay entre docker ps y docker ps -a, y qué significa STATUS = Exited (0)?

`docker ps` solo enseña los contenedores que están en marcha y `docker ps -a` los enseña todos, también los parados. En G2 `docker ps` me salía vacío y con `-a` aparecía el de hello-world. `Exited (0)` quiere decir que el contenedor ya terminó y que terminó bien (código 0). Si fuese otro número, por ejemplo `Exited (1)`, es que acabó con error.

### 4. En -p 8181:8181, ¿qué número corresponde a tu equipo y cuál al contenedor? ¿Qué pasaría con -p 80:8080 en el ejercicio de nginx?

El primero es el de mi equipo y el segundo el del contenedor. En nginx puse `-p 8080:80` porque nginx escucha en el 80 dentro del contenedor y yo entraba por `localhost:8080`. Si pongo `-p 80:8080` estoy mandando mi puerto 80 al 8080 del contenedor, y ahí nginx no está escuchando, así que la página no cargaría aunque el contenedor esté arrancado.

### 5. ¿Por qué un contenedor de Oracle se queda en marcha y el de hello-world termina solo?

Porque un contenedor dura lo que dura su proceso principal. hello-world solo imprime un mensaje y acaba, así que el contenedor se queda en `Exited (0)` enseguida. En Oracle el proceso principal es la base de datos, que es un servidor y no termina por sí solo, por eso sale `Up ... (healthy)`. Me pasó parecido con `prueba`: estuvo vivo hasta que escribí `exit` y se cerró el `sh`.

### 6. ¿Qué es el digest de una imagen y por qué lo registramos si ya sabemos que usamos :latest?

Es como la huella (un `sha256`) de la imagen: si dos personas tienen el mismo digest tienen exactamente la misma imagen. `:latest` solo es una etiqueta y Oracle la va cambiando a versiones más nuevas, así que no sirve para saber qué versión instalé. Por eso en la evidencia 04 queda guardado mi digest (`sha256:f988b0c0...`), para que se pueda saber la versión exacta aunque `latest` cambie.

### 7. ¿Qué comando borraría realmente los datos de Oracle? ¿Por qué docker rm oralab-26ai no lo hace?

`docker volume rm oralab-26ai-data`, y no tiene vuelta atrás. `docker rm oralab-26ai` solo borra el contenedor, pero los datos de Oracle están en `/opt/oracle/oradata`, que en el script 05 se monta en el volumen con `-v`. El volumen va aparte del contenedor, así que si creo otro contenedor con el mismo volumen la base de datos sigue estando, igual que en el G6.

## Git, organización y evidencia

### 8. ¿Por qué este laboratorio se hace dentro del repositorio oracle-database-lab, con Issue, branch y Pull Request, en vez de en una carpeta aparte?

Porque así todo queda registrado y se puede repetir. Si mañana se me rompe el portátil, con los scripts del repositorio vuelvo a tener el mismo entorno, y el reviewer y el profesor pueden ver los scripts y la salida real en las evidencias en vez de fiarse de que "me funcionó". El Issue (#4 en mi caso) dice qué hay que hacer, la rama evita tocar `main` directamente y el Pull Request hace que alguien lo revise antes de fusionar. En una carpeta aparte nadie más sabría cómo lo instalé.

### 9. ¿Qué diferencia hay entre source 00-config.sh y bash 00-config.sh? ¿Por qué usamos source?

Con `bash 00-config.sh` el script se ejecuta en otro proceso y cuando acaba se pierden las variables. Con `source` se ejecuta en mi terminal, así que `CONT_NAME`, `EVID`, `ts`, etc. se quedan disponibles para los siguientes comandos. Como ese archivo solo define constantes hay que cargarlo con `source`, y repetirlo cada vez que abro una terminal nueva.

### 10. Explica cada parte del nombre 20260915T091230Z_02-docker.script.log.

`20260915T091230Z` es la fecha y la hora: 15/09/2026 a las 09:12:30, y la Z significa que está en UTC (así no depende de la zona horaria y los archivos se ordenan solos por fecha). `02` es el número del paso, en este caso el script 02 de Docker. `docker` es la descripción, en minúsculas y con guiones. Y `.script.log` dice que es salida de terminal (si fuese SQL sería `.spool.log` y las capturas `.png`). La mía de ese paso es `20261008T160525Z_02-docker.script.log`, que la hice a las 18:05 de aquí.

### 11. ¿Para qué sirve .gitattributes y qué error evita?

Sirve para que Git guarde los archivos `.sh`, `.sql` y `.md` siempre con final de línea de Linux (LF). Windows usa CRLF y, si un script llega así a Linux o al contenedor, falla con errores raros tipo `$'\r': command not found`. Con el `.gitattributes` da igual desde qué sistema trabaje cada uno, Git lo normaliza.

### 12. ¿Por qué en este Pull Request elegimos Create a merge commit en lugar de Squash and merge?

Porque en este PR cada commit es una Parte del laboratorio y tiene sentido verlos por separado (cuándo se instaló Docker, cuándo se creó el contenedor, etc.). Con squash se quedaría todo en un solo commit y se perdería ese historial. Con merge commit se conservan todos en `main`.

## Seguridad

### 13. Describe las cuatro capas de la estrategia de contraseñas (Parte D) y qué pasaría si te saltas la primera.

1) Añadir `config/.env` al `.gitignore` antes de crear el archivo. 2) Tener una plantilla `config/.env.example` que sí se sube, con valores de ejemplo (`change_me`). 3) Crear el `config/.env` real solo en mi equipo y comprobar con `git check-ignore -v config/.env` que Git lo ignora. 4) No teclear nunca la contraseña: se carga con `set -a; source config/.env; set +a` y en los comandos se usa `$ORACLE_PWD`. Si me salto la primera, el `.env` saldría en `git status` y con un `git add` sin fijarme acabaría en un commit, y de ahí ya no se quita del historial.

### 14. ¿Por qué no escribimos la contraseña directamente en el comando docker run, aunque el script no se suba a Git?

Porque todo lo que se escribe en la terminal se queda guardado en el historial (`~/.bash_history`) en texto plano. Si pongo `-e ORACLE_PWD=LaQueSea` la contraseña queda ahí aunque no llegue a Git, y además saldría en las evidencias que se graban con `script` o `tee`. Usando `"$ORACLE_PWD"` lo único que queda escrito es el nombre de la variable.

### 15. Si descubres tu contraseña en un commit ya publicado, ¿basta con borrarla en un commit nuevo? ¿Qué debes hacer?

No, porque el commit viejo sigue en el historial y se puede ver volviendo atrás. Hay que dar esa contraseña por perdida y cambiarla (aquí sería recrear el contenedor con otra en `config/.env`), no seguir haciendo push y avisar al profesor para limpiar la rama. Por eso antes del push se pasa el `git log -p | grep -c -F "$ORACLE_PWD"`, que tiene que dar 0.

## Oracle y herramientas

### 16. ¿Por qué no usamos SPOOL ni @archivo.sql con sqlplus dentro del contenedor, y qué hicimos en su lugar?

Porque el `sqlplus` que usamos está dentro del contenedor. Un SPOOL guardaría el archivo dentro del contenedor y no en mi repositorio, y con `@archivo.sql` buscaría el archivo dentro del contenedor, donde no está (da SP2-0310). Lo que hice fue pasarle el `.sql` desde mi equipo con `docker exec -i ... < archivo.sql` y guardar la salida con `| tee` (evidencias 07 y 08). Luego con SQLcl, que sí está instalado en mi Ubuntu, ya usé SPOOL normal (evidencia 10).

### 17. ¿Qué hace WHENEVER SQLERROR EXIT SQL.SQLCODE al inicio de V000 y V001, y qué pasaría sin esa línea?

Hace que si una sentencia falla SQL*Plus se pare ahí y salga con el código del error. Sin esa línea seguiría ejecutando lo siguiente aunque algo hubiese fallado, y la base se quedaría a medias (por ejemplo un usuario sin su tablespace). Además así el script 08 se entera del fallo y no aplica V001 si V000 ha ido mal.

### 18. ¿Qué es una migración y por qué V000 y V001 no se deben editar una vez aplicadas?

Una migración es un script SQL numerado que cambia la base de datos de un estado al siguiente, y se aplican en orden (V000, V001...). No se editan después de aplicarlas porque la base ya quedó como decía esa versión: si cambio el archivo, lo que hay en el repositorio ya no coincide con lo que tengo yo ni con lo que tienen mis compañeros. Tampoco se pueden volver a lanzar, porque los usuarios y tablespaces ya existen y daría error. Si hay que cambiar algo se hace una migración nueva.

### 19. ¿Por qué en SQL Developer se usa el servicio FREEPDB1 y no FREE ni un SID?

Porque `FREE` es el contenedor raíz de Oracle (la CDB) y `FREEPDB1` es la base de datos donde se trabaja, que es donde están los 5 esquemas `ADMIN_`. Si entro por `FREE` o por SID acabaría en la raíz, donde no están las tablas. En mi conexión `oralab-26ai-system` puse FREEPDB1 en "Nombre del servicio", y en la evidencia 07 se ve que `SHOW CON_NAME` devuelve FREEPDB1.

### 20. ¿Qué aporta SQLcl frente a SQL*Plus, y por qué un DBA debe dominar ambas?

SQLcl es más cómodo: tiene autocompletado, historial, guarda conexiones (`CONNECT -save`) y con `SET SQLFORMAT ansiconsole` ajusta las columnas solo. Se nota en las evidencias: en la 08 (SQL*Plus) el número de tablas me salía en una línea distinta a la del esquema, y en la 10 (SQLcl) salía todo bien alineado. SQL*Plus es más antiguo pero está en cualquier servidor Oracle, de hecho ya venía en el contenedor. Hay que saber las dos porque no siempre vas a poder instalar SQLcl en el servidor.

## Entorno de trabajo

### 21. ¿Por qué el curso pasa de Git Bash a Ubuntu en WSL 2? Da al menos dos problemas concretos de Git Bash que desaparecen en Ubuntu.

Porque Oracle, Docker y los servidores van sobre Linux y Git Bash solo lo imita. Por ejemplo, Git Bash cambia las rutas tipo `/opt/...` a rutas de Windows y rompe comandos de Docker, y `docker run -it` falla con "not a TTY" (hay que usar winpty o PowerShell). Tampoco trae herramientas como `free`, `ss` o `htop`. En Ubuntu entré al contenedor de alpine con `docker run -it` sin problema, y los scripts usan `free -h` y `ss -tlnp` directamente.

### 22. ¿Por qué clonamos el repositorio en ~/oracle-database-lab y no trabajamos sobre la carpeta de Windows (/mnt/c/...)? ¿Y por qué recomendamos bash frente a zsh para los scripts del curso?

Porque en `/mnt/c` se está pasando todo el rato entre el sistema de archivos de Windows y el de Linux: Git y Docker van mucho más lentos, no se respetan los permisos de Linux y vuelven los problemas de finales de línea. De hecho, la captura que copié desde `/mnt/c` venía con permiso de ejecución y le tuve que hacer `chmod 644`. Y bash porque es la shell que viene por defecto en casi todos los servidores (Ubuntu, Red Hat, Oracle Linux), mientras que zsh normalmente hay que instalarla y tiene pequeñas diferencias. Por eso los scripts empiezan con `#!/usr/bin/env bash`.
