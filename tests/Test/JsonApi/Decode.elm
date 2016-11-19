module Test.JsonApi.Decode exposing (suite)

import ElmTest as Test
import Json.Decode exposing (decodeString)
import JsonApi.Decode
import JsonApi.Data exposing (emptyLinks)
import JsonApi exposing (Document)
import JsonApi.Resources
import JsonApi.Documents
import Test.Examples exposing (validPayload, invalidPayload, payloadWithResourceIdentifiers)


suite : Test.Test
suite =
    Test.suite "JsonApi Decoders"
        [ decodesValidPayload
        , decodesInvalidPayload
        , decodesPayloadWithResourceIdentifiers
        ]


decodesValidPayload : Test.Test
decodesValidPayload =
    let
        succeedsWithValidPayload =
            Test.assert <|
                case decodeString JsonApi.Decode.document validPayload of
                    Ok _ ->
                        True

                    Err _ ->
                        False
    in
        Test.test "can decode a valid JSON API payload" succeedsWithValidPayload


decodesInvalidPayload : Test.Test
decodesInvalidPayload =
    let
        failsWithInvalidPayload =
            Test.assert <|
                case decodeString JsonApi.Decode.document invalidPayload of
                    Ok _ ->
                        False

                    Err _ ->
                        True
    in
        Test.test "fails properly with invalid payload" failsWithInvalidPayload


decodesPayloadWithResourceIdentifiers : Test.Test
decodesPayloadWithResourceIdentifiers =
    let
        resourceIdentifierMeta =
            decodeString JsonApi.Decode.document payloadWithResourceIdentifiers
                |> (flip Result.andThen) JsonApi.Documents.primaryResource
                |> Result.toMaybe
                |> (flip Maybe.andThen) JsonApi.Resources.meta
                |> Result.fromMaybe "Meta not found"
                |> (flip Result.andThen) (Json.Decode.decodeValue Json.Decode.string)
    in
        Test.assertEqual resourceIdentifierMeta (Ok "this is the second article")
            |> Test.test "it can decode resource identifiers as the primary data"
