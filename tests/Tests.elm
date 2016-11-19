module Tests exposing (..)

import Test exposing (..)

import Tests.JsonApi.Documents
import Tests.JsonApi.Decode
import Tests.JsonApi.Errors


all: Test
all =
    describe "Elm Standard Library Tests"
        [ Tests.JsonApi.Documents.suite
        , Tests.JsonApi.Decode.suite
        , Tests.JsonApi.Errors.suite
        ]

