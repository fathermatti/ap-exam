-- This is a suggested skeleton for your main black-box tests. You are not
-- required to use Tasty, but be sure that your test suite can be build
-- and run against any implementation of the APQL APIs.

import           Types
import           Parser
import Preprocessor 
import           Engine
import           Test.Tasty
import           Test.Tasty.HUnit
import qualified Data.Set as S
import qualified Data.Map as M
main :: IO ()
main = defaultMain $ localOption (mkTimeout 1000000) tests

tests :: TestTree
tests = testGroup
  "Simple parsing"
  [programTests, atomTests, ruleTests, conditionTests, precedenceTests, clausifyTests, stratifyTests, termzTests, termsTests, constantTests, negativeWhiteSpaceTests]

programTests = testGroup
  "Program tests"
  [ let t = "x(). y()."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" []) CTrue, Rule (Atom "y" []) CTrue]
  , testCase "x().\\ny()." $ parseString "x().\ny()." @?= Right
    [Rule (Atom "x" []) CTrue, Rule (Atom "y" []) CTrue]
  , testCase " \\nx().\\n  y().  \\n\\n"
  $   parseString " \nx().\n  y()  \n\n."
  @?= Right [Rule (Atom "x" []) CTrue, Rule (Atom "y" []) CTrue]
  ]

ruleTests = testGroup
  "Rule tests"
  [ let t = "x(X) if y(Y)."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" [TVar "X"]) (CAtom (Atom "y" [TVar "Y"]))]
  , let t = "x(X) unless y(Y)."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" [TVar "X"]) (CNot (CAtom (Atom "y" [TVar "Y"])))]
  ]

conditionTests = testGroup
  "Condition tests"
  [ let t = "x() if y is z."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" []) (CEq (TVar "y") (TVar "z"))]
  , let t = "x() if y is not z."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" []) (CNot (CEq (TVar "y") (TVar "z")))]
  , let t = "x() if true."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) CTrue]
  , let t = "x() if false."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) (CNot CTrue)]
  , let t = "x() if not true."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) (CNot CTrue)]
  , let t = "x() if y() and z()."
    in
      testCase t $ parseString t @?= Right
        [Rule (Atom "x" []) (CAnd (CAtom (Atom "y" [])) (CAtom (Atom "z" [])))]
  , let t = "x() if not true."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) (CNot CTrue)]
  , let t = "x() if not not true."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" []) (CNot (CNot CTrue))]
  , let t = "x() if y() or z()."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" []) (COr (CAtom (Atom "y" [])) (CAtom (Atom "z" [])))]
  , let t = "x() if y() implies z()."
    in  testCase t $ parseString t @?= Right
          [ Rule (Atom "x" [])
                 (COr (CNot (CAtom (Atom "y" []))) (CAtom (Atom "z" [])))
          ]
  , let t = "x() if not true."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) (CNot CTrue)]
  , let t = "x() if y() and z()."
    in
      testCase t $ parseString t @?= Right
        [Rule (Atom "x" []) (CAnd (CAtom (Atom "y" [])) (CAtom (Atom "z" [])))]
  ]


atomTests = testGroup
  "Atom tests"
  [ let t = "x()."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) CTrue]
  , let t = " x(). "
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) CTrue]
  , let t = "x(t)."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TVar "t"]) CTrue]
  , let t = "x(\"y\") ."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TData "y"]) CTrue]
  , let t = "x(\"y\", z) ."
    in  testCase t $ parseString t @?= Right
          [Rule (Atom "x" [TData "y", TVar "z"]) CTrue]
  ]

termzTests = testGroup
  "Termz tests"
  [ let t = "x()."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" []) CTrue]
  , let t = "x(y)."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TVar "y"]) CTrue]
  ]


termsTests = testGroup
  "Terms tests"
  [ 
    let t = "x(y). "
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TVar "y"]) CTrue]
  , let t = "x(y, z, v, w) ."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TVar "y",TVar "z",TVar "v",TVar "w"]) CTrue]
  ]

constantTests = testGroup
  "String constant tests"
  [ 
    let t = "x(y). "
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TVar "y"]) CTrue]
  , let t = "x(\"y\")."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TData "y"]) CTrue]
  , let t = "x(\"Hello world!\")."
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TData "Hello world!"]) CTrue]
  , let t = "x(y, \"z\", q)."
    in  testCase t $ parseString t @?=
          Right [Rule (Atom "x" [TVar "y",TData "z",TVar "q"]) CTrue]
  ]

negativeWhiteSpaceTests = testGroup
  "Negative constant tests"
  [ 
    let t = "x(isnot). "
    in  testCase t $ parseString t @?= Right [Rule (Atom "x" [TVar "isnot"]) CTrue]
  , let t = "x(is not)."
    in  testCase t $ parseString t @?= Left (EUser "parsing failed")
  ]


