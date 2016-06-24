module Test.JsonApi.Decode exposing (suite)

import ElmTest as Test
import Json.Decode exposing (decodeString)
import JsonApi.Decode
import JsonApi.Data exposing (emptyLinks)
import JsonApi.Documents exposing (Document)
import Test.Examples exposing (validPayload, invalidPayload)


suite : Test.Test
suite =
    Test.suite "JsonApi Decoders" [ document ]


document : Test.Test
document =
    let
        succeedsWithValidPayload =
            Test.assert
                <| case decodeString JsonApi.Decode.document validPayload of
                    Ok _ ->
                        True

                    Err _ ->
                        False

        failsWithInvalidPayload =
            Test.assert
                <| case decodeString JsonApi.Decode.document invalidPayload of
                    Ok _ ->
                        False

                    Err _ ->
                        True
    in
        Test.suite "document"
            [ Test.test "can decode a valid JSON API payload" succeedsWithValidPayload
            , Test.test "fails properly with invalid payload" failsWithInvalidPayload
            ]
