Reimplemetamos un subconjunto de la biblioteca AspectAG original utilizando
las t\'ecnicas modernas de programaci\'on a nivel de tipos.
Con ello hicimos fuertemente tipadas las dos capas de programaci\'on,
a diferencia de la biblioteca original, que a nivel de tipos era
esencialmente no tipada.

A modo de ejemplo, el constructor de tipos {\tt Fam} en las versiones previas de
\emph{AspectAG} tiene \emph{kind}

> Fam :: * -> * -> *

Notar que {\tt Fam Bool Char} es un tipo v\'alido 
Peor a\'un, el constructor (de valores) {\tt Fam} tiene tipo

> Fam :: c -> p -> Fam c p

por lo que el tipo patol\'ogico {Fam Bool Char} est\'a habitado.

En la nueva implementaci\'on {\tt Fam} tiene \emph{kind}

> Fam :: [(k', [(k, Type)])] -> [(k, Type)] -> Type

> Fam :: forall k' k (c :: [(k', [(k, Type)])]) (p :: [(k, Type)]).
>        ChAttsRec c -> Attribution p -> Fam c p

Lo cual es mucho m\'as expresivo.
Notar que de todas formas el tipo {\tt Fam} a priori
no expresa la especificaci\'on
completa del tipo de datos (lo que podr\'iamos lograr en un lenguaje
de tipos verdaderamente dependientes): en ninguna parte se declara
que las listas de pares son en realidad mapeos donde las primeras
componentes (las etiquetas) no se repiten.
Sin embargo esto est\'a garantizado porque los constructores de
{\tt Attribution} y {\tt ChAttsRec} tienen restricciones.

Notar por ejemplo el constructor {\tt ConsAtt}:

