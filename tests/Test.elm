module Main exposing (..)

import ElmTest exposing (..)
import Test.JsonApi.Documents
import Test.JsonApi.Decode
import Test.JsonApi.Errors


tests : Test
tests =
    suite "Elm Standard Library Tests"
        [ Test.JsonApi.Documents.suite
        , Test.JsonApi.Decode.suite
        , Test.JsonApi.Errors.suite
        ]


main =
    runSuite tests
