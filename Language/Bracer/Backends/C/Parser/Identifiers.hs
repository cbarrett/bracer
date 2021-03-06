module Language.Bracer.Backends.C.Parser.Identifiers where
  
  import Prelude ()
  import Overture
  
  import Language.Bracer
  import Language.Bracer.Backends.C.Syntax
  import Language.Bracer.Backends.C.Parser.Internal
  
  import Data.HashSet
  import Text.Trifecta
  import Text.Parser.Token.Style
  
  instance IdentifierParsing CParser where
    type IdentifierSig CParser = Ident
    identifierStyle = c99Idents
    parseIdentifier = iIdent <$> parseName <?> "identifier"
  
  infixl 4 **>
  a **> b = reserve identifierStyle a *> b
  
  c99Idents :: TokenParsing m => IdentifierStyle m
  c99Idents = haskellIdents 
    { _styleReserved = fromList 
      [ "->"
      , "++"
      , "--"
      , "&"
      , "*"
      , "+"
      , "-"
      , "~"
      , "!"
      , "/"
      , "%"
      , "<<"
      , ">>"
      , "/"
      , "%"
      , "<<"
      , ">>"
      , "<"
      , ">"
      , "<="
      , ">="
      , "=="
      , "!="
      , "^"
      , "|"
      , "&&"
      , "?"
      , ":"
      , ";"
      , "..."
      , "="
      , "*="
      , "/="
      , "%="
      , "+="
      , "-="
      , "<<="
      , ">>="
      , "&="
      , "^="
      , "|="
      , ","
      , "#"
      , "##"
      , "["
      , "]"
      , "?"
      , ":"
      , "?:"
      , "..."
      , "asm"
      , "auto"
      , "break"
      , "case"
      , "char"
      , "const"
      , "continue"
      , "default"
      , "do"
      , "double"
      , "else"
      , "enum"
      , "extern"
      , "float"
      , "for"
      , "goto"
      , "if"
      , "inline"
      , "int"
      , "long"
      , "register"
      , "restrict"
      , "return"
      , "short"
      , "signed"
      , "sizeof"
      , "static"
      , "struct"
      , "switch"
      , "typedef"
      , "union"
      , "unsigned"
      , "void"
      , "volatile"
      , "while"
      , "__asm"
      , "__attribute__"
      , "__inline"
      , "__inline__"
      , "__typeof__"
      , "__builtin_va_arg"
      , "__builtin_offsetof"
      , "__int128_t"
      , "__uint128_t"
      ]
    }