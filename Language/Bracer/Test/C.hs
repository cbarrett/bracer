{-# LANGUAGE RankNTypes, ScopedTypeVariables #-}

module Language.Bracer.Test.C (tests) where

  import Prelude ()
  import Overture

  import Test.Hspec
  import Test.Hspec.QuickCheck
  import Test.QuickCheck hiding (Success, Result)
  import Test.QuickCheck.Property hiding (Result)

  import Control.Lens
  import Text.Trifecta
  import Data.Comp.Show
  import Data.Scientific
  import qualified Data.Vector as V

  import Language.Bracer
  import Language.Bracer.Pretty
  import Language.Bracer.Backends.C
  import Language.Bracer.Test.Internal
  import Text.PrettyPrint.ANSI.Leijen hiding ((<>))

  roundTrip :: (Pretty a) => CParser a -> a -> Result a
  roundTrip p it =
    let asString = displayS (renderCompact (pretty it)) ""
     in runCParser p asString

  tests :: Spec
  tests = describe "C" $ do

    let testInt = iIntLit 1 iNoSuffix
    let testFlt = iFltLit 1.0 iNoSuffix
    let testFlt2 = iFltLit (127.8) (iFloatSuffix iNoSuffix)
    let testFlt3 = iFltLit (616.6e100) iNoSuffix
    let testFlt4 = iFltLit (100e-100) iNoSuffix
    let testChr = iChrLit 'c'

    describe "token parser" $ do
      it "ignores traditional comments" $
        runCParser (whiteSpace *> parseLiteral <* eof) "/* comment */ 1" `shouldParseAs` testInt
      it "ignores C++ style comments" $
        runCParser (whiteSpace *> parseLiteral <* eof) "1 // comment" `shouldParseAs` testInt

    describe "literal parser" $ do
      it "parses integers" $
        runCParser (parseLiteral <* eof) "1" `shouldParseAs` testInt
      it "parses floats" $
        runCParser (parseLiteral <* eof) "1.0" `shouldParseAs` testFlt
      it "parses characters" $
        runCParser (parseLiteral <* eof) "'c'" `shouldParseAs` testChr

      it "parses floats with suffixes" $
        runCParser (parseLiteral <* eof) "127.8f" `shouldParseAs` testFlt2

      it "parses floats with exponent parts" $ do
        runCParser (parseLiteral <* eof) "616.6e100" `shouldParseAs` testFlt3
        runCParser (parseLiteral <* eof) "616.6e+100" `shouldParseAs` testFlt3

      it "parses floats with negative exponent parts" $ do
        runCParser (parseLiteral <* eof) "100.0e-100" `shouldParseAs` testFlt4
        runCParser (parseLiteral <* eof) "100e-100" `shouldParseAs` testFlt4

      it "doesn't accept just a dot as a valid float" $ do
        (runCParser (parseLiteral <* eof) ".") `shouldSatisfy` has _Failure

      prop "parses any floating-point number" $ do
        (NonNegative (s :: Scientific)) <- arbitrary
        let res = runCParser (parseLiteral <* eof) (show s)
        shouldSucceed res

      -- Doesn't compile as of 2015/8/10
      -- prop "preserves floating-point numbers round trip" $ do
      --   (NonNegative (s :: Scientific)) <- arbitrary
      --   let res = runCParser (parseLiteral <* eof) (show s) ^? _Success
      --   property (res /= (iFltLit s iNoSuffix))

    describe "identifier parser" $ do
      let parseIdentifier' = parseIdentifier :: CParser (Term Ident)

      it "succeeds on valid identifiers" $ do
        runCParser (parseIdentifier' <* eof) "hello" `shouldParseAs` iIdent "hello"
      it "fails on reserved words" $ do
        shouldn'tParse (runCParser (parseIdentifier' <* eof) "return")
      it "fails on invalid identifiers" $ do
        shouldn'tParse (runCParser (parseIdentifier' <* eof) "$$$$$")

    describe "type parser" $ do

      it "parses simple types" $
        runCParser (parseTypeName <* eof) "int" `shouldParseAs` iInt

      it "parses types with an implicit int" $ do
        runCParser parseTypeName "long" `shouldParseAs` iLong iInt

      it "parses types with pointers" $ do
        runCParser parseTypeName "int **" `shouldParseAs` iPointer (iPointer iInt)

      it "parses types with qualified pointers" $ do
        runCParser parseTypeName "int * volatile" `shouldParseAs` iVolatile (iPointer iInt)

      it "parses types with qualified pointers and implicit int" $ do
        runCParser parseTypeName "long ** const" `shouldParseAs` iConst (iPointer (iPointer (iLong iInt)))

      it "parses types with multiple qualified pointers" $ do
        runCParser parseTypeName "int * const * volatile" `shouldParseAs` iVolatile (iPointer (iConst (iPointer iInt)))

    describe "expression parser" $ do
      it "parses bare literals" $ do
        (runCParser parseExpression "5") `shouldParseAs` iIntLit 5 iNoSuffix
        (runCParser parseExpression "'c'") `shouldParseAs` iChrLit 'c'

      it "parses parenthesized literals correctly" $ do
        (runCParser parseExpression "(10)") `shouldParseAs` iParen (iIntLit 10 iNoSuffix)

      it "parses identifiers" $ do
        runCParser parseExpression "foo" `shouldParseAs` iIdent "foo"

      it "parses simple prefix operators" $ do
        let notGuilty = iUnary iNot (iIdent "guilty")
        runCParser parseExpression "!guilty" `shouldParseAs` notGuilty
        runCParser parseExpression "!!guilty" `shouldParseAs` iUnary iNot notGuilty
        runCParser parseExpression "! guilty" `shouldParseAs` notGuilty

      it "parses preincrement rather than two posivate" $ do
        runCParser parseExpression "++x" `shouldParseAs` iUnary iInc (iIdent "x")

      it "doesn't parse more than two trailing plus signs" $ do
        runCParser (parseExpression <* eof) "+++x" `shouldSatisfy` isn't _Success
        runCParser (parseExpression <* eof) "++++x" `shouldSatisfy` isn't _Success

      it "parses mixing prefix and postfix correctly" $ do
        runCParser (parseExpression <* eof) "!blah[500]" `shouldParseAs`
          iUnary iNot (iIndex (iIdent "blah") (iIntLit 500 iNoSuffix))
        runCParser (parseExpression <* eof) "!!something()" `shouldParseAs`
          iUnary iNot (iUnary iNot (iCall (iIdent "something") []))
        runCParser (parseExpression <* eof) "*it++" `shouldParseAs` (iUnary iDeref (iUnary iPostInc (iIdent "it")))


    describe "variable parser" $ do

      it "parses simple variables" $ do
        runCParser (parseVariable <* eof) "int x;" `shouldParseAs` iVariableDecl (iVariable "x" iInt)
        runCParser (parseVariable <* eof) "long letter;" `shouldParseAs` iVariableDecl (iVariable "letter" (iLong iInt))

      it "parses `const int (* volatile bar)[64]` correctly" $ do
        runCParser (parseVariable <* eof) "const int (* volatile biggie)[64];" `shouldParseAs`
          iVariableDecl (iVariable "biggie" (iVolatile (iPointer (iArray (Just (iIntLit 64 iNoSuffix)) (iConst iInt)))))

      it "parses `int (*(*big_pun)(void))[3]` correctly" $ do
        runCParser (parseVariable <* eof) "int (*(*big_pun)(void ))[3];" `shouldParseAs`
          iVariableDecl (iVariable "big_pun" (iPointer (iFunction Anonymous (iPointer (iArray (Just (iIntLit 3 iNoSuffix)) iInt)) [iVariable Anonymous iVoid])))

      it "parses `char (*(*x[3])())[5]` correctly" $ do
        runCParser (parseVariable <* eof) "char (*(*x[3])())[5];" `shouldParseAs`
          iVariableDecl (iVariable "x" (iArray (Just (iIntLit 3 iNoSuffix)) (iPointer (iFunction Anonymous (iPointer (iArray (Just (iIntLit 5 iNoSuffix)) iChar)) []))))

      it "parses variables with pointers" $ do
        runCParser (parseVariable <* eof) "const int *bar;" `shouldParseAs` iVariableDecl (iVariable "bar" (iPointer (iConst iInt)))

      it "parses variables with pointers" $ do
        runCParser (parseVariable <* eof) "int foo = 1;" `shouldSatisfy` has _Success




    describe "statement parser" $ do
      it "parses bare expressions" $ do
        (runCParser parseStatement "1;") `shouldParseAs` iIntLit 1 iNoSuffix

      it "parses break statements" $
        (runCParser parseStatement "break;") `shouldParseAs` iBreak

      it "parses returns with and without values" $ do
        (runCParser parseStatement "return;") `shouldParseAs` iReturn Nothing
        (runCParser parseStatement "return 'c';") `shouldParseAs` (iReturn (Just (iChrLit 'c')))

      it "parses block items" $ do
        let p = runCParser parseBlock "return 1; return 2; return 3;"
        p `shouldSatisfy` has _Success
        let (Just (blk :: Statement StatementT)) = project $ p ^?! _Success
        blk `shouldSatisfy` has _Block
        let vec = blk ^. _Block & lengthOf each
        vec `shouldBe` 3

    describe "pretty-printing" $ do

      it "should correctly round-trip literals" $ do
        roundTrip parseLiteral testInt `shouldParseAs` testInt
        roundTrip parseLiteral testFlt2 `shouldParseAs` testFlt2
        roundTrip parseLiteral testChr `shouldParseAs` testChr
