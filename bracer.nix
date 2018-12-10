{ mkDerivation, ansi-wl-pprint, base, bytestring, compdata
, data-default, hashable, hspec, HUnit, lens, mtl, parsers
, QuickCheck, scientific, semigroups, stdenv, trifecta
, unordered-containers, utf8-string, vector
}:
mkDerivation {
  pname = "bracer";
  version = "0.1.1.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    ansi-wl-pprint base bytestring compdata data-default hashable lens
    mtl parsers scientific semigroups trifecta unordered-containers
    utf8-string vector
  ];
  executableHaskellDepends = [
    ansi-wl-pprint base bytestring compdata data-default hashable hspec
    HUnit lens mtl parsers QuickCheck scientific semigroups trifecta
    unordered-containers utf8-string vector
  ];
  homepage = "http://github.com/patrickt/bracer";
  description = "a rewriting system for curly-brace languages";
  license = stdenv.lib.licenses.mit;
}