> ConsAtt :: forall k (att :: k) val (atts :: [(k, Type)]).
>    LabelSet ('(att, val) : atts) =>
>    Attribute att val -> Attribution atts -> Attribution ('(att, val) : atts)

Nuestro sistema asegura que todos los valores de tipo {\tt Fam} van a estar
bien formados.\footnote{O casi: a\'un
es posible construir valores como {\tt undefined}
o {\tt Fam undefined undefined} de cualquier tipo construido con {\tt Fam}.
Estos valores adem\'as de ser patol\'ogicos (a nivel de t\'erminos), como no
usan los constructores nos permiten saltearnos la restricci\'on de la typeclass
y repetir etiquetas, y por tanto construir instancias patol\'ogicas a nivel
de tipos. Esto \'ultimo podr\'ia evitarse agregando las restricciones
de instancias de {\tt LabelSet} en el constructor {\tt Fam}, no lo consideramos
necesario.}


La implementaci\'on de estructuras especializadas provee nombres mnem\'onicos
para las estructuras, comparemos el tipo de {\tt asp\_sres}
en la implementaci\'on antig\"ua, y en la nueva:

> asp_sres
>   :: (HExtend (Att (Proxy Att_sres) val) sp1 sp'1,
>       HExtend (Att (Proxy Att_sres) Tree) sp2 sp'2,
>       HExtend (Att (Proxy Att_sres) Tree) sp3 sp'3,
>       HasField (Proxy (Ch_tree, Tree)) r1 r2,
>       HasField (Proxy (Ch_l, Tree)) r3 r4,
>       HasField (Proxy (Ch_r, Tree)) r3 r5,
>       HasField (Proxy Att_sres) r2 val,
>       HasField (Proxy Att_sres) r4 Tree,
>       HasField (Proxy Att_sres) r5 Tree,
>       HasField (Proxy Att_ival) r6 Int) =>
>   Record
>   (HCons(LVPair (Proxy P_Root) (Fam r1 p1 -> Fam ic1 sp1 -> Fam ic1 sp'1))
>   (HConS(LVPair (Proxy P_Node) (Fam r3 p2 -> Fam ic2 sp2 -> Fam ic2 sp'2))
>   (HCons(LVPair (Proxy P_Leaf) (Fam c r6  -> Fam ic3 sp3 -> Fam ic3 sp'3))
>    HNil)))


> asp_sres
>   :: (HasChild (Ch_tree, Tree) r1 v1, HasChild (Ch_l, Tree) r2 v2,
>       HasChild (Ch_r, Tree) r2 v3,
>       LabelSet ( '(Att_sres, val)  : sp1),
>       LabelSet ( '(Att_sres, Tree) : sp2),
>       LabelSet ( '(Att_sres, Tree) : sp3),
>       HasFieldAtt Att_sres v1 val,
>       HasFieldAtt Att_sres v2 Tree,
>       HasFieldAtt Att_sres v3 Tree,
>       HasFieldAtt Att_ival r3 Int) =>
>   Record
>   '['(P_Root, Fam r1 p1 -> Fam ic1 sp1 -> Fam ic1 ('(Att_sres, val) : sp1)),
>     '(P_Node, Fam r2 p2 -> Fam ic2 sp2 -> Fam ic2 ('(Att_sres, Tree) : sp2)),
>     '(P_Leaf, Fam c r3 -> Fam ic3 sp3 -> Fam ic3 ('(Att_sres, Tree) : sp3))]

Por otra parte, los mensajes de error han sido mejorados. Por ejemplo,
consideramos en el ejemplo {\tt repmin} [REF] que omitimos en la definici\'on
de {\tt asp\_smin} la regla {\tt p\_Node .=. node\_smin}.
La gram\'atica estar\'a mal formada y la funci\'on
{\tt repmin}, o {\tt getmin} no compilar\'an.

En las versiones antig\"uas obtenemos el cr\'iptico error:

>   . No instance for
> (HasField (Proxy P_Node) HNil
>  (Fam (Record (HCons (Chi (Proxy (Ch_l, Tree))
>                       (Record (HCons (LVPair (Proxy Att_smin) Int) HNil)))
>                (HCons (Chi (Proxy (Ch_r, Tree))
>                        (Record (HCons (LVPair (Proxy Att_smin) Int) HNil)))
>                 HNil)))
>    (Record HNil)
>  -> Fam (Record (HCons (Chi (Proxy (Ch_l, Tree)) (Record HNil))
>                  (HCons (Chi (Proxy (Ch_r, Tree)) (Record HNil)) HNil)))
>     (Record HNil)
>  -> Fam (Record (HCons (Chi (Proxy (Ch_l, Tree)) (Record HNil))
>                  (HCons (Chi (Proxy (Ch_r, Tree)) (Record HNil)) HNil)))
>    (Record (HCons (LVPair (Proxy Att_smin) Int) HNil))))
>   arising from a use of 'sem_Tree'
>      ....

En la reimplementaci\'on:


>   . Type Error : No Field found on Aspect.
>     A Field of type P_Node was expected
>    (Possibly there are productions where the attribute is undefined)
>      ....


Adem\'as de tipar fuertemente, sustituimos parte de la programaci\'on
a nivel de tipos al estilo l\'ogico utilizado con las t\'ecnicas antig\"uas
por un estilo funcional gracias a las type families, m\'as idiom\'atico
para una biblioteca implementada en Haskell.
Por ejemplo, en las distintas versiones de la biblioteca original
la funci\'on {\tt empties} viene dada por una relaci\'on entre tipos
que se declara funcional con una dependencia:

> class Empties fc ec | fc -> ec where
>   empties :: fc -> ec

En contraste, en la nueva implementaci\'on {\tt EmptiesR}
es expl\'icitamente una funci\'on a nivel de tipos de kind

> EmptiesR :: [(k, *)] -> [(k, [(k, *)])]

Y {\tt empties} una funci\'on a nivel de valores, de tipo

> empties :: Record fc -> ChAttsRec (EmptiesR fc)


\'Esta cuesti\'on era planteada
como trabajo futuro en la publicaci\'on
original~\cite{Viera:2009:AGF:1596550.1596586} de la biblioteca.
A\'un puede ser mejorado en ciertas porciones de c\'odigo.

Adem\'as de las caracter\'isticas que tiene el sistema, se provee una
demostraci\'on del uso de la programaci\'on a nivel de tipos en Haskell
enriquecido por el conjunto de extensiones que implementa el compilador GHC.


\section{Trabajo Futuro}
En este proyecto, se reimplement\'o un subconjunto de la biblioteca
original; es natural fijarnos como objetivo a futuro, tener una versi\'on
completa de la biblioteca implementada con las t\'ecnicas modernas para
publicar.

Continua abierta la cuesti\'on planteada
en~\cite{Viera:2009:AGF:1596550.1596586} sobre la implementaci\'on de
un sistema an\'alogo en un lenguaje de tipos dependientes.