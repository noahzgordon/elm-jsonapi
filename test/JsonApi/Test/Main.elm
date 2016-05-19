module JsonApi.Test.Main exposing (..)

import ElmTest exposing (..)
import Dict
import Debug
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi.Decode exposing (..)

import JsonApi.Test.Decode


main =
  runSuiteHtml tests


tests : Test
tests =
  suite
    "All tests"
    [ JsonApi.Test.Decode.suite ]


