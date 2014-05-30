module Main where

  import Prelude ()
  import Overture
  
  import Test.Hspec
  import qualified Test.Hspec.Core as HC
  
  import Language.Bracer
  import Language.Bracer.Test.C as C
  import Language.Bracer.Test.Examples.BinaryLiterals as BL
  
  suite :: String -> [Spec] -> Spec
  suite label specs = HC.fromSpecList [HC.describe label (concatMap HC.runSpecM specs)]
  
  main = hspec $ suite "bracer"
    [ C.tests
    , BL.tests
    ]
