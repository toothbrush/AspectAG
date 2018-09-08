{-|
Module      : Record
Description : Strongly typed heterogeneous records,
              using (polykinded) phantom labels as index.
Copyright   : (c) Juan García Garland, 2018 
License     : LGPL
Maintainer  : jpgarcia@fing.edu.uy
Stability   : experimental
Portability : POSIX

-}

{-# LANGUAGE DataKinds,
             TypeOperators,
             PolyKinds,
             GADTs,
             TypeInType,
             RankNTypes,
             StandaloneDeriving,
             FlexibleInstances,
             FlexibleContexts,
             ConstraintKinds,
             MultiParamTypeClasses,
             FunctionalDependencies,
             UndecidableInstances,
             ScopedTypeVariables,
             TypeFamilies,
             InstanceSigs
#-}

module Record where

import Data.Kind 
import Data.Type.Equality
import Data.Proxy
import TPrelude
import Data.Tagged hiding (unTagged)
import TagUtils
import GHC.TypeLits

-- * Constructors


-- ** Internal representation

-- | A Record is a map from labels to values. Labels must be unique,
--so we use a proof of 'LabelSet' as an implicit parameter to construct a new
--instance
data Record :: forall k . [(k,Type)] -> Type where
  EmptyR :: Record '[]
  ConsR  :: LabelSet ( '(l, v) ': xs) =>
   Tagged l v -> Record xs -> Record ( '(l,v) ': xs)


-- ** Exported
-- | Pretty constructors

-- | For the empty Record
emptyRecord :: Record '[]
emptyRecord = EmptyR


-- | A pretty constructor for ConsR
infixr 2 .*.

(.*.) :: LabelSet ('(att, val) : atts) =>
    Tagged att val -> Record atts -> Record ('(att, val) : atts)
(.*.) = ConsR



-- * Getting

-- | get a field indexed by a label
class HasFieldRec (l::k) (r :: [(k,Type)]) where
  type LookupByLabelRec l r :: Type
  hLookupByLabelRec:: Label l -> Record r -> LookupByLabelRec l r


instance (HasFieldRec' (l == l2) l ( '(l2,v) ': r)) =>
  HasFieldRec l ( '(l2,v) ': r) where
  type LookupByLabelRec l ( '(l2,v) ': r)
    = LookupByLabelRec' (l == l2) l ( '(l2,v) ': r)
  hLookupByLabelRec :: Label l -> Record ( '(l2,v) ': r)
                    -> LookupByLabelRec l ( '(l2,v) ': r)
  hLookupByLabelRec l r
    = hLookupByLabelRec' (Proxy :: Proxy (l == l2)) l r 

class HasFieldRec' (b::Bool) (l::k) (r :: [(k,Type)]) where
  type LookupByLabelRec' b l r :: Type
  hLookupByLabelRec' ::
     Proxy b -> Label l -> Record r -> LookupByLabelRec' b l r


-- | Since the typechecker cannot decide an instance dependent of the context,
--but on the head, an auxiliary class with an extra parameter to decide
--if we update on the head of r or not is used
instance HasFieldRec'    'True l ( '(l, v) ': r) where
  type LookupByLabelRec' 'True l ( '(l, v) ': r) = v
  hLookupByLabelRec' _ _ (ConsR lv _) = unTagged lv

instance (HasFieldRec l r )=>
  HasFieldRec' 'False l ( '(l2, v) ': r) where
  type LookupByLabelRec' 'False l ( '(l2, v) ': r) = LookupByLabelRec l r
  hLookupByLabelRec' _ l (ConsR _ r) = hLookupByLabelRec l r

-- | Error instance, using :
instance TypeError (Text "Type Error ----" :$$:
                    Text "From the use of 'HasFieldRec' :" :$$:
                    Text "No Field of type " :<>: ShowType l
                    :<>: Text " on Record" )
  => HasFieldRec l '[] where
  type LookupByLabelRec l '[] = TypeError (Text "unreachable")
  hLookupByLabelRec = undefined



-- * Updating

-- | updating the value on a label, possibly changing the type of the index
class UpdateAtLabelRec (l :: k)(v :: Type)(r :: [(k,Type)])(r' :: [(k,Type)])
   | l v r -> r' where
  updateAtLabelRec :: Label l -> v -> Record r -> Record r'


instance (HEqK l l' b, UpdateAtLabelRec' b l v ( '(l',v')': r) r')
 -- note that if pattern over r is not written this does not compile
       => UpdateAtLabelRec l v ( '(l',v') ': r) r' where
  updateAtLabelRec = updateAtLabelRec' (Proxy :: Proxy b)

-- | Again, the usual hack 
class UpdateAtLabelRec' (b::Bool)(l::k)(v::Type)(r::[(k,Type)])(r'::[(k,Type)])
    | b l v r -> r'  where
  updateAtLabelRec' :: Proxy b -> Label l -> v -> Record r -> Record r'



instance (LabelSet ( '(l,v') ': r), LabelSet ( '(l,v) ': r) ) =>
         UpdateAtLabelRec' 'True l v ( '(l,v') ': r) ( '(l,v) ': r) where
  updateAtLabelRec' _ (l :: Label l) v (att `ConsR` atts)
    = (Tagged v :: Tagged l v) `ConsR` atts


instance ( UpdateAtLabelRec l v r r', LabelSet  ( a ': r' ) ) =>
         UpdateAtLabelRec' False l v ( a ': r) ( a ': r') where
  updateAtLabelRec' (b :: Proxy False) (l :: Label l) (v :: v)
    (ConsR att xs :: Record ( a ': r))
    = case (updateAtLabelRec l v xs) of
        xs' -> ConsR att xs' :: Record( a ': r')

-- | Type errors using GHC.TypeLits
instance TypeError (Text "Type Error ----" :$$:
                    Text "From the use of 'HasFieldRec' :" :$$:
                    Text "No Field of type " :<>: ShowType l
                    :<>: Text " on Record" )
  => UpdateAtLabelRec l v '[] '[] where
  updateAtLabelRec _ _ r = r




-- * Predicates

-- | Boolean membership, at type level
class HasLabelRec (e :: k)(r ::[(k,Type)]) where
  type HasLabelRecRes (e::k)(r ::[(k,Type)]) :: Bool
  hasLabelRec :: Label e -> Record r -> Proxy (HasLabelRecRes e r)

instance HasLabelRec e '[] where
  type HasLabelRecRes e '[] = 'False
  hasLabelRec _ _ = Proxy

instance HasLabelRec  k ( '(k' ,v) ': ls) where
  type HasLabelRecRes k ( '(k' ,v) ': ls)
      = Or (k == k') (HasLabelRecRes k ls)
  hasLabelRec _ _ = Proxy



-- | Show instance, used for debugging
instance Show (Record '[]) where
  show _ = "{}"

instance (Show v, Show (Record xs)) =>
         Show (Record ( '(l,v) ': xs ) ) where
  show (ConsR lv xs) = let tail = show xs
                       in "{" ++ show (unTagged lv)
                          ++ "," ++ drop 1 tail




