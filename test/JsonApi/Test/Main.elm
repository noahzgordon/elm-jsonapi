module JsonApi.Test.Main (..) where

import ElmTest exposing (..)
import Dict
import Debug
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi exposing (..)
import JsonApi.Decode exposing (..)
import Graphics.Element exposing (Element)

import JsonApi.Test.Decode


main : Element
main =
  elementRunner tests


tests : Test
tests =
  suite
    "All tests"
    [ JsonApi.Test.Decode.suite ]


