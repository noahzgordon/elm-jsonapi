module Test.JsonApi.Resources exposing (suite)

import Test
import Expect
import Test.Examples exposing (simpleResource)
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi.Decode
import JsonApi.Documents as D
import JsonApi.Resources as R


suite : Test.Test
suite =
    Test.describe "working with resources"
        [ updateExistingAttributes
        , updateNewAttributes
        ]


updateExistingAttributes : Test.Test
updateExistingAttributes =
    Test.test "it replaces attributes when they exist"
        (\_ ->
            Expect.equal (Ok "A new title")
                (decodeString JsonApi.Decode.document simpleResource
                    |> Result.andThen D.primaryResource
                    |> Result.map (R.updateAttributes [ ( "title", Json.Encode.string "A new title" ) ])
                    |> Result.andThen (R.attribute "title" Json.Decode.string)
                )
        )


updateNewAttributes : Test.Test
updateNewAttributes =
    Test.test "it adds attributes when they don't exist"
        (\_ ->
            Expect.equal (Ok "Ursula K. Le Guin")
                (decodeString JsonApi.Decode.document simpleResource
                    |> Result.andThen D.primaryResource
                    |> Result.map (R.updateAttributes [ ( "author", Json.Encode.string "Ursula K. Le Guin" ) ])
                    |> Result.andThen (R.attribute "author" Json.Decode.string)
                )
        )
