# Tipos de ataque Injeccion SQL.

## Denegacion de servicio.
La denegacion de servicio consta en el borrado sea de las columnas, tablas o la entera base de datos. Aqui no se busca conseguir informacion, si no puramente hacer daño. Ejemplo:

* User ID: ' ; DROP TABLE USER; --
* Password: ' OR ''='

### Como se veria la consulta en el motor:
SELECT UserID from USER WHERE UserID = ' ';DROP TABLE USER; -- ' and PWD =''OR ''=''

### ¿Que hace cada parte de la injeccion?:
1. "'" La primera comilla cierrra el string que abrio la aplicacion, bypasseando el contexto del dato para entrar al context SQL
2.  "; DROP TABLE USER" El punto y coma cierra la primera consulta e abre la nuestra, con la instruccion de borrar toda la tabla USER
3. "--" Es un comentario en SQL. Todo lo que viene despues es ignorado por el motor, lo que anula el resto de la consulta original
4. " ' OR ''=' " Si el drop llegara a no funcionar, esta condicion siempre es Verdadera, lo que permitiria saltarse la autentificacion.

## Exploracion y manipulacion de contenido:
Nosotros podemos materializar la SQL Injection y una vez dentro de la Base de datos hacer consultas y modificar las tablas, la pagina para hacer defacing, o distribuir malware. (Esto ultimo asumiendo que tenemos permisos de "sa" o quizas incluso de "bd_owner").

Ejemplo:
En el caso hipotetico de que nosotros descubramos un nombre de usuario, podemos bypassear la contraseña, aun si la escribimos erroneamente, al explotar una falla del lenguaje.

* Login : Admin (nombre de usuario existente en la base de datos)
* Contraseña: .....' or 1=1 #'

Como la contraseña es incorrecta, pero el OR statement es verdadero, MySQL va a pasar la contraseña como verdadera y darmos acceso al sistema. El "#", es para que la comilla abierta del final quede como un comentario, para que el motor no piense que la comilla extra que nosotros añadimos es codigo sin cerrar. 

