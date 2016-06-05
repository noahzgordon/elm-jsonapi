module Main exposing (..)

import ElmTest exposing (..)

import Test.JsonApi
import Test.JsonApi.Decode

tests : Test
tests =
    suite "Elm Standard Library Tests"
        [ Test.JsonApi.suite
        , Test.JsonApi.Decode.suite
        ]


main =
    runSuite tests
