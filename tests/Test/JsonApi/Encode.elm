module Test.JsonApi.Encode exposing (suite)

import Test
import Expect
import Json.Encode exposing (string)
import Json.Decode as Decode exposing (decodeString, decodeValue, at)
import JsonApi.Encode
import JsonApi.Decode
import JsonApi.Documents
import JsonApi.Resources as Resources
import Test.Examples exposing (simpleResource)


suite : Test.Test
suite =
    Test.describe "JsonApi Encoders"
        [ encodesClientResource
        , encodesResource
        ]


encodesClientResource : Test.Test
encodesClientResource =
    let
        assertFieldEquality fieldList expectedString resource =
            Expect.equal (decodeValue (at fieldList Decode.string) resource) (Ok expectedString)

        validUuid =
            "123e4567-e89b-12d3-a456-426655440000"

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
                |> Resources.withUuid validUuid
                |> Result.map JsonApi.Encode.clientResource
                |> Result.map
                    (Expect.all
                        [ assertFieldEquality [ "data", "id" ] validUuid
                        , assertFieldEquality [ "data", "type" ] "jedi"
                        , assertFieldEquality [ "data", "attributes", "first_name" ] "Luke"
                        , assertFieldEquality [ "data", "attributes", "last_name" ] "Skywalker"
                        , assertFieldEquality [ "data", "attributes", "home_planet" ] "Tatooine"
                        , assertFieldEquality [ "data", "relationships", "father", "data", "type" ] "jedi"
                        , assertFieldEquality [ "data", "relationships", "father", "data", "id" ] "vader"
                        , assertFieldEquality [ "data", "relationships", "sister", "data", "type" ] "princess"
                        , assertFieldEquality [ "data", "relationships", "sister", "data", "id" ] "leia"
                        ]
                    )
                |> Result.withDefault (Expect.fail "Client resource coud not be encoded")
    in
        Test.test "it encodes a client resource" assertion


encodesResource : Test.Test
encodesResource =
    let
        assertFieldEquality fieldList expectedString resource =
            Expect.equal (decodeValue (at fieldList Decode.string) resource) (Ok expectedString)

        decodedResource =
            decodeString JsonApi.Decode.document simpleResource
                |> Result.andThen JsonApi.Documents.primaryResource
                |> Result.map JsonApi.Encode.resource

        assertion _ =
            case decodedResource of
                Ok resource ->
                    (Expect.all
                        [ assertFieldEquality [ "data", "id" ] "1"
                        , assertFieldEquality [ "data", "type" ] "articles"
                        , assertFieldEquality [ "data", "attributes", "title" ] "JSON API paints my bikeshed!"
                        , assertFieldEquality [ "data", "relationships", "author", "data", "type" ] "people"
                        , assertFieldEquality [ "data", "relationships", "author", "data", "id" ] "9"
                        ]
                    )
                        resource

                Err string ->
                    Expect.fail string
    in
        Test.test "it encodes a resource fetched from the server" assertion
