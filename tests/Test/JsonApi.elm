module Test.JsonApi exposing (suite)

import ElmTest as Test
import Dict
import Debug
import List.Extra
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi
import JsonApi.Decode
import JsonApi.Data exposing (Document, Resource(..), emptyLinks)
import JsonApi.OneOrMany exposing (OneOrMany(..))
import Test.Examples exposing (validPayload, recursivePayload)


suite : Test.Test
suite =
    Test.suite "JsonApi core functions"
        [ primaryResourceErrors
        , resourceChaining
        , resourceCircularReferences
        , jsonapiObject
        ]


primaryResourceErrors : Test.Test
primaryResourceErrors =
    Test.test "it returns an error when used incorrectly"
        (Test.assertEqual (Err "Expected a singleton resource, got a collection")
            (JsonApi.primaryResource exampleDocument)
        )


resourceChaining : Test.Test
resourceChaining =
    let
        decodedPrimaryResource =
            case JsonApi.primaryResourceCollection exampleDocument of
                Err string ->
                    Debug.crash string

                Ok resourceList ->
                    case List.head resourceList of
                        Nothing ->
                            Debug.crash "Expected non-empty collection"

                        Just resource ->
                            resource

        decodedPrimaryResourceAttrs =
            JsonApi.attributes decodedPrimaryResource

        relatedCommentResource =
            case JsonApi.relatedResourceCollection "comments" decodedPrimaryResource of
                Err string ->
                    Debug.crash string

                Ok commentResources ->
                    case (List.Extra.find (\(Resource ident _ _) -> ident.id == "12") commentResources) of
                        Nothing ->
                            Debug.crash "Expected to find related comment with id 12"

                        Just resource ->
                            resource

        relatedCommentResourceAttrs =
            JsonApi.attributes relatedCommentResource

        relatedCommentAuthorResource =
            case JsonApi.relatedResource "author" relatedCommentResource of
                Err string ->
                    Debug.crash string

                Ok resource ->
                    resource

        relatedCommentAuthorResourceAttrs =
            JsonApi.attributes relatedCommentAuthorResource

        primaryAttributesAreDecoded =
            Test.assertEqual (Dict.get "title" decodedPrimaryResourceAttrs)
                (Just (Json.Encode.string "JSON API paints my bikeshed!"))

        relationshipAttributesAreDecoded =
            Test.assertEqual (Dict.get "body" relatedCommentResourceAttrs)
                (Just (Json.Encode.string "I like XML better"))

        relationshipsAreHydratedRecursively =
            Test.assertEqual (Dict.get "twitter" relatedCommentAuthorResourceAttrs)
                (Just (Json.Encode.string "dgeb"))
    in
        Test.suite "decoding and relationships"
            [ Test.test "it extracts the primary data attributes from the document" primaryAttributesAreDecoded
            , Test.test "it extracts the relationship attributes" relationshipAttributesAreDecoded
            , Test.test "recursively hydrates relationships" relationshipsAreHydratedRecursively
            ]


resourceCircularReferences : Test.Test
resourceCircularReferences =
    let
        primaryResourceResult =
            decodeString JsonApi.Decode.document recursivePayload
                `Result.andThen` JsonApi.primaryResource
                `Result.andThen` (JsonApi.relatedResource "author")
                `Result.andThen` (JsonApi.relatedResource "article")

        primaryResourceTitle =
            case primaryResourceResult of
                Ok resource ->
                    Dict.get "title" (JsonApi.attributes resource)

                Err string ->
                    Debug.crash string
    in
        Test.test "it can handle circular references in the payload"
            (Test.assertEqual (Just (Json.Encode.string "JSON API paints my bikeshed!"))
                primaryResourceTitle
            )


jsonapiObject : Test.Test
jsonapiObject =
    let
        expectedResult =
            Just
                { version = Just "1.0"
                , meta = Just (Json.Encode.object [ ( "foo", Json.Encode.string "bar" ) ])
                }
    in
        Test.test "it can extract jsonapi object information"
            (Test.assertEqual expectedResult (JsonApi.jsonapi exampleDocument))


exampleDocument : Document
exampleDocument =
    case decodeString JsonApi.Decode.document validPayload of
        Ok doc ->
            doc

        Err string ->
            Debug.crash string
