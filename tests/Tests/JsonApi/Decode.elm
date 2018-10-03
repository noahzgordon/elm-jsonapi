module Tests.JsonApi.Decode exposing (suite)

import Test exposing (..)
import Expect
import Json.Decode exposing (decodeString)
import JsonApi.Decode
import JsonApi.Data exposing (emptyLinks)
import JsonApi exposing (Document)
import JsonApi.Resources
import JsonApi.Documents
import Tests.Examples exposing (validPayload, invalidPayload, payloadWithResourceIdentifiers)


suite : Test.Test
suite =
    Test.describe "JsonApi Decoders"
        [ Test.test "can decode a valid JSON API payload" <|
            \_ ->
                case decodeString JsonApi.Decode.document validPayload of
                    Ok _ ->
                        Expect.pass

                    Err _ ->
                        Expect.fail "Failed to decode a valid payload"
        , Test.test "fails properly with invalid payload" <|
            \_ ->
                case decodeString JsonApi.Decode.document invalidPayload of
                    Ok _ ->
                        Expect.fail "Somehow decoded an invalid payload!"

                    Err _ ->
                        Expect.pass
        , Test.test "it can decode resource identifiers as the primary data" <|
            \_ ->
                let
                    resourceIdentifierMeta =
                        decodeString JsonApi.Decode.document payloadWithResourceIdentifiers
                            |> Result.andThen JsonApi.Documents.primaryResource
                            |> Result.toMaybe
                            |> Maybe.andThen JsonApi.Resources.meta
                            |> Result.fromMaybe "Meta not found"
                            |> Result.andThen (Json.Decode.decodeValue Json.Decode.string)
                in
                    Expect.equal resourceIdentifierMeta (Ok "this is the second article")
        , Test.test
        ]
