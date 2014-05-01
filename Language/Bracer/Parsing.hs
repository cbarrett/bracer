module Language.Bracer.Parsing where

  import Prelude (undefined)
  import Overture hiding (try)

  import Data.ByteString (ByteString)
  import Data.Comp.Derive
  import Data.Scientific
  
  import Text.Parser.Combinators
  import Text.Parser.Token
  import qualified Text.Parser.Expression as E
  
  -- Class for parsers that understand literals
  class (TokenParsing m) => LiteralParsing m where
    type LiteralSig :: * -> *
    parseLiteral :: m (Term LiteralSig)
  
  class (TokenParsing m, Monad m) => IdentifierParsing m where
    type IdentifierSig :: * -> *
    identifierStyle :: IdentifierStyle m
    makeIdentifier :: ByteString -> m (Term IdentifierSig)
  
  parseIdentifier :: (IdentifierParsing m) => m (Term IdentifierSig)
  parseIdentifier = ident identifierStyle >>= makeIdentifier <?> "identifier"
  
  class (IdentifierParsing m) => TypeParsing m where
    type SpecifierSig :: * -> *
    parseModifier :: m (Endo (Term SpecifierSig))
    parseRootType :: m (Term (SpecifierSig))
    defaultRootType :: m (Term SpecifierSig)
    parseDerived :: m (Endo (Term SpecifierSig))
    
  
  -- Class for parsers that understand expressions. Note that we use a type family 
  -- here so that parsers, when implementing this class, get to specify the type of parsed expressions
  class (IdentifierParsing m, TypeParsing m, LiteralParsing m) => ExpressionParsing m where
    type ExpressionSig :: * -> *
    parsePrefixOperator :: m (Term ExpressionSig)
    parsePostfixOperator :: m (Term ExpressionSig -> Term ExpressionSig)
    infixOperatorTable :: E.OperatorTable m (Term ExpressionSig)
  
  class (ExpressionParsing m) => DeclaratorParsing m where
    type DeclaratorSig :: * -> *
    parseDeclarator :: m (Term DeclarationSig)
  
  class (DeclaratorParsing m) => StatementParsing m where
    type StatementSig :: * -> *
    parseStatement :: m (Term (StatementSig :+: DeclaratorSig))
  
  class (StatementParsing m) => DeclarationParsing m where 
    type DeclarationSig :: * -> *
    parseDeclaration :: m (Term DeclarationSig)