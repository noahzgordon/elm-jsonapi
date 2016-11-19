module Tests.JsonApi.Decode exposing (suite)

import Test
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
        [ decodesValidPayload
        , decodesInvalidPayload
        , decodesPayloadWithResourceIdentifiers
        ]


decodesValidPayload : Test.Test
decodesValidPayload =
    let
        succeedsWithValidPayload =
            Expect.true "" <|
                case decodeString JsonApi.Decode.document validPayload of
                    Ok _ ->
                        True

                    Err _ ->
                        False
    in
        Test.test "can decode a valid JSON API payload" <| \() -> succeedsWithValidPayload


decodesInvalidPayload : Test.Test
decodesInvalidPayload =
    let
        failsWithInvalidPayload =
            Expect.true "" <|
                case decodeString JsonApi.Decode.document invalidPayload of
                    Ok _ ->
                        False

                    Err _ ->
                        True
    in
        Test.test "fails properly with invalid payload" <| \() -> failsWithInvalidPayload


decodesPayloadWithResourceIdentifiers : Test.Test
decodesPayloadWithResourceIdentifiers =
    let
        resourceIdentifierMeta =
            decodeString JsonApi.Decode.document payloadWithResourceIdentifiers
                |> Result.andThen JsonApi.Documents.primaryResource
                |> Result.toMaybe
                |> Maybe.andThen JsonApi.Resources.meta
                |> Result.fromMaybe "Meta not found"
                |> Result.andThen (Json.Decode.decodeValue Json.Decode.string)
    in
        Test.test "it can decode resource identifiers as the primary data"
          <| \() -> Expect.equal resourceIdentifierMeta (Ok "this is the second article")
