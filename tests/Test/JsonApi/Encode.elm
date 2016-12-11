module Test.JsonApi.Encode exposing (suite)

import Test
import Expect
import Json.Encode exposing (string)
import Json.Decode as Decode exposing (decodeValue, at)
import JsonApi.Encode
import JsonApi.Resources as Resources


suite : Test.Test
suite =
    Test.describe "JsonApi Encoders"
        [ encodesClientResource
        ]


encodesClientResource : Test.Test
encodesClientResource =
    let
        assertFieldEquality fieldList expectedString resource =
            Expect.equal (decodeValue (at fieldList Decode.string) resource) (Ok expectedString)

        assertion =
            Resources.build "jedi"
                |> Resources.withAttributes
                    [ ( "first_name", string "Luke" )
                    , ( "last_name", string "Skywalker" )
                    ]
                |> Resources.withRelationship "father" { id = "vader", resourceType = "jedi" }
                |> JsonApi.Encode.clientResource
                |> Expect.all
                    [ assertFieldEquality [ "data", "attributes", "first_name" ] "Luke"
                    , assertFieldEquality [ "data", "attributes", "last_name" ] "Skywalker"
                    , assertFieldEquality [ "data", "relationships", "father", "data", "type" ] "jedi"
                    , assertFieldEquality [ "data", "relationships", "father", "data", "id" ] "vader"
                    ]
    in
        Test.test "it encodes a client resource" (\() -> assertion)
