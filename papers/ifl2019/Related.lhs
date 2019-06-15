%Attribute grammars encoded in functional languages have a long history, starting
%with Johnson \cite{652508}. 
%Related to Haskell, the {\tt uuagc} (Uthrech University Attribute Grammar
%Compiler) is probably the most well known example. 


There are a significant number of AG implementations. Some of them implemented
as standalone compilers or generators, like LRC \cite{Saraiva02}, UUAGC
\cite{uuagc}, LISA \cite{lisa}, JastAdd \cite{jastadd} and Silver \cite{silver},
and others embbeded in languages like Scala (e.g. Kiama \cite{kiama}) or Haskell
(\cite{DBLP:conf/gcse/MoorPW99, Moor99first-classattribute,
  Viera:2009:AGF:1596550.1596586,DBLP:conf/ifl/VieraBP18, MFS13,
  DBLP:phd/ethos/Balestrieri15}).


This work is based on \AspectAG\ \cite{Viera:2009:AGF:1596550.1596586}, where
extensible records are used to implement a strongly typed first class AG DSL
embedded in Haskell. We preserve its main characteristics, i.e. safety and
modularity, tackling in turn its main drawbacks. We use new Haskell type level
programming techniques to obtain a more clear design and implementation. Also,
we push a towards the direction of type safety making types strongly kinded.

%First class implementations of Attibute grammars in Haskell were introduced by
%Moor \cite{Moor99first-classattribute} with a lightweight approach missing from
%type safety. Viera \emph{et al} \cite{Viera:2009:AGF:1596550.1596586} in the
%original design og \AspectAG\ introduced a type safe approach. Other embedded
%implementations existed \cite{DBLP:phd/ethos/Balestrieri15}. Error messages were
%a weakness. Also, we push a towards the direction of type safety making types
%strongly kinded. 

Error messages are another weakness we dealed with. Managing type errors on
EDSLs is an old problem to the community and an active research area. The idea
of transforming a typing problem into a constraint problem is not recent
\cite{10635_42131, improvingtypeerror}. Other embedded implementations of AGs
\cite{DBLP:conf/ifl/VieraBP18} solve the type diagnose problem at the cost of
making it staged.


Compiler support added with the |TypeError| family was essential, but further
support would be desirable, in particular to control class constraint solving
and avoid leaks an non readable messages. Research by
Heeren~\cite{DBLP:phd/basesearch/Heeren05} was implemented for the Helium
compiler. Recently, Serrano Mena and Hage \cite{DBLP:phd/basesearch/Serrano18,
  DBLP:conf/ifl/SerranoH17} developed a set of techniques for customizing type
error diagnosis for GHC. We think this can complement our more ad-hoc approach.
%Unfortunately this implementation was not merged in main tree.