precedenceTests = testGroup
  "Precedence tests"
  [ let t = "x() if x() or y() and z()."
    in  testCase t $ parseString t @?= Right
          [ Rule
              (Atom "x" [])
              (COr (CAtom (Atom "x" []))
                   (CAnd (CAtom (Atom "y" [])) (CAtom (Atom "z" [])))
              )
          ]
  , testCase "Above using redundant parenthesis"
  $   parseString "x() if x() or y() and z()."
  @?= parseString "x() if x() or (y() and z())."
  , let t = "x() if x() or not y() and z()."
    in  testCase t $ parseString t @?= Right
          [ Rule
              (Atom "x" [])
              (COr (CAtom (Atom "x" []))
                   (CAnd (CNot (CAtom (Atom "y" []))) (CAtom (Atom "z" [])))
              )
          ]
  , testCase "Above using redundant parenthesis"
  $   parseString "x() if x() or not y() and z()."
  @?= parseString "x() if x() or ((not y()) and z())."
  , let t = "x() if x() or not y() and z()."
    in  testCase t $ parseString t @?= Right
          [ Rule
              (Atom "x" [])
              (COr (CAtom (Atom "x" []))
                   (CAnd (CNot (CAtom (Atom "y" []))) (CAtom (Atom "z" [])))
              )
          ]
  , let t = "a(x) unless b(x) and c() implies true."
    in
      testCase t $ parseString t @?= Right
        [ Rule
            (Atom "a" [TVar "x"])
            (CNot
              (COr
                (CNot (CAnd (CAtom (Atom "b" [TVar "x"])) (CAtom (Atom "c" [])))
                )
                CTrue
              )
            )
        ]
  , testCase "Above using rewrite"
  $   parseString "a(x) unless b(x) and c() implies true."
  @?= parseString "a(x) if not (not (b(x) and c()) or true)."
  ]

clausifyTests = testGroup
  "Clausify tests"
  [ let t = "p(x) if q(x) and not (r(x) and x is not a)."
    in  testCase t $ clausify [Rule (Atom "p1" [TVar "x"]) (CEq (TVar "x") (TData "a"))] @?= Right (IDB [("p",1)] [Clause (Atom "p" [TVar "x"]) [Atom "q" [TVar "x"]] [TNot (Atom "r" [TVar "x"])],Clause (Atom "p" [TVar "x"]) [Atom "q" [TVar "x"]] [TEq (TVar "x") (TVar "a")]])
  ]
  
stratifyTests = testGroup
  "Stratify tests"
  [ let t = "p(x) if q(x) and not (r(x) and x is not a)."
    in  testCase t $ stratify (IDB [("s",0),("q",0),("p",0)] [Clause (Atom "p" []) [Atom "q" [],Atom "r" []] [],Clause (Atom "p" []) [Atom "p" []] [TNot (Atom "r" [])],Clause (Atom "q" []) [Atom "q" []] [TNot (Atom "s" [])],Clause (Atom "s" []) [Atom "r" []] []]) [("r", 0)] @?= Right [[("s",0)],[("q",0),("p",0)]]
  ]

testCaseBad s t =
  testCase ("*" ++ s) $
    case t of
      Right a -> assertFailure $ "Unexpected success: " ++ show a
      Left (EUser _) -> return () -- any message is fine
      Left em -> assertFailure $ "Error: " ++ show em

rudimentary :: TestTree
rudimentary =
 testGroup "Rudimentary tests"
   [testCase "parse1" $
      parseString pgmStr @?= Right pgmAST,
    testCaseBad "parse2" $
      parseString "p(x) if .",
    testCase "clausify1" $
      clausify pgmAST @?= Right pgmIDB,
    testCaseBad "clausify2" $
      clausify [Rule (Atom "p" [TVar "x"]) CTrue],
    testCase "stratify1" $ -- too strict! other correct answers also possible
      stratify pgmIDB [("r",1)] @?= Right pgmStratX,
    testCaseBad "stratify2" $
      stratify (IDB [("p",0)]
                    [Clause (Atom "p" []) [] [TNot (Atom "p" [])]]) [],
    testCase "execute" $
      fmap M.fromList (execute pgmIDB pgmStratX [(("r",1), pgmExtR)])
        @?= Right (M.fromList pgmEDB) ]
 where
   pgmStr = "p(x,y) if q(x) and r(y). q(\"a\")."
   pgmAST = [Rule (Atom "p" [TVar "x", TVar "y"])
                  (CAnd (CAtom (Atom "q" [TVar "x"]))
                        (CAtom (Atom "r" [TVar "y"]))),
             Rule (Atom "q" [TData "a"])
                  CTrue]
   pgmIDB = IDB [("p", 2), ("q",1)]
                [Clause (Atom "p" [TVar "x", TVar "y"])
                        [Atom "q" [TVar "x"], Atom "r" [TVar "y"]]
                        [],
                 Clause (Atom "q" [TData "a"]) [] []]
   pgmStratX = [[("p",2), ("q",1)]]
   pgmExtR = S.fromList [["b"], ["c"]]
   pgmExtQ = S.fromList [["a"]]
   pgmExtP = S.fromList [["a", "b"], ["a", "c"]]
   pgmEDB = [(("p",2),pgmExtP), (("q",1), pgmExtQ), (("r",1), pgmExtR)]
