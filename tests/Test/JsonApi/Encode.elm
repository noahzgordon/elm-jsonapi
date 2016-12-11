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

        assertion _ =
            Resources.build "jedi"
                |> Resources.withAttributes
                    [ ( "first_name", string "Luke" )
                    , ( "last_name", string "Skywalker" )
                    ]
                |> Resources.withAttributes
                    [ ( "home_planet", string "Tatooine" )
                    ]
                |> Resources.withRelationship "father" { id = "vader", resourceType = "jedi" }
                |> Resources.withRelationship "sister" { id = "leia", resourceType = "princess" }
                |> JsonApi.Encode.clientResource
                |> Expect.all
                    [ assertFieldEquality [ "data", "type" ] "jedi"
                    , assertFieldEquality [ "data", "attributes", "first_name" ] "Luke"
                    , assertFieldEquality [ "data", "attributes", "last_name" ] "Skywalker"
                    , assertFieldEquality [ "data", "attributes", "home_planet" ] "Tatooine"
                    , assertFieldEquality [ "data", "relationships", "father", "data", "type" ] "jedi"
                    , assertFieldEquality [ "data", "relationships", "father", "data", "id" ] "vader"
                    , assertFieldEquality [ "data", "relationships", "sister", "data", "type" ] "princess"
                    , assertFieldEquality [ "data", "relationships", "sister", "data", "id" ] "leia"
                    ]
    in
        Test.test "it encodes a client resource" assertion
