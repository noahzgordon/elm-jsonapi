module Tests.JsonApi.Errors exposing (suite)

import Test
import Expect
import Debug exposing (crash)
import Tests.Examples exposing (payloadWithErrors)
import Json.Decode exposing (decodeString)
import JsonApi.Decode exposing (errors)
import JsonApi


suite : Test.Test
suite =
    Test.describe "error handling"
        [ documentErrors
        ]


documentErrors : Test.Test
documentErrors =
    let
        error =
            case decodeString errors payloadWithErrors of
                Ok errorObjects ->
                    List.head errorObjects

                Err _ ->
                    crash "Expected decode to pass in test 'documentErrors'"

        assertion =
            Expect.equal error
                (Just
                    { id = Just "123"
                    , links =
                        Just
                            { about = Just "something/happened"
                            }
                    , status = Just "500"
                    , code = Just "12345"
                    , title = Just "Something Happened"
                    , detail = Just "I'm not really sure what happened"
                    , source =
                        Just
                            { pointer = Just "/foo/0"
                            , parameter = Nothing
                            }
                    , meta = Nothing
                    }
                )
    in
        Test.test "it decodes error payloads into error objects" <| \() -> assertion
