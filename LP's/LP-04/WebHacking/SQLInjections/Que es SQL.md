## ¿Que es SQL?
 SQL, o Structure Query Language, es un lenguaje de programacion estandar
 interactivo que sirve para la alteracion de la informacion de una base de datos.

## Origen
Se origina en las bases de datos relacionales de PC o movil. En 1970, IB; se basa en estas ideas y define al lenguaje SEQUEL (Structured English Query Language) que luego es ampliamente adpotado por los [SGBD](../../Glosario.md). Casi en la decada de los 80, Oracle lo introduce comercialmente.
En 1986, el Instituto Nacional Estadounidense de Estandares toma a SEQUEL y crea SQL1, o SQL86, y un año despues el mismo es adpotado por la Organizacion Internacional de Estandares para crear SQL2. Desde ese punto el lenguaje fue evolucionando.


## ¿Para que sirve?
SQL explora la flexibilidad y la potencia de los sistemas relacionales. Permite gran variedad de operaciones. Es un lenguaje declarativo de alto nivel y de no procesamiento. Gracias a que su fuerte es una base teorica y que su orientacion es el manejo de conjunto de los registros es, hasta cierto punto, efectivo en P.O.O

## ¿Porque hacer una SQL Injection?
Normalmente, las motivaciones para hacer una SQL Injection son las siguientes:
1. Defacing o hacktivismo:
    * El defacing consta en atacar una pagina web y modificar los datos para alterar la apariencia visual o contenido, normalmente la principal. Se lo conoce como vandalismo digital, ya que se altera para mostrar imagenes, mensajes o firmas del atacante

    ![Ejemplo](https://blog.sucuri.net/wp-content/uploads/2023/03/hacked_by.png)

2. Robo de datos personales:
    * El atacante apunta a robar datos del usuario o usuarios finales, como puede ser el nnombre, direccion, codigo postal, registros pedicos, preferencias sexuales, creencias religiosas etc. Una forma mas extrema de esto es el Carding, robo de informacion financiera, digase numeros de cuenta, pin, fecha de vencimiento y o clonacion de tarjetas.

3. Pivot a sistemas internos:
    * Son ataques mas complejos que apuntan a dañar la infraestructura del sistema, accediendo a sistemas que podrian no ser accesibles desde la red. Se pueden llegar a robar usuarios, contraseñas de red, etc. Un ejemplo de esto es que se encuentre una terminal en la misma red que el objetivo, pero mas vulnerable, y empezar a construir el ataque desde otro angulo.