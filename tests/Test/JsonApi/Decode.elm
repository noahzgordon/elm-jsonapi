module Test.JsonApi.Decode exposing (suite)

import Expect
import Json.Decode exposing (decodeString)
import JsonApi exposing (Document)
import JsonApi.Data exposing (emptyLinks)
import JsonApi.Decode
import JsonApi.Documents
import JsonApi.Resources
import Test
import Test.Examples exposing (invalidPayload, payloadWithResourceIdentifiers, validPayload)


suite : Test.Test
suite =
    Test.describe "JsonApi Decoders"
        [ decodesValidPayload
        , decodesInvalidPayload
        , decodesPayloadWithResourceIdentifiers
        ]


decodesValidPayload : Test.Test
decodesValidPayload =
    let
        succeedsWithValidPayload =
            \_ ->
                case decodeString JsonApi.Decode.document validPayload of
                    Ok _ ->
                        Expect.pass

                    Err _ ->
                        Expect.fail "Failed to decode a valid payload"
    in
    Test.test "can decode a valid JSON API payload" succeedsWithValidPayload


decodesInvalidPayload : Test.Test
decodesInvalidPayload =
    let
        failsWithInvalidPayload =
            \_ ->
                case decodeString JsonApi.Decode.document invalidPayload of
                    Ok _ ->
                        Expect.fail "Somehow decoded an invalid payload!"

                    Err _ ->
                        Expect.pass
    in
    Test.test "fails properly with invalid payload" failsWithInvalidPayload


decodesPayloadWithResourceIdentifiers : Test.Test
decodesPayloadWithResourceIdentifiers =
    let
        resourceIdentifierMeta =
            decodeString JsonApi.Decode.document payloadWithResourceIdentifiers
                |> Result.mapError Json.Decode.errorToString
                |> Result.andThen JsonApi.Documents.primaryResource
                |> Result.toMaybe
                |> Maybe.andThen (Maybe.map JsonApi.Resources.meta)
                |> Result.fromMaybe "Meta not found"
                |> Result.andThen (Result.fromMaybe "Meta is null")
                |> Result.andThen (Json.Decode.decodeValue Json.Decode.string >> Result.mapError Json.Decode.errorToString)
    in
    (\_ -> Expect.equal resourceIdentifierMeta (Ok "this is the second article"))
        |> Test.test "it can decode resource identifiers as the primary data"
