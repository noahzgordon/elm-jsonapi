module Tests exposing (all)

import Test exposing (..)

import Test.JsonApi.Documents
import Test.JsonApi.Decode
import Test.JsonApi.Errors

all : Test
all =
    describe "Elm Standard Library Tests"
        [ Test.JsonApi.Documents.suite
        , Test.JsonApi.Decode.suite
        , Test.JsonApi.Errors.suite
        ]
