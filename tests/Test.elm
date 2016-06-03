module Main exposing (..)

import ElmTest exposing (..)

import Test.JsonApi as JsonApi

tests : Test
tests =
    suite "Elm Standard Library Tests"
        [ JsonApi.suite ]


main =
    runSuite tests
