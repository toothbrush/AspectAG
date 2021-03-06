\documentclass[11pt, a4paper]{article}

%include lhs2TeX.fmt
%include lhs2TeX.sty

\usepackage{cite}
%\usepackage{epigraph}
\usepackage{color}   
\usepackage{hyperref}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{ marvosym }
\usepackage{etoolbox}
\AtBeginEnvironment{tabbing}{\footnotesize}


\hypersetup{
    colorlinks=true,
    linktoc=all,  
    linkcolor=blue,
}

\author{Juan Pablo Garc\'ia Garland}
\title{Reimplementaci\'on de {\tt AspectAG} \\ basada en nuevas
       extensiones de Haskell
}

\setlength\parindent{0pt} % noindent in all file
\usepackage{geometry}
\geometry{margin=1.5in}
\usepackage{graphicx}

\usepackage[nottoc,notlot,notlof]{tocbibind}

\date{}
\renewcommand{\contentsname}{\'Indice}
\renewcommand{\refname}{Bibliograf\'ia}

\begin{document}


\hspace{-0.5cm}
\includegraphics[height=0.11\textheight]{./src/img/udelar_logo.jpg} \hfill
\includegraphics[height=0.10\textheight]{./src/img/logo_FING_rgb.png}  \hfil

{\let\newpage\relax\maketitle}
\maketitle

\begin{center}
  {\large
    Trabajo Final\\
    Licenciatura en Computaci\'on\\
    Facultad de Ingenier\'ia\\
    Universidad de la Rep\'ublica\\
    Orientadores: Alberto Pardo, Marcos Viera\\
    2019
  }
\end{center}


\newpage
\tableofcontents{}

\newpage


\section{Introducci\'on}

AspectAG~\cite{Viera:2009:AGF:1596550.1596586}
es un lenguaje de dominio espec\'ifico embebido\footnote{
  del t\'ermino en ingl\'es \emph{embedded},
  literalmente ``empotrado'' o ``incrustado'',
  pero usualmente traducido con este anglicismo
} (EDSL)
desarrollado en Haskell que permite
la construcción modular de Gram\'aticas de Atributos. En AspectAG
los fragmentos de una Gram\'atica de Atributos son definidos en forma
independiente y luego combinados a trav\'es del uso de operadores de
composici\'on que el propio EDSL provee. AspectAG se basa fuertemente en el
uso de registros extensibles, los cuales son implementados en t\'erminos
de {\tt HList}\cite{Kiselyov:2004:STH:1017472.1017488},
una biblioteca de Haskell que implementa la manipulaci\'on
de colecciones heterog\'eneas de forma fuertemente tipada.
{\tt HList} est\'a implementada utilizando t\'ecnicas de programaci\'on a nivel
de tipos (los tipos son usados para representar valores
a nivel de tipos y las clases de tipos (\emph{typeclasses})
son usadas para representar
tipos y funciones en la manipulación a nivel de tipos).

Desde el momento de la implementaci\'on original de AspectAG hasta
la actualidad
la programaci\'on a nivel de tipos en Haskell ha tenido una evoluci\'on
importante, habi\'endose incorporado nuevas extensiones como
\emph{data promotion} o polimorfismo de kinds, entre otras,
las cuales constituyen elementos fundamentales debido
a que permiten programar de forma ``fuertemente tipada'' a nivel de
tipos de forma similar a cuando se programa a nivel de
valores, algo que originalmente era imposible
o muy dif\'icil de lograr. El uso de estas extensiones permite
una programaci\'on a nivel de tipos m\'as robusta y segura.

En este proyecto implementamos un subconjunto
de la biblioteca original en base a las nuevas extensiones.

\newpage

\paragraph{
Estructura del documento:
}
\begin{itemize}
\item
En la secci\'on \ref{typelevel} se presenta una breve rese\~na de las
t\'ecnicas de programaci\'on a nivel de tipos 
y las extensiones a Haskell que provee el compilador GHC
que las hacen posibles.
Se presentan
las estructuras de listas heterogeneas (\ref{hlist})
y registros heterogeneos (\ref{hrecord}) que
normalmente no ser\'ian implementables en un lenguaje fuertemente tipado
sin tipos dependientes.
\item
En la secci\'on \ref{ags} se presentan las gram\'aticas de atributos
y en particular la implementaci\'on (nueva) de AspectAG mediante un
ejemplo que introduce las primitivas importantes de la biblioteca.
\item
En la secci\'on \ref{impl} se presentan los detalles de la
implementaci\'on, que se basan en las t\'ecnicas  modernas de programaci\'on a
nivel de tipos.
\item
  En la secci\'on \ref{discusion} discuten las contribuciones de la nueva         implementación, en comparaci\'on a la original.
\end{itemize}


\paragraph{
Fuentes y documentaci\'on:
}

\hfill\break
El c\'odigo fuente de la biblioteca y la documentaci\'on
-incluido el presente documento- se encuentra disponible en el repositorio:
\begin{center}
\url{https://gitlab.fing.edu.uy/jpgarcia/AspectAG/}.
\end{center}

La distribuci\'on consiste en un paquete {\tt cabal},
y compila con las versiones modernas de {\tt GHC}\footnote{
  Testeado en {\tt 8.4.4} y {\tt 8.6.3}.
}.
En el directorio {\tt /test} se implementan ejemplos
de utilizaci\'on de la biblioteca.
La versi\'on compilada de la documentaci\'on de los fuentes
se encuentra en la web:

\begin{center}
\url{https://www.fing.edu.uy/~jpgarcia/AspectAG/}
\end{center}


\newpage

\section{Programaci\'on a nivel de tipos en GHC Haskell}
\label{typelevel}
\subsection{Extensiones utilizadas}

\paragraph{T\'ecnicas antiguas}\hfill\break
La biblioteca AspectAG presentada originalmente
en 2009, adem\'as de implementar un sistema de gram\'aticas de atributos
como un EDSL provee un buen ejemplo del uso de la
programaci\'on a nivel de tipos en Haskell.
La implementaci\'on utiliza fuertemente los registros extensibles que provee
la biblioteca {\tt HList}. Ambas bibliotecas se basan en la combinaci\'on
de las extensiones {\tt MultiParamTypeClasses}\cite{type-classes-an-exploration-of-the-design-space}
(hace posible la implementaci\'on de relaciones a nivel de tipos) con\break
{\tt FunctionalDependencies}~\cite{DBLP:conf/esop/Jones00},
que hace posible expresar en particular
relaciones funcionales. Adem\'as se utilizan otras relaciones
que ya eran de uso
extendido como {\tt FlexibleContexts}, {\tt FlexibleInstances},
{\tt UndecidableInstances} etc.

\paragraph{T\'ecnicas modernas}\hfill\break
Durante la d\'ecada pasada\footnote{Algunas extensiones como
{\tt GADTS} o incluso {\tt TypeFamilies} ya exist\'ian en la \'epoca
de la publicaci\'on original de AspectAG, pero eran experimentales,
y de uso poco extendido.} se han implementado m\'ultiples extensiones
en el compilador GHC que proveen herramientas para hacer la programaci\'on
a nivel de tipos m\'as expresiva. A continuaci\'on se enumeran algunas de
estas extensiones, y se proveen referencias a su bibiliograf\'ia.
Las familias de tipos implementadas
en la extensi\'on
{\tt TypeFamilies}\cite{Chakravarty:2005:ATC:1047659.1040306, Chakravarty:2005:ATS:1090189.1086397, Sulzmann:2007:SFT:1190315.1190324}
nos permiten definir funciones a nivel
de tipos de una forma m\'as idiom\'atica que el estilo l\'ogico de la
programaci\'on orientada a relaciones por medio de clases y dependencias
funcionales. La extensi\'on
{\tt DataKinds}~\cite{Yorgey:2012:GHP:2103786.2103795}
implementa la \emph{data promotion} que provee la posibilidad de definir
tipos de datos -tipados- a nivel de tipos, introduciendo nuevos kinds.
Bajo el mismo trabajo Yorgey et al. implementan la
extensi\'on {\tt PolyKinds} proveyendo polimorfismo a nivel de kinds.
Adem\'as la extensi\'on {\tt KindSignatures}\cite{ghcman}
permite realizar anotaciones de kinds a las construcciones
en el nivel de tipos. Con toda esta maquinaria Haskell cuenta
con un lenguaje a nivel de tipos casi tan expresivo como a nivel
de t\'erminos\footnote{no es posible, por ejemplo, la aplicaci\'on parcial.}.
La extensi\'on {\tt GADTs}\cite{Cheney2003FirstClassPT,Xi:2003:GRD:604131.604150}
permite definir tipos de datos algebraicos
generalizados\cite{gadts} y combinada con las anteriores nos permite escribir
familias indizadas, como en los lenguajes dependientes.
La extensi\'on {\tt TypeOperators}\cite{ghcman}
habilita el uso de operadores como constructores de tipos.
El m\'odulo {\tt Data.Kind} de la biblioteca {\tt base}
exporta la notaci\'on {\tt Type} para
el kind {\tt *}. Esto fue implementado originalmente con la extensi\'on
{\tt TypeInType}, que en las \'ultimas versiones del compilador es
equivalente a {\tt PolyKinds + DataKinds + KindSignatures}\cite{ghcman}.


\subsection{Programando con tipos dependientes en Haskell}


Con todas estas extensiones combinadas, una declaraci\'on como:

> data Nat = Zero | Succ Nat

se ``duplica'' a nivel de kinds ({\tt DataKinds}). Esto es, que
adem\'as de introducir los t\'erminos {\tt Zero} y {\tt Succ} de tipo
{\tt Nat}, y al propio tipo {\tt Nat} de kind {\tt *} la declaraci\'on
introduce los {\bf tipos}
{\tt Zero} y {\tt Succ} de kind {\tt Nat} (y al propio kind {\tt Nat}).
Para evitar la ambig\"uedad\footnote{
  depende de la construcci\'on sint\'actica si es necesario desambiguar o no,
  esto se detalla en el manual de GHC\cite{ghcman}.
}, los constructores a nivel de tipos
son accesibles por sus nombres precedidos por un ap\'ostrofo, para
este caso, {\tt 'Zero} y {\tt 'Succ}.
Luego es posible declarar, por ejemplo ({\tt GADTs}, {\tt KindSignatures}):

> data Vec :: Nat -> Type -> Type where
>   VZ :: Vec Zero a
>   VS :: a -> Vec n a -> Vec (Succ n) a

y funciones seguras como:

> vTail :: Vec (Succ n) a -> Vec n a
> vTail (VS _ as) = as

> vZipWith :: (a -> b -> c) -> Vec n a -> Vec n b -> Vec n c
> vZipWith _ VZ VZ = VZ
> vZipWith f (VS x xs) (VS y ys)
>   = VS (f x y)(vZipWith f xs ys)

Es posible definir funciones puramene a nivel de tipos mediante familias\break
({\tt TypeFamilies}, {\tt TypeOperators}, {\tt DataKinds},
{\tt KindSignatures}) como la suma:

> type family (m :: Nat) + (n :: Nat) :: Nat
> type instance Zero + n = n
> type instance Succ m  + n = Succ (m + n) 

o mediante la notaci\'on alternativa, cerrada:

> type family (m :: Nat) + (n :: Nat) :: Nat where
>   (+) Zero     a = a
>   (+) (Succ a) b = Succ (a + b)

Con la notaci\'on abierta las familias son extensibles.
Las definiciones cerradas son una inclusi\'on m\'as reciente
y permiten ecuaciones que se superpongan\cite{Eisenberg:2014:CTF:2578855.2535856}
del mismo modo que cuando se hace \emph{pattern matching} a nivel de valores.
En este caso las definiciones son equivalentes. 


Podemos combinar las t\'ecnicas para programar, por ejemplo:

> vAppend :: Vec n a -> Vec m a -> Vec (n + m) a
> vAppend (VZ) bs      = bs
> vAppend (VS a as) bs = VS a (vAppend as bs)

\subsection{Limitaciones}
\label{sec:limitaciones}

En contraste a lo que ocurre en los sistemas de tipos dependientes,
los lenguajes de t\'erminos y de tipos en Haskell
contin\'uan habitando mundos separados.
La correspondencia entre nuestra definici\'on de vectores
y las familias inductivas en los lenguajes de tipos dependientes no es tal.

Las ocurrencias de {\tt m} y {\tt n} en los tipos de las funciones anteriores son
est\'aticas, y borradas en tiempo de
ejecuci\'on, mientras que en un lenguaje de tipos dependientes estos
par\'ametros son esencialmente
\emph{din\'amicos}~\cite{Lindley:2013:HPP:2578854.2503786}.
En las teor\'ias de tipos intensionales
una definici\'on como la suma ({\tt (+)}) declarada anteriormente
extiende el algoritmo de normalizaci\'on, de forma tal que el
compilador decidir\'a la igualdad de tipos seg\'un las formas
normales. Si dos tipos tienen la misma forma normal entonces los mismos
t\'erminos les habitar\'an.
Por ejemplo, los tipos  {\tt Vec (S (S Z) + n) a} y {\tt Vec (S (S n)) a}
tendr\'an los mismos habitantes.
Esto no va a ser cierto para tipos como
{\tt Vec (n + S (S Z)) a} y {\tt Vec (S (S n)) a}, aunque los tipos
coincidan para todas las instancias concretas de {\tt n}.
Para expresar propiedades como la conmutatividad
se utilizan evidencias de las ecuaciones utilizando
\emph{igualdad proposicional}
~\cite{Lindley:2013:HPP:2578854.2503786}. 

En el sistema de tipos de Haskell, sin embargo la igualdad de tipos
es puramente sint\'actica. Los tipos 
{\tt Vec (n + S (S Z)) a} y {\tt Vec (S (S n)) a} {\bf no} son el mismo
tipo, y no poseen los mismos habitantes.
Las ecuaciones que definen una familia de tipos como {\tt (+)} axiomatizan
nuevas igualdades a nivel de tipos en Haskell.
Cada ocurrencia de {\tt (+)} debe estar soportada
con evidencia expl\'icita derivada de estos axiomas.
Cuando el compilador traduce desde el lenguaje externo al lenguaje del kernel,
busca generar evidencia mediante heur\'isticas de resoluci\'on de
restricciones.
La evidencia sugiere que el \emph{constraint solver} computa agresivamente,
y esta es la raz\'on por la cual la funci\'on {\tt vAppend} definida
anteriormente compila y funciona correctamente.

Sin embargo, funciones como:

> vchop :: Vec (m + n) x -> (Vec m x, Vec n x)

resultan imposibles de definir si no tenemos la informaci\'on de
{\tt m} o {\tt n} en tiempo de ejecuci\'on (intuitivamente,
ocurre que ``no sabemos donde partir el vector'').

Por otra parte la funci\'on:

< vtake :: Vec (m + n) x -> Vec m x

tendr\'ia un problema m\'as sutil. Incluso asuminedo que tuvieramos forma
de obtener {\tt m} en tiempo
de ejecuci\'on, no es posible para el verificador de tipos aceptar
la definici\'on.
No hay forma de deducir {\tt n} a partir del tipo del tipo {\tt m + n}
sin la informaci\'on de que {\tt (+)} es una funci\'on inyectiva en el
segundo argumento, lo cual
el verificador es incapaz de deducir.


\subsection{Singletons y Proxies}
\label{sec:sings}

Existen dos formas de atacar los problemas planteados
anteriormente.

\paragraph{Singletons}\hfill\break

Si pretendemos implementar {\tt vChop} cuyo tipo
podemos escribir m\'as expl\'icitamente como 

> vChop :: forall (m n :: Nat). Vec (m + n) x -> (Vec m x, Vec n x)

necesitamos hacer
referencia expl\'icita a {\tt m} para decidir donde cortar el vector.
Como en Haskell el cuantificador universal solo se refiere
a objetos est\'aticos (los lenguajes de tipos y t\'erminos est\'an
separados), esto no es posible directamente.
Un tipo \emph{singleton}\cite{Eisenberg:2012:DTP:2430532.2364522}
en el contexto de Haskell, es un {\tt GADT}
que replica datos est\'aticos a nivel de t\'erminos.

> data SNat :: Nat -> * where
>   SZ :: SNat Zero
>   SS :: SNat n -> SNat (Succ n)

Existe por cada tipo {\tt n} de kind {\tt Nat}, un \'unico
\footnote{Formalmente esto no es cierto, si consideramos las posibles
ocurrecias de $\bot$, la unicidad es cierta
para t\'erminos totalmente definidos}
t\'ermino de tipo {\tt SNat n}. Sobre estos t\'erminos podemos
hacer \emph{pattern matching}, e impl\'icitamente decidimos seg\'un
la informaci\'on del tipo.

Estamos en condiciones de implementar {\tt vChop}:

> vChop :: SNat m -> Vec (m + n) x -> (Vec m x, Vec n x)
> vChop SZ xs            = (VZ, xs)
> vChop (SS m) (VS x xs) = let (ys, zs) = vChop m xs
>                          in (VS x ys, zs)


La biblioteca {\tt singleton}\cite{libsingleton}
provee la generaci\'on autom\'atica
de instancias de tipos singleton y otras utilidades.


\paragraph{Proxies}\hfill\break

Para definir {\tt vTake} tambi\'en es necesario el valor de
{\tt m} en tiempo de ejecuci\'on para conocer
cu\'antos elementos extraer, pero una funci\'on de tipo

> vTake :: SNat m -> Vec (m + n) x -> Vec m x

a\'un no ser\'a implementable. Es necesaria tambi\'en la informaci\'on
de {\tt n} en tiempo de compilaci\'on,
pero no as\'i una representaci\'on de {\tt n}
en tiempo de ejecuci\'on. El natural
{\tt n} es est\'atico pero estamos obligados a proveer
un valor testigo expl\'icito para asistir al verificador de tipos que es
incapaz de deducir la inyectividad de la suma.

Consideramos la definici\'on:

> data Proxy :: k -> * where
>   Proxy :: Proxy a

Proxy es un tipo que no contiene datos, pero contiene un par\'ametro
\emph{phantom} de tipo arbitrario (de hecho, de kind arbitrario).
El uso de un proxy va a resolver el problema de {\tt vTake}, indicando
simplemente que la ocurrencia del proxy tiene la informaci\'on del tipo
{\tt n} en el vector.

La siguiente implementaci\'on de vTake compila y funciona correctamente:

> vTake :: SNat m -> Proxy n -> Vec (m + n) x -> Vec m x
> vTake SZ _ xs            = VZ
> vTake (SS m) n (VS x xs) = VS x (vTake m n xs)

Durante la implementaci\'on de AspectAG y sus dependencias haremos uso
intensivo de estas t\'ecnicas.



\newpage
\subsection{HList : Colecciones Heterogeneas Fuertemente tipadas}
\label{hlist}

%include ./src/HCols.lhs


\newpage
\section{Gram\'aticas de atributos y AspectAG}
Presentamos una breve introducci\'on a las gram\'aticas de
atributos, de manera informal por medio de en un ejemplo.
Implementamos el mismo ejemplo en AspectAG.

\label{ags}

%include ./src/AGs.lhs


\newpage
\section{Reimplementaci\'on de AspectAG}
\label{impl}

A continuaci\'on presentamos algunos de los aspectos m\'as importantes
de la implementaci\'on de la biblioteca.

%include ./src/AAG.lhs

\newpage
\section{Discusi\'on}
\label{discusion}

%include ./src/Conc.lhs

\newpage

\bibliography{bib}{}
\bibliographystyle{plain}


\end{document}
