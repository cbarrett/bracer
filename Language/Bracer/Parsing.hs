module Language.Bracer.Parsing 
  ( LiteralParsing (..) 
  , IdentifierParsing (..)
  , TypeParsing (..)
  , TypeSig
  , VariableParsing (..)
  , ExpressionParsing (..)
  , StatementParsing (..)
  ) where

  import Prelude ()
  import Overture
  
  import Text.Parser.Token
  import qualified Text.Parser.Expression as E
  
  import Language.Bracer.Syntax.Names
  
  -- Class for parsers that understand literals
  class (TokenParsing m) => LiteralParsing m where
    type LiteralSig :: * -> *
    parseLiteral :: (Functor f, LiteralSig :<: f) => m (Term f)
  
  class (TokenParsing m, Monad m) => IdentifierParsing m where
    type IdentifierSig :: * -> *
    identifierStyle    :: IdentifierStyle m
    parseIdentifier    :: (Functor f, IdentifierSig :<: f) => m (Term f)
    parseName          :: m Name
    parseName = Name <$> ident identifierStyle
  
  class (IdentifierParsing m, LiteralParsing m) => TypeParsing m where
    type BaseSig     :: * -> *
    type ModifierSig :: * -> *
    type AliasSig    :: * -> *
    
    parseTypeName :: ( Functor f
                    , LiteralSig    :<: f
                    , IdentifierSig :<: f
                    , BaseSig       :<: f
                    , ModifierSig   :<: f
                    , AliasSig      :<: f
                    ) => m (Term f)
  
  class (TypeParsing m) => VariableParsing m where
    type VariableSig :: * -> *
    type FunctionSig :: * -> *
    
    parseVariable :: ( Functor f
                    , LiteralSig    :<: f
                    , IdentifierSig :<: f
                    , BaseSig       :<: f
                    , ModifierSig   :<: f
                    , AliasSig      :<: f
                    , VariableSig   :<: f
                    , FunctionSig   :<: f
                    ) => m (Term f)
                    
  type TypeSig = LiteralSig :+: IdentifierSig :+: BaseSig :+: ModifierSig :+: AliasSig
  
  
  -- Class for parsers that understand expressions. Note that we use a type family 
  -- here so that parsers, when implementing this class, get to specify the type of parsed expressions
  class (TypeParsing m) => ExpressionParsing m where
    type ExpressionSig :: * -> *
    type OperatorSig :: * -> *
    parsePrefixOperator :: ( Functor f
                           , IdentifierSig :<: f
                           , ExpressionSig :<: f
                           , OperatorSig :<: f
                           , LiteralSig :<: f) => m (Term f)
    
    parsePostfixOperator :: ( Functor f
                            , IdentifierSig :<: f
                            , ExpressionSig :<: f
                            , OperatorSig :<: f
                            , LiteralSig :<: f
                            ) => m (Term f -> Term f)
    infixOperatorTable :: ( Functor f 
                          , IdentifierSig :<: f
                          , ExpressionSig :<: f
                          , OperatorSig :<: f) => E.OperatorTable m (Term f)
  
  class (ExpressionParsing m) => StatementParsing m where
    type StatementSig :: * -> *
    parseStatement :: m (Term (ExpressionSig :+: StatementSig))
  
  class (StatementParsing m) => DeclarationParsing m where 
    type DeclarationSig :: * -> *
    parseDeclaration :: m (Term DeclarationSig)