3 Tipos de Neuronas en una Inteligencia Artificial

| Tipo | Función Principal | Ejemplo de Uso |
| :---- | :---- | :---- |
| Perceptrón | Clasificación binaria(si/no) | ¿Es un Gato?¿Es Spam? |
| Neurona Sigmoide | Probabilidad Continua (0 a 1\) | Probabilidad de Lluvia |
| Neurona ReLU | Activación no Lineal (0 o Valor Positivo) | Visión por Computadora |

Perceptron:  
La más simple, tiene muchas entradas, las multiplica por pesos (?), las suma y si superan un Umbral, se activa.

Fórmula matemática:

Salida \= 1 si (w1·x1 \+ w2·x2 \+ ... \+ wn·xn \+ b) \> 0  
Salida \= 0 si no

Representación visual:

      x1 ──► (w1)  
      x2 ──► (w2)    ┌─────────┐  
      x3 ──► (w3) ──►│  SUMA   ├──► ¿≥ umbral? ──► 0 o 1  
      ...            └─────────┘  
      xn ──► (wn)        ▲  
                          b (sesgo)

| Propiedad | Valor |
| :---- | :---- |
| Salida | Binaria |
| Funcion de Activacion | Escalón (step function) |
| Aprendizaje | Regla Delta Simple |
| Limitación | Solo Resuelve Problemas Linealmente |

Le re cuesta la compuerta XOR (no puede hacer sus cálculos)

NEURONA SIGMOIDE (Neurona Logística):  
Es tipo el perceptrón pero no da binario, da un valor continuo, permite expresar "grados de activación" y es derivable (ayuda en el backpropagation).

Fórmula matemática:

σ(z) \= 1 / (1 \+ e^(-z))

donde z \= w1·x1 \+ w2·x2 \+ ... \+ wn·xn \+ b

Representación visual:

Entradas ──► Suma ponderada ──► z ──► f(z) \= 1/(1+e^(-z)) ──► salida (0 a 1\)

Curva sigmoide:

salida  
  1 ──────────────────────\_\_\_\_  
    │                 \_\_─"  
    │             \_\_─"  
    │         \_\_─"  
    │      \_\_─"  
    │  \_\_\_"  
  0 ─────────────────────────────► z

Características:

| Propiedad | Valor |
| :---- | :---- |
| Salida | Continua (entre 0 y 1\) |
| Derivable | Si, Ayuda a Aprender Mejor |
| Interpretación | Probabilidad |
| Rango | 0 a 1 |

¿Para qué sirve?  
Clasificación binaria: La salida se interpreta como probabilidad (ej. 0.85 \= 85% de ser un perro)  
Puertas en redes LSTM: Controla qué información pasa  
Última capa en clasificación binaria

Derivada (importante para backpropagation)

σ'(z) \= σ(z) · (1 \- σ(z))

La derivada se calcula usando la propia salida (buenardo).

NEURONA ReLU (Rectified Linear Unit):  
La neurona más usada hoy en deep learning, es sencilla.  
Si la entrada es negativa, salida 0, si es positiva, sale el mismo valor(?).

Fórmula matemática

ReLU(z) \= max(0, z)  
Representación visual

salida  
   │  
   │  
   │        /  
   │       /  
   │      /  
   │     /  
   │    /  
   │   /  
   │  /  
   │ /  
   │/  
   └────────────────────────────► z  
       0

Características:

| Propiedad | Valor |
| :---- | :---- |
| Salida | 0 o Positivo |
| Derivable | Si, menos en Z=0 |
| Ventaja | No Sufre “Vanishing gradient” |
| Problema | “Neuronas Muertas” si es 0 Siempre |

¿Por qué es tan popular?

Problema con sigmoide \-----\> Solución con ReLU  
Gradientes muy pequeños cuando \------\> z es grande \-----\> Gradiente \= 1 para z \> 0  
Aprendizaje lento en capas profundas \-----\> Aprendizaje rápido  
Mucha computación (exponencial) \------\> Solo max(0, z)

Variantes de ReLU

| Nombre | Fórmula | Característica |
| :---- | :---- | :---- |
| Leaky ReLU | Max (0.01 · z, z) | Permite Pequeños Negativos |
| Parametric ReLU | Max(a · z, z) | a se Aprende |
| ELU | z si z\>0, a(e^z \-1) si z≤0 | Sueva en Negativos |
| Swish | z · sigmoid(z) | Google, Más Suave |

