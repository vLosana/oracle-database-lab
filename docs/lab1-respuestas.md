1\. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository? Da un ejemplo de un archivo pasando por las tres. 

&#x09;Working directory es el espacio donde se crea, edita y elimina el código, la staging area es la bandeja de entrada que organiza los cambios que se van a incluir en el commit y el local repository es la base de datos interna con los commit

2\. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit? Explica por qué.

&#x09;Las modificaciones no aparecerán en el commit

3\. ¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos para solucionarlo? 

&#x09;git status no muestra las carpetas porque no detecta directorios ni carpetas vacías en los archivos

4\. Explica con tus palabras qué es HEAD. 

&#x09;Es una referencia que indica a qué brach pertenezco en el momento

5\. ¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir? ¿Cómo lo comprobamos en la Parte G? 

&#x09;mkdir sirve para crear una carpeta física, git switch -c crea una branch nueva en Git, no debe de crear una carpeta física en el entorno donde estoy trabajando

6\. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Y entre ======= y >>>>>>>? 

&#x09;Muestra las versiones que proviene de una branch A y la otra sobre la branch B, ahora bien, el primer caso es la versión que existe actualmente en mi branch y la otra, la versión de la otra branch

7\. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push? 

&#x09;amend sirve para modificar el identificador Hash del commit. Si ya se ha subido, el historial local y el remoto entran en conflicto.

8\. Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde también el código fuente que está en el disco?

&#x09;Se pierde todo el historial de commits, branchs y toda la configuración, pero todo el entorno físico se mantiene a salvo porque están en el disco duro.

9\. Explica con tus propias palabras la diferencia entre Git y GitHub, sin usar la palabra "nube". 

&#x09;Git es un programa de sistema de control de versiones que se ejecuta en una máquina sin necesidad de internet, mientras que GitHub es una plataforma web que aloja estos repositorios que hemos creado en Git y permite la colaboración de los mismos.

10\. ¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque el repositorio sea privado? 

&#x09;Porque cualquier persona con el acceso al historial de commits podrá extraer las contraseñas.

11\. Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con 'non-fastforward'". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?

&#x09;El repositorio remoto contiene cambios más recientes que no se han descargado, para ello se debe de ejecutar git pull o git pull -rebase

12\. ¿Qué tipo de Conventional Commit (feat, fix, docs, test…) usarías para: añadir un índice de rendimiento a una tabla, corregir una restricción mal definida, y actualizar el README? 

&#x09;Añadir un índice de rendimiento a una tabla: feat

&#x09;Corregir una restricción mal definida: fix

&#x09;Actualizar el README: docs



